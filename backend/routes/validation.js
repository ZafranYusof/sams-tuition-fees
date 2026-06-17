const express = require('express');
const router = express.Router();
const ValidationController = require('../controllers/ManageOpenRegistration/ValidationController');
const { auth } = require('../middleware/auth');

// POST /validation/check — Validate course registration eligibility
router.post('/check', auth, async (req, res) => {
  try {
    const { courseId } = req.body;
    if (!courseId) {
      return res.status(400).json({ message: 'courseId required' });
    }

    const validation = await ValidationController.validateRegistration(req.user.id, courseId);
    res.json(validation);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /validation/credits — Get student's current credit hours
router.get('/credits', auth, async (req, res) => {
  try {
    if (req.user.role !== 'student') {
      return res.status(403).json({ message: 'Student access required' });
    }

    const credits = await ValidationController.getCurrentCredits(req.user.id);
    res.json({ credits, maxCredits: 20 });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
