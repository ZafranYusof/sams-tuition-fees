const mongoose = require('mongoose');

const creditClaimSchema = new mongoose.Schema({
  registration: { type: mongoose.Schema.Types.ObjectId, ref: 'ActivityRegistration', required: true },
  student: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  paStaff: { type: mongoose.Schema.Types.ObjectId, ref: 'PusatAdab' },
  supportingClaim: { type: String },
  claimStatus: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
  reviewedAt: { type: Date },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('CreditClaim', creditClaimSchema);