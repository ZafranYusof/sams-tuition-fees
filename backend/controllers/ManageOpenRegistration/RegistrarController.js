const Session = require('../../models/ManageOpenRegistration/Session');
const Course = require('../../models/ManageOpenRegistration/Course');
const Enrollment = require('../../models/ManageOpenRegistration/Enrollment');

class RegistrarController {
  // Get registration statistics
  static async getRegistrationStats(req, res) {
    try {
      if (req.user.role !== 'admin' && req.user.role !== 'faculty') {
        return res.status(403).json({ message: 'Faculty access required' });
      }

      const totalCourses = await Course.countDocuments();
      const totalEnrollments = await Enrollment.countDocuments({ status: 'active' });
      const openSessions = await Session.countDocuments({ status: 'open' });

      // Get enrollments by course
      const enrollmentsByCourse = await Enrollment.aggregate([
        { $match: { status: 'active' } },
        { $group: { _id: '$course', count: { $sum: 1 } } },
        { $lookup: { from: 'courses', localField: '_id', foreignField: '_id', as: 'course' } },
        { $unwind: '$course' },
        { $project: { courseId: '$course.courseId', courseName: '$course.courseName', enrolled: '$count' } }
      ]);

      res.json({
        totalCourses,
        totalEnrollments,
        openSessions,
        enrollmentsByCourse
      });
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }

  // Manage subject quotas
  static async updateQuota(req, res) {
    try {
      if (req.user.role !== 'admin' && req.user.role !== 'faculty') {
        return res.status(403).json({ message: 'Faculty access required' });
      }

      const { courseId, capacity } = req.body;
      const course = await Course.findById(courseId);
      
      if (!course) {
        return res.status(404).json({ message: 'Course not found' });
      }

      course.capacity = capacity;
      await course.save();

      res.json({ message: 'Quota updated', course });
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }

  // Setup registration session
  static async setupSession(req, res) {
    try {
      if (req.user.role !== 'admin' && req.user.role !== 'faculty') {
        return res.status(403).json({ message: 'Faculty access required' });
      }

      const { sessionName, startDate, endDate, courseIds } = req.body;
      
      const session = new Session({
        sessionId: `SES-${Date.now()}`,
        sessionName,
        startDate,
        endDate,
        status: 'scheduled',
        courses: courseIds || []
      });

      await session.save();
      res.json({ message: 'Session setup complete', session });
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }
}

module.exports = RegistrarController;
