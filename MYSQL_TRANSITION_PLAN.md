# Local MySQL Architecture & Migration Guide (MYSQL_TRANSITION_PLAN.md)

> **Objective**: Complete architectural blueprint for migrating the AS Clinic application from Cloud Firestore to an on-premises local MySQL database running within a clinic's Local Area Network (LAN).

---

## 1. Context & Motivation

For small clinics, running a local database offers distinct advantages:
- **Zero Cloud Subscription Fees**: No recurring Firestore document read/write or storage costs.
- **Complete Data Sovereignty**: Patient health and financial records never leave the physical clinic premises.
- **Full Offline Operation**: Works seamlessly even during broadband ISP outages via the local clinic Wi-Fi router.

The current application was built using a modular service architecture (lib/services/firestore_service.dart), meaning the UI screens interact exclusively with state models, not raw database queries. Replacing Firestore with MySQL requires updating only the service layer.

---

## 2. Target Local Architecture

`
[ Reception Phone / Tablet ]        [ Doctor Phone / Tablet ]        [ Admin Console ]
             \                                |                               /
              \                               |                              /
               +------------------------------+-----------------------------+
                                              |
                                     (Local Clinic Wi-Fi)
                                              |
                                              v
                              +-------------------------------+
                              |    Clinic Local PC / Server   |
                              |   (Static IP: 192.168.1.100)  |
                              |                               |
                              |  +-------------------------+  |
                              |  | Node.js / FastAPI REST  |  |
                              |  | + WebSockets Server     |  |
                              |  +-------------------------+  |
                              |               |               |
                              |  +-------------------------+  |
                              |  |  MySQL 8.x Database     |  |
                              |  +-------------------------+  |
                              +-------------------------------+
`

---

## 3. Relational MySQL Schema (DDL)

Below is the complete, normalized SQL DDL schema corresponding to the active Firestore collections:

