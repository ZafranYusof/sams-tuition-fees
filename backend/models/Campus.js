const mongoose = require('mongoose');

const campusSchema = new mongoose.Schema({
  campusId: { type: String, unique: true, required: true },
  campusName: { type: String, required: true },
  centerLatitude: { type: Number, required: true },
  centerLongitude: { type: Number, required: true },
  radius: { type: Number, required: true, default: 100 }, // meters
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Campus', campusSchema);