const mongoose = require('mongoose');

const treasurySchema = new mongoose.Schema({
  trsName: { type: String, required: true },
  trsEmail: { type: String, required: true, unique: true },
  trsPassword: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Treasury', treasurySchema);
