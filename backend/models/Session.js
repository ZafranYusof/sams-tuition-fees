const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
  sessionId: { type: String, unique: true, required: true },
  sessionType: { type: String, enum: ['lecture', 'tutorial', 'lab', 'seminar'], required: true },
  sessionNum: { type: String },
  sectionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Section', required: true },
  lectId: { type: mongoose.Schema.Types.ObjectId, ref: 'Lecturer', required: true },
  campusId: { type: mongoose.Schema.Types.ObjectId, ref: 'Campus', required: true },
  day: { type: String, enum: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'], required: true },
  startTime: { type: String, required: true },
  endTime: { type: String, required: true },
  capacity: { type: Number, default: 50 },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Session', sessionSchema);