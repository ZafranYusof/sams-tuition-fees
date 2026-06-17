const express = require('express');
const router = express.Router();
const Campus = require('../models/Campus');
const { auth } = require('../middleware/auth');

// POST /campus — Create campus (admin)
router.post('/', auth, async (req, res) => {
  try {
    if (req.user.role !== 'admin') return res.status(403).json({ message: 'Admin access required' });
    const { campusId, campusName, centerLatitude, centerLongitude, radius } = req.body;
    if (!campusId || !campusName || !centerLatitude || !centerLongitude) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    const campus = await Campus.create({ campusId, campusName, centerLatitude, centerLongitude, radius: radius || 100 });
    res.status(201).json({ message: 'Campus created', campus });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /campus — List all campuses
router.get('/', auth, async (req, res) => {
  try {
    const campuses = await Campus.find();
    res.json({ campuses });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /campus/:id — Update campus
router.put('/:id', auth, async (req, res) => {
  try {
    if (req.user.role !== 'admin') return res.status(403).json({ message: 'Admin access required' });
    const campus = await Campus.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!campus) return res.status(404).json({ message: 'Campus not found' });
    res.json({ message: 'Campus updated', campus });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;