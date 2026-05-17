# SAMs - Tuition Fees Module

**Module 4: Manage Student Tuition Fees**  
By Zafran (CB23109)

A standalone tuition fees management module extracted from the SAMs (Student Academic Management System) project.

## Features

- **Student Portal**: View fee breakdown, outstanding balance, payment history, alerts
- **Treasury Portal**: Manage student fees, view dashboard analytics, student records
- **Payment Gateway**: Online payment processing with receipt generation
- **Authentication**: Login/register with role-based access (Student/Admin/Treasury)

## Tech Stack

- **Backend**: Node.js + Express + MongoDB
- **Frontend**: Flutter (Dart) with Riverpod state management
- **Design Theme**: Dark blue (#0A1929), Primary (#2196F3), Gold accent (#FFB74D)

## Setup

### Backend

```bash
cd backend
npm install
# Create .env file with:
# PORT=5000
# MONGODB_URI=mongodb://localhost:27017/sams
# JWT_SECRET=your_secret_key
npm start
```

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

### API Base URL

- Local: `http://localhost:5000`
- Production: `https://sams-app-vasb.onrender.com`

## Dummy Accounts

| Role    | Email                        | Password    |
|---------|------------------------------|-------------|
| Student | zafran@student.umpsa.edu.my  | password123 |
| Admin   | admin@sams.edu.my            | admin123    |

## Project Structure

```
├── backend/
│   ├── config/          # DB & app configuration
│   ├── controllers/     # Auth, Fee, Payment controllers
│   ├── middleware/      # Auth middleware (JWT)
│   ├── models/          # User, Fee, Payment models
│   ├── routes/          # API routes
│   ├── services/        # Auth & email services
│   ├── utils/           # Helpers & logger
│   └── server.js        # Express app entry
├── frontend/
│   └── lib/
│       ├── config/      # Theme & API config
│       ├── models/      # Data models
│       ├── providers/   # Riverpod providers
│       ├── routes/      # App routing
│       ├── screens/     # UI screens (auth, fees, home)
│       ├── services/    # API & cache services
│       └── widgets/     # Shared UI components
└── README.md
```

## License

University project - UMPSA © 2025
