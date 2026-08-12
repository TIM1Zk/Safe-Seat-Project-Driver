# 🛡️ Safe Seat Project

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![Express.js](https://img.shields.io/badge/Express.js-%23404d59.svg?style=for-the-badge&logo=express&logoColor=%2361DAFB)](https://expressjs.com/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

A professional full-stack mobile application designed for secure wallet management and user profile interactions. 

The project has recently been refactored to a strict **MVC Architecture**. The mobile app now communicates via a custom **Node.js/Express Backend API**, which handles all business logic and securely connects to **Supabase** for database operations.

---

## ✨ Key Features

- **🔐 Secure Authentication & Persistent Login:** Login restricted to approved users with automatic login state storage (`shared_preferences`) and direct navigation to MapPage on successful startup/login.
- **🚗 Driver Car Management:** Premium vehicle details card on the profile page and a dedicated frosted-blue vehicle edit screen supporting real-time database updates for drivercar details (Brand, Model, Color, Plate).
- **🤝 Synced Buddy Request & Team System:** 
  - **Location-Aware Search:** Find nearby buddies based on real-time location.
  - **Real-time Requests:** Send/Receive buddy requests with a 5-minute auto-expiry rule.
  - **Notification Badge:** Instant visual indicators for new pending requests.
  - **My Buddy Dashboard:** View current active buddy details, chat/call options, and team management (Leave Team) with instant, real-time UI state synchronization.
  - **Robust Fkey Database Handling:** Safely handles database constraints when leaving teams by dynamically resetting `buddy_team_id` references on members before deletion.
- **📋 User Reporting & Strict Validation:**
  - Dedicated **Report User Page** (`report_user_page.dart`) with comprehensive client-side data validation rules (event detail text length max 200 chars, character validation restricting to Thai/English/numbers, required image upload in JPG/PNG format up to 10 MB).
  - Safety check disabling user reports for pub/nightlife establishment requests (`_isPubJob`).
- **🗺️ Advanced Map Routing, High-Accuracy GPS & Real-time Job Sync:**
  - **Enhanced GPS Accuracy:** Upgraded location tracking settings (`LocationAccuracy.high`) across `map_page.dart` and `searchbuddy_page.dart` for precise real-time positioning.
  - **OSRM Map Router Integration:** Renders accurate, dynamic routes along actual roads using the Open Source Routing Machine (OSRM) API instead of straight lines, drawing distinct paths from driver-to-pickup (blue) and pickup-to-destination (green).
  - **Real-time Job Syncing:** Dynamically updates map states when any teammate accepts a job. Listens to database events and syncs current job state (e.g. status changes: "ถึงจุดนัดหมาย", "กำลังเดินทาง", "เสร็จสิ้น") instantly between buddy devices via Supabase Realtime Broadcast.
  - **Correct Destination Mapping:** Direct extraction of accurate customer pickup and drop-off coordinates from the `requestbyuser` data model, displaying precise locations on both driver/buddy devices.
- **📋 Driver Problem & Expense Reporting:**
  - **Multi-Status Filter:** View and filter submitted reports by status: "ทั้งหมด" (All), "กำลังดำเนินการ" (In Progress), and "เสร็จสิ้น" (Completed).
  - **Detailed Report Sheet:** Interactive modal sheets showing report details, date, status, custom category icons, and receipt images.
  - **Team-based API Querying:** Intelligently joins and matches reports to drivers based on their current `buddy_team_id` context.
- **👤 Profile Management & Redesign:** 
  - Beautiful white-themed profile detail screen (`DriverProfileDetailPage`) with a custom circular pencil/edit button.
  - Redesigned "แก้ไขข้อมูลบัญชี" (`EditProfilePage`) screen matching custom mockup layout to update full name (first name & last name), email, and phone number.
  - **🆕 Review & Rating Display:** Displays real-time average review ratings and a list of feedback/comments from users on the profile page.
  - **🆕 User Reported History:** A dedicated tracking screen (`UserReportedHistoryPage`) to view and filter all submitted user-related reports by status ("ทั้งหมด", "กำลังตรวจสอบ", "ตรวจสอบแล้ว", "ไม่อนุมัติ" with red indicator color).
- **💰 Upgraded Wallet System:** Premium styled UI cards displaying real-time balance, custom withdrawal input flow, and withdrawal transaction history screen.
- **📍 Location & Team Tracking:** Automatic capture and storage of leader's GPS coordinates every 30 seconds into `buddyteam` database table when active.
- **🖼️ Image Optimization:** Dynamic JSON parsing utility for resilient profile picture loading across the app.
- **🎨 Premium UI & Experience Enhancements:** Beautiful white-themed search buddy cards, modern search input fields with subtle shadow borders, and redesigned buddy profile/dashboard cards for a cleaner, more interactive user experience.
- **🏗️ MVC Architecture:** Clean separation of concerns across the full stack.


---

## 📂 Project Structure

### Mobile (Flutter)
```text
lib/
├── core/
│   ├── network/              # API Service (Dio Client)
│   └── utils/                # SessionManager (Local storage), ImageUtils, etc.
├── features/
│   ├── searchbuddy_page/     # Buddy search & Request notifications
│   ├── Mybuddy_page/         # Active buddy details & Team management
│   ├── Listdriverreport_page/# Driver problem & expense reporting interface
│   ├── login_page/           # Authentication flow
│   ├── profile_page/         # User profile, vehicle card, and user reported history
│   ├── view_wallet_balance/  # Dashboard for wallet
│   ├── withdraw_wallet_page/ # Withdrawal interface
│   ├── edit_profile_page/    # Phone number modification interface
│   ├── edit_car_page/        # Vehicle details modification interface
│   └── loading_screen/       # Loader & auto-login check on startup
└── main.dart                 # App entry point & configuration
```

### Backend (Node.js)
```text
safeseat_backend/
├── src/
│   ├── controllers/          # buddyRequestController.js, driverReportController.js, userController.js, etc.
│   ├── models/               # buddyRequestModel.js, driverReportModel.js, userModel.js, authModel.js
│   ├── routes/               # buddyRequestRoutes.js, driverReportRoutes.js, userRoutes.js, etc.
│   └── index.js              # Express app entry point
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.10.1 or higher)
- [Node.js](https://nodejs.org/) (v16 or higher)
- A Supabase account and project.

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/TIM1Zk/Safe-Seat-Project.git
   cd Safe-Seat-Project
   ```

2. **Backend Setup:**
   ```bash
   cd safeseat_backend
   npm install
   ```
   *Create a `.env` file in the `safeseat_backend/` directory with your Supabase credentials (see `.env.example` or code for keys).*

3. **Run the Backend:**
   ```bash
   npm run dev
   ```
   *(Server runs on `http://localhost:3000`)*

4. **Frontend Setup:**
   ```bash
   # Open a new terminal in the root Safe-Seat-Project directory
   flutter pub get
   ```
   *Note: API base URL is configured in `lib/main.dart` (Default: `http://10.0.2.2:3000/api` for Android emulator).*

5. **Run the Application:**
   ```bash
   flutter run
   ```

---

## 🛠️ Built With

* **Frontend:** [Flutter](https://flutter.dev/), [Dio](https://pub.dev/packages/dio)
* **Backend:** [Node.js](https://nodejs.org/), [Express.js](https://expressjs.com/)
* **Database & Auth:** [Supabase](https://supabase.io/) (PostgreSQL)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Developed with ❤️ by **TIM1Zk_***
