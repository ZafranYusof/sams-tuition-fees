const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const feesRoutes = require('./routes/fees');
const paymentsRoutes = require('./routes/payments');
const notificationsRoutes = require('./routes/notifications');
const paymentGatewayRoutes = require('./routes/payment-gateway');

const Payment = require('./models/Payment');

const app = express();

// Expire pending payments older than 10 minutes (runs every 2 min)
setInterval(async () => {
  try {
    const result = await Payment.updateMany(
      { status: 'pending', expiresAt: { $lte: new Date() } },
      { $set: { status: 'failed' } }
    );
    if (result.modifiedCount > 0) {
      console.log(`[Payment] Expired ${result.modifiedCount} pending payment(s)`);
    }
  } catch (err) {
    console.error('[Payment] Expiry check error:', err.message);
  }
}, 2 * 60 * 1000);

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/fees', feesRoutes);
app.use('/api/payments', paymentsRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/payment', paymentGatewayRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 404 handler for unknown routes
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err.message);
  res.status(500).json({ error: 'Internal server error' });
});

// Connect to MongoDB and start server
const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sams';

mongoose.connect(MONGODB_URI)
  .then(() => {
    console.log('Connected to MongoDB');
    app.listen(PORT, () => {
      console.log(`SAMs API running on port ${PORT}`);
    });
  })
  .catch(err => {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  });

module.exports = app;
