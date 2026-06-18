const Enrollment = require('../../models/ManageOpenRegistration/Enrollment');
const Course = require('../../models/ManageOpenRegistration/Course');

class ValidationController {
  // Check student course eligibility: credit limit, seat availability, timetable clash
  static async validateRegistration(studentId, courseId) {
    try {
      const course = await Course.findById(courseId);
      if (!course) {
        return { valid: false, message: 'Course not found' };
      }

      // Check credit limit (max 20 credits per semester)
      const currentEnrollments = await Enrollment.find({
        student: studentId,
        status: 'active'
      }).populate('course');

      const totalCredits = currentEnrollments.reduce((sum, e) => {
        return sum + (e.course?.creditHours || 0);
      }, 0);

      if (totalCredits + course.creditHours > 20) {
        return { valid: false, message: `Credit limit exceeded. Current: ${totalCredits}, Adding: ${course.creditHours}, Max: 20` };
      }

      // Check seat availability (scoped to active session)
      const RegistrationSession = require('../../models/ManageOpenRegistration/RegistrationSession');
      const activeSession = await RegistrationSession.findOne({ status: 'open' }).sort({ createdAt: -1 });
      const sessionFilter = activeSession ? { session: activeSession._id } : {};
      const enrolledCount = await Enrollment.countDocuments({
        course: courseId,
        status: 'active',
        ...sessionFilter
      });

      const capacity = course.capacity || 30;
      if (enrolledCount >= capacity) {
        return { valid: false, message: 'Course is full' };
      }

      // Timetable clash detection (placeholder - requires session data)
      // Can be extended when timetable data is available

      return { valid: true };
    } catch (err) {
      return { valid: false, message: err.message };
    }
  }

  // Get student's current credit hours
  static async getCurrentCredits(studentId) {
    try {
      const enrollments = await Enrollment.find({
        student: studentId,
        status: 'active'
      }).populate('course');

      return enrollments.reduce((sum, e) => sum + (e.course?.creditHours || 0), 0);
    } catch (err) {
      return 0;
    }
  }
}

module.exports = ValidationController;
