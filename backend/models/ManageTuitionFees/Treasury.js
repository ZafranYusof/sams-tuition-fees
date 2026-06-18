const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const treasurySchema = new mongoose.Schema({
  trsName: { type: String, required: true },        // TrsName
  trsEmail: { type: String, required: true, unique: true },  // TrsEmail
  trsPassword: { type: String, required: true },    // TrsPassword
  createdAt: { type: Date, default: Date.now }
});

treasurySchema.pre('save', async function(next) {
  if (!this.isModified('trsPassword')) return next();
  this.trsPassword = await bcrypt.hash(this.trsPassword, 12);
  next();
});

treasurySchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.trsPassword);
};

module.exports = mongoose.model('Treasury', treasurySchema);
