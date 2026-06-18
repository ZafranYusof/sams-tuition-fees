const Enrollment = require('../../models/ManageOpenRegistration/Enrollment');
const Course = require('../../models/ManageOpenRegistration/Course');
const ValidationController = require('./ValidationController');

class RegistrationController {
  // Student enrolls in a course
  static async registerCourse(req, res) {
    try {
      const { courseId, semester, academicYear } = req.body;
      
      // Validate eligibility
      const validation = await ValidationController.validateRegistration(req.user.id, courseId);
      if (!validation.valid) {
        return res.status(400).json({ message: validation.message });
      }

      // Check duplicate
      const existing = await Enrollment.findOne({
        student: req.user.id,
        course: courseId,
        status: 'active'
      });

      if (existing) {
        return res.status(400).json({ message: 'Already registered for this course' });
      }

      // Create enrollment
      const enrollment = new Enrollment({
        student: req.user.id,
        course: courseId,
        semester: semester || 1,
        academicYear: academicYear || '2025/2026',
        status: 'active'
      });

      await enrollment.save();
      res.json({ message: 'Course registered successfully', enrollment });
    } catch (err) {
      console.error('Registration error:', err.message);
      res.status(500).json({ message: err.message });
    }
  }

  // Get student's registrations
  static async getMyRegistrations(req, res) {
    try {
      const enrollments = await Enrollment.find({ student: req.user.id })
        .populate('course')
        .sort({ createdAt: -1 });
      res.json(enrollments);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }
}

module.exports = RegistrationController;
