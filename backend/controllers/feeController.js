const mongoose = require('mongoose');
const crypto = require('crypto');
const Fee = require('../models/Fee');
const Payment = require('../models/Payment');
const User = require('../models/User');

// Get my fees
exports.getMyFees = async (req, res) => {
  try {
    const fees = await Fee.find({ student: req.user.id }).sort({ createdAt: -1 });
    res.json(fees);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get fees by student ID
exports.getFeesByStudentId = async (req, res) => {
  try {
    const sid = req.params.studentId;
    if (/^[a-f0-9]{24}$/.test(sid)) {
      const fee = await Fee.findById(sid);
      if (!fee) return res.status(404).json({ error: 'Fee not found' });
      const payments = await Payment.find({ fee: sid }).sort({ paidAt: -1 });
      return res.json({ fee, payments });
    }
    const user = await User.findOne({ studentId: sid });
    if (!user) return res.json({ fees: [], summary: { total_due: 0, total_paid: 0, balance: 0 } });
    const fees = await Fee.find({ student: user._id }).sort({ createdAt: -1 });
    const totalDue = fees.reduce((s, f) => s + f.totalAmount, 0);
    const totalPaid = fees.reduce((s, f) => s + f.paidAmount, 0);
    res.json({ fees, summary: { total_due: totalDue, total_paid: totalPaid, balance: totalDue - totalPaid } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get summary
exports.getFeeSummary = async (req, res) => {
  try {
    const user = await User.findOne({ studentId: req.params.studentId });
    if (!user) return res.json({ summary: { total_due: 0, total_paid: 0, balance: 0 } });
    const fees = await Fee.find({ student: user._id });
    const totalDue = fees.reduce((s, f) => s + f.totalAmount, 0);
    const totalPaid = fees.reduce((s, f) => s + f.paidAmount, 0);
    res.json({ summary: { total_due: totalDue, total_paid: totalPaid, balance: totalDue - totalPaid } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Make payment
exports.makePayment = async (req, res) => {
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
    if (fee.status === 'paid') return res.status(400).json({ error: 'Already fully paid' });

    const transactionId = 'FPX' + crypto.randomBytes(8).toString('hex').toUpperCase();

    const payment = new Payment({
      student: req.user.id,
      fee: feeId,
      amount,
      method: 'fpx',
      bank,
      transactionId,
      status: 'success',
      receipt: `RCP-${Date.now()}`
    });
    await payment.save();

    fee.paidAmount += amount;
    fee.status = fee.paidAmount >= fee.totalAmount ? 'paid' : 'partial';
    await fee.save();

    res.status(201).json({ payment, fee });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get payment history
exports.getPaymentHistory = async (req, res) => {
  try {
    const payments = await Payment.find({ student: req.user.id }).populate('fee').sort({ paidAt: -1 });
    res.json(payments);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Admin: Create fee
exports.createFee = async (req, res) => {
  try {
    let { student, studentId, items, semester, academicYear, dueDate } = req.body;

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
    res.status(500).json({ error: err.message });
  }
};

// Admin: Get all fees
exports.getAllFees = async (req, res) => {
  try {
    const fees = await Fee.find().populate('student', 'name studentId');
    res.json(fees);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
