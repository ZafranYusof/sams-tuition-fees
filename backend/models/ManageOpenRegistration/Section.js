const mongoose = require('mongoose');

const sectionSchema = new mongoose.Schema({
  sectionNum: { type: String, required: true },
  course: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Section', sectionSchema);