# Clinic Management System — Requirements & Specifications (REQUIREMENTS.md)

> **Application Name**: AS Clinic Management System  
> **Client / Organization**: Outpatient Healthcare Clinic  
> **Target Release Package**: Android ARM64-v8a Release APK (pk/app-arm64-v8a-release.apk)  
> **Core Architecture**: Flutter 3.x Frontend • Google Firebase Backend (Firestore & Auth) • Transition Ready for Local MySQL / REST API  

---

## 1. Executive Summary & Business Goals

The AS Clinic Management Application is a multi-role, production-grade outpatient clinical workflow and practice management system. It replaces manual paper ledgers, fragmented records, and hardcoded clinic logic with a dynamic, real-time clinical platform.

### Core Objectives
1. **Role-Specific Operating Environments**: Distinct, dedicated operational flows for Super Administrator, Doctor Cabin, Reception Desk (Staff), and Outpatient Customers.
2. **Zero-Hardcoding Dynamic Configuration**: All clinic parameters (clinic name, branding, address, phone numbers, consultation fees, operating hours, ID prefixes, and doctor rosters) are stored in the database and manageable directly from the mobile Admin Console without recompiling the application.
3. **Patient Identification & Duplicate Avoidance**: Automated sequential patient ID allocation (P-101, P-102, ...) backed by a persistent high-water mark counter, coupled with duplicate detection by phone number.
4. **Deterministic Token System**: Daily queue token numbers resetting cleanly at 1 each morning, preventing duplicate token assignment across reception desks.
5. **Dual Payment & Cash Handover Auditing**: Real-time tracking of consultation and procedure fees across payment modes (Cash and GPay / UPI), complete with physical cash handover reconciliation between reception staff and the doctor.
6. **Robust Role-Based Security**: Cryptographically verified server-side security rules protecting patient medical confidentiality, financial ledgers, and administrative access.

---

## 2. System Architecture & Tech Stack

`
+-------------------------------------------------------------------------+
|                              Flutter Client                             |
|  +--------------------+  +--------------------+  +-------------------+  |
|  | Super Admin Panel  |  |   Doctor Cabin     |  |  Reception Desk   |  |
|  +--------------------+  +--------------------+  +-------------------+  |
|  +-------------------------------------------------------------------+  |
|  |               ClinicStateProvider (State Management)              |  |
|  +-------------------------------------------------------------------+  |
+------------------------------------+------------------------------------+
                                     |
                +--------------------+--------------------+
                |                                         |
                v                                         v
+-------------------------------+       +---------------------------------+
|  Google Cloud Firebase        |       |  Local Clinic LAN (Future Stage)|
|  - Firebase Auth (Role-gated) |       |  - Node.js / FastAPI Service    |
|  - Cloud Firestore (Live sync)|       |  - MySQL 8.x Local Server       |
|  - Cloud Storage (Images/PDF) |       |  - Local Wi-Fi Sync             |
|  - Firebase Cloud Messaging   |       +---------------------------------+
+-------------------------------+
`

### Technology Specifications
- **Client Framework**: Flutter 3.x / Dart (Sound Null Safety)
- **Target OS**: Android 8.0+ (API Level 26+)
- **Target ABI**: rm64-v8a (Optimized 64-bit release build)
- **Orientation**: Portrait-Locked (DeviceOrientation.portraitUp) for ergonomic single-hand usage
- **Theme**: High-contrast Medical UI (AppTheme with clean clinical palettes, high legibility cards, and tactile buttons)
- **Backend (Active)**: Cloud Firestore + Firebase Authentication (sclinic-6cd9b)
- **Backend (Local Roadmap)**: Relational MySQL 8.x with REST API abstraction layer

---

## 3. User Roles & Privilege Matrix

| Role | Access Level | Primary Responsibilities | Handover Permissions |
|---|---|---|---|
| **Super Admin** (dmin) | Full System Authority | Clinic configuration, doctor roster management, user account provisioning, financial audits, security oversight. | Full Read / Write on all collections. Can provision staff and doctor accounts. |
| **Doctor** (doctor) | Clinical & Billing Authority | Live waiting queue, clinical case notes, diagnoses, electronic prescriptions, in-cabin procedure charges, financial audit. | Can view assigned patients, create case notes, add procedure fees, and accept cash handovers. |
| **Reception Staff** (staff) | Front Desk Operations | Patient registration, OP token issuance, vitals capture, fee collection, appointment scheduling, daily cash handover. | Can register patients, issue OP visits, record fee payments, and initiate cash handovers. |
| **Patient / Customer** (customer) | Outpatient Self-Service | Viewing clinic profile, doctor schedules, requesting appointments, and accessing personal medical history. | Read access to own profile, appointments, and prescriptions only. |

