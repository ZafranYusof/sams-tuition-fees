const express = require('express');
const router = express.Router();
const Enrollment = require('../models/ManageOpenRegistration/Enrollment');
const RegistrationSession = require('../models/ManageOpenRegistration/RegistrationSession');
const Course = require('../models/ManageOpenRegistration/Course');
const FacultyRegistrar = require('../models/FacultyRegistrar');
const { auth } = require('../middleware/auth');

// GET /registration/session — Get active registration session
router.get('/session', auth, async (req, res) => {
  try {
    const now = new Date();
    const session = await RegistrationSession.findOne({
      status: 'open',
      startDate: { $lte: now },
      endDate: { $gte: now }
    }).populate('courses');
    res.json(session || null);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /registration/courses — List all available courses
router.get('/courses', auth, async (req, res) => {
  try {
    const courses = await Course.find({}).sort({ courseId: 1 });
    res.json(courses);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /registration/my — Get current student's enrollments
router.get('/my', auth, async (req, res) => {
  try {
    if (req.user.role !== 'student') {
      return res.status(403).json({ message: 'Student access required' });
    }
    const enrollments = await Enrollment.find({ student: req.user.id })
      .populate('course')
      .sort({ createdAt: -1 });
    res.json(enrollments);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /registration/open — FacultyRegistrar opens registration for a session
router.post('/open', auth, async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'faculty') {
      return res.status(403).json({ message: 'Faculty access required' });
    }
    const { sessionId, courseId, startDatetime, endDatetime } = req.body;
    if (!sessionId || !courseId) return res.status(400).json({ message: 'sessionId and courseId required' });

    const session = await RegistrationSession.findById(sessionId);
    if (!session) return res.status(404).json({ message: 'Session not found' });

    // Update session status
    session.status = 'open';
    await session.save();

    res.json({ message: 'Registration opened', sessionId, courseId, startDatetime, endDatetime });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /registration/enroll — Student enrolls in a course
router.post('/enroll', auth, async (req, res) => {
  try {
    if (req.user.role !== 'student') {
      return res.status(403).json({ message: 'Student access required' });
    }
    const { courseId } = req.body;
    if (!courseId) return res.status(400).json({ message: 'courseId required' });

    // Check active session exists and now is within session date range
    const now = new Date();
    const activeSession = await RegistrationSession.findOne({
      status: 'open',
      startDate: { $lte: now },
      endDate: { $gte: now }
    });

    if (!activeSession) {
      return res.status(400).json({ message: 'Registration is closed' });
    }

    // Check capacity
    const course = await Course.findById(courseId);
    if (!course) return res.status(404).json({ message: 'Course not found' });

    const currentEnrollments = await Enrollment.countDocuments({ course: courseId, session: activeSession._id, status: 'active' });
    if (currentEnrollments >= course.capacity) {
      return res.status(400).json({ message: 'Course is full' });
    }

    // Check duplicate
    const existing = await Enrollment.findOne({ student: req.user.id, course: courseId, session: activeSession._id, status: 'active' });
    if (existing) return res.status(400).json({ message: 'Already enrolled' });

    const enrollment = await Enrollment.create({
      student: req.user.id,
      session: activeSession._id,
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
