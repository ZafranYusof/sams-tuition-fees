const jwt = require('jsonwebtoken');
const { jwtSecret, jwtExpire } = require('../config');

// Generate JWT token
exports.generateToken = (userId, role) => {
  return jwt.sign({ id: userId, role }, jwtSecret, { expiresIn: jwtExpire });
};

// Verify JWT token
exports.verifyToken = (token) => {
  try {
    return jwt.verify(token, jwtSecret);
  } catch (err) {
    return null;
  }
};