---

## 4. Detailed Functional Requirements

### 4.1 Super Administrator & Identity Management
- **REQ-ADM-01 (Single Super Admin Claim)**:
  - When the app is deployed for the first time, a setup screen appears allowing the clinic owner to initialize the Super Admin account.
  - The bootstrap is protected by a server-verified Setup Key (AppConfig.adminSetupKey).
  - Upon completion, the system records clinic_settings/bootstrap, permanently closing the initialization portal. No additional admin accounts can be self-created.
- **REQ-ADM-02 (Dynamic Clinic Settings)**:
  - Super Admin can update Clinic Name, Address, Contact Phone, Operating Hours, Default Consultation Fee, and Patient ID Prefix directly inside the app.
  - Changes reflect instantly across all staff and doctor devices via real-time stream listeners without requiring app updates.
- **REQ-ADM-03 (Doctor Roster Management)**:
  - Super Admin can dynamically add new doctors, update qualifications, set consultation fees, define room numbers, adjust weekly availability, and activate/deactivate doctor profiles.
  - Replaces all hardcoded doctor lists with dynamic Firestore records.
- **REQ-ADM-04 (Staff & Doctor User Account Provisioning)**:
  - Super Admin can create login accounts for doctors and reception staff with predefined emails and passwords.
  - Accounts are tagged with ctive: true and the corresponding UserRole.
  - Deactivated accounts (ctive: false) are immediately locked out and terminated upon authentication.

### 4.2 Reception & Front-Desk Operations
- **REQ-STF-01 (Patient Registration & Lookup)**:
  - Staff can register new patients with Name, Phone, Age, Gender, Blood Group, and Address.
  - Live phone number lookup detects existing patient records instantly to avoid duplicate registrations.
- **REQ-STF-02 (Deterministic Patient ID)**:
  - Patient IDs follow a configured pattern (e.g., P-101, P-102).
  - IDs are generated via a high-water mark counter transaction, ensuring unique sequential IDs across concurrent desks.
- **REQ-STF-03 (OP Token & Daily Reset)**:
  - Daily OP tokens start at 1 each morning and increment strictly per day.
  - Staff select the target doctor, assign token numbers, and queue the patient for consultation.
- **REQ-STF-04 (Vitals Entry)**:
  - Real-time vitals recording: Blood Pressure (auto-formatted with /, e.g., 120/80), Pulse Rate, Temperature, Weight (kg), and Height (cm).
  - Live calculation and classification of Body Mass Index (BMI).
- **REQ-STF-05 (Fee Collection & Receipting)**:
  - Immediate OP consultation fee collection.
  - Flexible payment mode selection (Cash vs. GPay / UPI).
  - Digital receipt generation with timestamp, staff ID, and transaction reference.

### 4.3 Doctor Cabin & Consultation
- **REQ-DOC-01 (Live OPD Waiting Queue)**:
  - Real-time queue showing waiting, in-consultation, and completed patients for the logged-in doctor.
  - Visual status chips indicating wait time and vitals preview.
- **REQ-DOC-02 (Patient History Inspection)**:
  - 1-tap access to previous visit logs, prior diagnoses, past prescriptions, and recurring vitals trends.
- **REQ-DOC-03 (Case Notes & Diagnosis)**:
  - Clinical note-taking: Chief Complaints, Clinical Observations, Provisional Diagnosis, and Advice.
- **REQ-DOC-04 (Digital Prescriptions)**:
  - Multi-item prescription drafting: Drug Name, Dosage, Frequency (Morning/Noon/Night), Duration (Days), and Instructions (Before/After Food).
- **REQ-DOC-05 (In-Cabin Procedure Charges)**:
  - Doctor can add charges for specialized procedures (e.g., nebulization, ECG, dressing, injections).
  - Fees are added to the patient's visit bill and flagged for collection.
- **REQ-DOC-06 (Daily Revenue Audit & Reconciliation)**:
  - Real-time audit dashboard showing total patient count, total revenue, Cash total, and UPI total.
  - 1-tap Cash <-> UPI correction button to rectify mislabeled cashier entries before day-end closing.

