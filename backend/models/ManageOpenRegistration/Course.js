const mongoose = require('mongoose');

const courseSchema = new mongoose.Schema({
  courseId: { type: String, unique: true, required: true },
  courseName: { type: String, required: true },
  creditHours: { type: Number, required: true },
  section: { type: mongoose.Schema.Types.ObjectId, ref: 'Section' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Course', courseSchema);