// timetableChecker.js — Utility for detecting timetable clashes

class TimetableChecker {
  // Check if two time slots clash
  static hasClash(slot1, slot2) {
    if (slot1.day !== slot2.day) return false;
    
    const start1 = this.parseTime(slot1.startTime);
    const end1 = this.parseTime(slot1.endTime);
    const start2 = this.parseTime(slot2.startTime);
    const end2 = this.parseTime(slot2.endTime);

    return (start1 < end2 && start2 < end1);
  }

  // Parse time string (HH:MM) to minutes
  static parseTime(timeStr) {
    const [hours, minutes] = timeStr.split(':').map(Number);
    return hours * 60 + minutes;
  }

  // Check if student has clash with new course
  static async checkStudentClash(studentEnrollments, newCourseSlots) {
    // Placeholder - requires timetable data in courses
    // Returns { hasClash: false, conflicts: [] }
    return { hasClash: false, conflicts: [] };
  }
}

module.exports = TimetableChecker;
