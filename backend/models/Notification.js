const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  studentId: { type: String, required: true },
  title: { type: String, required: true },
  message: { type: String },
  type: { type: String, enum: ['info', 'warning', 'payment', 'reminder'], default: 'info' },
  read: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.models.Notification || mongoose.model('Notification', notificationSchema);
