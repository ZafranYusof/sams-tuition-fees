const express = require('express');
const bcrypt = require('bcryptjs');
const Student = require('../models/Student');
const Lecturer = require('../models/Lecturer');
const FacultyRegistrar = require('../models/FacultyRegistrar');
const PusatAdab = require('../models/PusatAdab');
const Treasury = require('../models/ManageTuitionFees/Treasury');

const router = express.Router();

// POST /seed — Seed all user accounts (one-time use)
router.post('/', async (req, res) => {
  try {
    const results = [];

    // 1. Student
    const studentExists = await Student.findOne({ studentId: 'CB23109' });
    if (!studentExists) {
      const student = new Student({
        studentId: 'CB23109',
        studName: 'Ahmad Faiz',
        studEmail: 'CB23109@student.umpsa.edu.my',
        studPassword: 'student123',
        major: 'Computer Science'
      });
      await student.save();
      results.push('Student CB23109 seeded');
    } else {
      results.push('Student CB23109 already exists');
    }

    // 2. Lecturer
    const lectExists = await Lecturer.findOne({ lectEmail: 'lecturer@umpsa.edu.my' });
    if (!lectExists) {
      const lecturer = new Lecturer({
        lectId: 'LEC001',
        lectName: 'Dr. Siti Aminah',
        lectEmail: 'lecturer@umpsa.edu.my',
        lectPassword: 'lecturer123',
        lectPhoneNum: '0123456789',
        lectExperience: '10 years'
      });
      await lecturer.save();
      results.push('Lecturer seeded');
    } else {
      results.push('Lecturer already exists');
    }

    // 3. FacultyRegistrar
    const facExists = await FacultyRegistrar.findOne({ facultyEmail: 'faculty@umpsa.edu.my' });
    if (!facExists) {
      const faculty = new FacultyRegistrar({
        facultyId: 'FAC001',
        facultyEmail: 'faculty@umpsa.edu.my',
        facultyPassword: 'faculty123',
        facultyPhoneNumber: '0198765432'
      });
      await faculty.save();
      results.push('FacultyRegistrar seeded');
    } else {
      results.push('FacultyRegistrar already exists');
    }

    // 4. PusatAdab
    const paExists = await PusatAdab.findOne({ staffEmail: 'staff@umpsa.edu.my' });
    if (!paExists) {
      const pusatAdab = new PusatAdab({
        paStaffId: 'PA001',
        staffName: 'Nurul Huda',
        staffEmail: 'staff@umpsa.edu.my',
        staffPhoneNumber: '0112233445',
        staffPassword: 'staff123'
      });
      await pusatAdab.save();
      results.push('PusatAdab seeded');
    } else {
      results.push('PusatAdab already exists');
    }

    // 5. Treasury
    const trsExists = await Treasury.findOne({ trsEmail: 'treasury@umpsa.edu.my' });
    if (!trsExists) {
      const treasury = new Treasury({
        trsName: 'Treasury Admin',
        trsEmail: 'treasury@umpsa.edu.my',
        trsPassword: 'admin123'
      });
      await treasury.save();
      results.push('Treasury seeded');
    } else {
      results.push('Treasury already exists');
    }

    res.json({ message: 'Seed completed', results });
  } catch (err) {
    console.error('Seed error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
