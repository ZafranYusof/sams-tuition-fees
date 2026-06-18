const mongoose = require('mongoose');

const enrollmentSchema = new mongoose.Schema({
  student: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  session: { type: mongoose.Schema.Types.ObjectId, ref: 'RegistrationSession', required: true },
  course: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  faculty: { type: mongoose.Schema.Types.ObjectId, ref: 'FacultyRegistrar' },
  startDatetime: { type: Date, required: true },
  endDatetime: { type: Date },
  status: { type: String, enum: ['active', 'dropped', 'completed'], default: 'active' },
  createdAt: { type: Date, default: Date.now }
});

enrollmentSchema.index({ student: 1, course: 1, session: 1 }, { unique: true });

module.exports = mongoose.model('Enrollment', enrollmentSchema);