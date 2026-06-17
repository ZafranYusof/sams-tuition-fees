const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const studentSchema = new mongoose.Schema({
  studentId: { type: String, unique: true, required: true },   // StudentID PK
  enrollId: { type: mongoose.Schema.Types.ObjectId, ref: 'Enrollment' },  // EnrollID FK
  studName: { type: String, required: true },                   // StudName
  studEmail: { type: String, unique: true, required: true },    // StudEmail
  studPassword: { type: String, required: true },               // StudPassword
  major: { type: String },                                      // Major
  fcmTokens: { type: [String], default: [] },                   // FCM push notification tokens
  createdAt: { type: Date, default: Date.now }
});

studentSchema.pre('save', async function(next) {
  if (!this.isModified('studPassword')) return next();
  this.studPassword = await bcrypt.hash(this.studPassword, 12);
  next();
});

studentSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.studPassword);
};

module.exports = mongoose.model('Student', studentSchema);
