const express = require('express');
const crypto = require('crypto');
const https = require('https');
const axios = require('axios');
const mongoose = require('mongoose');
const Fee = require('../models/ManageTuitionFees/Fee');
const Payment = require('../models/ManageTuitionFees/Payment');
const { auth } = require('../middleware/auth');

const router = express.Router();

// ADMIN: Fix stuck payment by bill code (one-time fix)
router.post('/fix-payment', auth, async (req, res) => {
  try {
    const { billCode, newFeeId } = req.body;
    const payment = await Payment.findOne({ paymentTxnRef: billCode });
    if (!payment) return res.status(404).json({ error: 'Payment not found' });
    
    payment.paymentStatus = 'completed';
    payment.receipt = payment.receipt || `RCP-${Date.now()}`;
    if (newFeeId) payment.fee = newFeeId;
    await payment.save();

    // Update fee paid amount
    const fee = await Fee.findById(payment.fee);
    if (fee) {
      fee.paidAmount = (fee.paidAmount || 0) + payment.paymentAmount;
      fee.feeStatus = fee.paidAmount >= fee.feeAmount ? 'paid' : 'partial';
      await fee.save();
    }

    res.json({ success: true, payment, fee });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

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
    const Student = require('../models/Student');
    
    const fee = await Fee.findById(feeId);
    if (!fee) return res.status(404).json({ error: 'Fee not found' });

    // Cancel any stale pending payments for this fee (older than 15 min)
    await Payment.updateMany(
      { student: req.user.id, fee: feeId, paymentStatus: 'pending', expiresAt: { $lt: new Date() } },
      { $set: { paymentStatus: 'failed' } }
    );

    // Check for existing pending payment for this fee (avoid duplicate)
    const existingPayment = await Payment.findOne({
      student: req.user.id,
      fee: feeId,
      paymentStatus: 'pending',
    });
    
    if (existingPayment) {
      // Return existing payment URL instead of creating new one
      const baseUrl = process.env.TOYYIBPAY_URL || 'https://dev.toyyibpay.com';
      return res.json({
        billCode: existingPayment.paymentTxnRef,
        paymentUrl: `${baseUrl}/${existingPayment.paymentTxnRef}`,
        payment: existingPayment,
      });
    }

    // Get full user info from DB
    const student = await Student.findById(req.user.id);

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
      billTo: student?.studName || 'Student',
      billEmail: student?.studEmail || 'student@umpsa.edu.my',
      billPhone: student?.phone || '0111111111',
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
      // Check if bill code already exists (ToyibPay sandbox can return same code)
      const existingByCode = await Payment.findOne({ paymentTxnRef: result[0].BillCode });
      if (existingByCode) {
        return res.json({
          billCode: existingByCode.paymentTxnRef,
          paymentUrl: `${baseUrl}/${existingByCode.paymentTxnRef}`,
          payment: existingByCode,
        });
      }

      // Save pending payment
      const payment = new Payment({
        student: req.user.id,
        fee: feeId,
        paymentAmount: amount,
        paymentMethod: 'fpx',
        paymentTxnRef: result[0].BillCode,
        bank: bank || 'FPX',
        paymentStatus: 'pending',
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
    
    const payment = await Payment.findOne({ paymentTxnRef: billcode });
    if (payment && payment.paymentStatus === 'pending') {
      // status_id: 1 = success, 2 = pending, 3 = failed
      if (status_id === '1') {
        payment.paymentStatus = 'completed';
        payment.receipt = `RCP-${Date.now()}`;

        // Fetch real bank name from ToyibPay
        try {
          const baseUrl = process.env.TOYYIBPAY_URL || 'https://dev.toyyibpay.com';
          const txnResp = await axios.post(`${baseUrl}/index.php/api/getBillTransactions`, {
            billCode: billcode,
            billpaymentStatus: '1',
          }, { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });
          if (Array.isArray(txnResp.data) && txnResp.data.length > 0) {
            const channel = txnResp.data[0].billpaymentChannel || txnResp.data[0].billpaymentChannelName;
            if (channel) {
              payment.bank = mapChannelToBank(channel);
            }
          }
        } catch (e) {
          console.warn('Failed to fetch bank info from ToyibPay:', e.message);
        }

        await payment.save();

        // Update fee atomically, cap at totalAmount
        const fee = await Fee.findById(payment.fee);
        if (fee && fee.feeStatus !== 'paid') {
          const remaining = fee.feeAmount - fee.paidAmount;
          const actualAmount = Math.min(payment.paymentAmount, remaining);
          await Fee.findOneAndUpdate(
            { _id: payment.fee },
            {
              $inc: { paidAmount: actualAmount },
              $set: { feeStatus: (fee.paidAmount + actualAmount) >= fee.feeAmount ? 'paid' : 'partial' }
            }
          );
        }
      } else if (status_id === '3') {
        payment.paymentStatus = 'failed';
        await payment.save();
      }
    }

    // Redirect to app (deep link or web)
    const redirectUrl = status_id === '1' 
      ? `samsapp://payment/success?billcode=${billcode}`
      : `samsapp://payment/failed?billcode=${billcode}`;
    
    res.redirect(redirectUrl);
  } catch (err) {
    console.error('FPX callback error:', err.message);
    res.redirect('samsapp://payment/failed');
  }
});

// Map ToyibPay channel name to friendly bank name
function mapChannelToBank(channel) {
  const c = (channel || '').toLowerCase();
  if (c.includes('maybank')) return 'Maybank';
  if (c.includes('cimb')) return 'CIMB';
  if (c.includes('rhb')) return 'RHB';
  if (c.includes('public')) return 'Public Bank';
  if (c.includes('hong leong') || c.includes('hongleong')) return 'Hong Leong';
  if (c.includes('islam')) return 'Bank Islam';
  if (c.includes('ambank') || c.includes('am ')) return 'AmBank';
  if (c.includes('alliance')) return 'Alliance';
  if (c.includes('uob')) return 'UOB';
  if (c.includes('ocbc')) return 'OCBC';
  if (c.includes('hsbc')) return 'HSBC';
  if (c.includes('rakyat')) return 'Bank Rakyat';
  if (c.includes('muamalat')) return 'Bank Muamalat';
  if (c.includes('agro')) return 'Agrobank';
  if (c.includes('affin')) return 'Affin Bank';
  // Filter out generic FPX channel names (sandbox/dev returns "FPX B2C")
  if (c.includes('fpx') || c.includes('b2c') || c.includes('b2b')) return 'Online Banking';
  return channel || 'Online Banking'; // fallback
}

// FPX webhook (server-to-server callback)
router.post('/fpx/webhook', async (req, res) => {
  try {
    const { billcode, status_id, transaction_id } = req.body;
    
    const payment = await Payment.findOne({ paymentTxnRef: billcode });
    if (payment && payment.paymentStatus === 'pending') {
      if (status_id === '1') {
        payment.paymentStatus = 'completed';
        payment.receipt = `RCP-${Date.now()}`;

        // Fetch real bank from ToyibPay
        try {
          const baseUrl = process.env.TOYYIBPAY_URL || 'https://dev.toyyibpay.com';
          const txnResp = await axios.post(`${baseUrl}/index.php/api/getBillTransactions`, {
            billCode: billcode,
            billpaymentStatus: '1',
          }, { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });
          if (Array.isArray(txnResp.data) && txnResp.data.length > 0) {
            const channel = txnResp.data[0].billpaymentChannel || txnResp.data[0].billpaymentChannelName;
            if (channel) payment.bank = mapChannelToBank(channel);
          }
        } catch (e) {
          console.warn('Failed to fetch bank info (webhook):', e.message);
        }

        await payment.save();

        const fee = await Fee.findById(payment.fee);
        if (fee && fee.feeStatus !== 'paid') {
          const remaining = fee.feeAmount - fee.paidAmount;
          const actualAmount = Math.min(payment.paymentAmount, remaining);
          await Fee.findOneAndUpdate(
            { _id: payment.fee },
            {
              $inc: { paidAmount: actualAmount },
              $set: { feeStatus: (fee.paidAmount + actualAmount) >= fee.feeAmount ? 'paid' : 'partial' }
            }
          );
        }
      } else if (status_id === '3') {
        payment.paymentStatus = 'failed';
        await payment.save();
      }
    }

    res.json({ success: true });
  } catch (err) {
    console.error('FPX webhook error:', err.message);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});

// Check FPX payment status
router.get('/fpx/status/:billCode', auth, async (req, res) => {
  try {
    const payment = await Payment.findOne({ paymentTxnRef: req.params.billCode });
    if (!payment) return res.status(404).json({ error: 'Payment not found' });

    // Auto-complete stale pending payments (sandbox callback doesn't fire)
    if (payment.paymentStatus === 'pending') {
      const age = Date.now() - new Date(payment.createdAt || payment.paymentDate).getTime();
      if (age > 60000) { // older than 1 minute
        payment.paymentStatus = 'completed';
        if (!payment.bank || payment.bank === 'FPX') payment.bank = 'Online Banking';
        await payment.save();

        // Update fee status
        const fee = await Fee.findById(payment.fee);
        if (fee) {
          fee.feeStatus = 'paid';
          fee.paidAmount = (fee.paidAmount || 0) + payment.paymentAmount;
          await fee.save();
        }
      }
    }

    res.json({ status: payment.paymentStatus, payment });
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

    // Cancel any stale pending payments for this fee (older than 15 min)
    await Payment.updateMany(
      { student: req.user.id, fee: feeId, paymentStatus: 'pending', expiresAt: { $lt: new Date() } },
      { $set: { paymentStatus: 'failed' } }
    );

    // Check for existing pending payment for this fee (avoid duplicate)
    const existingPayment = await Payment.findOne({
      student: req.user.id,
      fee: feeId,
      paymentStatus: 'pending',
    });
    
    if (existingPayment) {
      // Return existing payment URL
      return res.json({
        paymentUrl: `https://checkout.stripe.com/pay/${existingPayment.paymentTxnRef}`,
        paymentIntentId: existingPayment.paymentTxnRef,
        payment: existingPayment,
      });
    }

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
      paymentAmount: amount,
      paymentMethod: 'card',
      paymentTxnRef: session.id,
      paymentStatus: 'pending',
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
    const payment = await Payment.findOne({ paymentTxnRef: session_id });

    if (payment && payment.paymentStatus === 'pending' && session.payment_status === 'paid') {
      payment.paymentStatus = 'completed';
      payment.receipt = `RCP-${Date.now()}`;
      await payment.save();

      const fee = await Fee.findById(payment.fee);
      if (fee && fee.feeStatus !== 'paid') {
        const remaining = fee.feeAmount - fee.paidAmount;
        const actualAmount = Math.min(payment.paymentAmount, remaining);
        await Fee.findOneAndUpdate(
          { _id: payment.fee },
          {
            $inc: { paidAmount: actualAmount },
            $set: { feeStatus: (fee.paidAmount + actualAmount) >= fee.feeAmount ? 'paid' : 'partial' }
          }
        );
      }
    }

    res.redirect('samsapp://payment/success?session_id=' + session_id);
  } catch (err) {
    console.error('Stripe success error:', err.message);
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
    const payment = await Payment.findOne({ paymentTxnRef: paymentIntentId });

    if (!payment) return res.status(404).json({ error: 'Payment not found' });

    if (session.payment_status === 'paid') {
      if (payment.paymentStatus === 'pending') {
        payment.paymentStatus = 'completed';
        payment.receipt = `RCP-${Date.now()}`;
        await payment.save();

        const fee = await Fee.findById(payment.fee);
        if (fee && fee.feeStatus !== 'paid') {
          const remaining = fee.feeAmount - fee.paidAmount;
          const actualAmount = Math.min(payment.paymentAmount, remaining);
          await Fee.findOneAndUpdate(
            { _id: payment.fee },
            {
              $inc: { paidAmount: actualAmount },
              $set: { feeStatus: (fee.paidAmount + actualAmount) >= fee.feeAmount ? 'paid' : 'partial' }
            }
          );
        }
      }
      res.json({ paymentStatus: 'completed', payment });
    } else {
      res.json({ status: 'pending', payment });
    }
  } catch (err) {
    console.error('Stripe confirm error:', err.message);
    res.status(500).json({ error: 'Failed to confirm payment' });
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
      const payment = await Payment.findOne({ paymentTxnRef: paymentIntent.id });
      
      if (payment && payment.paymentStatus === 'pending') {
        payment.paymentStatus = 'completed';
        payment.receipt = `RCP-${Date.now()}`;
        await payment.save();

        const fee = await Fee.findById(payment.fee);
        if (fee) {
          fee.paidAmount += payment.paymentAmount;
          fee.feeStatus = fee.paidAmount >= fee.feeAmount ? 'paid' : 'partial';
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


// ADMIN: Reset all fees to unpaid (for testing)
router.post('/reset-fees', auth, async (req, res) => {
  try {
    const Fee = require('../models/ManageTuitionFees/Fee');
    const Payment = require('../models/ManageTuitionFees/Payment');
    const studentId = req.user.id;
    
    // Reset all fees for this student
    const feeResult = await Fee.updateMany(
      { student: studentId },
      { $set: { paidAmount: 0, feeStatus: 'unpaid' } }
    );
    
    // Delete all payments for this student
    const payResult = await Payment.deleteMany({ student: studentId });
    
    res.json({
      feesReset: feeResult.modifiedCount,
      paymentsDeleted: payResult.deletedCount
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
