const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { jwtSecret, jwtExpire } = require('../config');
const { auth } = require('../middleware/auth');

const router = express.Router();

// Register
router.post('/register', async (req, res) => {
  try {
    const studentId = req.body.studentId || req.body.student_id;
    const { name, email, password, faculty, program } = req.body;

    // [Bug #8] Input validation on registration
    if (!studentId || !name || !email || !password) {
      return res.status(400).json({ error: 'studentId, name, email, and password are required' });
    }
    // Email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }
    
    const exists = await User.findOne({ $or: [{ email }, { studentId }] });
    if (exists) return res.status(400).json({ error: 'User already exists' });

    const user = new User({ studentId, name, email, password, faculty, program });
    await user.save();

    const token = jwt.sign({ id: user._id, role: user.role }, jwtSecret, { expiresIn: jwtExpire });
    // [Bug #4] Include studentId in register response
    res.status(201).json({ token, user: { id: user._id, name: user.name, email: user.email, role: user.role, studentId: user.studentId, student_id: user.studentId } });
  } catch (err) {
    // [Bug #9] Don't leak internal errors
    console.error('Register error:', err.message);
    res.status(500).json({ error: 'Registration failed. Please try again.' });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const identifier = req.body.email || req.body.student_id || req.body.studentId;
    const { password } = req.body;
    const user = await User.findOne({ $or: [{ email: identifier }, { studentId: identifier }] });
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });

    const isMatch = await user.comparePassword(password);
    if (!isMatch) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ id: user._id, role: user.role }, jwtSecret, { expiresIn: jwtExpire });
    res.json({ token, user: { id: user._id, name: user.name, email: user.email, role: user.role, studentId: user.studentId, student_id: user.studentId } });
  } catch (err) {
    console.error('Login error:', err.message);
    res.status(500).json({ error: 'Login failed. Please try again.' });
  }
});

// Get profile
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    res.json(user);
  } catch (err) {
    console.error('Profile error:', err.message);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// Alias /me -> /profile
router.get('/me', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    res.json(user);
  } catch (err) {
    console.error('Profile error:', err.message);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// Update profile
router.put('/profile', auth, async (req, res) => {
  try {
    const { name, phone, faculty, program } = req.body;
    const user = await User.findByIdAndUpdate(req.user.id, { name, phone, faculty, program }, { new: true }).select('-password');
    res.json(user);
  } catch (err) {
    console.error('Update profile error:', err.message);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

module.exports = router;
