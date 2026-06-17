const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
  sessionType: { type: String, enum: ['lecture', 'tutorial', 'lab', 'seminar'], required: true },
  sessionNum: { type: Number },
  section: { type: mongoose.Schema.Types.ObjectId, ref: 'Section', required: true },
  lecturer: { type: mongoose.Schema.Types.ObjectId, ref: 'Lecturer', required: true },
  campus: { type: mongoose.Schema.Types.ObjectId, ref: 'Campus', required: true },
  day: { type: String, enum: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'], required: true },
  startTime: { type: String, required: true },
  endTime: { type: String, required: true },
  capacity: { type: Number, default: 50 },
  status: { type: String, enum: ['scheduled', 'active', 'completed', 'cancelled'], default: 'scheduled' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Session', sessionSchema);