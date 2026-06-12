const express = require('express');
const mongoose = require('mongoose');
const { auth, adminOnly } = require('../middleware/auth');

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

// POST /api/notifications - create notification(s) [admin only]
router.post('/', auth, adminOnly, async (req, res) => {
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
    console.error('Create notification error:', err.message);
    res.status(500).json({ error: 'Failed to create notification' });
  }
});

// POST /api/notifications/send-reminder - bulk send payment reminders [admin only]
router.post('/send-reminder', auth, adminOnly, async (req, res) => {
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
    console.error('Send reminder error:', err.message);
    res.status(500).json({ error: 'Failed to send reminders' });
  }
});

// PUT /api/notifications/read-all/:studentId - mark all as read (specific path to avoid conflict)
router.put('/read-all/:studentId', auth, async (req, res) => {
  try {
    // Authorization: only own notifications or admin
    const User = require('../models/User');
    const user = await User.findById(req.user.id);
    if (user.studentId !== req.params.studentId && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }
    await Notification.updateMany({ studentId: req.params.studentId }, { read: true });
    res.json({ success: true });
  } catch (err) {
    console.error('Read-all error:', err.message);
    res.status(500).json({ error: 'Failed to mark notifications as read' });
  }
});

// PUT /api/notifications/:id/read - mark single as read
router.put('/:id/read', auth, async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid notification ID' });
    }
    const notif = await Notification.findById(req.params.id);
    if (!notif) return res.status(404).json({ error: 'Notification not found' });
    // Authorization: only own notification or admin
    const User = require('../models/User');
    const user = await User.findById(req.user.id);
    if (notif.studentId !== user.studentId && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }
    await Notification.findByIdAndUpdate(req.params.id, { read: true });
    res.json({ success: true });
  } catch (err) {
    console.error('Mark read error:', err.message);
    res.status(500).json({ error: 'Failed to mark notification as read' });
  }
});

// GET /api/notifications/:studentId - get notifications for student
router.get('/:studentId', auth, async (req, res) => {
  try {
    // Authorization: only own notifications or admin
    const User = require('../models/User');
    const user = await User.findById(req.user.id);
    if (user.studentId !== req.params.studentId && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }
    const notifications = await Notification.find({ studentId: req.params.studentId }).sort({ createdAt: -1 });
    res.json({ notifications });
  } catch (err) {
    console.error('Get notifications error:', err.message);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

module.exports = router;
