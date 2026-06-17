const express = require('express');
const router = express.Router();
const {
  generateAttendanceCode,
  terminateAttendanceCode,
  checkIn,
  getStudentAttendance,
  getStudentAttendancePercentage,
  getSessionAttendance,
  getActiveCode,
} = require('../controllers/AttendanceController');

// Lecturer routes
router.post('/generate', generateAttendanceCode);           // generate code
router.post('/terminate', terminateAttendanceCode);         // end class
router.get('/active-code/:sessionId', getActiveCode);       // check if code is active
router.get('/session/:sessionId', getSessionAttendance);    // get all students for a session

// Student routes
router.post('/checkin', checkIn);                           // student check in
router.get('/student/:studId/session/:sessionId', getStudentAttendance);
router.get('/student/:studId/percentage', getStudentAttendancePercentage);

module.exports = router;