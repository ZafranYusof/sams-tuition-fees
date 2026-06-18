const mongoose = require('mongoose');

const feeSchema = new mongoose.Schema({
  student: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  feeType: { type: String, required: true },  // contoh: "Tuition", "Asrama", "Insurance"
  feeDescription: { type: String },
  feeAmount: { type: Number, required: true },
  feeDueDate: { type: Date },
  feeStatus: { type: String, enum: ['unpaid', 'partial', 'paid', 'overdue'], default: 'unpaid' },
  feeSemester: { type: Number, required: true },
  academicYear: { type: String },
  paidAmount: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Fee', feeSchema);