### 4.4 Financial Ledger & Cash Handover
- **REQ-FIN-01 (Immutable Payment Ledger)**:
  - Every financial transaction is recorded with a unique ID, visit reference, patient reference, amount, payment method, collected-by UID, and server timestamp.
- **REQ-FIN-02 (Reception-to-Doctor Cash Handover)**:
  - Reception staff can initiate physical cash transfers to the doctor at shift end or when cash accumulates.
  - Doctor receives a handover notification and must explicitly verify and accept the handover batch.
  - Multi-transfer batches are tracked so discrepancies are pinpointed to specific shifts.

### 4.5 Security & Data Integrity
- **REQ-SEC-01 (Server-Side Role Enforcement)**:
  - Access permissions are enforced by Firestore Security Rules (irestore.rules). Client UI state is never trusted as security.
  - Roles are verified against /users/{uid}.
- **REQ-SEC-02 (Authentication Safeguards)**:
  - Accounts with missing profiles, undefined roles, or ctive == false are immediately evicted.
  - Email/Password authentication enforced via Firebase Auth.
- **REQ-SEC-03 (Offline Resiliency & Write Timeouts)**:
  - App employs local Firestore offline caching for read resilience.
  - Network writes are wrapped with robust timeouts to prevent infinite UI spinning during Wi-Fi drops.

---

## 5. Data Model & Schema

`
collections/
├── clinic_settings/
│   ├── general              -> { clinicName, address, phone, workingHours, defaultFee, patientIdPrefix, ... }
│   └── bootstrap            -> { superAdminClaimed: true, claimedAt, superAdminUid }
├── users/
│   └── {uid}                -> { email, fullName, role ('admin'|'doctor'|'staff'|'customer'), active, createdAt }
├── doctors/
│   └── {doctorId}           -> { fullName, qualification, specialization, consultationFee, roomNumber, phone, active }
├── patients/
│   └── {patientId}          -> { patientNo ('P-101'), fullName, phone, age, gender, bloodGroup, address, createdAt }
├── op_visits/
│   └── {visitId}            -> { tokenNumber, date, patientId, doctorId, status, vitals: {...}, fee, paymentMethod, paid }
├── case_notes/
│   └── {noteId}             -> { visitId, patientId, doctorId, complaints, diagnosis, notes, timestamp }
├── prescriptions/
│   └── {prescriptionId}     -> { visitId, patientId, doctorId, items: [ { drugName, dosage, timing, duration } ], date }
├── payments/
│   └── {paymentId}          -> { visitId, patientId, amount, type ('op_fee'|'procedure'), method ('cash'|'upi'), collectedBy, timestamp }
└── cash_handovers/
    └── {handoverId}         -> { date, staffUid, doctorUid, amount, status ('pending'|'accepted'|'disputed'), handedOverAt }
`

---

## 6. Non-Functional Requirements

| Metric | Requirement | Verification Method |
|---|---|---|
| **Launch Time** | Cold start < 2.0s on mid-tier Android devices | Automated profiling & device stopwatch |
| **Data Sync Latency** | Queue and token updates propagate within < 500ms on 4G/Wi-Fi | Firestore real-time snapshot test |
| **Offline Tolerance** | Retains read-access to queue and patient lists when network drops | Disconnect Wi-Fi during local test |
| **Package Size** | ARM64 Release APK under 25 MB (current: **20.8 MB**) | APK build artifact inspection |
| **Crash-Free Rate** | Zero fatal crashes on unhandled state transitions | ClinicStateProvider guard clauses & null-safe tests |
| **Test Coverage** | Comprehensive unit & integration tests for all primary clinical workflows | 18 Flutter tests + 38 Firestore rule tests passing |

---

## 7. APK Delivery & Deployment Details

- **Release Package Path**: pk/app-arm64-v8a-release.apk
- **Architecture**: rm64-v8a (Android 64-bit ARM)
- **File Size**: ~20.8 MB (20,829,341 bytes)
- **Application ID**: com.maac.asclinic
- **Build Mode**: Release (Obfuscated & optimized, debug flags stripped)
- **Local Testing Guide**: Refer to SUPER_ADMIN_SETUP.md and MYSQL_TRANSITION_PLAN.md for complete configuration and local verification steps.
