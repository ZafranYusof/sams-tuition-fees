const express = require('express');
const router = express.Router();
const Session = require('../models/Session');
const { auth } = require('../middleware/auth');

// POST /sessions — Create session (lecturer/admin)
router.post('/', auth, async (req, res) => {
  try {
    if (req.user.role !== 'lecturer' && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Lecturer access required' });
    }
    const { sessionType, section, campus, day, startTime, endTime, capacity, sessionNum } = req.body;
    if (!section || !campus || !day || !startTime || !endTime) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    const session = await Session.create({
      sessionType: sessionType || 'lecture',
      sessionNum, section, lecturer: req.user.id, campus, day, startTime, endTime, capacity
    });
    res.status(201).json({ message: 'Session created', session });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /sessions — List sessions (filter by lecturer/day)
router.get('/', auth, async (req, res) => {
  try {
    const filter = {};
    if (req.user.role === 'lecturer') filter.lecturer = req.user.id;
    if (req.query.day) filter.day = req.query.day;
    const sessions = await Session.find(filter)
      .populate('section')
      .populate('campus')
      .populate('lecturer', 'name lectId');
    res.json({ sessions });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /sessions/:id — Get single session
router.get('/:id', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.id)
      .populate('section')
      .populate('campus')
      .populate('lecturer', 'name lectId');
    if (!session) return res.status(404).json({ message: 'Session not found' });
    res.json({ session });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /sessions/:id — Update session
router.put('/:id', auth, async (req, res) => {
  try {
    const session = await Session.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!session) return res.status(404).json({ message: 'Session not found' });
    res.json({ message: 'Session updated', session });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// DELETE /sessions/:id — Delete session
router.delete('/:id', auth, async (req, res) => {
  try {
    await Session.findByIdAndDelete(req.params.id);
    res.json({ message: 'Session deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;