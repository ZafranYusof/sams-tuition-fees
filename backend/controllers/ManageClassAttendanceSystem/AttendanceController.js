const AttendanceCode = require('../models/AttendanceCode');
const Attendance = require('../models/Attendance');
const { isWithinCampus } = require('../services/locationService');

// ─── Helper: generate a random 6-character alphanumeric code ─────────────────
function generateCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no confusing chars (0,O,1,I)
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

// ─── LECTURER: Generate attendance code for a session ────────────────────────
// POST /api/attendance/generate
// Body: { sessionId }
const generateAttendanceCode = async (req, res) => {
  try {
    const { sessionId } = req.body;

    // Terminate any existing active code for this session first
    await AttendanceCode.updateMany(
      { sessionId, timeTerminated: null },
      { timeTerminated: new Date() }
    );

    // Generate a unique code (retry if collision)
    let code;
    let exists = true;
    while (exists) {
      code = generateCode();
      exists = await AttendanceCode.findOne({ code, timeTerminated: null });
    }

    const newCode = await AttendanceCode.create({
      code,
      sessionId,
      timeGenerated: new Date(),
      timeTerminated: null,
    });

    res.status(201).json({ success: true, code: newCode.code });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── LECTURER: Terminate attendance code (end class) ─────────────────────────
// POST /api/attendance/terminate
// Body: { sessionId }
const terminateAttendanceCode = async (req, res) => {
  try {
    const { sessionId } = req.body;

    await AttendanceCode.updateMany(
      { sessionId, timeTerminated: null },
      { timeTerminated: new Date() }
    );

    res.json({ success: true, message: 'Attendance session ended.' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── STUDENT: Check in with code + GPS coordinates ───────────────────────────
// POST /api/attendance/checkin
// Body: { studId, sessionId, code, latitude, longitude }
const checkIn = async (req, res) => {
  try {
    const { studId, sessionId, code, latitude, longitude } = req.body;

    // 1. Validate the attendance code (must exist and be active)
    const activeCode = await AttendanceCode.findOne({
      code,
      sessionId,
      timeTerminated: null,
    });

    if (!activeCode) {
      return res.status(400).json({
        success: false,
        reason: 'invalid_code',
        message: 'Incorrect or expired attendance code.',
      });
    }

    // 2. Verify the student is within campus boundary
    const onCampus = await isWithinCampus(latitude, longitude);
    if (!onCampus) {
      return res.status(403).json({
        success: false,
        reason: 'outside_boundary',
        message: 'You are outside the campus boundary.',
      });
    }

    // 3. Find or create the attendance record for this student + session
    let record = await Attendance.findOne({ studId, sessionId });

    if (record) {
      // Update existing record
      record.status = 'Present';
      record.code = code;
      record.checkInTime = new Date();
      record.latitude = latitude;
      record.longitude = longitude;
      await record.save();
    } else {
      // Create new record
      record = await Attendance.create({
        studId,
        sessionId,
        code,
        status: 'Present',
        checkInTime: new Date(),
        latitude,
        longitude,
      });
    }

    res.json({ success: true, message: 'Attendance recorded successfully.' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── STUDENT: Get attendance records for a student in a course ───────────────
// GET /api/attendance/student/:studId/session/:sessionId
const getStudentAttendance = async (req, res) => {
  try {
    const { studId, sessionId } = req.params;
    const records = await Attendance.find({ studId, sessionId });
    res.json({ success: true, data: records });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── STUDENT: Get overall attendance percentage for a student ─────────────────
// GET /api/attendance/student/:studId/percentage
const getStudentAttendancePercentage = async (req, res) => {
  try {
    const { studId } = req.params;
    const { sessionIds } = req.query; // comma-separated session IDs for a course

    const ids = sessionIds ? sessionIds.split(',') : [];
    const query = { studId };
    if (ids.length > 0) query.sessionId = { $in: ids };

    const records = await Attendance.find(query);
    const total = records.length;
    const present = records.filter((r) => r.status === 'Present').length;
    const percentage = total === 0 ? 0 : Math.round((present / total) * 100);

    res.json({ success: true, total, present, percentage });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── LECTURER: Get all attendance records for a session ──────────────────────
// GET /api/attendance/session/:sessionId
const getSessionAttendance = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const records = await Attendance.find({ sessionId });

    const total = records.length;
    const present = records.filter((r) => r.status === 'Present').length;
    const percentage = total === 0 ? 0 : Math.round((present / total) * 100);

    res.json({ success: true, data: records, total, present, percentage });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// ─── LECTURER: Check if an active code exists for a session ──────────────────
// GET /api/attendance/active-code/:sessionId
const getActiveCode = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const activeCode = await AttendanceCode.findOne({
      sessionId,
      timeTerminated: null,
    });

    res.json({
      success: true,
      hasActiveCode: !!activeCode,
      code: activeCode ? activeCode.code : null,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

module.exports = {
  generateAttendanceCode,
  terminateAttendanceCode,
  checkIn,
  getStudentAttendance,
  getStudentAttendancePercentage,
  getSessionAttendance,
  getActiveCode,
};