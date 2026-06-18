const Course = require('../../models/ManageOpenRegistration/Course');

class SubjectController {
  // Get all subjects/courses
  static async getSubjects(req, res) {
    try {
      const courses = await Course.find().sort({ courseId: 1 });
      res.json(courses);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }

  // Get subject by ID
  static async getSubjectById(req, res) {
    try {
      const course = await Course.findById(req.params.id);
      if (!course) {
        return res.status(404).json({ message: 'Subject not found' });
      }
      res.json(course);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }

  // Create new subject (admin only)
  static async createSubject(req, res) {
    try {
      if (req.user.role !== 'admin' && req.user.role !== 'faculty') {
        return res.status(403).json({ message: 'Faculty access required' });
      }

      const { courseId, courseName, creditHours, capacity } = req.body;
      
      const course = new Course({
        courseId,
        courseName,
        creditHours: creditHours || 3,
        capacity: capacity || 30
      });

      await course.save();
      res.json({ message: 'Subject created', course });
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }

  // Update subject quota/availability
  static async updateSubject(req, res) {
    try {
      if (req.user.role !== 'admin' && req.user.role !== 'faculty') {
        return res.status(403).json({ message: 'Faculty access required' });
      }

      const { courseName, creditHours, capacity } = req.body;
      const course = await Course.findById(req.params.id);
      
      if (!course) {
        return res.status(404).json({ message: 'Subject not found' });
      }

      if (courseName) course.courseName = courseName;
      if (creditHours) course.creditHours = creditHours;
      if (capacity !== undefined && capacity !== null) course.capacity = capacity;

      await course.save();
      res.json({ message: 'Subject updated', course });
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }
}

module.exports = SubjectController;
