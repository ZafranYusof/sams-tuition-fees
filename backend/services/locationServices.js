/**
 * locationService.js
 *
 * Checks if a student's GPS coordinates are inside the campus boundary.
 *
 * HOW GPS WORKS HERE (simple explanation):
 * - The campus has a center point (lat/lng) and a radius in metres.
 * - The student's phone sends their current lat/lng when they check in.
 * - We use the Haversine formula to calculate the distance (in metres)
 *   between the student's position and the campus center.
 * - If distance <= campus radius → they are on campus → allow check-in.
 * - If distance > campus radius → they are off campus → reject check-in.
 */

const Campus = require('../models/Campus');

/**
 * Pure math: Haversine formula.
 * Returns the distance in METRES between two GPS coordinates.
 */
function haversineDistance(lat1, lng1, lat2, lng2) {
  const earthRadius = 6371000; // Earth radius in metres

  const toRad = (deg) => (deg * Math.PI) / 180;

  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return earthRadius * c; // distance in metres
}

/**
 * Checks if the student's coordinates are within any campus boundary.
 * Returns true if they are inside, false if outside.
 */
async function isWithinCampus(studentLat, studentLng) {
  // Get all campus records (usually just one for UMPSA)
  const campuses = await Campus.find();

  for (const campus of campuses) {
    const distance = haversineDistance(
      campus.centerLatitude,
      campus.centerLongitude,
      studentLat,
      studentLng
    );

    if (distance <= campus.radius) {
      return true; // student is within this campus boundary
    }
  }

  return false; // student is outside all campus boundaries
}

module.exports = { isWithinCampus, haversineDistance };