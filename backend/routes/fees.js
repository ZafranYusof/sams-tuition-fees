const express = require('express');
const mongoose = require('mongoose');
const Fee = require('../models/Fee');
const Payment = require('../models/Payment');
const { auth, adminOnly } = require('../middleware/auth');
const crypto = require('crypto');

const router = express.Router();

// Get my fees
router.get('/my', auth, async (req, res) => {
  try {
    const fees = await Fee.find({ student: req.user.id }).sort({ createdAt: -1 });
    res.json(fees);
  } catch (err) {
    console.error('Get my fees error:', err.message);
    res.status(500).json({ error: 'Failed to fetch fees' });
  }
});

// Get payment history (MUST be before /:studentId to avoid route conflict)
router.get('/payments/history', auth, async (req, res) => {
  try {
    const payments = await Payment.find({ student: req.user.id }).populate('fee').sort({ paidAt: -1 });
    res.json(payments);
  } catch (err) {
    console.error('Payment history error:', err.message);
    res.status(500).json({ error: 'Failed to fetch payment history' });
  }
});

// Get fees by student ID (e.g. CB23109)
router.get('/:studentId', auth, async (req, res) => {
  try {
    const sid = req.params.studentId;
    // If it looks like a MongoDB ObjectId, find by _id
    if (/^[a-f0-9]{24}$/.test(sid)) {
      const fee = await Fee.findById(sid);
      if (!fee) return res.status(404).json({ error: 'Fee not found' });
      // Authorization: only owner or admin can view
      if (fee.student.toString() !== req.user.id && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Access denied' });
      }
      const payments = await Payment.find({ fee: sid }).sort({ paidAt: -1 });
      return res.json({ fee, payments });
    }
    // Otherwise find by studentId string
    const User = require('../models/User');
    const user = await User.findOne({ studentId: sid });
    if (!user) return res.json({ fees: [], summary: { total_due: 0, total_paid: 0, balance: 0 } });
    // Authorization: only own data or admin
    if (user._id.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }
    const fees = await Fee.find({ student: user._id }).sort({ createdAt: -1 });
    const totalDue = fees.reduce((s, f) => s + f.totalAmount, 0);
    const totalPaid = fees.reduce((s, f) => s + f.paidAmount, 0);
    res.json({ fees, summary: { total_due: totalDue, total_paid: totalPaid, balance: totalDue - totalPaid } });
  } catch (err) {
    console.error('Get fees error:', err.message);
    res.status(500).json({ error: 'Failed to fetch fees' });
  }
});

// Get summary by student ID
router.get('/:studentId/summary', auth, async (req, res) => {
  try {
    const User = require('../models/User');
    const user = await User.findOne({ studentId: req.params.studentId });
    if (!user) return res.json({ summary: { total_due: 0, total_paid: 0, balance: 0 } });
    // Authorization: only own data or admin
    if (user._id.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }
    const fees = await Fee.find({ student: user._id });
    const totalDue = fees.reduce((s, f) => s + f.totalAmount, 0);
    const totalPaid = fees.reduce((s, f) => s + f.paidAmount, 0);
    res.json({ summary: { total_due: totalDue, total_paid: totalPaid, balance: totalDue - totalPaid } });
  } catch (err) {
    console.error('Fee summary error:', err.message);
    res.status(500).json({ error: 'Failed to fetch fee summary' });
  }
});

// Make payment (FPX simulation)
router.post('/pay', auth, async (req, res) => {
  try {
    const { feeId, amount, bank } = req.body;
    if (!feeId || !mongoose.Types.ObjectId.isValid(feeId)) {
      return res.status(400).json({ error: 'Invalid fee ID' });
    }
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }
    
    const fee = await Fee.findById(feeId);
    if (!fee) return res.status(404).json({ error: 'Fee not found' });
    // Authorization: only fee owner can pay
    if (fee.student.toString() !== req.user.id) {
      return res.status(403).json({ error: 'You can only pay your own fees' });
    }
    if (fee.status === 'paid') return res.status(400).json({ error: 'Already fully paid' });

    // Cap amount at remaining balance to prevent overpayment
    const remaining = fee.totalAmount - fee.paidAmount;
    const actualAmount = Math.min(amount, remaining);

    const transactionId = 'FPX' + crypto.randomBytes(8).toString('hex').toUpperCase();
    
    const payment = new Payment({
      student: req.user.id,
      fee: feeId,
      amount: actualAmount,
      method: 'fpx',
      bank,
      transactionId,
      status: 'success',
      receipt: `RCP-${Date.now()}`
    });
    await payment.save();

    // Use findOneAndUpdate with $inc for atomicity
    const updatedFee = await Fee.findOneAndUpdate(
      { _id: feeId },
      { 
        $inc: { paidAmount: actualAmount },
        $set: { status: (fee.paidAmount + actualAmount) >= fee.totalAmount ? 'paid' : 'partial' }
      },
      { new: true }
    );

    res.status(201).json({ payment, fee: updatedFee });
  } catch (err) {
    console.error('Payment error:', err.message);
    res.status(500).json({ error: 'Payment failed. Please try again.' });
  }
});

// Admin: Create fee for student
router.post('/', auth, adminOnly, async (req, res) => {
  try {
    const User = require('../models/User');
    let { student, studentId, items, semester, academicYear, dueDate } = req.body;

    // Resolve studentId string to ObjectId
    if (!student && studentId) {
      const user = await User.findOne({ studentId });
      if (!user) return res.status(404).json({ error: `Student ${studentId} not found` });
      student = user._id;
    }
    if (!student) return res.status(400).json({ error: 'Student ID required' });
    if (!items || !items.length) return res.status(400).json({ error: 'Fee items required' });

    const totalAmount = items.reduce((sum, item) => sum + (item.amount || 0), 0);
    const fee = new Fee({
      student,
      items,
      semester: semester || 1,
      academicYear: academicYear || '2025/2026',
      totalAmount,
      paidAmount: 0,
      status: 'unpaid',
      dueDate: dueDate ? new Date(dueDate) : new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
    });
    await fee.save();
    res.status(201).json(fee);
  } catch (err) {
    console.error('Create fee error:', err.message);
    res.status(500).json({ error: 'Failed to create fee' });
  }
});

// Admin: Get all fees (with pagination)
router.get('/', auth, adminOnly, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 100;
    const skip = (page - 1) * limit;
    
    const fees = await Fee.find().populate('student', 'name studentId').skip(skip).limit(limit).sort({ createdAt: -1 });
    const total = await Fee.countDocuments();
    res.json(fees.length <= 100 ? fees : { fees, total, page, pages: Math.ceil(total / limit) });
  } catch (err) {
    console.error('Get all fees error:', err.message);
    res.status(500).json({ error: 'Failed to fetch fees' });
  }
});

module.exports = router;
