const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema({
  student: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  code: { type: mongoose.Schema.Types.ObjectId, ref: 'AttendanceCode', required: true },
  status: { type: String, enum: ['present', 'absent', 'late', 'excused'], default: 'present' },
  checkInTime: { type: Date, default: Date.now },
  latitude: { type: Number },
  longitude: { type: Number },
  createdAt: { type: Date, default: Date.now }
});

attendanceSchema.index({ student: 1, code: 1 }, { unique: true });

module.exports = mongoose.model('Attendance', attendanceSchema);