`sql
CREATE DATABASE IF NOT EXISTS clinic_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE clinic_db;

-- 1. Clinic Settings & Profile
CREATE TABLE clinic_settings (
    id VARCHAR(50) PRIMARY KEY DEFAULT 'general',
    clinic_name VARCHAR(150) NOT NULL,
    address TEXT,
    phone VARCHAR(30),
    working_hours VARCHAR(100),
    default_consultation_fee DECIMAL(10,2) DEFAULT 300.00,
    patient_id_prefix VARCHAR(10) DEFAULT 'P-',
    super_admin_claimed BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. User Accounts & Credentials
CREATE TABLE users (
    id VARCHAR(64) PRIMARY KEY, -- UUID
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    role ENUM('admin', 'doctor', 'staff', 'customer') NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Doctor Profiles
CREATE TABLE doctors (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64),
    full_name VARCHAR(150) NOT NULL,
    qualification VARCHAR(100),
    specialization VARCHAR(100),
    consultation_fee DECIMAL(10,2) NOT NULL DEFAULT 300.00,
    room_number VARCHAR(20),
    phone VARCHAR(30),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 4. Patients
CREATE TABLE patients (
    id VARCHAR(64) PRIMARY KEY,
    patient_no VARCHAR(50) UNIQUE NOT NULL, -- P-101, P-102
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    age INT,
    gender ENUM('Male', 'Female', 'Other'),
    blood_group VARCHAR(10),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_phone (phone),
    INDEX idx_patient_no (patient_no)
);

-- 5. Outpatient Visits & Token Queue
CREATE TABLE op_visits (
    id VARCHAR(64) PRIMARY KEY,
    token_number INT NOT NULL,
    visit_date DATE NOT NULL,
    patient_id VARCHAR(64) NOT NULL,
    doctor_id VARCHAR(64) NOT NULL,
    status ENUM('waiting', 'in_consultation', 'completed', 'cancelled') DEFAULT 'waiting',
    fee DECIMAL(10,2) NOT NULL,
    payment_method ENUM('cash', 'upi') NOT NULL,
    is_paid BOOLEAN DEFAULT FALSE,
    bp VARCHAR(20),
    pulse VARCHAR(20),
    temperature VARCHAR(20),
    weight_kg DECIMAL(5,2),
    height_cm DECIMAL(5,2),
    bmi DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE,
    INDEX idx_visit_date_doctor (visit_date, doctor_id)
);

-- 6. Consultation Case Notes
CREATE TABLE case_notes (
    id VARCHAR(64) PRIMARY KEY,
    visit_id VARCHAR(64) NOT NULL,
    patient_id VARCHAR(64) NOT NULL,
    doctor_id VARCHAR(64) NOT NULL,
    chief_complaints TEXT,
    clinical_findings TEXT,
    diagnosis VARCHAR(255),
    advice TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (visit_id) REFERENCES op_visits(id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE
);

-- 7. Electronic Prescriptions
CREATE TABLE prescriptions (
    id VARCHAR(64) PRIMARY KEY,
    visit_id VARCHAR(64) NOT NULL,
    patient_id VARCHAR(64) NOT NULL,
    doctor_id VARCHAR(64) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (visit_id) REFERENCES op_visits(id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE
);

CREATE TABLE prescription_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    prescription_id VARCHAR(64) NOT NULL,
    drug_name VARCHAR(150) NOT NULL,
    dosage VARCHAR(50),
    frequency VARCHAR(50),
    duration VARCHAR(50),
    instructions VARCHAR(100),
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE
);

-- 8. Payment Ledger
CREATE TABLE payments (
    id VARCHAR(64) PRIMARY KEY,
    visit_id VARCHAR(64),
    patient_id VARCHAR(64) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_type ENUM('op_fee', 'procedure', 'pharmacy') NOT NULL,
    method ENUM('cash', 'upi') NOT NULL,
    collected_by VARCHAR(64) NOT NULL,
    transaction_ref VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (collected_by) REFERENCES users(id)
);

-- 9. Cash Handover Ledger
CREATE TABLE cash_handovers (
    id VARCHAR(64) PRIMARY KEY,
    handover_date DATE NOT NULL,
    staff_user_id VARCHAR(64) NOT NULL,
    doctor_user_id VARCHAR(64) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'accepted', 'disputed') DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    FOREIGN KEY (staff_user_id) REFERENCES users(id),
    FOREIGN KEY (doctor_user_id) REFERENCES users(id)
);
`

---

## 4. Flutter Integration Layer (Repository Pattern)

To switch backend engines cleanly without modifying UI screens:

1. **Define an Abstract Repository Interface**:
   `dart
   abstract class IClinicRepository {
     Stream<List<OpVisit>> streamTodayQueue(String doctorId);
     Future<Patient> registerPatient(Patient patient);
     Future<void> issueOpToken(OpVisit visit);
     Future<void> recordPayment(Payment payment);
     Future<ClinicSettings> getClinicSettings();
     Future<void> updateClinicSettings(ClinicSettings settings);
   }
   `
2. **Current Implementation**:
   - FirestoreClinicRepository implementing IClinicRepository using FirebaseFirestore.instance.
3. **Local MySQL Implementation**:
   - MysqlRestClinicRepository implementing IClinicRepository using http.Client pointing to http://192.168.1.100:8080/api with WebSocket listeners for live queue updates.

---

## 5. Deployment Checklist for Local Server

1. **Hardware**: Any office PC, mini PC (e.g. Intel NUC), or old laptop running Windows 10/11 or Ubuntu.
2. **Software Stack**:
   - MySQL Community Server 8.0+
   - Node.js (v18+) or Python 3.11+
   - Local Wi-Fi router with static DHCP reservation (e.g. assigning 192.168.1.100 to the server).
3. **LAN Discovery**:
   - The Flutter mobile app can discover the local server via mDNS (Bonjour / Zeroconf) or a simple IP configuration field in the staff login screen.
