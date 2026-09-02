# 🛡️ Safe Seat Project (Driver Application)

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![Express.js](https://img.shields.io/badge/Express.js-%23404d59.svg?style=for-the-badge&logo=express&logoColor=%2361DAFB)](https://expressjs.com/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**Safe Seat (Driver App)** is a comprehensive full-stack mobile application platform built for designated drivers and buddy-team operations. It features real-time navigation, team buddy matching, dispatch notifications, payment processing (PromptPay QR & Cash), driver wallet management, and incident reporting.

The project follows a strict **MVC Architecture**. The mobile client communicates via a custom **Node.js/Express Backend API**, which handles business logic and securely interfaces with **Supabase (PostgreSQL & Realtime Channels)**.

---

## ✨ Key Features & System Modules

### 🔐 1. Authentication & Driver Profile
- **Restricted Driver Login:** Secure authentication restricted to active driver accounts with persistent local session caching (`shared_preferences`).
- **Strict Input Validation:** 
  - Mobile phone format validation (10 numeric digits, no whitespace).
  - Password strength validation (8–30 characters, alphanumeric with special symbols `[!#_.]`).
- **Profile & Rating Display:** View average rating score, total review count, and passenger feedback comments.
- **Account & Car Editing:** Update personal info (name, phone, email) and manage vehicle details (brand, model, color, license plate).

### 👥 2. Buddy Team System
- **Proximity & Phone Search:** Search available drivers by mobile number or nearby active location.
- **Real-time Team Pairing:** Send and accept buddy pairing requests with a 5-minute auto-expiration window.
- **Live Team Dashboard:** View active teammate profile, call/chat actions, and leave team with robust foreign-key constraint safety.

### 🗺️ 3. Map Routing, Real-time GPS & Ride Dispatch
- **High-Accuracy GPS Stream:** Continuous driver location streaming with dynamic heading updates and teammate synchronization.
- **OSRM Dynamic Road Routing:** Turn-by-turn routing using Open Source Routing Machine (OSRM) rendering distinct paths for pickup and destination.
- **Real-time Ride Dispatch:** Receive instant job popups from passengers and nightlife venues (Pubs) via Supabase Realtime broadcast channels.
- **Service Workflow:** Step-by-step ride flow with status synchronization ("ถึงจุดนัดหมาย", "กำลังเดินทาง", "เสร็จสิ้น").

### 💳 4. Job Completion & Payment Settlement
- **Finish Job Verification:** Mandatory parking proof photo capture before completing rides.
- **Split Payment & Commission Handling:**
  - Automatic split payout between Driver and Buddy teammates (50/50).
  - Commission deduction for Cash payments (`cash_commission_deduct`) and automated driver wallet balance updates.
  - Dynamic PromptPay QR generation for cash/direct payment settlement.

### 💰 5. Driver Wallet & Earnings Analytics
- **Driver Wallet Dashboard:** Real-time wallet balance preview, fast withdrawal flow with bank account details.
- **Transaction History:** Detailed ledger for earnings, withdrawals, and cash commissions.
- **Service Summary Dashboard:** Filter earnings and completed rides by Today, This Week, This Month, or All Time, complete with weekly earnings charts.

### ⚠️ 6. Reporting & Safety
- **Report User:** Report passenger misconduct with required category, detailed description (5-200 chars), and proof images.
- **Reported History Tracking:** Filter submitted user reports with clear status indicators (*Pending*, *Under Review*, *Approved*, *Rejected*).
- **Driver Expense & Problem Reports:** Submit road expenses and vehicle issue claims with receipt attachments.

---

## 🏗️ System Architecture

```text
Safe-Seat-Project/ (Full Monorepo)
├── Safe-Seat-Project/          # Flutter Frontend Mobile App
│   ├── lib/
│   │   ├── core/
│   │   │   ├── network/        # Dio API Client
│   │   │   ├── theme/          # AppTheme Design Tokens & Colors
│   │   │   └── utils/          # SessionManager, LocationHelper, ImageUtils
│   │   └── features/           # Modular Feature Modules (MVC)
│   │       ├── login_page/
│   │       ├── map_page/
│   │       ├── searchbuddy_page/
│   │       ├── Mybuddy_page/
│   │       ├── profile_page/
│   │       ├── edit_profile_page/
│   │       ├── edit_car_page/
│   │       ├── service_summary/
│   │       ├── view_wallet_balance/
│   │       ├── view_wallet_history/
│   │       ├── withdraw_wallet_page/
│   │       └── Listdriverreport_page/
│   └── pubspec.yaml
│
└── safeseat_backend/           # Node.js & Express REST API
    ├── src/
    │   ├── config/             # Supabase client & environment configuration
    │   ├── controllers/        # Express request handlers
    │   ├── models/             # Database access layers (Supabase PostgreSQL)
    │   ├── routes/             # RESTful API route definitions
    │   └── services/           # Realtime dispatch & background services
    └── package.json
```

---

## 📋 Use Case Mapping

| Use Case | Description | Primary Controller | Primary Model / Tables |
| :--- | :--- | :--- | :--- |
| **Login Driver** | Authenticate driver and create session | `AuthController` | `AuthModel` (`driver`) |
| **View / Edit Profile** | Profile stats, reviews, and updates | `UserController` | `UserModel` (`driver`, `review`) |
| **Edit Car** | Update vehicle specifications | `VehicleController` | `UserModel` (`driver_car`) |
| **Search & Buddy Pairing**| Search partners, send/accept buddy requests | `BuddyRequestController` | `BuddyRequestModel` (`buddyteam`, `driver`) |
| **Accept & Manage Job** | Real-time job alert, routing, and ride flow | `JobController` / `BuddyController` | `BuddyRequestModel` (`requestbyuser`, `requestbypub`) |
| **Finish Job & Payment**| Parking proof, PromptPay QR, earnings split | `JobController` / `BuddyController` | `BuddyRequestModel`, `WalletModel` |
| **Driver Wallet & Withdraw** | View balance, request bank withdrawal | `WalletController` | `WalletModel` (`driver`, `driverwallettransaction`) |
| **Service Summary** | Earnings analytics & ride history | `WalletController` | `WalletModel`, `BuddyRequestModel` |
| **Report User & History** | Submit user report and track report status | `UserReportController` | `UserReportModel` (`userreport`) |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.10.1 or higher)
- [Node.js](https://nodejs.org/) (v18 or higher)
- Supabase Project with configured schema

### 1. Backend Setup
```bash
cd safeseat_backend
npm install
npm run dev
# Server will start on http://localhost:3000
```

### 2. Frontend Setup
```bash
cd Safe-Seat-Project
flutter pub get
flutter run
```

*Note: Base URL is configured in `lib/main.dart` (`http://10.0.2.2:3000/api` for Android Emulator or your local LAN IP for physical testing).*

---

## 🛠️ Tech Stack

* **Frontend:** Flutter, Dart, Dio, Flutter Map, Geolocator, Shared Preferences
* **Backend:** Node.js, Express.js, Supabase JS SDK
* **Database & Realtime:** Supabase (PostgreSQL, Realtime Broadcast)
* **Routing:** OSRM (Open Source Routing Machine)

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

*Developed with ❤️ by **TIM1Zk_***
