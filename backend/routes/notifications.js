const express = require('express');
const mongoose = require('mongoose');
const { auth } = require('../middleware/auth');

const router = express.Router();

// Notification schema (inline, simple)
const notificationSchema = new mongoose.Schema({
  studentId: { type: String, required: true },
  title: { type: String, required: true },
  message: { type: String },
  type: { type: String, enum: ['info', 'warning', 'payment', 'reminder'], default: 'info' },
  read: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

const Notification = mongoose.models.Notification || mongoose.model('Notification', notificationSchema);

// GET /api/notifications/:studentId
router.get('/:studentId', auth, async (req, res) => {
  try {
    const notifications = await Notification.find({ studentId: req.params.studentId }).sort({ createdAt: -1 });
    res.json({ notifications });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/notifications/:id/read
router.put('/:id/read', auth, async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid notification ID' });
    }
    await Notification.findByIdAndUpdate(req.params.id, { read: true });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/notifications/:studentId/read-all
router.put('/:studentId/read-all', auth, async (req, res) => {
  try {
    await Notification.updateMany({ studentId: req.params.studentId }, { read: true });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/notifications - create notification(s)
router.post('/', auth, async (req, res) => {
  try {
    const { notifications } = req.body;
    if (Array.isArray(notifications) && notifications.length > 0) {
      const created = await Notification.insertMany(notifications);
      return res.status(201).json({ success: true, count: created.length });
    }
    // Single notification
    const { studentId, title, message, type } = req.body;
    if (!studentId || !title) {
      return res.status(400).json({ error: 'studentId and title are required' });
    }
    const notif = await Notification.create({ studentId, title, message, type: type || 'reminder' });
    res.status(201).json({ success: true, notification: notif });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/notifications/send-reminder - bulk send payment reminders to unpaid students
router.post('/send-reminder', auth, async (req, res) => {
  try {
    const { studentIds, message } = req.body;
    if (!Array.isArray(studentIds) || studentIds.length === 0) {
      return res.status(400).json({ error: 'studentIds array required' });
    }
    const notifications = studentIds.map(sid => ({
      studentId: sid,
      title: 'Payment Reminder',
      message: message || 'You have outstanding tuition fees. Please make payment before the deadline to avoid penalties.',
      type: 'reminder',
      read: false,
    }));
    const created = await Notification.insertMany(notifications);
    res.status(201).json({ success: true, count: created.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
