const express = require('express');
const mongoose = require('mongoose');
const Activity = require('../models/Activity');
const { auth, adminOnly } = require('../middleware/auth');

const router = express.Router();

// Get all activities
router.get('/', auth, async (req, res) => {
  try {
    const { category, status } = req.query;
    const filter = {};
    if (category) filter.category = category;
    if (status) filter.status = status;
    const activities = await Activity.find(filter).sort({ date: -1 });
    res.json(activities);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get my activities (MUST be before /:id to avoid route conflict)
router.get('/my/joined', auth, async (req, res) => {
  try {
    const activities = await Activity.find({ participants: req.user.id }).sort({ date: -1 });
    res.json(activities);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get single activity
router.get('/:id', auth, async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid activity ID' });
    }
    const activity = await Activity.findById(req.params.id).populate('participants', 'name studentId');
    if (!activity) return res.status(404).json({ error: 'Activity not found' });
    res.json(activity);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Join activity
router.post('/:id/join', auth, async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid activity ID' });
    }
    const activity = await Activity.findById(req.params.id);
    if (!activity) return res.status(404).json({ error: 'Activity not found' });
    if (activity.participants.includes(req.user.id)) return res.status(400).json({ error: 'Already joined' });
    if (activity.participants.length >= activity.capacity) return res.status(400).json({ error: 'Activity is full' });

    activity.participants.push(req.user.id);
    await activity.save();
    res.json(activity);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Leave activity
router.post('/:id/leave', auth, async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid activity ID' });
    }
    const activity = await Activity.findById(req.params.id);
    if (!activity) return res.status(404).json({ error: 'Activity not found' });

    activity.participants = activity.participants.filter(p => p.toString() !== req.user.id);
    await activity.save();
    res.json(activity);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Admin: Create activity
router.post('/', auth, adminOnly, async (req, res) => {
  try {
    const activity = new Activity(req.body);
    await activity.save();
    res.status(201).json(activity);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Admin: Update activity
router.put('/:id', auth, adminOnly, async (req, res) => {
  try {
    const activity = await Activity.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(activity);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
