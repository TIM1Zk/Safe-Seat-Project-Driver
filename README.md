# 🛡️ Safe Seat Project (Driver Application)
### แพลตฟอร์มสนับสนุนการป้องกันเมาแล้วขับด้วยบริการผู้ขับขี่แทน (Safe-Seat)

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![Express.js](https://img.shields.io/badge/Express.js-%23404d59.svg?style=for-the-badge&logo=express&logoColor=%2361DAFB)](https://expressjs.com/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**Safe Seat (Driver App)** คือแอปพลิเคชันมือถือสำหรับ **ผู้ให้บริการขับขี่แทน (Designated Driver)** และระบบคู่หูบัดดี้ (Buddy Team System) ภายใต้โครงการแพลตฟอร์มสนับสนุนการป้องกันเมาแล้วขับ โดยเชื่อมต่อกับระบบหลังบ้าน **Node.js/Express REST API** และฐานข้อมูลแบบเรียลไทม์ **Supabase (PostgreSQL & Realtime Broadcast Channels)** พร้อมทั้งระบบแผนที่นำทางถนนด้วย **OSRM (Open Source Routing Machine)**

โครงสร้างสถาปัตยกรรมของแอปพลิเคชันถูกออกแบบตามหลัก **MVC (Model-View-Controller)** อย่างเคร่งครัด แยกโมดูลตามฟังก์ชันการทำงาน และเชื่อมโยงข้อกำหนดฟังก์ชันระบบครบถ้วนตาม **เอกสารข้อกำหนดความต้องการระบบ (SRS)**

---

## 📌 สารบัญ (Table of Contents)
1. [ฟีเจอร์เด่นและโมดูลการทำงาน (Key Features)](#-ฟีเจอร์เด่นและโมดูลการทำงาน-key-features)
2. [โครงสร้าง Use Cases ตามเอกสาร SRS (25 Use Cases)](#-โครงสร้าง-use-cases-ตามเอกสาร-srs-25-use-cases)
3. [ตารางเชื่อมโยง Use Cases กับหน้าจอและโค้ด (SRS Mapping)](#-ตารางเชื่อมโยง-use-cases-กับหน้าจอและโค้ด-srs-mapping)
4. [โครงสร้างไดเรกทอรีโปรเจกต์ (Project Structure)](#-โครงสร้างไดเรกทอรีโปรเจกต์-project-structure)
5. [ระบบธีมและดีไซน์ (Design System & AppTheme)](#-ระบบธีมและดีไซน์-design-system--apptheme)
6. [สแตกเทคโนโลยี (Tech Stack)](#-สแตกเทคโนโลยี-tech-stack)
7. [ขั้นตอนการติดตั้งและรันโปรเจกต์ (Getting Started)](#-ขั้นตอนการติดตั้งและรันโปรเจกต์-getting-started)
8. [การตั้งค่าการเชื่อมต่อ (Configuration)](#-การตั้งค่าการเชื่อมต่อ-configuration)
9. [เอกสารอ้างอิงเพิ่มเติม (Documentation)](#-เอกสารอ้างอิงเพิ่มเติม-documentation)

---

## ✨ ฟีเจอร์เด่นและโมดูลการทำงาน (Key Features)

### 🔐 1. Authentication & Driver Profile (การยืนยันตัวตนและโปรไฟล์)
- **Restricted Driver Login:** ระบบเข้าสู่ระบบจำกัดเฉพาะบัญชีผู้ขับขี่ที่ได้รับการอนุมัติเท่านั้น พร้อมตรวจสอบและอัปเดตพิกัด GPS ปัจจุบันทันทีที่เข้าสู่ระบบ
- **Validation เข้มงวดตาม SRS:**
  - หมายเลขโทรศัพท์: ตัวเลข 10 หลัก ไม่เว้นวรรค
  - รหัสผ่าน: ตัวอักษรและตัวเลข 8–30 ตัวอักษร พร้อมอักขระพิเศษ `[!#_.]`
- **Persistent Session:** จัดเก็บและจดจำเซสชันการเข้าสู่ระบบผ่าน `SharedPreferences` และตรวจสอบความถูกต้องอัตโนมัติที่หน้า `LoadingScreen`
- **Brand Identity:** แสดงโลโก้โครงการทางการ (`assets/images/logo.png`) บนหน้าจอเข้าสู่ระบบ
- **Rating & Customer Reviews:** แสดงคะแนนดาวเฉลี่ย การกระจายตัวของเรตติ้ง (1–5 ดาว) และรายการความคิดเห็นจากลูกค้าผู้โดยสารจริง
- **Profile & Vehicle Management:** แก้ไขข้อมูลส่วนตัว (ชื่อ-นามสกุล, อีเมล) และจัดการข้อมูลยานพาหนะคู่ใจ (ยี่ห้อ, รุ่น, สี, ทะเบียนรถ, ภาพถ่ายตัวรถ)

### 👥 2. Buddy Team System (ระบบคู่หูบัดดี้ร่วมปฏิบัติงาน)
- **Proximity & Phone Search:** ค้นหาผู้ขับขี่รอบข้างด้วยพิกัด GPS ระยะใกล้ หรือค้นหาเจาะจงด้วยหมายเลขโทรศัพท์
- **Pairing Request Workflow:** ส่งคำขอจับคู่เป็นบัดดี้ โดยมีเวลารอการตอบรับ 5 นาที พร้อมระบบแจ้งเตือนแบบเรียลไทม์
- **Team Dashboard:** แสดงข้อมูลคู่หูที่กำลังร่วมงาน เบอร์โทรศัพท์ ปุ่มโทรออก และระบบกดยกเลิกการเป็นเพื่อนร่วมงาน (ยุบทีม) อย่างปลอดภัยด้วย Foreign-Key Constraint Handling

### 🗺️ 3. Real-time GPS, Map Routing & Ride Dispatch (ระบบแผนที่และรับงาน)
- **High-Accuracy GPS Stream:** สตรีมพิกัดตำแหน่งคนขับแบบเรียลไทม์ พร้อมคำนวณทิศทางการหันหน้ารถ (Dynamic Heading/Bearing)
- **OSRM Road Routing:** ระบบคำนวณและวาดเส้นทางบนถนนจริงแบบ Turn-by-Turn ผ่าน Open Source Routing Machine แยกสีชัดเจนระหว่างเส้นทางไปรับและเส้นทางไปส่ง
- **Realtime Job Dispatch:** รับการแจ้งเตือนงานใหม่แบบทันทีผ่าน Supabase Realtime Broadcast Channels รองรับทั้ง:
  - งานที่เรียกโดยผู้โดยสารทั่วไป (`requestbyuser`)
  - งานที่ส่งต่อจากสถานบันเทิง/ผับ (`requestbypub`)
- **Step-by-Step Ride Status:** ซิงค์สถานะการเดินทาง 4 ขั้นตอนแบบเรียลไทม์:
  1. กำลังเดินทางไปรับผู้โดยสาร
  2. ถึงจุดนัดหมายรับผู้โดยสาร
  3. กำลังเดินทางไปส่งยังจุดหมาย
  4. เสร็จสิ้นการให้บริการ

### 💳 4. Job Completion & Payment Settlement (การจบงานและการชำระเงิน)
- **Vehicle Delivery Proof:** บังคับถ่ายภาพถ่ายสถานที่จอดรถ/ส่งมอบรถเป็นหลักฐานก่อนจบงานทุกครั้ง
- **Automatic Split Payout:** แบ่งรายได้ค่าบริการระหว่าง Driver หลัก และ Buddy ประจำทีมโดยอัตโนมัติ (50/50)
- **PromptPay QR Code:** สร้าง QR Code พร้อมเพย์ตามยอดค่าบริการแบบไดนามิก รองรับการรับชำระเงินสด
- **Commission Deduction:** หักค่าธรรมเนียมคอมมิชชันกรณีรับเงินสด (`cash_commission_deduct`) และอัปเดตยอดเงินในกระเป๋าเงินทันที

### 💰 5. Driver Wallet & Earnings Analytics (กระเป๋าเงินและสรุปผลงาน)
- **Driver Wallet Dashboard:** แสดงยอดเงินคงเหลือสะสมในกระเป๋าเงินสดแบบเรียลไทม์
- **Fast Withdraw Flow:** ทำรายการถอนเงินรายได้เข้าบัญชีพร้อมเพย์ (ยอด 100–9,999 บาท) พร้อมตรวจสอบยอดเงินคงเหลือก่อนอนุมัติ
- **Withdrawal & Transaction Ledger:** ประวัติรายการเงินเข้า-ออกและค่าคอมมิชชัน พร้อมแปลง Timezone ประเทศไทย (Bangkok UTC+7) อย่างแม่นยำ
- **Service Summary & Date Range Filter:** สรุปสถิติเที่ยวขับ รายได้ และเวลาออนไลน์ สามารถเลือกช่วงเวลาได้ทั้ง:
  - วันนี้ (Today)
  - สัปดาห์นี้ (This Week)
  - เดือนนี้ (This Month)
  - ทั้งหมด (All Time)
  - **กำหนดช่วงเวลาเอง (Custom Date Range):** ปฏิทินเลือกวันเริ่มต้น - สิ้นสุด พร้อมกราฟแท่งแสดงรายได้สะสมประจำสัปดาห์

### ⚠️ 6. Safety & Incident Reporting (ความปลอดภัยและการร้องเรียน)
- **Report User:** รายงานพฤติกรรมผู้โดยสารที่ไม่เหมาะสมหรือเหตุฉุกเฉิน พร้อมระบุหมวดหมู่ รายละเอียด (5–200 ตัวอักษร) และแนบภาพถ่ายหลักฐาน
- **User Reported History:** ติดตามสถานะเรื่องร้องเรียนผู้โดยสารที่ส่งไป (*Pending*, *Under Review*, *Approved*, *Rejected*)
- **Driver Expense & Problem Reports:** ส่งเรื่องเบิกค่าใช้จ่ายระหว่างทางหรือรายงานปัญหารถยนต์และระบบต่อฝ่ายแอดมิน

---

## 📋 โครงสร้าง Use Cases ตามเอกสาร SRS (25 Use Cases)

อ้างอิงเอกสารข้อกำหนดความต้องการระบบ **`SRS2026_แพลตฟอร์มสนับสนุนการป้องกันเมาแล้วขับด้วยบริการผู้ขับขี่แทน` (หัวข้อ 2.4.2 และหัวข้อ 3.1.2 หน้า 61–91):**

```text
├── Authentication & Profile
│   ├── 3.1.2.1  Login Driver (เข้าสู่ระบบผู้ให้บริการขับรถ)
│   ├── 3.1.2.2  View Driver Profile (ดูโปรไฟล์ผู้ให้บริการขับรถ)
│   ├── 3.1.2.3  Edit Driver Profile (แก้ไขโปรไฟล์ผู้ให้บริการขับรถ)
│   ├── 3.1.2.4  Edit Driver Vehicle (แก้ไขยานพาหนะของผู้ให้บริการขับรถ)
│   └── (Dia 2.2) List Review Receive (ดูรายการรีวิวและความคิดเห็นจากลูกค้า)
├── Buddy Pairing System
│   ├── 3.1.2.5  Search Buddy (ค้นหาเพื่อนร่วมงาน/บัดดี้)
│   ├── 3.1.2.6  Send Buddy Request (ส่งคำขอเป็นเพื่อนร่วมงาน)
│   ├── 3.1.2.7  View Buddy Request (ดูรายการคำขอเป็นเพื่อนร่วมงาน)
│   ├── 3.1.2.8  Approve Request Buddy (อนุมัติ/ตอบรับคำขอเป็นเพื่อนร่วมงาน)
│   ├── 3.1.2.9  View My Buddy (ดูข้อมูลเพื่อนร่วมงานปัจจุบัน)
│   └── 3.1.2.10 End Buddy Service (ยกเลิกการเป็นเพื่อนร่วมงาน/ยุบทีม)
├── Real-time Ride & Dispatch System
│   ├── 3.1.2.12 View Notified Job (ดูการแจ้งเตือนงานจากผู้ใช้ทั่วไป)
│   ├── 3.1.2.13 Approve Job (ยืนยันรับงานจากผู้ใช้ทั่วไป)
│   ├── 3.1.2.12 View Notified Job By Pub (ดูการแจ้งเตือนงานจากสถานบันเทิง)
│   ├── 3.1.2.13 Approve Job By Pub (ยืนยันรับงานจากสถานบันเทิง)
│   ├── 3.1.2.14 View Service Info (ดูข้อมูลรายละเอียดการเดินทางและเส้นทาง)
│   └── 3.1.2.15 Update Service Status (อัปเดตสถานะการบริการ: ไปรับ/ถึงแล้ว/ไปส่ง/จบงาน)
├── Incident & Problem Reporting
│   ├── 3.1.2.16 Report User (รายงานผู้ใช้บริการ/กรณีฉุกเฉิน)
│   ├── 3.1.2.17 List Reported User (ดูประวัติการร้องเรียนผู้ใช้บริการ)
│   ├── 3.1.2.18 View Reported User Detail (ดูรายละเอียดประวัติการรายงานผู้ใช้บริการ)
│   └── 3.1.2.26 List Driver Reported (ดูรายการปัญหา/ข้อร้องเรียนที่คนขับแจ้ง)
└── Driver Finance & Analytics
    ├── 3.1.2.19 View Service Summary (ดูสรุปรายได้และสถิติการปฏิบัติงาน)
    ├── 3.1.2.20 View Driver Wallet (ดูกระเป๋าเงินสดและยอดเงินสะสม)
    ├── 3.1.2.21 Withdraw Wallet (ถอนเงินรายได้เข้าบัญชีพร้อมเพย์)
    └── 3.1.2.22 View Withdraw History (ดูประวัติการถอนเงิน)
```

---

## 🗺️ ตารางเชื่อมโยง Use Cases กับหน้าจอและโค้ด (SRS Mapping)

| ลำดับ | หน้าจอในแอปพลิเคชัน | ไฟล์ Component ในโปรเจกต์ | รหัสและชื่อ Use Case ตามเอกสาร SRS | รายละเอียดและการทำงาน |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **Loading Screen** | `lib/features/loading_screen/loading_screen.dart` | *(Infrastructure Session Init)* | ตรวจสอบ Session ถาวรในเครื่องเพื่อนำทางอัตโนมัติ |
| **2** | **Login Page** | `lib/features/login_page/login_page.dart` | **3.1.2.1 Login Driver** | เข้าสู่ระบบผู้ให้บริการด้วยเบอร์โทรและรหัสผ่าน พร้อมส่งพิกัด GPS |
| **3** | **Map Page (หน้าจอหลัก)** | `lib/features/map_page/map_page.dart` | **3.1.2.12 View Notified Job**<br>**3.1.2.13 Approve Job**<br>**3.1.2.12 View Notified Job By Pub**<br>**3.1.2.13 Approve Job By Pub**<br>**3.1.2.14 View Service Info**<br>**3.1.2.15 Update Service Status** | ศูนย์กลางรับงานจาก User & Pub แสดงเส้นทาง OSRM และอัปเดตสถานะการเดินทางเรียลไทม์ |
| **4** | **Finish Job Page** | `lib/features/map_page/finish_job_page.dart` | **3.1.2.15 Update Service Status** *(Completed)* | ถ่ายภาพหลักฐานส่งมอบรถ ยืนยันจบงาน และแสดง QR Code รับเงินสด |
| **5** | **Report User Page** | `lib/features/map_page/report_user_page.dart` | **3.1.2.16 Report User** | ส่งรายงานพฤติกรรมไม่เหมาะสมของผู้โดยสารพร้อมภาพถ่ายหลักฐาน |
| **6** | **Search Buddy Page** | `lib/features/searchbuddy_page/searchbuddy_page.dart` | **3.1.2.5 Search Buddy**<br>**3.1.2.6 Send Buddy Request**<br>**3.1.2.7 View Buddy Request**<br>**3.1.2.8 Approve Request Buddy** | ค้นหาคนขับใกล้เคียง ส่งคำขอเข้าร่วมทีม และตอบรับ/ปฏิเสธคำขอจับคู่ |
| **7** | **My Buddy Page** | `lib/features/Mybuddy_page/my_buddy_page.dart` | **3.1.2.9 View My Buddy**<br>**3.1.2.10 End Buddy Service** | ตรวจสอบโปรไฟล์บัดดี้ปัจจุบัน ปุ่มโทรออก และกดยกเลิกการเป็นบัดดี้ |
| **8** | **Wallet Balance Page** | `lib/features/view_wallet_balance/view_wallet_balance.dart` | **3.1.2.20 View Driver Wallet** | แสดงยอดเงินสดสะสมคงเหลือ และปุ่มลัดไปยังหน้าถอนเงิน/ประวัติ |
| **9** | **Withdraw Wallet Page** | `lib/features/withdraw_wallet_page/withdraw_wallet.dart` | **3.1.2.21 Withdraw Wallet** | บันทึกคำขอถอนเงินเข้าบัญชีพร้อมเพย์ (100–9,999 บาท) |
| **10** | **Wallet History Page** | `lib/features/view_wallet_history/view_wallet_history.dart` | **3.1.2.22 View Withdraw History** | ตรวจสอบประวัติการถอนเงิน วันที่ จำนวนเงิน และสถานะการโอน |
| **11** | **Service Summary Page** | `lib/features/service_summary/service_summary_page.dart` | **3.1.2.19 View Service Summary** | รายงานสรุปผลการปฏิบัติงาน รายได้ เที่ยวขับ กรองตามวัน/สัปดาห์/เดือน/กำหนดเอง |
| **12** | **Driver Profile Page** | `lib/features/profile_page/profile_page.dart` | **3.1.2.2 View Driver Profile** | แสดงข้อมูลคนขับ คะแนนเรตติ้ง เมนูตั้งค่ารถ/โปรไฟล์ และออกจากระบบ |
| **13** | **Driver Profile Detail** | `lib/features/profile_page/driver_profile_detail_page.dart` | **List Review Receive** *(หน้า 27)*<br>**3.1.2.2 View Driver Profile** | รายละเอียดคะแนนดาว การกระจายเรตติ้ง และข้อความรีวิวจากผู้โดยสาร |
| **14** | **Edit Profile Page** | `lib/features/edit_profile_page/edit_profile_page.dart` | **3.1.2.3 Edit Driver Profile** | แก้ไขข้อมูลส่วนตัว เช่น ชื่อ นามสกุล และอีเมล |
| **15** | **Edit Car Page** | `lib/features/edit_car_page/edit_car_page.dart` | **3.1.2.4 Edit Driver Vehicle** | แก้ไขข้อมูลรถ ยี่ห้อ รุ่น สี ป้ายทะเบียน และอัปโหลดภาพถ่ายยานพาหนะ |
| **16** | **User Reported History** | `lib/features/profile_page/user_reported_history_page.dart` | **3.1.2.17 List Reported User**<br>**3.1.2.18 View Reported User Detail** | รายการประวัติการรายงานผู้โดยสาร และติดตามผลการตรวจสอบของแอดมิน |
| **17** | **List Driver Report** | `lib/features/Listdriverreport_page/Listdriverreport_page.dart` | **3.1.2.26 List Driver Reported** | ติดตามประวัติและสถานะปัญหาการใช้งานที่คนขับแจ้งต่อระบบ |

---

## 🏗️ โครงสร้างไดเรกทอรีโปรเจกต์ (Project Structure)

```text
Mobile_project/
├── assets/
│   └── images/
│       └── logo.png                # Official Safe Seat Brand Logo
├── lib/
│   ├── main.dart                   # Application Entry Point & Theme Injection
│   ├── core/                       # Core Foundation Layer
│   │   ├── constants/              # Application Constants & Endpoint URLs
│   │   ├── network/
│   │   │   └── api_service.dart    # Dio HTTP Client Wrapper & Interceptors
│   │   ├── theme/
│   │   │   └── app_theme.dart      # Design Tokens, Color Palette & Styles
│   │   └── utils/
│   │       ├── image_utils.dart    # Base64 & Multipart Image Processing
│   │       ├── location_helper.dart# GPS Distance & Dynamic Heading Calculation
│   │       └── session_manager.dart# Persistent Session & SharedPreferences Cache
│   │
│   └── features/                   # MVC Feature Modules
│       ├── loading_screen/         # Session Guard & App Bootstrapping
│       ├── login_page/             # Driver Authentication & Brand Display
│       ├── map_page/               # Live Map, GPS, Ride Dispatch & Job Workflow
│       │   ├── map_page.dart       # Main Map & Realtime Listener
│       │   ├── finish_job_page.dart# Parking Proof & PromptPay QR
│       │   └── report_user_page.dart # Incident & Passenger Report
│       ├── searchbuddy_page/       # Driver Discovery & Pairing Request
│       ├── Mybuddy_page/           # Active Buddy Status & Team Management
│       ├── view_wallet_balance/    # Driver Wallet Balance Screen
│       ├── withdraw_wallet_page/   # PromptPay Bank Withdrawal
│       ├── view_wallet_history/    # Transaction & Withdrawal Ledger
│       ├── service_summary/        # Earnings Analytics & Custom Date Filtering
│       ├── profile_page/           # Driver Profile, Ratings & Safety Center
│       │   ├── profile_page.dart
│       │   ├── driver_profile_detail_page.dart # Reviews & Star Breakdown
│       │   └── user_reported_history_page.dart # Passenger Incident History
│       ├── edit_profile_page/      # Edit Personal Information
│       ├── edit_car_page/          # Vehicle Management & Photos
│       └── Listdriverreport_page/  # Driver System Issue Reports
│
├── screens_and_usecases.md         # Comprehensive SRS Mapping Document
├── pubspec.yaml                    # Flutter Dependencies & Assets Configuration
└── README.md
```

---

## 🎨 ระบบธีมและดีไซน์ (Design System & AppTheme)

แอปพลิเคชันใช้ดีไซน์ซิสเต็มมาตรฐาน (`AppTheme`) ที่กำหนดค่าสีและสไตล์ชัดเจน เพื่อความสม่ำเสมอและประสบการณ์การใช้งานที่พรีเมียม:

| Token Name | Color Code | ตัวอย่างสี | การใช้งานหลัก |
| :--- | :--- | :---: | :--- |
| **Primary Blue** | `#2340A7` | 🟦 | แถบ AppBar, ปุ่มหลัก (Primary Buttons), Header |
| **Accent / Secondary Blue** | `#2563EB` | 🔷 | ปุ่มกดเน้นย้ำ, ลิงก์, ไอคอนสถานะ |
| **Background** | `#F8FAFC` | ⬜ | พื้นหลังหน้าจอหลักทุกหน้า (Scaffold Background) |
| **Surface** | `#FFFFFF` | ◽ | การ์ดคอนเทนต์, แผ่นโมดอล, ฟิลด์กรอกข้อมูล |
| **Success Green** | `#16A34A` | 🟩 | สถานะงานเสร็จสิ้น, รายได้เข้า, ยอดเงินบวก |
| **Error / Alert Red** | `#DC2626` | 🟥 | แจ้งเตือนข้อผิดพลาด, ปุ่มยกเลิก, ปุ่มรายงานเหตุ |
| **Typography** | `Kanit` | - | ฟอนต์หลักของทั้งแอปพลิเคชัน อ่านง่าย สวยงาม |

---

## 🛠️ สแตกเทคโนโลยี (Tech Stack)

### Frontend (Mobile Application)
* **Framework:** [Flutter](https://flutter.dev) (SDK ^3.10.1) & [Dart](https://dart.dev)
* **Design Token System:** Material Design 3 + Custom `AppTheme` Design Tokens
* **HTTP Client:** [Dio](https://pub.dev/packages/dio) (^5.7.0)
* **Map & GPS Routing:** [flutter_map](https://pub.dev/packages/flutter_map) (^6.1.0), [latlong2](https://pub.dev/packages/latlong2), [geolocator](https://pub.dev/packages/geolocator) (^14.0.2), OSRM Routing Engine
* **Realtime & Database SDK:** [supabase_flutter](https://pub.dev/packages/supabase_flutter) (^2.15.0)
* **Payment & Utility:** [qr_flutter](https://pub.dev/packages/qr_flutter) (^4.1.0), [image_picker](https://pub.dev/packages/image_picker) (^1.1.2), [intl](https://pub.dev/packages/intl) (^0.20.2)
* **Local Storage:** [shared_preferences](https://pub.dev/packages/shared_preferences) (^2.2.3)

### Backend & Cloud Infrastructure
* **Backend Runtime:** Node.js & Express.js RESTful API
* **Database & Auth:** Supabase (Managed PostgreSQL)
* **Realtime Communication:** Supabase Realtime Channels (Broadcast & Presence)
* **Routing Engine:** Open Source Routing Machine (OSRM)

---

## 🚀 ขั้นตอนการติดตั้งและรันโปรเจกต์ (Getting Started)

### ข้อกำหนดเบื้องต้น (Prerequisites)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (เวอร์ชัน 3.10.1 ขึ้นไป)
- [Android Studio](https://developer.android.com/studio) หรือ VS Code พร้อม Flutter Extension
- อุปกรณ์จำลอง (Android Emulator) หรือ สมาร์ตโฟนจริงที่เปิด USB Debugging
- Backend Server ของ Safe Seat ที่รันอยู่บนเน็ตเวิร์กที่เชื่อมต่อได้

### 1. ติดตั้ง Dependencies
```bash
flutter pub get
```

### 2. ตั้งค่าไฟล์สภาพแวดล้อม (.env)
คัดลอกไฟล์ `.env.example` เป็น `.env` และระบุค่า Supabase Keys และ API URL:
```bash
cp .env.example .env
```
เนื้อหาภายในไฟล์ `.env`:
```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key

# Backend API Configuration (http://10.0.2.2:3000/api สำหรับ Emulator หรือ IP วง LAN สำหรับเครื่องจริง)
API_BASE_URL=http://10.0.2.2:3000/api
```

### 3. รันแอปพลิเคชัน
```bash
# ตรวจสอบอุปกรณ์ที่เชื่อมต่อ
flutter devices

# รันแอปพลิเคชัน
flutter run
```

---

## ⚙️ การตั้งค่าการเชื่อมต่อ (Configuration)

### จัดการตัวแปรสภาพแวดล้อมด้วย AppEnv & flutter_dotenv
โปรเจกต์ใช้คลาสรวมศูนย์ `AppEnv` (`lib/core/constants/app_env.dart`) ในการโหลดค่า Configuration จาก `.env`:
```dart
// main.dart
await dotenv.load(fileName: ".env");

await Supabase.initialize(
  url: AppEnv.supabaseUrl,
  anonKey: AppEnv.supabaseAnonKey,
);

ApiService.init(baseUrl: AppEnv.apiBaseUrl);
```

### Android Permissions
ใน `android/app/src/main/AndroidManifest.xml` มีการขอสิทธิ์ที่จำเป็นดังนี้:
- `ACCESS_FINE_LOCATION` & `ACCESS_COARSE_LOCATION` สำหรับการระบุพิกัด GPS
- `CAMERA` สำหรับการถ่ายรูปหลักฐานส่งมอบรถและรายงานเหตุ
- `INTERNET` สำหรับการเชื่อมต่อ Network API และ Supabase Realtime

---

## 📄 เอกสารอ้างอิงเพิ่มเติม (Documentation)
- **สรุปหน้าจอและ Use Cases ตามเล่ม SRS ฉบับเต็ม:** [screens_and_usecases.md](screens_and_usecases.md)
- **เอกสารข้อกำหนดความต้องการระบบ:** `SRS2026_แพลตฟอร์มสนับสนุนการป้องกันเมาแล้วขับด้วยบริการผู้ขับขี่แทน (ฉบับสมบูรณ์).pdf`

---

## ⚖️ License
โปรเจกต์นี้เผยแพร่ภายใต้สัญญาอนุญาต [MIT License](LICENSE)

*Developed with ❤️ by **TIM1Zk_***
