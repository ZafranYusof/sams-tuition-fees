const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema({
  studId: {
    type: String,
    required: true,
  },
  sessionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Session',
    required: true,
  },
  code: {
    type: String,
    default: null, // the code the student used to check in
  },
  status: {
    type: String,
    enum: ['Present', 'Absent'],
    default: 'Absent',
  },
  checkInTime: {
    type: Date,
    default: null,
  },
  latitude: {
    type: Number,
    default: null,
  },
  longitude: {
    type: Number,
    default: null,
  },
});

module.exports = mongoose.model('Attendance', attendanceSchema);