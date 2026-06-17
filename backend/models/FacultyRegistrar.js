const mongoose = require('mongoose');

const facultyRegistrarSchema = new mongoose.Schema({
  facultyId: { type: String, unique: true, required: true },
  email: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  phoneNum: { type: String },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('FacultyRegistrar', facultyRegistrarSchema);