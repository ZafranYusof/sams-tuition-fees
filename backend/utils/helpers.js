const mongoose = require('mongoose');

// Validate MongoDB ObjectId
exports.isValidObjectId = (id) => {
  return id && mongoose.Types.ObjectId.isValid(id);
};

// Format currency (MYR)
exports.formatCurrency = (amount) => {
  return `RM ${Number(amount).toFixed(2)}`;
};

// Calculate fee status based on amounts
exports.calculateFeeStatus = (totalAmount, paidAmount) => {
  if (paidAmount >= totalAmount) return 'paid';
  if (paidAmount > 0) return 'partial';
  return 'unpaid';
};

// Generate transaction ID
exports.generateTransactionId = (prefix = 'TXN') => {
  const crypto = require('crypto');
  return prefix + crypto.randomBytes(8).toString('hex').toUpperCase();
};

// Paginate query results
exports.paginate = (page = 1, limit = 20) => {
  const skip = (Math.max(1, page) - 1) * limit;
  return { skip, limit: Math.min(limit, 100) };
};

// Sanitize user object (remove password)
exports.sanitizeUser = (user) => {
  if (!user) return null;
  const obj = user.toObject ? user.toObject() : { ...user };
  delete obj.password;
  return obj;
};

// Check if date is overdue
exports.isOverdue = (dueDate) => {
  if (!dueDate) return false;
  return new Date(dueDate) < new Date();
};
