# เอกสารสรุปหน้าจอและยูสเคส (Use Cases) ตามเอกสารข้อกำหนดความต้องการระบบ (SRS)
**โครงการ:** แพลตฟอร์มสนับสนุนการป้องกันเมาแล้วขับด้วยบริการผู้ขับขี่แทน (Safe-Seat)  
**อ้างอิงเอกสาร:** `SRS2026_แพลตฟอร์มสนับสนุนการป้องกันเมาแล้วขับด้วยบริการผู้ขับขี่แทน (ฉบับสมบูรณ์).pdf`  
**แอปพลิเคชันส่วนที่ประมวลผล:** ฝั่งผู้ให้บริการขับรถ (Mobile Application - Driver)

---

## 📌 บทนำและโครงสร้าง Use Cases ฝั่ง Mobile Driver ตามเล่ม SRS

ในเล่มข้อกำหนดความต้องการระบบ (SRS หัวข้อ **2.4.2 Use Cases ฝั่ง Mobile Application** และหัวข้อ **3.1.2 Mobile Application (หน้า 61–86)** รวมถึง Use Case Diagram รูปที่ 2.2 หน้า 27) ได้กำหนด Use Cases สำหรับผู้ให้บริการขับรถ (Driver) ไว้ดังนี้:

1. **Login Driver** (เข้าสู่ระบบผู้ให้บริการขับรถ) - หัวข้อ 3.1.2.1
2. **View Driver Profile** (ดูโปรไฟล์ผู้ให้บริการขับรถ) - หัวข้อ 3.1.2.2
3. **Edit Driver Profile** (แก้ไขโปรไฟล์ผู้ให้บริการขับรถ) - หัวข้อ 3.1.2.3
4. **Edit Driver Vehicle** (แก้ไขยานพาหนะของผู้ให้บริการขับรถ) - หัวข้อ 3.1.2.4
5. **Search Buddy** (ค้นหาเพื่อนร่วมงาน/บัดดี้) - หัวข้อ 3.1.2.5
6. **Send Buddy Request** (ส่งคำขอเป็นเพื่อนร่วมงาน) - หัวข้อ 3.1.2.6
7. **View Buddy Request** (ดูรายการคำขอเป็นเพื่อนร่วมงาน) - หัวข้อ 3.1.2.7
8. **Approve Request Buddy** (อนุมัติ/ตอบรับคำขอเป็นเพื่อนร่วมงาน) - หัวข้อ 3.1.2.8
9. **View My Buddy** (ดูข้อมูลเพื่อนร่วมงานปัจจุบัน) - หัวข้อ 3.1.2.9
10. **End Buddy Service** (ยกเลิกการเป็นเพื่อนร่วมงาน/ยุบทีม) - หัวข้อ 3.1.2.10
11. **View Notified Job** (ดูการแจ้งเตือนงานจากผู้ใช้บริการทั่วไป) - หัวข้อ 3.1.2.12
12. **Approve Job** (ยืนยันรับงานจากผู้ใช้บริการทั่วไป) - หัวข้อ 3.1.2.13
13. **View Notified Job By Pub** (ดูการแจ้งเตือนงานจากสถานบันเทิง) - หัวข้อ 3.1.2.12 (By Pub)
14. **Approve Job By Pub** (ยืนยันรับงานจากสถานบันเทิง) - หัวข้อ 3.1.2.13 (By Pub)
15. **View Service Info** (ดูข้อมูลรายละเอียดการเดินทางและเส้นทาง) - หัวข้อ 3.1.2.14
16. **Update Service Status** (อัปเดตสถานะการบริการ เช่น กำลังไปรับ / ถึงแล้ว / กำลังไปส่ง / เสร็จสิ้น) - หัวข้อ 3.1.2.15
17. **Report User** (รายงานผู้ใช้บริการ/กรณีฉุกเฉิน) - หัวข้อ 3.1.2.16
18. **List Reported User** (ดูประวัติการร้องเรียนผู้ใช้บริการ) - หัวข้อ 3.1.2.17
19. **View Reported User Detail** (ดูรายละเอียดประวัติการรายงานผู้ใช้บริการ) - หัวข้อ 3.1.2.18
20. **List Driver Reported** (ดูรายการปัญหา/ข้อร้องเรียนที่คนขับแจ้ง) - หัวข้อ 3.1.2.26
21. **View Service Summary** (ดูสรุปรายได้และสถิติการปฏิบัติงาน) - หัวข้อ 3.1.2.19
22. **View Driver Wallet** (ดูกระเป๋าเงินสดและยอดเงินสะสม) - หัวข้อ 3.1.2.20
23. **Withdraw Wallet** (ถอนเงินรายได้เข้าบัญชีพร้อมเพย์) - หัวข้อ 3.1.2.21
24. **View Withdraw History** (ดูประวัติการถอนเงิน) - หัวข้อ 3.1.2.22
25. **List Review Receive** (ดูรายการรีวิวและความคิดเห็นที่ได้รับจากลูกค้า) - ไดอะแกรมรูป 2.2 หน้า 27

