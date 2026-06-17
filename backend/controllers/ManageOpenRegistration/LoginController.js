const Student = require('../../models/Student');
const FacultyRegistrar = require('../../models/FacultyRegistrar');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'sams-secret-key-2026';

class LoginController {
  // Process login for students/registrars
  static async login(req, res) {
    try {
      const { email, studentId, student_id, password } = req.body;
      const identifier = email || studentId || student_id;
      
      if (!identifier || !password) {
        return res.status(400).json({ message: 'Identifier and password required' });
      }

      let user = null;
      let role = null;
      let userId = null;

      // Check Student (by studentId or email)
      if (identifier.startsWith('CB') || identifier.includes('student')) {
        user = await Student.findOne({
          $or: [
            { studentId: identifier },
            { studEmail: identifier }
          ]
        });
        if (user) {
          role = 'student';
          userId = user.studentId;
        }
      }

      // Check Faculty Registrar
      if (!user && identifier.includes('faculty')) {
        user = await FacultyRegistrar.findOne({ facultyEmail: identifier });
        if (user) {
          role = 'faculty';
          userId = user.facultyId;
        }
      }

      if (!user) {
        return res.status(401).json({ message: 'Invalid credentials' });
      }

      // Verify password
      const storedPassword = user.studPassword || user.facultyPassword;
      const isMatch = await bcrypt.compare(password, storedPassword);
      if (!isMatch) {
        return res.status(401).json({ message: 'Invalid credentials' });
      }

      // Generate JWT
      const token = jwt.sign(
        { id: user._id, userId, role },
        JWT_SECRET,
        { expiresIn: '24h' }
      );

      res.json({
        token,
        user: {
          id: user._id,
          userId,
          name: user.studName || user.facultyName || 'User',
          email: user.studEmail || user.facultyEmail,
          role
        }
      });
    } catch (err) {
      console.error('Login error:', err.message);
      res.status(500).json({ message: 'Server error' });
    }
  }
}

module.exports = LoginController;
