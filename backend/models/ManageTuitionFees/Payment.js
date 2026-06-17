const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  student: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  fee: { type: mongoose.Schema.Types.ObjectId, ref: 'Fee', required: true },
  paymentAmount: { type: Number, required: true },
  paymentMethod: { type: String, enum: ['fpx', 'card', 'cash', 'scholarship'], default: 'fpx' },
  paymentStatus: { type: String, enum: ['pending', 'completed', 'failed', 'refunded'], default: 'pending' },
  paymentDate: { type: Date, default: Date.now },
  paymentTxnRef: { type: String, unique: true },
  paymentOrderNo: { type: String },
  bank: { type: String },
  receipt: { type: String },
  expiresAt: { type: Date, default: () => new Date(Date.now() + 10 * 60 * 1000) }
});

paymentSchema.index({ paymentStatus: 1, expiresAt: 1 });

module.exports = mongoose.model('Payment', paymentSchema);
