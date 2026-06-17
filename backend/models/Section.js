const mongoose = require('mongoose');

const sectionSchema = new mongoose.Schema({
  sectionId: { type: String, unique: true, required: true },
  sectionNum: { type: String, required: true },
  courseId: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Section', sectionSchema);