---

## 📱 ตารางเชื่อมโยงหน้าจอในแอปพลิเคชัน กับ Use Case ในเล่ม SRS

| ลำดับหน้าจอ | หน้าจอในโค้ดแอปพลิเคชัน | ไฟล์ Component ในโปรเจกต์ | รหัสและชื่อ Use Case ในเล่ม SRS | หมายเหตุ / คำอธิบายตามเล่ม |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **Loading Screen** | [loading_screen.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/loading_screen/loading_screen.dart) | *(Infrastructure / Session Initialization)* | ตรวจสอบ Session ก่อนเข้าใช้งานระบบ |
| **2** | **Login Page** | [login_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/login_page/login_page.dart) | **3.1.2.1 Login Driver** | เข้าสู่ระบบผู้ให้บริการขับรถ ด้วยหมายเลขโทรศัพท์และรหัสผ่าน พร้อมระบุ GPS |
| **3** | **Map Page** (หน้าจอหลักและระบบรับงาน) | [map_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/map_page/map_page.dart) | **3.1.2.12 View Notified Job**<br>**3.1.2.13 Approve Job**<br>**3.1.2.12 View Notified Job By Pub**<br>**3.1.2.13 Approve Job By Pub**<br>**3.1.2.14 View Service Info**<br>**3.1.2.15 Update Service Status** | หน้าหลักสำหรับเปิดออนไลน์, รับการแจ้งเตือนงานทั้งจาก User และ Pub, กดยืนยันรับงาน, ดูข้อมูลการเดินทาง และอัปเดตสถานะการเดินทางแบบเรียลไทม์ร่วมกับบัดดี้ |
| **4** | **Finish Job Page** | [finish_job_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/map_page/finish_job_page.dart) | **3.1.2.15 Update Service Status** *(สถานะ Completed)* | ยืนยันสิ้นสุดการเดินทาง ถ่ายรูปหลักฐานส่งมอบรถ แสดง QR Code เรียกเก็บเงินกรณีเงินสด |
| **5** | **Report User Page** | [report_user_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/map_page/report_user_page.dart) | **3.1.2.16 Report User** | รายงานผู้ใช้บริการกรณีมีพฤติกรรมไม่เหมาะสม หรือเกิดเหตุฉุกเฉิน พร้อมแนบรูปถ่าย |
| **6** | **Search Buddy Page** | [searchbuddy_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/searchbuddy_page/searchbuddy_page.dart) | **3.1.2.5 Search Buddy**<br>**3.1.2.6 Send Buddy Request**<br>**3.1.2.7 View Buddy Request**<br>**3.1.2.8 Approve Request Buddy** | ค้นหารายชื่อคนขับใกล้เคียง, ส่งคำขอจับคู่เป็นบัดดี้, ตรวจสอบคำขอที่ส่งเข้ามา และกดอนุมัติ/ปฏิเสธคำขอจับคู่ |
| **7** | **My Buddy Page** | [my_buddy_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/Mybuddy_page/my_buddy_page.dart) | **3.1.2.9 View My Buddy**<br>**3.1.2.10 End Buddy Service** | ตรวจสอบโปรไฟล์คู่หูบัดดี้ปัจจุบัน และกดยกเลิกการเป็นเพื่อนร่วมงาน (ยุบทีม) |
| **8** | **Wallet Balance Page** | [view_wallet_balance.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/view_wallet_balance/view_wallet_balance.dart) | **3.1.2.20 View Driver Wallet** | แสดงยอดเงินสะสมในกระเป๋าเงินสดของคนขับ พร้อมทางลัดไปหน้าถอนเงินและประวัติ |
| **9** | **Withdraw Wallet Page** | [withdraw_wallet.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/withdraw_wallet_page/withdraw_wallet.dart) | **3.1.2.21 Withdraw Wallet** | บันทึกคำขอถอนเงินออกจากกระเป๋าเงิน และอัปเดตยอดคงเหลือเข้าบัญชีพร้อมเพย์ |
| **10** | **Wallet History Page** | [view_wallet_history.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/view_wallet_history/view_wallet_history.dart) | **3.1.2.22 View Withdraw History** | เรียกดูรายการประวัติการถอนเงิน วันที่ จำนวนเงิน และสถานะการโอน |
| **11** | **Service Summary Page** | [service_summary_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/service_summary/service_summary_page.dart) | **3.1.2.19 View Service Summary** | เรียกดูรายงานสรุปผลการปฏิบัติงาน รายได้สะสม จำนวนเที่ยวขับ และเวลาออนไลน์ |
| **12** | **Driver Profile Page** | [profile_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/profile_page/profile_page.dart) | **3.1.2.2 View Driver Profile** | ดูข้อมูลส่วนตัวคนขับ คะแนนดาว เมนูการตั้งค่า และปุ่มออกจากระบบ |
| **13** | **Driver Profile Detail Page** | [driver_profile_detail_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/profile_page/driver_profile_detail_page.dart) | **List Review Receive** *(หน้า 27)*<br>**3.1.2.2 View Driver Profile** | ดูรายละเอียดคะแนนเรตติ้ง (1-5 ดาว) และรายการความคิดเห็น/รีวิวที่ได้รับจากลูกค้า |
| **14** | **Edit Profile Page** | [edit_profile_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/edit_profile_page/edit_profile_page.dart) | **3.1.2.3 Edit Driver Profile** | แก้ไขข้อมูลโปรไฟล์ส่วนตัว (ชื่อ-นามสกุล, อีเมล) |
| **15** | **Edit Car Page** | [edit_car_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/edit_car_page/edit_car_page.dart) | **3.1.2.4 Edit Driver Vehicle** | เพิ่ม/แก้ไขข้อมูลยานพาหนะ ยี่ห้อ รุ่น สี ป้ายทะเบียน และรูปถ่ายรถ |
| **16** | **User Reported History Page** | [user_reported_history_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/profile_page/user_reported_history_page.dart) | **3.1.2.17 List Reported User**<br>**3.1.2.18 View Reported User Detail** | แสดงรายการประวัติการร้องเรียนผู้ใช้บริการ และรายละเอียดสถานะการตรวจสอบ |
| **17** | **List Driver Report Page** | [Listdriverreport_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/Listdriverreport_page/Listdriverreport_page.dart) | **3.1.2.26 List Driver Reported** | ติดตามประวัติและสถานะเรื่องร้องเรียน/ปัญหาการใช้งานที่คนขับแจ้งต่อระบบ |

