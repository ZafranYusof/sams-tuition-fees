# Attendance Module

Backend API untuk module attendance dalam SAMs (Student Academic Management System).

## Setup

### 1. Install dependencies
```bash
npm install mongoose express jsonwebtoken
```

### 2. Copy files
- `attendance.js` → `routes/attendance.js`
- `Attendance.js` → `models/Attendance.js`
- `AttendanceCode.js` → `models/AttendanceCode.js`
- `Session.js` → `models/Session.js`
- `Campus.js` → `models/Campus.js`
- `Enrollment.js` → `models/Enrollment.js`

### 3. Mount route kat server.js
```javascript
const attendanceRoutes = require('./routes/attendance');
app.use('/api', attendanceRoutes);
```

### 4. Middleware auth
Route ni guna `auth` middleware. Pastikan ada `middleware/auth.js` yang verify JWT dan letak `req.user`:
```javascript
req.user = { id: '...', role: 'student' | 'lecturer' | 'admin' }
```

---

## Endpoints

### POST /api/attendance/generate-code
**Lecturer/Admin sahaja**

Generate attendance code untuk satu session.

**Body:**
```json
{
  "sessionId": "64a1b2c3d4e5f67890123456",
  "expiresIn": 300
}
```
- `sessionId` (required) - ID session
- `expiresIn` (optional) - Saat sebelum code expired, default 300 (5 minit)

**Response:**
```json
{
  "code": "A1B2C3",
  "expiresAt": "2026-06-17T10:05:00.000Z",
  "sessionId": "64a1b2c3d4e5f67890123456"
}
```

---

### POST /api/attendance/check-in
**Student sahaja**

Student check-in guna code.

**Body:**
```json
{
  "code": "A1B2C3",
  "latitude": 3.5453,
  "longitude": 103.4266
}
```
- `code` (required) - 6-digit attendance code
- `latitude` (optional) - Untuk geofence check
- `longitude` (optional) - Untuk geofence check

**Response:**
```json
{
  "message": "Check-in successful",
  "status": "present",
  "checkInTime": "2026-06-17T10:01:23.000Z"
}
```

**Status logic:**
- `present` - Check-in dalam 15 minit dari start time
- `late` - Check-in lepas 15 minit

---

### GET /api/attendance/session/:sessionId
**Lecturer/Admin view attendance list**

**Response:**
```json
{
  "session": { ... },
  "totalCheckedIn": 25,
  "records": [
    {
      "student": { "name": "Ahmad", "studentId": "CB23109" },
      "status": "present",
      "checkInTime": "2026-06-17T10:01:23.000Z"
    }
  ],
  "absent": [
    { "name": "Ali", "studentId": "CB23110" }
  ]
}
```

---

### GET /api/attendance/student/:studentId
**Student view attendance history**

**Response:**
```json
{
  "records": [
    {
      "status": "present",
      "checkInTime": "2026-06-17T10:01:23.000Z",
      "code": {
        "session": {
          "section": {
            "course": { "name": "Software Engineering" }
          }
        }
      }
    }
  ]
}
```

---

### POST /api/attendance/terminate-code
**Lecturer/Admin terminate code awal**

**Body:**
```json
{
  "codeId": "64a1b2c3d4e5f67890123456"
}
```

---

## MongoDB Collections

### attendancecodes
```javascript
{
  code: "A1B2C3",           // 6-char uppercase hex
  session: ObjectId,         // Reference ke sessions
  expiresIn: 300,            // Saat
  isActive: true,
  createdBy: ObjectId,       // Lecturer ID
  createdAt: Date,
  timeTerminated: Date       // Kalau terminate awal
}
```

### attendances
```javascript
{
  student: ObjectId,         // Reference ke users
  code: ObjectId,            // Reference ke attendancecodes
  status: "present" | "late" | "absent",
  latitude: Number,
  longitude: Number,
  checkInTime: Date,
  createdAt: Date
}
```

---

## Flow Test

1. **Lecturer buat session** - POST /api/sessions
2. **Lecturer generate code** - POST /api/attendance/generate-code { sessionId }
3. **Student check-in** - POST /api/attendance/check-in { code }
4. **Lecturer view list** - GET /api/attendance/session/:sessionId

---

## Dummy Data (untuk test cepat)

```javascript
// Kat MongoDB shell atau Compass

// 1. Buat session
db.sessions.insertOne({
  section: ObjectId("..."),  // Kena ada section dulu
  date: new Date(),
  startTime: "10:00",
  endTime: "12:00",
  status: "active",
  campus: ObjectId("...")    // Kena ada campus dulu
})

// 2. Buat attendance code manually
db.attendancecodes.insertOne({
  code: "TEST01",
  session: ObjectId("..."),  // ID session dari atas
  expiresIn: 3600,
  isActive: true,
  createdBy: ObjectId("..."), // Lecturer ID
  createdAt: new Date()
})

// 3. Buat attendance record manually
db.attendances.insertOne({
  student: ObjectId("..."),  // Student ID
  code: ObjectId("..."),     // Code ID dari atas
  status: "present",
  checkInTime: new Date(),
  createdAt: new Date()
})
```

---

## Dependencies

- `mongoose` - MongoDB ODM
- `crypto` - Generate random code (built-in Node.js)
- `jsonwebtoken` - JWT auth (dari middleware)

## Notes

- Code auto-expire selepas `expiresIn` saat
- Duplicate check-in akan return error "Already checked in"
- Geofence check guna Haversine formula (kalau ada lat/lng)
- Lecturer boleh terminate code awal guna POST /terminate-code
