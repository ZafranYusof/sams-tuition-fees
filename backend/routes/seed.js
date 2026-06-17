const express = require('express');
const bcrypt = require('bcryptjs');
const Student = require('../models/Student');
const Lecturer = require('../models/Lecturer');
const FacultyRegistrar = require('../models/FacultyRegistrar');
const PusatAdab = require('../models/PusatAdab');
const Treasury = require('../models/ManageTuitionFees/Treasury');
const Fee = require('../models/ManageTuitionFees/Fee');
const Course = require('../models/ManageOpenRegistration/Course');

const router = express.Router();

// POST /seed — Seed all user accounts + clean/reseed fees
router.post('/', async (req, res) => {
  try {
    const results = [];
    let feesResult = null;

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

    // 6. Clean old fees and create fresh ones for CB23109
    const student = await Student.findOne({ studentId: 'CB23109' });
    if (student) {
      // Delete ALL existing fee records (old data from users collection migration)
      const deleted = await Fee.deleteMany({});
      
      // Create fresh fee records for CB23109
      const fees = await Fee.insertMany([
        {
          student: student._id,
          feeType: 'Tuition Fee',
          feeDescription: 'Yuran Pengajian Semester 2 2025/2026',
          feeAmount: 860,
          feeStatus: 'unpaid',
          feeSemester: 2,
          academicYear: '2025/2026',
          paidAmount: 0
        },
        {
          student: student._id,
          feeType: 'Asrama Fee',
          feeDescription: 'Yuran Asrama Semester 2 2025/2026',
          feeAmount: 650,
          feeStatus: 'unpaid',
          feeSemester: 2,
          academicYear: '2025/2026',
          paidAmount: 0
        }
      ]);
      
      feesResult = {
        deleted: deleted.deletedCount,
        created: fees.length,
        fees: fees.map(f => ({ id: f._id, type: f.feeType, amount: f.feeAmount }))
      };
      results.push(`Cleaned ${deleted.deletedCount} old fee records, created ${fees.length} new ones`);
    }

    // 7. Seed courses for Open Registration
    const coursesData = [
      { courseId: 'BCS1013', courseName: 'Programming Fundamentals', creditHours: 3 },
      { courseId: 'BCS2013', courseName: 'Data Structures & Algorithms', creditHours: 3 },
      { courseId: 'BCS2023', courseName: 'Object Oriented Programming', creditHours: 3 },
      { courseId: 'BCS3013', courseName: 'Database Systems', creditHours: 3 },
      { courseId: 'BMS1013', courseName: 'Calculus I', creditHours: 3 },
      { courseId: 'BMS2013', courseName: 'Linear Algebra', creditHours: 3 },
      { courseId: 'BEE1013', courseName: 'Basic Electrical Engineering', creditHours: 3 },
      { courseId: 'BME1013', courseName: 'Engineering Mechanics', creditHours: 3 },
    ];
    
    const existingCourses = await Course.countDocuments();
    if (existingCourses === 0) {
      const courses = await Course.insertMany(coursesData);
      results.push(`Seeded ${courses.length} courses`);
    } else {
      results.push(`${existingCourses} courses already exist`);
    }

    res.json({ message: 'Seed completed', results, fees: feesResult });
  } catch (err) {
    console.error('Seed error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
