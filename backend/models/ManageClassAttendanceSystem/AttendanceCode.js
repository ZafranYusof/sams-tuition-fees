const mongoose = require('mongoose');

const attendanceCodeSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true,
  },
  sessionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Session',
    required: true,
  },
  timeGenerated: {
    type: Date,
    default: Date.now,
  },
  timeTerminated: {
    type: Date,
    default: null, // null means still active
  },
});

// Helper: check if this code is still active (not terminated yet)
attendanceCodeSchema.methods.isActive = function () {
  return this.timeTerminated === null;
};

module.exports = mongoose.model('AttendanceCode', attendanceCodeSchema);