const RegistrationSession = require('../../models/ManageOpenRegistration/RegistrationSession');

class SessionController {
  // Create new registration session
  static async createSession(req, res) {
    try {
      if (req.user.role !== 'admin' && req.user.role !== 'faculty') {
        return res.status(403).json({ message: 'Faculty access required' });
      }

      const { sessionName, startDate, endDate, capacity } = req.body;
      
      const session = new RegistrationSession({
        sessionId: `SES-${Date.now()}`,
        sessionName,
        startDate,
        endDate,
        status: 'scheduled',
        capacity: capacity || 100
      });

      await session.save();
      res.json({ message: 'Session created', session });
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }

  // Activate session
  static async activateSession(req, res) {
    try {
      if (req.user.role !== 'admin' && req.user.role !== 'faculty') {
        return res.status(403).json({ message: 'Faculty access required' });
      }

      const { sessionId } = req.params;
      const session = await RegistrationSession.findById(sessionId);
      
      if (!session) {
        return res.status(404).json({ message: 'Session not found' });
      }

      session.status = 'open';
      session.startDate = new Date();
      await session.save();

      res.json({ message: 'Session activated', session });
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }

  // Close session
  static async closeSession(req, res) {
    try {
      if (req.user.role !== 'admin' && req.user.role !== 'faculty') {
        return res.status(403).json({ message: 'Faculty access required' });
      }

      const { sessionId } = req.params;
      const session = await RegistrationSession.findById(sessionId);
      
      if (!session) {
        return res.status(404).json({ message: 'Session not found' });
      }

      session.status = 'closed';
      session.endDate = new Date();
      await session.save();

      res.json({ message: 'Session closed', session });
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }

  // Get all sessions
  static async getSessions(req, res) {
    try {
      const sessions = await RegistrationSession.find().sort({ createdAt: -1 });
      res.json(sessions);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }
}

module.exports = SessionController;
