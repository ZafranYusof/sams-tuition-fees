const express = require('express');
const crypto = require('crypto');
const https = require('https');
const mongoose = require('mongoose');
const Fee = require('../models/Fee');
const Payment = require('../models/Payment');
const { auth } = require('../middleware/auth');

const router = express.Router();

// ─── TOYYIBPAY (FPX) ───

// Create FPX payment bill
router.post('/fpx/create', auth, async (req, res) => {
  try {
    const { feeId, amount, description, bank } = req.body;
    if (!feeId || !mongoose.Types.ObjectId.isValid(feeId)) {
      return res.status(400).json({ error: 'Invalid fee ID' });
    }
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }
    const User = require('../models/User');
    
    const fee = await Fee.findById(feeId);
    if (!fee) return res.status(404).json({ error: 'Fee not found' });

    // Get full user info from DB
    const user = await User.findById(req.user.id);

    const billData = new URLSearchParams({
      userSecretKey: process.env.TOYYIBPAY_SECRET_KEY,
      categoryCode: process.env.TOYYIBPAY_CATEGORY_CODE,
      billName: description || 'UMPSA Tuition Fee Payment',
      billDescription: `Fee payment for ${feeId}`,
      billPriceSetting: 1,
      billPayorInfo: 1,
      billAmount: Math.round(amount * 100), // in cents
      billReturnUrl: `${process.env.APP_URL || 'https://sams-app-vasb.onrender.com'}/api/payment/fpx/callback`,
      billCallbackUrl: `${process.env.APP_URL || 'https://sams-app-vasb.onrender.com'}/api/payment/fpx/webhook`,
      billExternalReferenceNo: `FPX-${feeId}-${Date.now()}`,
      billTo: user?.name || 'Student',
      billEmail: user?.email || 'student@umpsa.edu.my',
      billPhone: user?.phone || '0111111111',
      billPaymentChannel: 0, // FPX only
    });

    const baseUrl = process.env.TOYYIBPAY_URL || 'https://dev.toyyibpay.com'; // dev = sandbox
    
    const response = await fetch(`${baseUrl}/index.php/api/createBill`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: billData.toString(),
    });

    const result = await response.json();

    if (result && result[0] && result[0].BillCode) {
      // Save pending payment
      const payment = new Payment({
        student: req.user.id,
        fee: feeId,
        amount,
        method: 'fpx',
        transactionId: result[0].BillCode,
        bank: bank || 'FPX',
        status: 'pending',
      });
      await payment.save();

      res.json({
        billCode: result[0].BillCode,
        paymentUrl: `${baseUrl}/${result[0].BillCode}`,
        payment: payment,
      });
    } else {
      res.status(400).json({ error: 'Failed to create bill', details: result });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// FPX callback (redirect after payment)
router.get('/fpx/callback', async (req, res) => {
  try {
    const { billcode, status_id, transaction_id, order_id } = req.query;
    
    const payment = await Payment.findOne({ transactionId: billcode });
    if (payment) {
      // status_id: 1 = success, 2 = pending, 3 = failed
      if (status_id === '1') {
        payment.status = 'success';
        payment.receipt = `RCP-${Date.now()}`;
        await payment.save();

        // Update fee
        const fee = await Fee.findById(payment.fee);
        if (fee) {
          fee.paidAmount += payment.amount;
          fee.status = fee.paidAmount >= fee.totalAmount ? 'paid' : 'partial';
          await fee.save();
        }
      } else if (status_id === '3') {
        payment.status = 'failed';
        await payment.save();
      }
    }

    // Redirect to app (deep link or web)
    const redirectUrl = status_id === '1' 
      ? `samsapp://payment/success?billcode=${billcode}`
      : `samsapp://payment/failed?billcode=${billcode}`;
    
    res.redirect(redirectUrl);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// FPX webhook (server-to-server callback)
router.post('/fpx/webhook', async (req, res) => {
  try {
    const { billcode, status_id, transaction_id } = req.body;
    
    const payment = await Payment.findOne({ transactionId: billcode });
    if (payment && payment.status === 'pending') {
      if (status_id === '1') {
        payment.status = 'success';
        payment.receipt = `RCP-${Date.now()}`;
        await payment.save();

        const fee = await Fee.findById(payment.fee);
        if (fee) {
          fee.paidAmount += payment.amount;
          fee.status = fee.paidAmount >= fee.totalAmount ? 'paid' : 'partial';
          await fee.save();
        }
      } else if (status_id === '3') {
        payment.status = 'failed';
        await payment.save();
      }
    }

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Check FPX payment status
router.get('/fpx/status/:billCode', auth, async (req, res) => {
  try {
    const payment = await Payment.findOne({ transactionId: req.params.billCode });
    if (!payment) return res.status(404).json({ error: 'Payment not found' });
    res.json({ status: payment.status, payment });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── STRIPE (CARD) ───

// Create Stripe Checkout Session
router.post('/card/create-intent', auth, async (req, res) => {
  try {
    const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
    const { feeId, amount } = req.body;
    if (!feeId || !mongoose.Types.ObjectId.isValid(feeId)) {
      return res.status(400).json({ error: 'Invalid fee ID' });
    }
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }

    const fee = await Fee.findById(feeId);
    if (!fee) return res.status(404).json({ error: 'Fee not found' });

    const appUrl = process.env.APP_URL || 'https://sams-app-vasb.onrender.com';

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{
        price_data: {
          currency: 'myr',
          product_data: { name: 'UMPSA Tuition Fee Payment' },
          unit_amount: Math.round(amount * 100),
        },
        quantity: 1,
      }],
      mode: 'payment',
      success_url: `${appUrl}/api/payment/card/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${appUrl}/api/payment/card/cancel`,
      metadata: { feeId, studentId: req.user.id },
    });

    // Save pending payment
    const payment = new Payment({
      student: req.user.id,
      fee: feeId,
      amount,
      method: 'card',
      transactionId: session.id,
      status: 'pending',
    });
    await payment.save();

    res.json({
      paymentUrl: session.url,
      sessionId: session.id,
      paymentIntentId: session.id,
      payment,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Stripe success redirect
router.get('/card/success', async (req, res) => {
  try {
    const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
    const { session_id } = req.query;

    const session = await stripe.checkout.sessions.retrieve(session_id);
    const payment = await Payment.findOne({ transactionId: session_id });

    if (payment && payment.status === 'pending' && session.payment_status === 'paid') {
      payment.status = 'success';
      payment.receipt = `RCP-${Date.now()}`;
      await payment.save();

      const fee = await Fee.findById(payment.fee);
      if (fee) {
        fee.paidAmount += payment.amount;
        fee.status = fee.paidAmount >= fee.totalAmount ? 'paid' : 'partial';
        await fee.save();
      }
    }

    res.redirect('samsapp://payment/success?session_id=' + session_id);
  } catch (err) {
    res.redirect('samsapp://payment/failed');
  }
});

// Stripe cancel redirect
router.get('/card/cancel', (req, res) => {
  res.redirect('samsapp://payment/failed');
});

// Confirm Stripe payment (polling from app)
router.post('/card/confirm', auth, async (req, res) => {
  try {
    const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
    const { paymentIntentId } = req.body;

    const session = await stripe.checkout.sessions.retrieve(paymentIntentId);
    const payment = await Payment.findOne({ transactionId: paymentIntentId });

    if (!payment) return res.status(404).json({ error: 'Payment not found' });

    if (session.payment_status === 'paid') {
      if (payment.status === 'pending') {
        payment.status = 'success';
        payment.receipt = `RCP-${Date.now()}`;
        await payment.save();

        const fee = await Fee.findById(payment.fee);
        if (fee) {
          fee.paidAmount += payment.amount;
          fee.status = fee.paidAmount >= fee.totalAmount ? 'paid' : 'partial';
          await fee.save();
        }
      }
      res.json({ status: 'success', payment });
    } else {
      res.json({ status: 'pending', payment });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Stripe webhook
router.post('/card/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  try {
    const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
    const sig = req.headers['stripe-signature'];
    const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

    let event;
    if (endpointSecret) {
      event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
    } else {
      event = req.body;
    }

    if (event.type === 'payment_intent.succeeded') {
      const paymentIntent = event.data.object;
      const payment = await Payment.findOne({ transactionId: paymentIntent.id });
      
      if (payment && payment.status === 'pending') {
        payment.status = 'success';
        payment.receipt = `RCP-${Date.now()}`;
        await payment.save();

        const fee = await Fee.findById(payment.fee);
        if (fee) {
          fee.paidAmount += payment.amount;
          fee.status = fee.paidAmount >= fee.totalAmount ? 'paid' : 'partial';
          await fee.save();
        }
      }
    }

    res.json({ received: true });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// Get Stripe publishable key (for frontend)
router.get('/card/config', (req, res) => {
  res.json({ publishableKey: process.env.STRIPE_PUBLISHABLE_KEY });
});

module.exports = router;
