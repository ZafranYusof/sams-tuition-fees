const express = require('express');
const router = express.Router();
const AttendanceCode = require('../models/ManageClassAttendance/AttendanceCode');
const Attendance = require('../models/ManageClassAttendance/Attendance');
const Session = require('../models/ManageOpenRegistration/Session');
const Campus = require('../models/ManageClassAttendance/Campus');
const Enrollment = require('../models/ManageOpenRegistration/Enrollment');
const { auth } = require('../middleware/auth');
const crypto = require('crypto');

function generateCode() {
  return crypto.randomBytes(3).toString('hex').toUpperCase();
}

// Haversine distance in meters
function haversine(lat1, lon1, lat2, lon2) {
  const R = 6371000;
  const toRad = x => x * Math.PI / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat/2)**2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon/2)**2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
}

// POST /attendance/generate-code — Lecturer generates attendance code
router.post('/generate-code', auth, async (req, res) => {
  try {
    if (req.user.role !== 'lecturer' && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Lecturer access required' });
    }
    const { sessionId, expiresIn } = req.body;
    if (!sessionId) return res.status(400).json({ message: 'sessionId required' });

    const session = await Session.findById(sessionId);
    if (!session) return res.status(404).json({ message: 'Session not found' });

    // Deactivate existing codes
    await AttendanceCode.updateMany(
      { session: sessionId, isActive: true },
      { isActive: false, timeTerminated: new Date() }
    );

    const code = await AttendanceCode.create({
      code: generateCode(),
      session: sessionId,
      expiresIn: expiresIn || 300,
      createdBy: req.user.id
    });

    session.status = 'active';
    await session.save();

    res.status(201).json({
      code: code.code,
      expiresAt: new Date(code.createdAt.getTime() + code.expiresIn * 1000),
      sessionId
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /attendance/check-in — Student checks in with code + location
router.post('/check-in', auth, async (req, res) => {
  try {
    if (req.user.role !== 'student') return res.status(403).json({ message: 'Student access required' });

    const { code, latitude, longitude } = req.body;
    if (!code) return res.status(400).json({ message: 'Code required' });

    const attendanceCode = await AttendanceCode.findOne({ code: code.toUpperCase() });
    if (!attendanceCode) return res.status(404).json({ message: 'Invalid code' });
    if (!attendanceCode.isValid()) return res.status(400).json({ message: 'Code has expired' });

    // Verify student is enrolled in this session
    const session = await Session.findById(attendanceCode.session);
    if (!session) return res.status(404).json({ message: 'Session not found' });

    const enrolled = await Enrollment.findOne({ student: req.user.id, session: session._id, status: 'active' });
    if (!enrolled) return res.status(403).json({ message: 'Not enrolled in this session' });

    // Geofence check
    if (latitude && longitude) {
      const campus = await Campus.findById(session.campus);
      if (campus) {
        const dist = haversine(latitude, longitude, campus.centerLatitude, campus.centerLongitude);
        if (dist > campus.radius) {
          return res.status(400).json({ message: `Outside campus radius (${Math.round(dist)}m > ${campus.radius}m)` });
        }
      }
    }

    // Check duplicate
    const existing = await Attendance.findOne({ student: req.user.id, code: attendanceCode._id });
    if (existing) return res.status(400).json({ message: 'Already checked in' });

    // Determine status
    let status = 'present';
    const now = new Date();
    const sessionStart = new Date(session.date || now);
    const [h, m] = (session.startTime || '00:00').split(':');
    sessionStart.setHours(parseInt(h), parseInt(m), 0);
    const diffMin = (now - sessionStart) / 60000;
    if (diffMin > 15) status = 'late';

    const attendance = await Attendance.create({
      student: req.user.id,
      code: attendanceCode._id,
      status,
      latitude,
      longitude,
      checkInTime: new Date()
    });

    res.status(201).json({ message: 'Check-in successful', status: attendance.status, checkInTime: attendance.checkInTime });
  } catch (err) {
    if (err.code === 11000) return res.status(400).json({ message: 'Already checked in' });
    res.status(500).json({ message: err.message });
  }
});

// GET /attendance/session/:sessionId — Attendance list for a session
router.get('/session/:sessionId', auth, async (req, res) => {
  try {
    const session = await Session.findById(req.params.sessionId);
    if (!session) return res.status(404).json({ message: 'Session not found' });

    const codes = await AttendanceCode.find({ session: req.params.sessionId });
    const codeIds = codes.map(c => c._id);

    const records = await Attendance.find({ code: { $in: codeIds } })
      .populate('student', 'name studentId email')
      .sort({ checkInTime: 1 });

    // Get enrolled students for absent list
    const enrollments = await Enrollment.find({ session: req.params.sessionId, status: 'active' })
      .populate('student', 'name studentId email');
    
    const attendedIds = new Set(records.map(r => r.student._id.toString()));
    const absent = enrollments
      .filter(e => !attendedIds.has(e.student._id.toString()))
      .map(e => e.student);

    res.json({ session, totalCheckedIn: records.length, records, absent });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /attendance/student/:studentId — Student attendance history
router.get('/student/:studentId', auth, async (req, res) => {
  try {
    if (req.user.role === 'student' && req.user.id !== req.params.studentId) {
      return res.status(403).json({ message: 'Access denied' });
    }
    const records = await Attendance.find({ student: req.params.studentId })
      .populate({ path: 'code', populate: { path: 'session', populate: { path: 'section', populate: { path: 'course' } } } })
      .sort({ createdAt: -1 });
    res.json({ records });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /attendance/terminate-code — Lecturer terminates active code
router.post('/terminate-code', auth, async (req, res) => {
  try {
    if (req.user.role !== 'lecturer' && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Lecturer access required' });
    }
    const { codeId } = req.body;
    const code = await AttendanceCode.findById(codeId);
    if (!code) return res.status(404).json({ message: 'Code not found' });
    code.isActive = false;
    code.timeTerminated = new Date();
    await code.save();
    res.json({ message: 'Code terminated' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;