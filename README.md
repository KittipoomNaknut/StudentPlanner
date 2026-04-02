# Student Planner

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white)

## แอปพลิเคชันช่วยจัดการชีวิตนักศึกษา — ตาราง, การบ้าน, คะแนน, โน้ต ในที่เดียว

`Version 1.0.0` · `Draft` · `Flutter Course — Week 4`

---

## สารบัญ

- [Student Planner](#student-planner)
  - [แอปพลิเคชันช่วยจัดการชีวิตนักศึกษา — ตาราง, การบ้าน, คะแนน, โน้ต ในที่เดียว](#แอปพลิเคชันช่วยจัดการชีวิตนักศึกษา--ตาราง-การบ้าน-คะแนน-โน้ต-ในที่เดียว)
  - [สารบัญ](#สารบัญ)
  - [ภาพรวมโครงการ](#ภาพรวมโครงการ)
    - [เป้าหมายผู้ใช้](#เป้าหมายผู้ใช้)
    - [Scope](#scope)
  - [Features](#features)
  - [สถาปัตยกรรมระบบ](#สถาปัตยกรรมระบบ)
    - [หลักการออกแบบ](#หลักการออกแบบ)
  - [โครงสร้างโฟลเดอร์](#โครงสร้างโฟลเดอร์)
  - [ฐานข้อมูล](#ฐานข้อมูล)
    - [`subjects` — วิชาทั้งหมด](#subjects--วิชาทั้งหมด)
    - [`assignments` — การบ้าน](#assignments--การบ้าน)
    - [`grades` — คะแนน](#grades--คะแนน)
    - [`schedules` — ตารางเรียน / สอบ](#schedules--ตารางเรียน--สอบ)
    - [`notes` — โน้ตสรุปวิชา](#notes--โน้ตสรุปวิชา)
  - [หน้าจอทั้งหมด](#หน้าจอทั้งหมด)
  - [Packages](#packages)
    - [Definition of Done](#definition-of-done)
  - [Coding Conventions](#coding-conventions)
    - [Naming](#naming)
    - [Model Template](#model-template)
  - [ประวัติเอกสาร](#ประวัติเอกสาร)

---

## ภาพรวมโครงการ

**Student Planner** คือแอปพลิเคชันสำหรับนักศึกษามหาวิทยาลัย ออกแบบมาเพื่อช่วยจัดการตารางเรียน การบ้าน คะแนน และบันทึกวิชาในที่เดียว โดยเน้นการใช้งานได้จริงในชีวิตประจำวัน ข้อมูลทั้งหมดเก็บบนอุปกรณ์ด้วย SQLite ไม่ต้องการ internet

### เป้าหมายผู้ใช้

- นักศึกษาระดับมหาวิทยาลัยที่ต้องการจัดการหลายวิชาพร้อมกัน
- ต้องการติดตามคะแนนและคำนวณ GPA อัตโนมัติ
- ต้องการระบบแจ้งเตือน deadline

### Scope

| ในขอบเขต | นอกขอบเขต |
| --- | --- |
| CRUD วิชา, ตาราง, การบ้าน, คะแนน, โน้ต | ระบบ Login / Authentication |
| Local Storage ด้วย SQLite | Cloud sync / Multi-device |
| Local Notification | Social features / Sharing |
| Dark / Light Theme | Export PDF |

---

## Features

| # | Feature | รายละเอียด | Priority |
| --- | --- | --- | --- |
| 1 | **Dashboard** | หน้าแรก แสดงสรุปงานที่ใกล้ deadline, ตารางวันนี้, GPA ล่าสุด | `Must Have` |
| 2 | **ตารางเรียน / สอบ** | เพิ่ม/แก้ไข/ลบตารางเรียนและตารางสอบ กำหนดวัน เวลา ห้อง | `Must Have` |
| 3 | **การบ้าน** | จัดการ assignment พร้อม deadline, priority, status | `Must Have` |
| 4 | **คะแนน / GPA** | บันทึกคะแนนแต่ละส่วน คำนวณเกรดและ GPA อัตโนมัติ | `Must Have` |
| 5 | **โน้ตสรุปวิชา** | บันทึกโน้ตอิสระแยกตามวิชา แก้ไขได้เสรี | `Should Have` |
| 6 | **แจ้งเตือน Deadline** | Local notification แจ้งก่อน deadline 1 วัน และ 1 ชั่วโมง | `Should Have` |
| 7 | **จัดการวิชา** | เพิ่ม/แก้ไข/ลบวิชา กำหนดสี อาจารย์ หน่วยกิต | `Must Have` |
| 8 | **Dark / Light Theme** | เปลี่ยน theme ได้ บันทึกด้วย SharedPreferences | `Nice to Have` |

---

## สถาปัตยกรรมระบบ

โปรเจคนี้ใช้ **Feature-first Architecture** โดยแบ่งโครงสร้างตาม feature ไม่ใช่ตาม layer เพื่อให้แต่ละ feature เป็นอิสระ สามารถเพิ่ม/แก้ไข/ลบได้โดยไม่กระทบส่วนอื่น

### หลักการออกแบบ

| หลักการ | การนำไปใช้ |
| --- | --- |
| **Single Responsibility** | แต่ละ class ทำหน้าที่เดียว — Model เก็บข้อมูล, Screen แสดงผล, Helper จัดการ DB |
| **DRY** | Widget ที่ใช้ซ้ำอยู่ใน `core/widgets/` ไม่ copy วางในแต่ละ feature |
| **Separation of Concerns** | UI (Screen) แยกจาก Data (Model) และ Storage (DatabaseHelper) |
| **Feature Isolation** | แต่ละ feature ใน `features/` แก้ได้อิสระ ไม่กระทบกัน |

---

## โครงสร้างโฟลเดอร์

```lib/
├── main.dart                    # Entry point — runApp()
├── app.dart                     # MaterialApp, ThemeData, Routes
│
├── core/
│   ├── database/                # DatabaseHelper — SQLite init & CRUD กลาง
│   ├── models/                  # Subject, Assignment, Grade, Schedule, Note
│   ├── theme/                   # AppTheme — สี, font, style ทั้ง app
│   └── widgets/                 # Shared widgets ใช้ร่วมกันหลาย feature
│
├── features/
│   ├── dashboard/               # หน้าแรก — สรุปภาพรวม
│   ├── subject/                 # จัดการวิชาทั้งหมด
│   ├── schedule/                # ตารางเรียน / ตารางสอบ
│   ├── assignment/              # การบ้าน CRUD + status
│   ├── grade/                   # คะแนนและ GPA calculator
│   ├── note/                    # โน้ตสรุปวิชา
│   └── notification/            # Local notification service
│
└── navigation/                  # Bottom Navigation Bar หลัก
```

---

## ฐานข้อมูล

- **Package:** `sqflite ^2.3.0` + `path_provider ^2.1.0`
- **Database file:** `student_planner.db`

### `subjects` — วิชาทั้งหมด

| Column | Type | Constraint | Description |
| --- | --- | --- | --- |
| `id` | INTEGER | PK AUTO | รหัสวิชา |
| `name` | TEXT | NOT NULL | ชื่อวิชา เช่น `Calculus I` |
| `code` | TEXT | — | รหัสวิชา เช่น `MTH101` |
| `color` | TEXT | NOT NULL | สี hex เช่น `#1565C0` |
| `teacher` | TEXT | — | ชื่ออาจารย์ |
| `credits` | INTEGER | DEFAULT 3 | จำนวนหน่วยกิต |

### `assignments` — การบ้าน

| Column | Type | Constraint | Description |
| --- | --- | --- | --- |
| `id` | INTEGER | PK AUTO | รหัส assignment |
| `subject_id` | INTEGER | FK NOT NULL | อ้างอิง `subjects.id` |
| `title` | TEXT | NOT NULL | ชื่องาน |
| `description` | TEXT | — | รายละเอียดเพิ่มเติม |
| `deadline` | TEXT | NOT NULL | วันส่ง ISO8601 เช่น `2568-03-15` |
| `status` | TEXT | DEFAULT `pending` | `pending` / `done` |
| `priority` | TEXT | DEFAULT `medium` | `low` / `medium` / `high` |

### `grades` — คะแนน

| Column | Type | Constraint | Description |
| --- | --- | --- | --- |
| `id` | INTEGER | PK AUTO | รหัสคะแนน |
| `subject_id` | INTEGER | FK NOT NULL | อ้างอิงวิชา |
| `name` | TEXT | NOT NULL | ชื่อการประเมิน เช่น `Midterm` |
| `score` | REAL | NOT NULL | คะแนนที่ได้ |
| `max_score` | REAL | NOT NULL | คะแนนเต็ม |
| `weight` | REAL | DEFAULT 1.0 | น้ำหนักคะแนน `0.0–1.0` |
| `type` | TEXT | — | `midterm` / `final` / `quiz` / `project` |

### `schedules` — ตารางเรียน / สอบ

| Column | Type | Constraint | Description |
| --- | --- | --- | --- |
| `id` | INTEGER | PK AUTO | รหัสตาราง |
| `subject_id` | INTEGER | FK NOT NULL | อ้างอิงวิชา |
| `type` | TEXT | NOT NULL | `class` / `exam` |
| `day_of_week` | INTEGER | — | `0`=จันทร์ … `6`=อาทิตย์ (สำหรับ class) |
| `date` | TEXT | — | วันที่สอบ ISO8601 (สำหรับ exam) |
| `start_time` | TEXT | NOT NULL | เวลาเริ่ม เช่น `09:00` |
| `end_time` | TEXT | NOT NULL | เวลาจบ เช่น `12:00` |
| `room` | TEXT | — | ห้อง เช่น `SC-101` |

### `notes` — โน้ตสรุปวิชา

| Column | Type | Constraint | Description |
| --- | --- | --- | --- |
| `id` | INTEGER | PK AUTO | รหัสโน้ต |
| `subject_id` | INTEGER | FK NOT NULL | อ้างอิงวิชา |
| `title` | TEXT | NOT NULL | หัวข้อโน้ต |
| `content` | TEXT | — | เนื้อหา |
| `updated_at` | TEXT | NOT NULL | วันที่แก้ไขล่าสุด ISO8601 |

---

## หน้าจอทั้งหมด

| # | Screen | Widget Type | หน้าที่ |
| --- | --- | --- | --- |
| 1 | `BottomNav` | StatefulWidget | Navigation หลัก 5 tabs |
| 2 | `DashboardScreen` | StatefulWidget | สรุปภาพรวม ดึงข้อมูลจาก DB |
| 3 | `ScheduleScreen` | StatefulWidget | แสดงตารางรายสัปดาห์ |
| 4 | `AddScheduleScreen` | StatefulWidget | Form เพิ่ม/แก้ไขตาราง |
| 5 | `AssignmentScreen` | StatefulWidget | รายการการบ้าน filter ตาม status |
| 6 | `AddAssignmentScreen` | StatefulWidget | Form เพิ่ม/แก้ไขการบ้าน |
| 7 | `GradeScreen` | StatefulWidget | รายการวิชา + GPA รวม |
| 8 | `GradeDetailScreen` | StatefulWidget | คะแนนแต่ละส่วนของวิชา |
| 9 | `NoteScreen` | StatefulWidget | รายการโน้ตทุกวิชา |
| 10 | `NoteDetailScreen` | StatefulWidget | อ่าน/แก้ไขโน้ต |
| 11 | `SubjectScreen` | StatefulWidget | จัดการวิชาทั้งหมด |
| 12 | `AddSubjectScreen` | StatefulWidget | Form เพิ่ม/แก้ไขวิชา |

---

## Packages

```yaml
dependencies:
  sqflite: ^2.3.0                    # SQLite database
  path_provider: ^2.1.0              # หา path สำหรับเก็บ database file
  shared_preferences: ^2.2.0         # เก็บ settings เช่น theme
  flutter_local_notifications: ^17.0.0  # Local notification แจ้งเตือน deadline
  intl: ^0.19.0                      # Format วันที่และเวลาภาษาไทย
  flutter_colorpicker: ^1.0.3        # Color picker สำหรับเลือกสีวิชา
table_calendar: ^3.1.0             # ปฏิทิน interactive สำหรับตารางสอบ

---

## แผนการพัฒนา

Phase 1 — Foundation          ████░░░░░░░░  1 คาบ
Phase 2 — Navigation + UI     ████░░░░░░░░  1 คาบ
Phase 3 — Subject + Assignment ████░░░░░░░░  1 คาบ
Phase 4 — Schedule + Grade    ████░░░░░░░░  1 คาบ
Phase 5 — Note + Notification  ████░░░░░░░░  1 คาบ
Phase 6 — Polish + Deploy      ████░░░░░░░░  1 คาบ
```

| Phase | หัวข้อ | งานที่ต้องทำ |
| --- | --- | --- |
| **1** | Foundation | สร้าง project, folder structure, DatabaseHelper, Models ทั้งหมด |
| **2** | Navigation + UI | BottomNav, AppTheme, Dashboard skeleton, core widgets |
| **3** | Subject + Assignment | CRUD วิชา, CRUD การบ้าน, Form validation, priority filter |
| **4** | Schedule + Grade | ตารางเรียน/สอบ, คะแนน, คำนวณ GPA อัตโนมัติ |
| **5** | Note + Notification | โน้ตวิชา, local notification, dashboard สมบูรณ์ |
| **6** | Polish + Deploy | Dark theme, empty states, bug fix, build APK |

### Definition of Done

- ทุก feature ผ่าน manual test บนอุปกรณ์จริง
- ข้อมูลอยู่รอดหลังปิด-เปิด app (SQLite persistent)
- ไม่มี crash บน Android 8.0 ขึ้นไป
- UI สามารถใช้งานได้บน screen ขนาด 5–6.5 นิ้ว
- Hot reload ไม่ทำให้ข้อมูลหาย

---

## Coding Conventions

### Naming

| สิ่งที่ตั้งชื่อ | รูปแบบ | ตัวอย่าง |
| --- | --- | --- |
| Class / Widget | UpperCamelCase | `AssignmentScreen`, `DatabaseHelper` |
| Variable / Method | lowerCamelCase | `_assignments`, `getSubjects()` |
| Private | `_` นำหน้า | `_count`, `_buildCard()` |
| Constant | lowerCamelCase | `const primaryColor = ...` |
| File | snake_case | `assignment_screen.dart` |
| Database Table | snake_case plural | `assignments`, `subjects` |

### Model Template

ทุก Model ต้องมีครบ 5 ส่วนนี้เสมอ:

```dart
class Subject {
  // 1. Fields — final, ประกาศชัดเจน
  final int? id;
  final String name;

  // 2. Constructor — named parameters, required/optional
  const Subject({this.id, required this.name});

  // 3. fromMap() — แปลง Map จาก SQLite เป็น object
  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
    id: map['id'],
    name: map['name'],
  );

  // 4. toMap() — แปลง object เป็น Map สำหรับบันทึก SQLite
  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  // 5. copyWith() — สร้าง object ใหม่จากของเดิม แก้ไขบางส่วน
  Subject copyWith({int? id, String? name}) => Subject(
    id: id ?? this.id,
    name: name ?? this.name,
  );
}
```

---

## ประวัติเอกสาร

| Version | วันที่ | รายละเอียด | ผู้แก้ไข |
| --- | --- | --- | --- |
| 1.0.0 | 2 เมษายน 2569 | จัดทำเอกสารครั้งแรก ครอบคลุม architecture, DB schema, screen inventory | Flutter Course Team |
