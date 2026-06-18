const mongoose = require('mongoose');

const registrationSessionSchema = new mongoose.Schema({
  sessionName: { type: String, required: true },
  startDate: { type: Date, required: true },
  endDate: { type: Date, required: true },
  courses: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Course' }],
  status: { type: String, enum: ['scheduled', 'open', 'closed', 'cancelled'], default: 'scheduled' },
  createdBy: { type: mongoose.Schema.Types.ObjectId, refPath: 'creatorModel' },
  creatorModel: { type: String, enum: ['FacultyRegistrar', 'Treasury'] },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('RegistrationSession', registrationSessionSchema);
