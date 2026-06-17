const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema({
  studentId: { type: String, unique: true, required: true },
  name: { type: String, required: true },
  email: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  major: { type: String },
  enrollments: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Enrollment' }],
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Student', studentSchema);