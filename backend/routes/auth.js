const express = require('express');
const jwt = require('jsonwebtoken');
const Student = require('../models/Student');
const Lecturer = require('../models/Lecturer');
const FacultyRegistrar = require('../models/FacultyRegistrar');
const PusatAdab = require('../models/PusatAdab');
const Treasury = require('../models/ManageTuitionFees/Treasury');
const { jwtSecret, jwtExpire } = require('../config');
const { auth } = require('../middleware/auth');

const router = express.Router();

// Helper: find user across all collections by email/studentId
async function findUser(identifier) {
  // Try Student
  let user = await Student.findOne({ $or: [{ studEmail: identifier }, { studentId: identifier }] });
  if (user) return { user, role: 'student', Model: Student };

  // Try Lecturer
  user = await Lecturer.findOne({ $or: [{ lectEmail: identifier }, { lectId: identifier }] });
  if (user) return { user, role: 'lecturer', Model: Lecturer };

  // Try FacultyRegistrar
  user = await FacultyRegistrar.findOne({ $or: [{ facultyEmail: identifier }, { facultyId: identifier }] });
  if (user) return { user, role: 'faculty', Model: FacultyRegistrar };

  // Try PusatAdab
  user = await PusatAdab.findOne({ $or: [{ staffEmail: identifier }, { paStaffId: identifier }] });
  if (user) return { user, role: 'staff', Model: PusatAdab };

  // Try Treasury
  user = await Treasury.findOne({ trsEmail: identifier });
  if (user) return { user, role: 'admin', Model: Treasury };

  return null;
}

// Helper: get password field name by role
function getPasswordField(role) {
  switch (role) {
    case 'student': return 'studPassword';
    case 'lecturer': return 'lectPassword';
    case 'faculty': return 'facultyPassword';
    case 'staff': return 'staffPassword';
    case 'admin': return 'trsPassword';
    default: return 'password';
  }
}

// Helper: format user response by role
function formatUser(user, role) {
  const base = { id: user._id, role };
  switch (role) {
    case 'student':
      return { ...base, studentId: user.studentId, student_id: user.studentId, name: user.studName, email: user.studEmail, major: user.major };
    case 'lecturer':
      return { ...base, lectId: user.lectId, name: user.lectName, email: user.lectEmail, phoneNum: user.lectPhoneNum, experience: user.lectExperience };
    case 'faculty':
      return { ...base, facultyId: user.facultyId, name: 'Faculty Registrar', email: user.facultyEmail, phoneNum: user.facultyPhoneNumber };
    case 'staff':
      return { ...base, paStaffId: user.paStaffId, name: user.staffName, email: user.staffEmail, phoneNum: user.staffPhoneNumber };
    case 'admin':
      return { ...base, name: user.trsName, email: user.trsEmail };
    default:
      return base;
  }
}

// Register (students only — CB##### format)
router.post('/register', async (req, res) => {
  try {
    const studentId = req.body.studentId || req.body.student_id;
    const { name, email, password, major } = req.body;

    if (!studentId || !name || !email || !password) {
      return res.status(400).json({ error: 'studentId, name, email, and password are required' });
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    const exists = await Student.findOne({ $or: [{ studEmail: email }, { studentId }] });
    if (exists) return res.status(400).json({ error: 'Student already exists' });

    const student = new Student({ studentId, studName: name, studEmail: email, studPassword: password, major });
    await student.save();

    const token = jwt.sign({ id: student._id, role: 'student' }, jwtSecret, { expiresIn: jwtExpire });
    res.status(201).json({ token, user: formatUser(student, 'student') });
  } catch (err) {
    console.error('Register error:', err.message);
    res.status(500).json({ error: 'Registration failed. Please try again.' });
  }
});

// Login — searches across Student, Lecturer, FacultyRegistrar, PusatAdab
router.post('/login', async (req, res) => {
  try {
    const identifier = req.body.email || req.body.student_id || req.body.studentId || req.body.identifier;
    const { password } = req.body;

    if (!identifier || !password) {
      return res.status(400).json({ error: 'Email/ID and password are required' });
    }

    const result = await findUser(identifier);
    if (!result) return res.status(401).json({ error: 'Invalid credentials' });

    const { user, role } = result;
    const passwordField = getPasswordField(role);
    const isMatch = await user.comparePassword(password);
    if (!isMatch) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ id: user._id, role }, jwtSecret, { expiresIn: jwtExpire });
    res.json({ token, user: formatUser(user, role) });
  } catch (err) {
    console.error('Login error:', err.message);
    res.status(500).json({ error: 'Login failed. Please try again.' });
  }
});

