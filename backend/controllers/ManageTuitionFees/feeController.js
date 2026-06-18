const Fee = require('../models/ManageTuitionFees/Fee');
const Payment = require('../models/ManageTuitionFees/Payment');
const Notification = require('../models/ManageTuitionFees/Notification');

// Get fee summary for a student
exports.getFeeSummary = async (req, res) => {
  try {
    const { studentId } = req.params;
    const fees = await Fee.find({ student: studentId });
    const totalDue = fees.reduce((sum, f) => sum + (f.feeAmount || 0), 0);
    const totalPaid = fees.reduce((sum, f) => sum + (f.paidAmount || 0), 0);
    const balance = totalDue - totalPaid;
    
    res.json({
      summary: {
        total_due: totalDue,
        total_paid: totalPaid,
        balance: balance,
        fees: fees
      }
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get all fees for a student
exports.getFees = async (req, res) => {
  try {
    const { studentId } = req.params;
    const fees = await Fee.find({ student: studentId }).sort({ createdAt: -1 });
    res.json({ fees });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Create a fee record
exports.createFee = async (req, res) => {
  try {
    const fee = await Fee.create(req.body);
    res.status(201).json(fee);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Update fee status
exports.updateFee = async (req, res) => {
  try {
    const fee = await Fee.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!fee) return res.status(404).json({ message: 'Fee not found' });
    res.json(fee);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get all fees (treasury view)
exports.getAllFees = async (req, res) => {
  try {
    const fees = await Fee.find().populate('student', 'name studentId email').sort({ createdAt: -1 });
    res.json({ fees });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
