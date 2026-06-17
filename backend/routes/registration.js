const express = require('express');
const router = express.Router();
const Enrollment = require('../models/Enrollment');
const Session = require('../models/Session');
const Course = require('../models/Course');
const FacultyRegistrar = require('../models/FacultyRegistrar');
const { auth } = require('../middleware/auth');

// POST /registration/open — FacultyRegistrar opens registration for a session
router.post('/open', auth, async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'faculty') {
      return res.status(403).json({ message: 'Faculty access required' });
    }
    const { sessionId, courseId, startDatetime, endDatetime } = req.body;
    if (!sessionId || !courseId) return res.status(400).json({ message: 'sessionId and courseId required' });

    const session = await Session.findById(sessionId);
    if (!session) return res.status(404).json({ message: 'Session not found' });

    // Update session status
    session.status = 'scheduled';
    await session.save();

    res.json({ message: 'Registration opened', sessionId, courseId, startDatetime, endDatetime });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /registration/enroll — Student enrolls in a session
router.post('/enroll', auth, async (req, res) => {
  try {
    if (req.user.role !== 'student') {
      return res.status(403).json({ message: 'Student access required' });
    }
    const { sessionId, courseId } = req.body;
    if (!sessionId || !courseId) return res.status(400).json({ message: 'sessionId and courseId required' });

    // Check capacity
    const session = await Session.findById(sessionId);
    if (!session) return res.status(404).json({ message: 'Session not found' });

    const currentEnrollments = await Enrollment.countDocuments({ session: sessionId, status: 'active' });
    if (currentEnrollments >= session.capacity) {
      return res.status(400).json({ message: 'Session is full' });
    }

    // Check duplicate
    const existing = await Enrollment.findOne({ student: req.user.id, session: sessionId, status: 'active' });
    if (existing) return res.status(400).json({ message: 'Already enrolled' });

    const enrollment = await Enrollment.create({
      student: req.user.id,
      session: sessionId,
      course: courseId,
      startDatetime: new Date(),
      faculty: req.body.facultyId
    });

    res.status(201).json({ message: 'Enrolled successfully', enrollment });
  } catch (err) {
    if (err.code === 11000) return res.status(400).json({ message: 'Already enrolled' });
    res.status(500).json({ message: err.message });
  }
});

// POST /registration/drop — Student drops a course
router.post('/drop', auth, async (req, res) => {
  try {
    const { enrollmentId } = req.body;
    const enrollment = await Enrollment.findById(enrollmentId);
    if (!enrollment) return res.status(404).json({ message: 'Enrollment not found' });
    if (enrollment.student.toString() !== req.user.id) return res.status(403).json({ message: 'Not your enrollment' });

    enrollment.status = 'dropped';
    enrollment.endDatetime = new Date();
    await enrollment.save();

    res.json({ message: 'Dropped successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /registration/my — Student's enrollments
router.get('/my', auth, async (req, res) => {
  try {
    const enrollments = await Enrollment.find({ student: req.user.id, status: 'active' })
      .populate('session')
      .populate('course');
    res.json({ enrollments });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /registration/session/:sessionId — List students enrolled in a session
router.get('/session/:sessionId', auth, async (req, res) => {
  try {
    const enrollments = await Enrollment.find({ session: req.params.sessionId, status: 'active' })
      .populate('student', 'name studentId email');
    res.json({ total: enrollments.length, enrollments });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;