# Deccan-Aid: AI-Powered Emergency Ambulance Response System
**Version Flutter FastAPI MongoDB License**

Revolutionizing Emergency Medical Services with AI-Powered Dispatch, Real-Time Tracking, and Intelligent Resource Management

[Features](#-key-features) • [Architecture](#-system-architecture) • [Installation](#-installation) • [Demo](#-demo) • [Documentation](#-documentation)

## 📋 Table of Contents
- [Overview](#-overview)
- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [Technology Stack](#-technology-stack)
- [System Flow](#-system-flow)
- [Installation](#-installation)
- [User Roles](#-user-roles)
- [Screenshots](#-screenshots)
- [API Documentation](#-api-documentation)
- [Real-Time Communication](#-real-time-communication)
- [Security](#-security)
- [Contributing](#-contributing)
- [License](#-license)

## 🌟 Overview
**Deccan-Aid** is a cutting-edge emergency ambulance response system that leverages artificial intelligence, real-time geospatial tracking, and intelligent sensor-based accident detection to drastically reduce emergency response times and save lives.

### The Problem We Solve
- **⏱️ Delayed Response:** Traditional emergency systems have average response times of 15-20 minutes
- **📍 Inefficient Dispatch:** Manual ambulance allocation leads to suboptimal routing
- **🏥 Hospital Capacity:** No real-time visibility into hospital availability
- **🚗 Accident Detection:** Victims unable to call for help in severe accidents

### Our Solution
Deccan-Aid provides:
- **Instant SOS Triggering** with one-tap emergency activation
- **AI-Powered Accident Detection** using accelerometer and gyroscope sensors
- **Geospatial Intelligent Dispatch** finding the nearest available ambulance within seconds
- **Real-Time Tracking** with live location updates for patients and drivers
- **Hospital Integration** showing real-time bed availability and capacity
- **Multi-Role Dashboard** for citizens, drivers, and hospital administrators

## ✨ Key Features

### 🚨 For Citizens (Patients)
| Feature | Description |
| :--- | :--- |
| **One-Tap SOS** | Emergency button triggers instant ambulance dispatch with GPS location |
| **Auto-SOS (AI)** | Automatic accident detection using phone sensors (accelerometer/gyroscope) |
| **Live Tracking** | Real-time map showing ambulance location and ETA |
| **Request History** | View all past emergency requests and their status |
| **Hospital Info** | See assigned hospital details, ICU availability, and contact info |
| **Blood Group Profile** | Store medical information for faster emergency response |

### 🚑 For Ambulance Drivers
| Feature | Description |
| :--- | :--- |
| **Nearby Patients** | Automatically receive SOS alerts from patients within 20km radius |
| **One-Tap Accept** | Accept emergency requests with single button press |
| **Navigation Integration** | Built-in maps with route optimization |
| **Injury Assessment** | Submit preliminary injury reports to hospitals |
| **Status Toggle** | Mark availability (Available/Busy/Offline) |
| **Live Location Broadcast** | GPS location continuously shared with patients and hospitals |
| **Request Queue** | View all pending emergency requests in the area |

### 🏥 For Hospital Administrators
| Feature | Description |
| :--- | :--- |
| **Incoming Patient Dashboard** | Real-time notifications of ambulances en route |
| **Capacity Management** | Update ICU beds, general beds, and doctor availability |
| **Patient Assessment Review** | View driver's preliminary injury assessment before arrival |
| **Admission Control** | Accept or reject incoming patients based on capacity |
| **Geospatial Hospital Network** | View nearby hospitals and their capacity |
| **Analytics Dashboard** | Statistics on admissions, response times, and resource utilization |

### 🤖 AI & Intelligent Features
- **Accident Detection Algorithm:** Multi-sensor fusion detecting impacts >25 m/s² and rotations >5 rad/s
- **Severity Classification:** Automatic categorization (High/Medium/Low) based on sensor data
- **Smart Dispatch:** Geospatial queries finding nearest ambulances with <100ms latency
- **Predictive ETA:** Real-time arrival time calculation based on distance and traffic patterns
- **Auto-Cooldown:** Prevents duplicate SOS triggers with intelligent 5-second cooldown

## 🏗️ System Architecture

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────────────────┐
│                         DECCAN-AID SYSTEM                            │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│                  │         │                  │         │                  │
│  Flutter Client  │◄────────►  FastAPI Backend │◄────────►  MongoDB Atlas   │
│  (Mobile/Web)    │   HTTP  │  + Socket.IO     │  CRUD   │  (Database)      │
│                  │  WebSocket                 │         │                  │
└──────────────────┘         └──────────────────┘         └──────────────────┘
        │                            │                            │
        │                            │                            │
        ▼                            ▼                            ▼
┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│ GPS/Sensors      │         │ Real-Time Events │         │ Geospatial Index │
│ - Location       │         │ - SOS Alerts     │         │ - $near queries  │
│ - Accelerometer  │         │ - Live Tracking  │         │ - GEOSPHERE      │
│ - Gyroscope      │         │ - Notifications  │         │ - 2dsphere index │
└──────────────────┘         └──────────────────┘         └──────────────────┘
```

### Backend Architecture (FastAPI)
```
┌───────────────────────────────────────────────────────────────────────┐
│                        FastAPI Application                            │
├───────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────┐  ┌──────────────────┐  ┌─────────────────┐   │
│  │  Authentication │  │  CORS Middleware │  │  Request Logging│   │
│  │  JWT + bcrypt   │  │  All Origins     │  │  Duration Track │   │
│  └─────────────────┘  └──────────────────┘  └─────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                     API Endpoints                             │  │
│  ├──────────────────────────────────────────────────────────────┤  │
│  │  /api/register/*     - User registration (citizen/driver/admin)│ │
│  │  /api/login/*        - JWT token authentication              │  │
│  │  /api/client/*       - SOS trigger, request history          │  │
│  │  /api/driver/*       - Accept requests, location updates     │  │
│  │  /api/hospital/*     - Capacity management, admissions       │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                   Socket.IO Server                            │  │
│  ├──────────────────────────────────────────────────────────────┤  │
│  │  Rooms: 'drivers', 'clients', 'admin'                        │  │
│  │  Events: sos_alert, driver_accepted, location_update         │  │
│  │  Real-time bi-directional communication                      │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────────┐
│                         MongoDB Atlas                                 │
├───────────────────────────────────────────────────────────────────────┤
│  Collections:                                                         │
│  ├─ users              (role, email, password, location)             │
│  ├─ patient_requests   (status, location, severity, timestamps)      │
│  ├─ ambulance_drivers  (status, location, vehicle_info)              │
│  └─ hospitals          (capacity, location, contact_info)            │
│                                                                       │
│  Indexes:                                                             │
│  ├─ Compound: (email, role), (phone, role)                          │
│  └─ Geospatial: location (2dsphere) for $near queries               │
└───────────────────────────────────────────────────────────────────────┘
```

### Frontend Architecture (Flutter)
```
lib/
├── config/
│   ├── api_config.dart        (Backend URL, endpoints)
│   └── app_theme.dart         (Material Design theme)
│
├── services/                  (Business Logic Layer)
│   ├── base_api_service.dart  (HTTP client + auto-discovery)
│   ├── auth_service.dart      (JWT token management)
│   ├── sos_service.dart       (Emergency API calls)
│   ├── socket_service.dart    (WebSocket real-time)
│   ├── location_service.dart  (GPS tracking)
│   ├── hospital_service.dart  (Hospital operations)
│   └── accident_detector_service.dart (AI sensor monitoring)
│
├── pages/                     (UI Layer)
│   ├── login_page.dart        (Multi-role authentication)
│   ├── client_dashboard_enhanced.dart    (Patient interface)
│   ├── driver_dashboard_enhanced.dart    (Ambulance interface)
│   └── admin_dashboard_enhanced.dart     (Hospital interface)
│
├── models/                    (Data Models)
│   └── injury_types.dart      (Severity classifications)
│
└── utils/
    └── logger.dart            (Debug logging)
```

## 🔄 System Flow

### 1. Emergency SOS Flow (Manual)

### 2. Auto-SOS Flow (AI Detection)
1. **SENSOR MONITORING (Continuous)**
   - [Accelerometer] → Reads acceleration in X, Y, Z axes
   - [Gyroscope] → Reads rotation in X, Y, Z axes
2. **DATA BUFFERING**
   - Store last 20 readings (rolling buffer)
   - Update every 100ms
3. **THRESHOLD DETECTION**
   - IF (acceleration > 25 m/s²) OR (rotation > 5 rad/s)
4. **SEVERITY CLASSIFICATION**
   - HIGH: acceleration > 40 OR rotation > 8
   - MEDIUM: acceleration > 30 OR rotation > 6
   - LOW: Detectable but below medium threshold
5. **AUTO-SOS TRIGGER**
   - `POST /api/client/sos { auto_triggered: true, preliminary_severity: "high", sensor_data: {...} }`
6. **COOLDOWN PERIOD (5 seconds)**
   - Prevent duplicate triggers
7. **[Resume monitoring after cooldown]**

### 3. Real-Time Location Tracking Flow
```
┌────────────┐                  ┌────────────┐                  ┌────────────┐
│   Driver   │                  │  Backend   │                  │   Client   │
│  (Moving)  │                  │ (Socket.IO)│                  │ (Watching) │
└────────────┘                  └────────────┘                  └────────────┘
      │                                │                                │
      │  GPS Update (every 5 sec)      │                                │
      ├───────────────────────────────>│                                │
      │  POST /api/driver/update_location                              │
      │  {lat: 12.97, lng: 77.59}      │                                │
      │                                │                                │
      │                                │  WebSocket Emit                │
      │                                ├───────────────────────────────>│
      │                                │  'driver_location_update'      │
      │                                │  {lat, lng, timestamp}         │
      │                                │                                │
      │                                │  ┌───────────────────────┐    │
      │                                │  │  Flutter Map Updates  │    │
      │                                │  │  - Move marker        │    │
      │                                │  │  - Calculate ETA      │    │
      │                                │  │  - Update distance    │    │
      │                                │  └───────────────────────┘    │
      │                                │                                │
      │  [Repeat every 5 seconds] ───>│                                │
```

### 4. Hospital Capacity Management Flow
- **Hospital Admin Dashboard**
  - Update Capacity: `POST /api/hospital/update_capacity`
  - View Incoming Patients: `GET /api/hospital/patient_requests`
  - Confirm/Reject Admission: `POST /api/hospital/confirm_admission`
    - Notify Driver & Patient via Socket.IO

## 💻 Technology Stack

### Backend
| Technology | Purpose | Version |
| :--- | :--- | :--- |
| **FastAPI** | High-performance async web framework | 0.104.1 |
| **Uvicorn** | ASGI server | 0.24.0 |
| **MongoDB Atlas** | NoSQL database with geospatial support | Latest |
| **PyMongo** | Python MongoDB driver | 4.6.0 |
| **Socket.IO** | Real-time bidirectional communication | 5.10.0 |
| **PyJWT** | JSON Web Token authentication | 3.3.0 |
| **Bcrypt** | Password hashing | 4.1.1 |
| **Pydantic** | Data validation and settings management | 2.5.0 |

### Frontend
| Technology | Purpose | Version |
| :--- | :--- | :--- |
| **Flutter** | Cross-platform UI framework | 3.9.2 |
| **Dart** | Programming language | 3.9.2 |
| **http** | HTTP client | 1.2.0 |
| **socket_io_client** | WebSocket client | 2.0.3 |
| **geolocator** | GPS location tracking | 10.1.0 |
| **google_maps_flutter** | Interactive maps | 2.5.0 |
| **sensors_plus** | Accelerometer/Gyroscope access | 4.0.0 |
| **flutter_secure_storage** | Secure credential storage | 9.0.0 |
| **fl_chart** | Analytics charts | 0.66.0 |
| **provider** | State management | 6.1.1 |

## 🚀 Installation

### Prerequisites
- Flutter SDK: 3.9.2 or higher
- Python: 3.8 or higher
- MongoDB Atlas Account
- Android Studio / Xcode
- Git

### Backend Setup
1. **Clone the Repository**
   ```bash
   git clone https://github.com/Dharun2712/deccanAid.git
   cd Deccan-Aid/backend
   ```
2. **Create Virtual Environment**
   ```bash
   python -m venv venv
   # Windows
   venv\Scripts\activate
   # Linux/Mac
   source venv/bin/activate
   ```
3. **Install Dependencies**
   ```bash
   pip install -r requirements_fastapi.txt
   ```
4. **Configure Environment Variables**
   Create a `.env` file in the backend directory:
   ```env
   MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/
   DB_NAME=deccan_ambulance
   JWT_SECRET=your_super_secret_key
   PORT=8000
   ```
5. **Initialize Database (Optional)**
   ```bash
   python init_complete_database.py
   ```
6. **Start Backend Server**
   ```bash
   python app_fastapi.py
   # or
   uvicorn app_fastapi:socket_app --host 0.0.0.0 --port 8000 --reload
   ```

### Frontend Setup
1. **Navigate to Project Root**
   ```bash
   cd ..
   ```
2. **Install Flutter Dependencies**
   ```bash
   flutter pub get
   ```
3. **Configure Backend URL**
   Edit `lib/config/api_config.dart`.
4. **Run Application**
   ```bash
   flutter run
   ```

## 👥 User Roles

### 🧑 Citizen (Patient)
- **Email/Phone:** `client@example.com` or `9876543210`
- **Password:** `Client123`
- **Features:** Emergency SOS, Auto-SOS, Live Tracking, Request History.

### 🚑 Ambulance Driver
- **Driver ID:** `drive123`
- **Password:** `drive@123`
- **Features:** Availability toggle, SOS alerts, Accept/Reject, Navigation, Injury assessment.

### 🏥 Hospital Administrator
- **Hospital Code:** `1`
- **Password:** `123`
- **Features:** Capacity management, Incoming patients, Admission control, Statistics.

## 📚 API Documentation
**Base URL:** `http://localhost:8000`

### Authentication Endpoints
| Method | Endpoint | Description |
| :--- | :--- | :--- |
| POST | `/api/register/client` | Register new citizen |
| POST | `/api/register/driver` | Register new driver |
| POST | `/api/register/hospital` | Register new hospital |
| POST | `/api/login/client` | Client login |
| POST | `/api/login/driver` | Driver login |
| POST | `/api/login/admin` | Hospital admin login |

## 🔐 Security
- **JWT Tokens:** Signed with HS256 algorithm.
- **Password Hashing:** Bcrypt.
- **Data Protection:** HTTPS (TLS 1.3), Input validation (Pydantic), NoSQL (No SQL Injection).

## 📄 License
This project is licensed under the MIT License.

---
Built with ❤️ for saving lives
