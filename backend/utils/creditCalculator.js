// creditCalculator.js — Utility for calculating student credit hours

class CreditCalculator {
  // Calculate total credits from enrollments
  static calculateTotal(enrollments) {
    return enrollments.reduce((sum, e) => {
      return sum + (e.course?.creditHours || e.creditHours || 0);
    }, 0);
  }

  // Check if adding new credits exceeds limit
  static canAddCredits(currentCredits, newCredits, maxCredits = 20) {
    return (currentCredits + newCredits) <= maxCredits;
  }

  // Get remaining credits
  static getRemaining(currentCredits, maxCredits = 20) {
    return Math.max(0, maxCredits - currentCredits);
  }
}

module.exports = CreditCalculator;
