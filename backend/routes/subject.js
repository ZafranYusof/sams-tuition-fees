const express = require('express');
const router = express.Router();
const SubjectController = require('../controllers/ManageOpenRegistration/SubjectController');
const { auth } = require('../middleware/auth');

// GET /subject — Get all subjects
router.get('/', auth, SubjectController.getSubjects);

// GET /subject/:id — Get subject by ID
router.get('/:id', auth, SubjectController.getSubjectById);

// POST /subject — Create new subject (admin)
router.post('/', auth, SubjectController.createSubject);

// PUT /subject/:id — Update subject (admin)
router.put('/:id', auth, SubjectController.updateSubject);

module.exports = router;
