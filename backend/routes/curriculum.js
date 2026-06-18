const express = require('express');
const mongoose = require('mongoose');
const Activity = require('../models/ManageCurriculumActivity/Activity');
const ActivityRegistration = require('../models/ManageCurriculumActivity/ActivityRegistration');
const CreditClaim = require('../models/ManageCurriculumActivity/CreditClaim');
const { auth, adminOnly } = require('../middleware/auth');

const router = express.Router();

// ─── ACTIVITY CRUD ───────────────────────────────────────────────────────────

// Get all activities (exclude cancelled by default)
router.get('/', auth, async (req, res) => {
  try {
    const { category, status } = req.query;
    const filter = { status: { $ne: 'cancelled' } };
    if (category) filter.category = category;
    if (status) filter.status = status; // override if explicitly passed
    const activities = await Activity.find(filter).sort({ date: -1 });
    res.json(activities);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get my joined activities (MUST be before /:id to avoid route conflict)
router.get('/my/joined', auth, async (req, res) => {
  try {
    const activities = await Activity.find({ participants: req.user.id }).sort({ date: -1 });
    res.json(activities);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get my credit claims (MUST be before /:id)
router.get('/my/claims', auth, async (req, res) => {
  try {
    const claims = await CreditClaim.find({ student: req.user.id })
      .populate('activity', 'name category status points creditHours')
      .sort({ createdAt: -1 });
    res.json(claims);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get pending credit claims (MUST be before /:id)
router.get('/claims/pending', auth, async (req, res) => {
  try {
    const claims = await CreditClaim.find({ claimStatus: 'pending' })
      .populate('student', 'name studentId')
      .populate('activity')
      .populate({ path: 'registration', populate: { path: 'activity' } });
    res.json({ claims });
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

// Join activity (atomic — prevents race condition)
router.post('/:id/join', auth, async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid activity ID' });
    }
    const activity = await Activity.findOneAndUpdate(
      { _id: req.params.id, participants: { $ne: req.user.id }, $expr: { $lt: [{ $size: '$participants' }, '$capacity'] } },
      { $addToSet: { participants: req.user.id } },
      { new: true }
    );
    if (!activity) return res.status(400).json({ error: 'Cannot join — already registered or activity full' });
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
    const activity = await Activity.findByIdAndUpdate(
      req.params.id,
      { $pull: { participants: req.user.id } },
      { new: true }
    );
    if (!activity) return res.status(404).json({ error: 'Activity not found' });
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
    if (!activity) return res.status(404).json({ error: 'Activity not found' });
    res.json(activity);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Admin: Hard delete activity
router.delete('/:id', auth, adminOnly, async (req, res) => {
  try {
    await Activity.findByIdAndDelete(req.params.id);
    res.json({ message: 'Activity deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── CREDIT CLAIMS ───────────────────────────────────────────────────────────

// Student submits credit claim
router.post('/claim', auth, async (req, res) => {
  try {
    const { activityId, supportingClaim, evidence } = req.body;
    if (!activityId) return res.status(400).json({ error: 'activityId required' });

    // Try to find existing registration
    const reg = await ActivityRegistration.findOne({ student: req.user.id, activity: activityId });

    const claimData = {
      student: req.user.id,
      activity: activityId,
      supportingClaim,
      claimStatus: 'pending'
    };
    if (reg) claimData.registration = reg._id;

    const claim = await CreditClaim.create(claimData);
    res.status(201).json({ message: 'Claim submitted', claim });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Staff reviews a credit claim
router.put('/claim/:claimId/review', auth, adminOnly, async (req, res) => {
  try {
    const { claimStatus } = req.body;
    if (!['approved', 'rejected'].includes(claimStatus)) {
      return res.status(400).json({ error: 'claimStatus must be approved or rejected' });
    }

    const claim = await CreditClaim.findByIdAndUpdate(
      req.params.claimId,
      { claimStatus, paStaff: req.user.id, reviewedAt: new Date() },
      { new: true }
    );
    if (!claim) return res.status(404).json({ error: 'Claim not found' });
    res.json({ message: `Claim ${claimStatus}`, claim });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Student's activity registrations (legacy compat)
router.get('/registrations/my', auth, async (req, res) => {
  try {
    const regs = await ActivityRegistration.find({ student: req.user.id }).populate('activity');
    res.json({ registrations: regs });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
