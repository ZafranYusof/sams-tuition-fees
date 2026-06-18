// ManageOpenRegistration Models
// Maps to SDD: Subject, RegistrationSession, StudentSubject

const Course = require('./Course');
const Session = require('./Session');
const Enrollment = require('./Enrollment');
const Registration = require('./Registration');
const Section = require('./Section');

module.exports = {
  // SDD mapping
  Subject: Course,              // Subject.js -> Course.js
  RegistrationSession: Session, // RegistrationSession.js -> Session.js
  StudentSubject: Enrollment,   // StudentSubject.js -> Enrollment.js
  
  // Original names
  Course,
  Session,
  Enrollment,
  Registration,
  Section
};
