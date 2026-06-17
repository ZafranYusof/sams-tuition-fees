const express = require('express');
const router = express.Router();
const CurriculumActivity = require('../models/CurriculumActivity');
const ActivityRegistration = require('../models/ActivityRegistration');
const CreditClaim = require('../models/CreditClaim');
const { auth } = require('../middleware/auth');

// POST /activities — Create new activity (admin/PusatAdab)
router.post('/', auth, async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'staff') {
      return res.status(403).json({ message: 'Admin/Staff access required' });
    }
    const { activityName, activityCategory, activityDate, activityLocation, creditHours, availableSlots } = req.body;
    if (!activityName || !activityCategory || !activityDate) {
      return res.status(400).json({ message: 'activityName, activityCategory, activityDate required' });
    }
    const activity = await CurriculumActivity.create({
      activityId: 'ACT-' + Date.now(),
      activityName, activityCategory, activityDate, activityLocation, creditHours, availableSlots
    });
    res.status(201).json({ message: 'Activity created', activity });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /activities — List all activities
router.get('/', auth, async (req, res) => {
  try {
    const { status, category } = req.query;
    const filter = {};
    if (status) filter.activityStatus = status;
    if (category) filter.activityCategory = category;
    const activities = await CurriculumActivity.find(filter).sort({ activityDate: -1 });
    res.json({ activities });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /activities/:id — Get single activity
router.get('/:id', auth, async (req, res) => {
  try {
    const activity = await CurriculumActivity.findById(req.params.id);
    if (!activity) return res.status(404).json({ message: 'Activity not found' });
    res.json({ activity });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /activities/:id — Update activity
router.put('/:id', auth, async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'staff') {
      return res.status(403).json({ message: 'Admin/Staff access required' });
    }
    const activity = await CurriculumActivity.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!activity) return res.status(404).json({ message: 'Activity not found' });
    res.json({ message: 'Activity updated', activity });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE /activities/:id — Delete activity
router.delete('/:id', auth, async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'staff') {
      return res.status(403).json({ message: 'Admin/Staff access required' });
    }
    await CurriculumActivity.findByIdAndDelete(req.params.id);
    res.json({ message: 'Activity deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /activities/:id/register — Student registers for activity
router.post('/:id/register', auth, async (req, res) => {
  try {
    if (req.user.role !== 'student') return res.status(403).json({ message: 'Student access required' });

    const activity = await CurriculumActivity.findById(req.params.id);
    if (!activity) return res.status(404).json({ message: 'Activity not found' });

    // Check slots
    const registered = await ActivityRegistration.countDocuments({ activity: activity._id, status: { $ne: 'cancelled' } });
    if (activity.availableSlots > 0 && registered >= activity.availableSlots) {
      return res.status(400).json({ message: 'No available slots' });
    }

    const reg = await ActivityRegistration.create({
      student: req.user.id,
      activity: activity._id
    });

    res.status(201).json({ message: 'Registered successfully', registration: reg });
  } catch (err) {
    if (err.code === 11000) return res.status(400).json({ message: 'Already registered' });
    res.status(500).json({ message: err.message });
  }
});

// POST /activities/claim — Student submits credit claim
router.post('/claim', auth, async (req, res) => {
  try {
    if (req.user.role !== 'student') return res.status(403).json({ message: 'Student access required' });
    const { registrationId, supportingClaim } = req.body;
    if (!registrationId) return res.status(400).json({ message: 'registrationId required' });

    const reg = await ActivityRegistration.findById(registrationId);
    if (!reg) return res.status(404).json({ message: 'Registration not found' });
    if (reg.student.toString() !== req.user.id) return res.status(403).json({ message: 'Not your registration' });

    const claim = await CreditClaim.create({
      registration: registrationId,
      student: req.user.id,
      supportingClaim
    });

    res.status(201).json({ message: 'Claim submitted', claim });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /activities/claim/:claimId/review — PusatAdab reviews claim
router.put('/claim/:claimId/review', auth, async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'staff') {
      return res.status(403).json({ message: 'Staff access required' });
    }
    const { claimStatus } = req.body;
    if (!['approved', 'rejected'].includes(claimStatus)) {
      return res.status(400).json({ message: 'claimStatus must be approved or rejected' });
    }

    const claim = await CreditClaim.findByIdAndUpdate(req.params.claimId, {
      claimStatus,
      paStaff: req.user.id,
      reviewedAt: new Date()
    }, { new: true });

    if (!claim) return res.status(404).json({ message: 'Claim not found' });
    res.json({ message: `Claim ${claimStatus}`, claim });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /activities/claims/pending — List pending claims (PusatAdab)
router.get('/claims/pending', auth, async (req, res) => {
  try {
    const claims = await CreditClaim.find({ claimStatus: 'pending' })
      .populate('student', 'name studentId')
      .populate({ path: 'registration', populate: { path: 'activity' } });
    res.json({ claims });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /activities/registrations/my — Student's activity registrations
router.get('/registrations/my', auth, async (req, res) => {
  try {
    const regs = await ActivityRegistration.find({ student: req.user.id })
      .populate('activity');
    res.json({ registrations: regs });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;