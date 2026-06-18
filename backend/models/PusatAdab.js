const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const pusatAdabSchema = new mongoose.Schema({
  paStaffId: { type: String, unique: true, required: true },        // PAStaffID PK
  staffName: { type: String, required: true },                      // StaffName
  staffEmail: { type: String, unique: true, required: true },       // StaffEmail
  staffPhoneNumber: { type: String },                               // StaffPhoneNumber
  staffPassword: { type: String, required: true },                  // StaffPassword
  createdAt: { type: Date, default: Date.now }
});

pusatAdabSchema.pre('save', async function(next) {
  if (!this.isModified('staffPassword')) return next();
  this.staffPassword = await bcrypt.hash(this.staffPassword, 12);
  next();
});

pusatAdabSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.staffPassword);
};

module.exports = mongoose.model('PusatAdab', pusatAdabSchema);
