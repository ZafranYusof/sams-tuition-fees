const express = require('express');
const router = express.Router();
const RegistrarController = require('../controllers/ManageOpenRegistration/RegistrarController');
const { auth } = require('../middleware/auth');

// GET /registrar/stats — Get registration statistics
router.get('/stats', auth, RegistrarController.getRegistrationStats);

// GET /registrar/session/active — Get active registration session
router.get('/session/active', auth, RegistrarController.getActiveSession);

// POST /registrar/quota — Update course quota
router.post('/quota', auth, RegistrarController.updateQuota);

// POST /registrar/session — Setup registration session
router.post('/session', auth, RegistrarController.setupSession);

module.exports = router;
