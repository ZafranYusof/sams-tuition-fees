const mongoose = require('mongoose');

const lecturerSchema = new mongoose.Schema({
  lectId: { type: String, unique: true, required: true },
  name: { type: String, required: true },
  email: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  phoneNum: { type: String },
  experience: { type: String },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Lecturer', lecturerSchema);