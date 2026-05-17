const express = require('express');
const mongoose = require('mongoose');
const Payment = require('../models/Payment');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const router = express.Router();

// GET /api/payments/:studentId
router.get('/:studentId', auth, async (req, res) => {
  try {
    const user = await User.findOne({ studentId: req.params.studentId });
    if (!user) return res.json({ payments: [] });
    
    const payments = await Payment.find({ student: user._id }).populate('fee').sort({ paidAt: -1 });
    res.json({ payments });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/payments
router.post('/', auth, async (req, res) => {
  try {
    const { fee_id, feeId, amount, bank, student_id } = req.body;
    const crypto = require('crypto');
    const Fee = require('../models/Fee');

    const targetFeeId = fee_id || feeId;
    if (!targetFeeId || !mongoose.Types.ObjectId.isValid(targetFeeId)) {
      return res.status(400).json({ error: 'Invalid fee ID' });
    }
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }
    const fee = await Fee.findById(targetFeeId);
    if (!fee) return res.status(404).json({ error: 'Fee not found' });

    const transactionId = 'FPX' + crypto.randomBytes(8).toString('hex').toUpperCase();

    const payment = new Payment({
      student: req.user.id,
      fee: targetFeeId,
      amount,
      method: 'fpx',
      bank,
      transactionId,
      status: 'success',
      receipt: `RCP-${Date.now()}`
    });
    await payment.save();

    fee.paidAmount += amount;
    if (fee.paidAmount >= fee.totalAmount) {
      fee.status = 'paid';
    } else {
      fee.status = 'partial';
    }
    await fee.save();

    res.status(201).json({ payment, fee, txn_id: transactionId, status: 'success' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
