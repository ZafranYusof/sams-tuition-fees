const Attendance = require('../models/ManageClassAttendance/Attendance');
const AttendanceCode = require('../models/ManageClassAttendance/AttendanceCode');
const Session = require('../models/ManageClassAttendance/Session');

// Generate attendance code (lecturer)
exports.generateCode = async (req, res) => {
  try {
    const { sessionId, expiresIn } = req.body;
    if (!sessionId) return res.status(400).json({ message: 'sessionId required' });

    const session = await Session.findById(sessionId);
    if (!session) return res.status(404).json({ message: 'Session not found' });

    // Deactivate existing codes
    await AttendanceCode.updateMany(
      { session: sessionId, isActive: true },
      { isActive: false, timeTerminated: new Date() }
    );

    const crypto = require('crypto');
    const code = await AttendanceCode.create({
      code: crypto.randomBytes(3).toString('hex').toUpperCase(),
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
};

// Student check-in
exports.checkIn = async (req, res) => {
  try {
    const { code, latitude, longitude } = req.body;
    if (!code) return res.status(400).json({ message: 'Code required' });

    const attendanceCode = await AttendanceCode.findOne({ code: code.toUpperCase() });
    if (!attendanceCode) return res.status(404).json({ message: 'Invalid code' });
    if (!attendanceCode.isValid()) return res.status(400).json({ message: 'Code has expired' });

    const session = await Session.findById(attendanceCode.session);
    if (!session) return res.status(404).json({ message: 'Session not found' });

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
};

// Get attendance for a session
exports.getSessionAttendance = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const codes = await AttendanceCode.find({ session: sessionId });
    const codeIds = codes.map(c => c._id);

    const records = await Attendance.find({ code: { $in: codeIds } })
      .populate('student', 'name studentId email')
      .sort({ checkInTime: 1 });

    res.json({ records, totalCheckedIn: records.length });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get student attendance history
exports.getStudentAttendance = async (req, res) => {
  try {
    const { studentId } = req.params;
    const records = await Attendance.find({ student: studentId })
      .populate({ path: 'code', populate: { path: 'session' } })
      .sort({ createdAt: -1 });
    res.json({ records });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Terminate code (lecturer)
exports.terminateCode = async (req, res) => {
  try {
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
};
