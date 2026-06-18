const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const facultyRegistrarSchema = new mongoose.Schema({
  facultyId: { type: String, unique: true, required: true },        // FacultyID PK
  facultyEmail: { type: String, unique: true, required: true },     // FacultyEmail
  facultyPassword: { type: String, required: true },                // FacultyPassword
  facultyPhoneNumber: { type: String },                             // FacultyPhoneNumber
  createdAt: { type: Date, default: Date.now }
});

facultyRegistrarSchema.pre('save', async function(next) {
  if (!this.isModified('facultyPassword')) return next();
  this.facultyPassword = await bcrypt.hash(this.facultyPassword, 12);
  next();
});

facultyRegistrarSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.facultyPassword);
};

module.exports = mongoose.model('FacultyRegistrar', facultyRegistrarSchema);
