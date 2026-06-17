const mongoose = require('mongoose');

const attendanceCodeSchema = new mongoose.Schema({
  code: { type: String, unique: true, required: true },
  session: { type: mongoose.Schema.Types.ObjectId, ref: 'Session', required: true },
  timeGenerated: { type: Date, default: Date.now },
  timeTerminated: { type: Date },
  isActive: { type: Boolean, default: true },
  expiresIn: { type: Number, default: 300 },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Lecturer', required: true },
  createdAt: { type: Date, default: Date.now }
});

attendanceCodeSchema.methods.isValid = function () {
  if (!this.isActive) return false;
  if (this.timeTerminated && new Date() > this.timeTerminated) return false;
  const expiry = new Date(this.createdAt.getTime() + this.expiresIn * 1000);
  return new Date() <= expiry;
};

module.exports = mongoose.model('AttendanceCode', attendanceCodeSchema);