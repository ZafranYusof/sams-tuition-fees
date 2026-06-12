const mongoose = require('mongoose');
const User = require('./models/User');

async function seed() {
  await mongoose.connect('mongodb://localhost:27017/sams');
  
  const exists = await User.findOne({ email: 'treasury@umpsa.edu.my' });
  if (exists) {
    console.log('Treasury account already exists:', exists.email, 'role:', exists.role);
    await mongoose.disconnect();
    return;
  }

  const user = new User({
    studentId: 'TREASURY001',
    name: 'Treasury Admin',
    email: 'treasury@umpsa.edu.my',
    password: 'Treasury@123',
    role: 'admin',
    faculty: 'Administration',
    program: 'Treasury Department'
  });

  await user.save();
  console.log('Treasury account created!');
  console.log('Email: treasury@umpsa.edu.my');
  console.log('Password: Treasury@123');
  console.log('Role: admin');
  
  await mongoose.disconnect();
}

seed().catch(e => { console.error(e.message); process.exit(1); });
