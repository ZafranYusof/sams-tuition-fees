// LEGACY: This controller is not imported after route consolidation. Kept for reference only.
const CurriculumActivity = require('../models/ManageCurriculumActivity/CurriculumActivity');
const Activity = require('../models/ManageCurriculumActivity/Activity');
const ActivityRegistration = require('../models/ManageCurriculumActivity/ActivityRegistration');
const CreditClaim = require('../models/ManageCurriculumActivity/CreditClaim');

// Get all activities
exports.getActivities = async (req, res) => {
  try {
    const activities = await Activity.find({ isActive: true }).sort({ date: 1 });
    res.json({ activities });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get activity details
exports.getActivity = async (req, res) => {
  try {
    const activity = await Activity.findById(req.params.id);
    if (!activity) return res.status(404).json({ message: 'Activity not found' });
    res.json(activity);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Register for an activity
exports.registerActivity = async (req, res) => {
  try {
    const { activityId } = req.body;
    const activity = await Activity.findById(activityId);
    if (!activity) return res.status(404).json({ message: 'Activity not found' });

    // Check if already registered
    const existing = await ActivityRegistration.findOne({ student: req.user.id, activity: activityId });
    if (existing) return res.status(400).json({ message: 'Already registered' });

    const registration = await ActivityRegistration.create({
      student: req.user.id,
      activity: activityId,
      status: 'registered'
    });

    res.status(201).json(registration);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get student activity registrations
exports.getStudentRegistrations = async (req, res) => {
  try {
    const { studentId } = req.params;
    const registrations = await ActivityRegistration.find({ student: studentId })
      .populate('activity')
      .sort({ createdAt: -1 });
    res.json({ registrations });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Submit credit claim
exports.submitCreditClaim = async (req, res) => {
  try {
    const { activityId, credits, evidence } = req.body;
    const claim = await CreditClaim.create({
      student: req.user.id,
      activity: activityId,
      credits,
      evidence,
      status: 'pending'
    });
    res.status(201).json(claim);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get student credit claims
exports.getCreditClaims = async (req, res) => {
  try {
    const { studentId } = req.params;
    const claims = await CreditClaim.find({ student: studentId })
      .populate('activity')
      .sort({ createdAt: -1 });
    res.json({ claims });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get all activities (admin view)
exports.getAllActivities = async (req, res) => {
  try {
    const activities = await Activity.find().sort({ createdAt: -1 });
    res.json({ activities });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
