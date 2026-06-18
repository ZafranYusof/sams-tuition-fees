const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const lecturerSchema = new mongoose.Schema({
  lectId: { type: String, unique: true, required: true },       // LectID PK
  lectName: { type: String, required: true },                   // LectName
  lectEmail: { type: String, unique: true, required: true },    // LectEmail
  lectPassword: { type: String, required: true },               // LectPassword
  lectPhoneNum: { type: String },                               // LectPhoneNum
  lectExperience: { type: String },                             // LectExperience
  createdAt: { type: Date, default: Date.now }
});

lecturerSchema.pre('save', async function(next) {
  if (!this.isModified('lectPassword')) return next();
  this.lectPassword = await bcrypt.hash(this.lectPassword, 12);
  next();
});

lecturerSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.lectPassword);
};

module.exports = mongoose.model('Lecturer', lecturerSchema);
