const mongoose = require('mongoose');

const activityRegistrationSchema = new mongoose.Schema({
  student: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  activity: { type: mongoose.Schema.Types.ObjectId, ref: 'CurriculumActivity', required: true },
  registeredAt: { type: Date, default: Date.now },
  status: { type: String, enum: ['registered', 'attended', 'cancelled'], default: 'registered' }
});

activityRegistrationSchema.index({ student: 1, activity: 1 }, { unique: true });

module.exports = mongoose.model('ActivityRegistration', activityRegistrationSchema);