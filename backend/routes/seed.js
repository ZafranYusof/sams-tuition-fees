const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const Student = require('../models/Student');
const Lecturer = require('../models/Lecturer');
const FacultyRegistrar = require('../models/FacultyRegistrar');
const PusatAdab = require('../models/PusatAdab');
const Treasury = require('../models/ManageTuitionFees/Treasury');
const Fee = require('../models/ManageTuitionFees/Fee');
const Course = require('../models/ManageOpenRegistration/Course');
const Activity = require('../models/ManageCurriculumActivity/Activity');

const router = express.Router();

// POST /seed — Seed all user accounts + clean/reseed fees
router.post('/', async (req, res) => {
  try {
    const results = [];
    let feesResult = null;

    // Drop stale transactionId index from old schema
    try {
      const paymentsCol = mongoose.connection.db.collection("payments");
      await paymentsCol.dropIndex("transactionId_1");
      results.push("Dropped stale transactionId_1 index");
    } catch (e) {
      if (e.codeName === "IndexNotFound") {
        results.push("transactionId_1 index already gone");
      } else {
        results.push("Index drop: " + e.message);
      }
    }

    // Drop stale enrollment index (student_1_course_1 without session)
    // Drop ALL stale enrollment indexes and recreate cleanly
    try {
      const enrollmentsCol = mongoose.connection.db.collection("enrollments");
      const indexes = await enrollmentsCol.indexes();
      for (const idx of indexes) {
        if (idx.name !== '_id') {
          try { await enrollmentsCol.dropIndex(idx.name); results.push(`Dropped index: ${idx.name}`); } catch(e) { results.push(`Index ${idx.name}: ${e.message}`); }
        }
      }
      // Re-create the correct unique index
      await enrollmentsCol.createIndex({ student: 1, course: 1, session: 1 }, { unique: true });
      results.push("Re-created student_1_course_1_session_1 unique index");

      // Also drop any duplicate enrollment documents (same student+course+session, keep latest)
      const allEnrollments = await enrollmentsCol.find({}).toArray();
      const seen = {};
      const duplicates = [];
      for (const e of allEnrollments) {
        const key = `${e.student}_${e.course}_${e.session}`;
        if (seen[key]) {
          duplicates.push(e._id);
        } else {
          seen[key] = e._id;
        }
      }
      if (duplicates.length > 0) {
        await enrollmentsCol.deleteMany({ _id: { $in: duplicates } });
        results.push(`Removed ${duplicates.length} duplicate enrollment(s)`);
      }
    } catch(e) {
      results.push("Enrollment cleanup: " + e.message);
    }

    // Drop ALL non-system enrollment records to start clean
    try {
      const Enrollment = require('../models/ManageOpenRegistration/Enrollment');
      const deleteResult = await Enrollment.deleteMany({});
      results.push(`Cleared ${deleteResult.deletedCount} stale enrollment records`);
    } catch (e) {
      results.push("Enrollment cleanup: " + e.message);
    }

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

    // 6. Seed fees for CB23109 (only if none exist — don't delete existing paid fees)
    const student = await Student.findOne({ studentId: 'CB23109' });
    if (student) {
      const existingFees = await Fee.find({ student: student._id });
      if (existingFees.length === 0) {
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
        feesResult = { created: fees.length, fees: fees.map(f => ({ id: f._id, type: f.feeType, amount: f.feeAmount })) };
        results.push(`Created ${fees.length} fee records for CB23109`);
      } else {
        feesResult = { existing: existingFees.length, fees: existingFees.map(f => ({ id: f._id, type: f.feeType, paid: f.paidAmount, status: f.feeStatus })) };
        results.push(`${existingFees.length} fee records already exist for CB23109 — skipped (preserves payment state)`);
      }
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

          // 8. Seed curriculum activities
          const activitiesData = [
            { name: 'Football Tournament 2026', description: 'Inter-faculty football tournament', category: 'sport', organizer: 'Sports Centre', date: new Date('2026-07-15'), venue: 'UMPSA Stadium', capacity: 200, points: 3, status: 'upcoming' },
            { name: 'Coding Workshop: Flutter', description: 'Mobile app development with Flutter', category: 'workshop', organizer: 'Faculty of Computing', date: new Date('2026-07-20'), venue: 'Lab A101', capacity: 50, points: 2, status: 'upcoming' },
            { name: 'Community Service - Kampung Bersih', description: 'Gotong-royong at nearby village', category: 'community', organizer: 'Student Affairs', date: new Date('2026-06-10'), venue: 'Kg. Permatang Badak', capacity: 100, points: 4, status: 'completed' },
            { name: 'Leadership Camp', description: '3-day leadership development camp', category: 'event', organizer: 'Student Council', date: new Date('2026-08-05'), venue: 'Tanjung Lumpur Campsite', capacity: 80, points: 5, status: 'upcoming' },
            { name: 'Photography Club Exhibition', description: 'Annual photography exhibition', category: 'club', organizer: 'Photography Club', date: new Date('2026-07-01'), venue: 'Main Lobby', capacity: 300, points: 2, status: 'ongoing' },
          ];
          const existingActivities = await Activity.countDocuments();
          if (existingActivities === 0) {
            const activities = await Activity.insertMany(activitiesData);
            results.push(`Seeded ${activities.length} curriculum activities`);
          } else {
            results.push(`${existingActivities} activities already exist`);
          }

          res.json({ message: 'Seed completed', results, fees: feesResult });
  } catch (err) {
    console.error('Seed error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
