const mongoose = require('mongoose');

const pusatAdabSchema = new mongoose.Schema({
  staffId: { type: String, unique: true, required: true },
  name: { type: String, required: true },
  email: { type: String, unique: true, required: true },
  phoneNum: { type: String },
  password: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('PusatAdab', pusatAdabSchema);