// Get profile — lookup from correct collection based on role in JWT
router.get('/profile', auth, async (req, res) => {
  try {
    const { id, role } = req.user;
    let user;
    switch (role) {
      case 'student':
        user = await Student.findById(id).select('-studPassword');
        break;
      case 'lecturer':
        user = await Lecturer.findById(id).select('-lectPassword');
        break;
      case 'faculty':
        user = await FacultyRegistrar.findById(id).select('-facultyPassword');
        break;
      case 'staff':
        user = await PusatAdab.findById(id).select('-staffPassword');
        break;
      case 'admin':
        user = await Treasury.findById(id).select('-trsPassword');
        break;
      default:
        return res.status(400).json({ error: 'Invalid role' });
    }
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ ...formatUser(user, role), createdAt: user.createdAt });
  } catch (err) {
    console.error('Profile error:', err.message);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// Alias /me -> /profile
router.get('/me', auth, async (req, res) => {
  try {
    const { id, role } = req.user;
    let user;
    switch (role) {
      case 'student':
        user = await Student.findById(id).select('-studPassword');
        break;
      case 'lecturer':
        user = await Lecturer.findById(id).select('-lectPassword');
        break;
      case 'faculty':
        user = await FacultyRegistrar.findById(id).select('-facultyPassword');
        break;
      case 'staff':
        user = await PusatAdab.findById(id).select('-staffPassword');
        break;
      case 'admin':
        user = await Treasury.findById(id).select('-trsPassword');
        break;
      default:
        return res.status(400).json({ error: 'Invalid role' });
    }
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ ...formatUser(user, role), createdAt: user.createdAt });
  } catch (err) {
    console.error('Profile error:', err.message);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// Update profile
router.put('/profile', auth, async (req, res) => {
  try {
    const { id, role } = req.user;
    let user;
    switch (role) {
      case 'student':
        user = await Student.findByIdAndUpdate(id, { studName: req.body.name, major: req.body.major }, { new: true }).select('-studPassword');
        break;
      case 'lecturer':
        user = await Lecturer.findByIdAndUpdate(id, { lectName: req.body.name, lectPhoneNum: req.body.phoneNum }, { new: true }).select('-lectPassword');
        break;
      case 'faculty':
        user = await FacultyRegistrar.findByIdAndUpdate(id, { facultyPhoneNumber: req.body.phoneNum }, { new: true }).select('-facultyPassword');
        break;
      case 'staff':
        user = await PusatAdab.findByIdAndUpdate(id, { staffName: req.body.name, staffPhoneNumber: req.body.phoneNum }, { new: true }).select('-staffPassword');
        break;
      case 'admin':
        user = await Treasury.findByIdAndUpdate(id, { trsName: req.body.name }, { new: true }).select('-trsPassword');
        break;
      default:
        return res.status(400).json({ error: 'Invalid role' });
    }
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ ...formatUser(user, role), createdAt: user.createdAt });
  } catch (err) {
    console.error('Update profile error:', err.message);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// Change password
router.post('/change-password', auth, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Current password and new password are required' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'New password must be at least 6 characters' });
    }

    const { id, role } = req.user;
    let user;
    switch (role) {
      case 'student': user = await Student.findById(id); break;
      case 'lecturer': user = await Lecturer.findById(id); break;
      case 'faculty': user = await FacultyRegistrar.findById(id); break;
      case 'staff': user = await PusatAdab.findById(id); break;
      case 'admin': user = await Treasury.findById(id); break;
      default: return res.status(400).json({ error: 'Invalid role' });
    }
    if (!user) return res.status(404).json({ error: 'User not found' });

    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) return res.status(401).json({ error: 'Current password is incorrect' });

    // Update password field based on role
    switch (role) {
      case 'student': user.studPassword = newPassword; break;
      case 'lecturer': user.lectPassword = newPassword; break;
      case 'faculty': user.facultyPassword = newPassword; break;
      case 'staff': user.staffPassword = newPassword; break;
      case 'admin': user.trsPassword = newPassword; break;
    }
    await user.save();

    res.json({ message: 'Password updated successfully' });
  } catch (err) {
    console.error('Change password error:', err.message);
    res.status(500).json({ error: 'Failed to change password' });
  }
});

module.exports = router;

// FCM Token Management (moved from routes/users.js)
const fcm = require('../services/fcmService');

/**
 * Register or update FCM device token for authenticated student.
 * POST /api/auth/fcm-token
 * body: { fcmToken }
 */
router.post('/fcm-token', auth, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken || typeof fcmToken !== 'string') {
      return res.status(400).json({ error: 'fcmToken required' });
    }

    // Only students have FCM tokens in this system
    if (req.user.role !== 'student') {
      return res.status(403).json({ error: 'FCM tokens are only for students' });
    }

    // $addToSet prevents duplicates
    await Student.findByIdAndUpdate(req.user.id, {
      $addToSet: { fcmTokens: fcmToken },
    });

    res.json({ success: true });
  } catch (e) {
    console.error('[auth/fcm-token]', e);
    res.status(500).json({ error: 'Failed to register token' });
  }
});

/**
 * Remove FCM token (called on logout).
 * DELETE /api/auth/fcm-token
 * body: { fcmToken }
 */
router.delete('/fcm-token', auth, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) {
      return res.status(400).json({ error: 'fcmToken required' });
    }
    await Student.findByIdAndUpdate(req.user.id, {
      $pull: { fcmTokens: fcmToken },
    });
    res.json({ success: true });
  } catch (e) {
    console.error('[auth/fcm-token DELETE]', e);
    res.status(500).json({ error: 'Failed to remove token' });
  }
});

/**
 * Send a test notification to self (debug/demo).
 * POST /api/auth/test-notification
 */
router.post('/test-notification', auth, async (req, res) => {
  try {
    const result = await fcm.sendToUser(req.user.id, {
      title: 'SAMS Test Notification',
      body: 'Push notifications working. Backend → FCM → your device.',
      data: { type: 'test', timestamp: Date.now().toString() },
    });
    if (result.success) {
      res.json(result);
    } else {
      res.status(500).json(result);
    }
  } catch (e) {
    console.error('[auth/test-notification]', e);
    res.status(500).json({ success: false, error: e.message });
  }
});
