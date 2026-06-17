const admin = require('firebase-admin');
const User = require('../models/User');

let initialized = false;
let initError = null; // Track init failure reason

function init() {
  if (initialized) return;
  try {
    let credential;
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      // Production: JSON string in env var (Render)
      const sa = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      credential = admin.credential.cert(sa);
    } else {
      // Local: load from file
      const sa = require('../firebase-service-account.json');
      credential = admin.credential.cert(sa);
    }
    
    // Check if already initialized (e.g. by another module)
    if (admin.apps.length > 0) {
      console.log('[FCM] Firebase Admin already initialized');
      initialized = true;
      return;
    }
    
    admin.initializeApp({ credential });
    initialized = true;
    console.log('[FCM] Firebase Admin initialized successfully');
    
    // Verify messaging is available
    if (typeof admin.messaging !== 'function') {
      console.error('[FCM] WARNING: admin.messaging is not available after init');
      initialized = false;
    }
  } catch (e) {
    console.error('[FCM] init failed:', e.message, e.stack);
    initialized = false;
    initError = e.message; // Save for debugging
  }
}

/**
 * Send notification to one user's all registered devices.
 * @param {string} userId
 * @param {object} payload - { title, body, data? }
 */
async function sendToUser(userId, payload) {
  init();
  if (!initialized) {
    console.warn('[FCM] not initialized, skipping push');
    return { success: false, reason: 'not_initialized', error: initError || 'Unknown init error' };
  }

  // Check if messaging() is available
  if (typeof admin.messaging !== 'function') {
    console.error('[FCM] admin.messaging is not a function - Firebase Admin SDK issue');
    return { success: false, reason: 'messaging_unavailable' };
  }

  try {
    const user = await User.findById(userId).select('fcmTokens');
    if (!user || !user.fcmTokens || user.fcmTokens.length === 0) {
      console.log(`[FCM] no tokens for user ${userId}`);
      return { success: false, reason: 'no_tokens' };
    }

    const message = {
      notification: { title: payload.title, body: payload.body },
      data: Object.fromEntries(
        Object.entries(payload.data || {}).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: 'high',
        notification: { channelId: 'sams_default', sound: 'default' },
      },
      tokens: user.fcmTokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`[FCM] sent ${response.successCount}/${user.fcmTokens.length} to ${userId}`);

    // Cleanup invalid tokens
    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success && (
          resp.error?.code === 'messaging/invalid-registration-token' ||
          resp.error?.code === 'messaging/registration-token-not-registered'
        )) {
          invalidTokens.push(user.fcmTokens[idx]);
        }
      });
      if (invalidTokens.length > 0) {
        await User.findByIdAndUpdate(userId, {
          $pull: { fcmTokens: { $in: invalidTokens } },
        });
        console.log(`[FCM] cleaned ${invalidTokens.length} stale tokens`);
      }
    }

    return { success: true, sent: response.successCount, failed: response.failureCount };
  } catch (e) {
    console.error('[FCM] send error:', e.message);
    return { success: false, error: e.message };
  }
}

/**
 * Send same notification to many users.
 * @param {string[]} userIds
 * @param {object} payload
 */
async function sendToUsers(userIds, payload) {
  const results = await Promise.all(userIds.map(id => sendToUser(id, payload)));
  return results;
}

/**
 * Send to all users with a specific role.
 */
async function sendToRole(role, payload) {
  const users = await User.find({ role, 'fcmTokens.0': { $exists: true } }).select('_id');
  const ids = users.map(u => u._id.toString());
  return sendToUsers(ids, payload);
}

module.exports = { init, sendToUser, sendToUsers, sendToRole };
