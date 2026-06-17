const mongoose = require('mongoose');

const enrollmentSchema = new mongoose.Schema({
  studId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  sessionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Session', required: true },
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  facultyId: { type: mongoose.Schema.Types.ObjectId, ref: 'FacultyRegistrar' },
  startDatetime: { type: Date, required: true },
  endDatetime: { type: Date },
  createdAt: { type: Date, default: Date.now }
});

enrollmentSchema.index({ studId: 1, sessionId: 1 }, { unique: true });

module.exports = mongoose.model('Enrollment', enrollmentSchema);