---

## 🔍 รายละเอียดของแต่ละหน้าจอและ Use Cases ตามเอกสาร SRS

### 1. หน้าจอ Login Page
- **หน้าจอในแอป:** [login_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/login_page/login_page.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.1 ยูสเคส Login Driver` (หน้า 61):**
    - **Actor:** Driver
    - **ข้อกำหนด (Requirements):**
      - `phoneNo`: ตัวเลข 10 หลัก ไม่เว้นวรรค และไม่เป็นค่าว่าง
      - `password`: ตัวอักษรภาษาอังกฤษ ตัวเลข อักขระพิเศษ `[!#_.]` ความยาว 8–16 ตัวอักษร
    - **การทำงาน:** ตรวจสอบข้อมูลผู้ขับขี่ในฐานข้อมูล หากถูกต้องจะดึงข้อมูลตัวตนและนำเข้าสู่ระบบ

---

### 2. หน้าจอ Map Page (ศูนย์กลางการรับงานและนำทาง)
- **หน้าจอในแอป:** [map_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/map_page/map_page.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.12 ยูสเคส View Notified Job` (หน้า 74):**
    - **Actor:** Driver (รับงานจาก User)
    - **การทำงาน:** แสดงป๊อปอัปแจ้งเตือนงานใหม่ ข้อมูลลูกค้า, จุดรับ, จุดส่ง, ราคาค่าโดยสาร, ชนิดเกียร์
  - **`3.1.2.13 ยูสเคส Approve Job` (หน้า 75):**
    - **Actor:** Driver
    - **การทำงาน:** ยืนยันรับงานบริการ หรือปฏิเสธงานภายในเวลาที่กำหนด
  - **`3.1.2.12 ยูสเคส View Notified Job By Pub` (หน้า 76):**
    - **Actor:** Driver (รับงานจากสถานบันเทิง)
    - **การทำงาน:** รับการแจ้งเตือนงานที่พนักงานสถานบันเทิงเรียกรถแทนลูกค้า
  - **`3.1.2.13 ยูสเคส Approve Job By Pub` (หน้า 77):**
    - **Actor:** Driver
    - **การทำงาน:** ยืนยันรับงานจากสถานบันเทิง
  - **`3.1.2.14 ยูสเคส View Service Info` (หน้า 78):**
    - **Actor:** Driver
    - **การทำงาน:** แสดงเส้นทางบนแผนที่ พิกัดต้นทาง ปลายทาง รายละเอียดรถลูกค้า และข้อมูลติดต่อผู้โดยสาร
  - **`3.1.2.15 ยูสเคส Update Service Status` (หน้า 79):**
    - **Actor:** Driver
    - **การทำงาน:** ปรับปรุงสถานะการเดินทาง (1. กำลังเดินทางไปรับ 2. ถึงจุดรับ 3. กำลังเดินทางไปส่ง 4. เสร็จสิ้น)

---

### 3. หน้าจอปิดงาน Finish Job Page
- **หน้าจอในแอป:** [finish_job_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/map_page/finish_job_page.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.15 ยูสเคส Update Service Status` (ขั้นตอนจบงาน):**
    - **Actor:** Driver
    - **การทำงาน:** บันทึกรูปถ่ายสถานที่ส่งมอบรถ/จอดรถเสร็จสิ้น, ปิดการให้บริการ และแสดง QR Code ชำระเงินกรณีเลือกชำระด้วยเงินสด

---

### 4. หน้าจอรายงานลูกค้า Report User Page
- **หน้าจอในแอป:** [report_user_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/map_page/report_user_page.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.16 ยูสเคส Report User` (หน้า 80):**
    - **Actor:** Driver
    - **การทำงาน:** ระบุประเภทการรายงาน (reportName เช่น พฤติกรรมลูกค้า), รายละเอียดเหตุการณ์ (reportDetail), วันที่ (reportDate) และแนบรูปภาพหลักฐาน (reportImagePath) เพื่อส่งเรื่องให้แอดมินตรวจสอบ

---

### 5. หน้าจอค้นหาและจับคู่บัดดี้ Search Buddy Page
- **หน้าจอในแอป:** [searchbuddy_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/searchbuddy_page/searchbuddy_page.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.5 ยูสเคส Search Buddy` (หน้า 67):**
    - **Actor:** Driver
    - **การทำงาน:** ค้นหาเพื่อนร่วมงานขับรถในระยะใกล้เคียงหรือตามชื่อ
  - **`3.1.2.6 ยูสเคส Send Buddy Request` (หน้า 68):**
    - **Actor:** Driver
    - **การทำงาน:** ส่งคำขอจับคู่เป็นบัดดี้ไปยังผู้ให้บริการขับรถอีกคน
  - **`3.1.2.7 ยูสเคส View Buddy Request` (หน้า 69):**
    - **Actor:** Driver
    - **การทำงาน:** แสดงรายการคำขอเข้าร่วมทีมที่ส่งมาถึงตนเอง
  - **`3.1.2.8 ยูสเคส Approve Request Buddy` (หน้า 70):**
    - **Actor:** Driver
    - **การทำงาน:** กดตอบรับ (Accept) หรือปฏิเสธ (Reject) คำขอเป็นคู่หูบัดดี้

---

### 6. หน้าจอทีมบัดดี้ปัจจุบัน My Buddy Page
- **หน้าจอในแอป:** [my_buddy_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/Mybuddy_page/my_buddy_page.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.9 ยูสเคส View My Buddy` (หน้า 71):**
    - **Actor:** Driver
    - **การทำงาน:** ดูข้อมูลและสถานะของเพื่อนร่วมงาน (บัดดี้) ที่กำลังทำงานร่วมกันอยู่ในปัจจุบัน
  - **`3.1.2.10 ยูสเคส End Buddy Service` (หน้า 72):**
    - **Actor:** Driver
    - **การทำงาน:** กดยกเลิกการทำงานร่วมกันหรือยุบทีมบัดดี้เพื่อแยกย้าย

---

### 7. หน้าจอกระเป๋าเงิน Wallet Balance Page
- **หน้าจอในแอป:** [view_wallet_balance.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/view_wallet_balance/view_wallet_balance.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.20 ยูสเคส View Driver Wallet` (หน้า 83):**
    - **Actor:** Driver
    - **การทำงาน:** เรียกดูยอดเงินสะสมคงเหลือในกระเป๋าเงินอิเล็กทรอนิกส์ของคนขับ

---

### 8. หน้าจอถอนเงิน Withdraw Wallet Page
- **หน้าจอในแอป:** [withdraw_wallet.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/withdraw_wallet_page/withdraw_wallet.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.21 ยูสเคส Withdraw Wallet` (หน้า 84):**
    - **Actor:** Driver
    - **ข้อกำหนด (Requirements):**
      - `Amount`: ต้องเป็นตัวเลขเท่านั้น ความยาว 3–4 หลัก (100–9,999 บาท) ไม่เป็นค่าว่าง
    - **การทำงาน:** กรอกจำนวนเงินที่ต้องการถอน ตรวจสอบยอดเงินคงเหลือ และส่งคำขอถอนเงินเข้าบัญชีพร้อมเพย์

---

### 9. หน้าจอประวัติการถอนเงิน Wallet History Page
- **หน้าจอในแอป:** [view_wallet_history.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/view_wallet_history/view_wallet_history.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.22 ยูสเคส View Withdraw History` (หน้า 85):**
    - **Actor:** Driver
    - **การทำงาน:** แสดงรายการประวัติการถอนเงิน วันที่ เวลา สถานะการทำรายการ และจำนวนเงินที่ถอน

---

### 10. หน้าจอสรุปผลงานและรายได้ Service Summary Page
- **หน้าจอในแอป:** [service_summary_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/service_summary/service_summary_page.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.19 ยูสเคส View Service Summary` (หน้า 83):**
    - **Actor:** Driver
    - **การทำงาน:** เรียกดูรายงานสรุปประสิทธิภาพการปฏิบัติงาน ยอดรายได้สะสม จำนวนเที่ยวขับ และเวลาออนไลน์ โดยสามารถกรองตามช่วงเวลาได้

---

### 11. หน้าจอโปรไฟล์คนขับ Driver Profile Page
- **หน้าจอในแอป:** [profile_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/profile_page/profile_page.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.2 ยูสเคส View Driver Profile` (หน้า 63):**
    - **Actor:** Driver
    - **การทำงาน:** ดูข้อมูลโปรไฟล์ตนเอง ชื่อ-นามสกุล, เบอร์โทรศัพท์, ข้อมูลรถ และเมนูสำหรับจัดการบัญชี

---

### 12. หน้าจอคะแนนรีวิวคนขับ Driver Profile Detail Page
- **หน้าจอในแอป:** [driver_profile_detail_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/profile_page/driver_profile_detail_page.dart)
- **Use Cases ในเล่ม SRS:**
  - **`List Review Receive` (Diagram หน้า 27):**
    - **Actor:** Driver
    - **การทำงาน:** ดูรายละเอียดคะแนนเรตติ้งดาวเฉลี่ย การกระจายตัวของเรตติ้ง (1–5 ดาว) และข้อความรีวิวประเมินจากลูกค้าผู้ใช้บริการ

---

### 13. หน้าจอแก้ไขข้อมูลส่วนตัว Edit Profile Page
- **หน้าจอในแอป:** [edit_profile_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/edit_profile_page/edit_profile_page.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.3 ยูสเคส Edit Driver Profile` (หน้า 64):**
    - **Actor:** Driver
    - **การทำงาน:** แก้ไขข้อมูลชื่อ-นามสกุล และอีเมลของผู้ให้บริการขับรถ

---

### 14. หน้าจอแก้ไขข้อมูลยานพาหนะ Edit Car Page
- **หน้าจอในแอป:** [edit_car_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/edit_car_page/edit_car_page.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.4 ยูสเคส Edit Driver Vehicle` (หน้า 65):**
    - **Actor:** Driver
    - **การทำงาน:** แก้ไขและบันทึกข้อมูลยานพาหนะ ยี่ห้อ, รุ่น, สี, ป้ายทะเบียน พร้อมอัปโหลดภาพถ่ายหน้ารถและข้างรถ

---

### 15. หน้าจอประวัติการรายงานผู้โดยสาร User Reported History Page
- **หน้าจอในแอป:** [user_reported_history_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/profile_page/user_reported_history_page.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.17 ยูสเคส List Reported User` (หน้า 81):**
    - แสดงรายการเรื่องร้องเรียนผู้โดยสารที่คนขับเคยแจ้งไว้
  - **`3.1.2.18 ยูสเคส View Reported User Detail` (หน้า 82):**
    - ดูรายละเอียดเหตุการณ์ รูปภาพหลักฐาน และสถานะการตรวจสอบ (กำลังตรวจสอบ/ตรวจสอบแล้ว)

---

### 16. หน้าจอประวัติรายงานปัญหาการใช้งาน List Driver Report Page
- **หน้าจอในแอป:** [Listdriverreport_page.dart](file:///Users/tim1zk_/FINAL_PROJECT/Safe-Seat-Project/lib/features/Listdriverreport_page/Listdriverreport_page.dart)
- **Use Cases ในเล่ม SRS:**
  - **`3.1.2.26 ยูสเคส List Driver Reported` (หน้า 91):**
    - ตรวจสอบรายการปัญหาการใช้งานหรือข้อร้องเรียนที่คนขับแจ้งไว้ต่อระบบแอดมิน
