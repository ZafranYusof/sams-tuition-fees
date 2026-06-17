const mongoose = require('mongoose');

const campusSchema = new mongoose.Schema({
  campusName: {
    type: String,
    required: true,
  },
  centerLatitude: {
    type: Number,
    required: true,
  },
  centerLongitude: {
    type: Number,
    required: true,
  },
  radius: {
    type: Number,
    required: true, // in metres, e.g. 1000 = 1 km
  },
});

module.exports = mongoose.model('Campus', campusSchema);