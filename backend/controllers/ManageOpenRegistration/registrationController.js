const Registration = require('../models/ManageOpenRegistration/Registration');
const Enrollment = require('../models/ManageOpenRegistration/Enrollment');
const Course = require('../models/ManageOpenRegistration/Course');
const Section = require('../models/ManageOpenRegistration/Section');

// Get available courses for registration
exports.getAvailableCourses = async (req, res) => {
  try {
    const courses = await Course.find({ isActive: true });
    res.json({ courses });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get student enrollments
exports.getEnrollments = async (req, res) => {
  try {
    const { studentId } = req.params;
    const enrollments = await Enrollment.find({ student: studentId })
      .populate('section')
      .populate({ path: 'section', populate: { path: 'course' } });
    res.json({ enrollments });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Register for a course section
exports.registerCourse = async (req, res) => {
  try {
    const { sectionId } = req.body;
    const section = await Section.findById(sectionId);
    if (!section) return res.status(404).json({ message: 'Section not found' });

    // Check if already enrolled
    const existing = await Enrollment.findOne({ student: req.user.id, section: sectionId, status: 'active' });
    if (existing) return res.status(400).json({ message: 'Already enrolled' });

    const enrollment = await Enrollment.create({
      student: req.user.id,
      section: sectionId,
      status: 'active'
    });

    res.status(201).json(enrollment);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Drop a course
exports.dropCourse = async (req, res) => {
  try {
    const { enrollmentId } = req.params;
    const enrollment = await Enrollment.findByIdAndUpdate(
      enrollmentId,
      { status: 'dropped' },
      { new: true }
    );
    if (!enrollment) return res.status(404).json({ message: 'Enrollment not found' });
    res.json(enrollment);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get all registrations (admin view)
exports.getAllRegistrations = async (req, res) => {
  try {
    const registrations = await Registration.find()
      .populate('student', 'name studentId')
      .sort({ createdAt: -1 });
    res.json({ registrations });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
