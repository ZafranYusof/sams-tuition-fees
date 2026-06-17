const express = require('express');
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const fcm = require('../services/fcmService');

const router = express.Router();

/**
 * Register or update FCM device token for authenticated user.
 * POST /api/users/fcm-token
 * body: { fcmToken }
 */
router.post('/fcm-token', auth, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken || typeof fcmToken !== 'string') {
      return res.status(400).json({ error: 'fcmToken required' });
    }

    // $addToSet prevents duplicates
    await User.findByIdAndUpdate(req.user.id, {
      $addToSet: { fcmTokens: fcmToken },
    });

    res.json({ success: true });
  } catch (e) {
    console.error('[users/fcm-token]', e);
    res.status(500).json({ error: 'Failed to register token' });
  }
});

/**
 * Remove FCM token (called on logout).
 * DELETE /api/users/fcm-token
 * body: { fcmToken }
 */
router.delete('/fcm-token', auth, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) {
      return res.status(400).json({ error: 'fcmToken required' });
    }
    await User.findByIdAndUpdate(req.user.id, {
      $pull: { fcmTokens: fcmToken },
    });
    res.json({ success: true });
  } catch (e) {
    console.error('[users/fcm-token DELETE]', e);
    res.status(500).json({ error: 'Failed to remove token' });
  }
});

/**
 * Send a test notification to self (debug/demo).
 * POST /api/users/test-notification
 */
router.post('/test-notification', auth, async (req, res) => {
  try {
    const result = await fcm.sendToUser(req.user.id, {
      title: 'SAMS Test Notification',
      body: 'Push notifications working. Backend → FCM → your device.',
      data: { type: 'test', timestamp: Date.now().toString() },
    });
    // Return actual result (includes success, reason, error fields)
    if (result.success) {
      res.json(result);
    } else {
      res.status(500).json(result); // Pass through reason/error from FCM service
    }
  } catch (e) {
    console.error('[users/test-notification]', e);
    res.status(500).json({ success: false, error: e.message });
  }
});

/**
 * List all users (admin only).
 * GET /api/users
 */
router.get('/', auth, async (req, res) => {
  try {
    // Only admins can list all users
    if (req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Admin access required' });
    }
    const users = await User.find().select('-password -fcmTokens').sort({ createdAt: -1 });
    res.json(users);
  } catch (e) {
    console.error('[users GET]', e);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

module.exports = router;
