# AS Clinic Management Application — Requirements & System Guide (`REQUIREMENTS.md`)

> **Application**: AS Clinic Management System (`com.maac.asclinic`)  
> **Release Package**: Android ARM64-v8a Release APK (`apk/app-arm64-v8a-release.apk`)  
> **Backend Platform**: Google Firebase (Firebase Auth & Cloud Firestore)  
> **Framework**: Flutter 3.x / Dart (Portrait-locked, high-contrast clinical theme)  

---

## 1. Project Overview & Clinical Scope

AS Clinic is an outpatient healthcare management application designed for small clinics to streamline daily clinical, administrative, and financial operations.

### Key Problems Solved
- **No Hardcoded Information**: Clinic name, address, phone numbers, working hours, consultation fees, and doctor details are not hardcoded. Everything is stored dynamically in Firestore and can be updated live from the Super Admin panel inside the app without rebuilding the APK.
- **Role-Based Workflows**: Separate, secure access for Super Admin, Doctors, Reception Staff, and Patients.
- **Deterministic Patient & Queue Management**: Daily OP tokens start cleanly at 1 each morning. Patient IDs follow a continuous sequence (`P-101`, `P-102`, ...) with phone lookup to prevent duplicate records.
- **Accurate Financial Reconciliation**: Tracks both Cash and GPay / UPI payments, allows doctor audits with 1-tap correction, and manages structured cash handovers from reception staff to the doctor.

---

## 2. User Roles & Access Rights

| Role | Interface | Core Responsibilities |
|---|---|---|
| **Super Admin** (`admin`) | Admin Console | Clinic profile settings, dynamic doctor roster management, staff/doctor login creation, overall financial audits. |
| **Doctor** (`doctor`) | Doctor Cabin | Live waiting queue, clinical consultation, case notes, electronic prescriptions, in-cabin procedure fees, revenue audit. |
| **Reception Staff** (`staff`) | Front Desk | Patient registration, OP token generation, vitals entry (BP, Pulse, BMI), fee collection, shift cash handover. |
| **Patient / Customer** (`customer`) | Mobile Portal | Viewing clinic hours, doctor profiles and availability, requesting appointments, and viewing past prescriptions. |

---

## 3. Functional Requirements

### 3.1 Super Administrator & Dynamic Clinic Configuration
- **One-Time Super Admin Claim**:
  - On first launch, the clinic owner claims the Super Admin account via the setup screen gated by a secure Setup Key (`AS-CLINIC-SETUP-9271`).
  - Once claimed, the bootstrap gate permanently closes in both app logic and Firestore security rules.
- **Dynamic Clinic Profile**:
  - Super Admin can change the clinic name, address, contact numbers, working hours, and default consultation fee in real-time.
  - Updates sync across all doctor and staff devices immediately.
- **Doctor Roster Management**:
  - Super Admin can add new doctors, update qualifications, set individual consultation fees, assign room numbers, and toggle doctor active status.
- **User Account Management**:
  - Super Admin can create login accounts for doctors and reception staff.
  - Accounts can be activated or deactivated at any time.

### 3.2 Reception & Front Desk Operations
- **Patient Registration & Duplicate Check**:
  - Register patients with Name, Phone, Age, Gender, Blood Group, and Address.
  - Phone lookup prevents creating duplicate records for returning patients.
- **Patient ID Sequence**:
  - Auto-assigns sequential IDs (`P-101`, `P-102`, ...) using a persistent counter.
- **Daily OP Token Issuance**:
  - OP tokens reset automatically to `1` every day and increment per patient visit.
  - Staff select the doctor and issue tokens directly into the doctor's live queue.
- **Vitals Capture**:
  - Records Blood Pressure (auto-formatted e.g. `120/80`), Pulse, Temperature, Height, and Weight.
  - Calculates and displays live BMI.
- **Fee Collection**:
  - Immediate OP fee collection supporting both `Cash` and `GPay / UPI`.

### 3.3 Doctor Cabin & Consultation
- **Live OPD Waiting Queue**:
  - Real-time queue displaying waiting, in-consultation, and completed patients.
- **Patient History & Vitals Review**:
  - Instant access to previous visit logs, prior diagnoses, and current vitals.
- **Clinical Notes & Diagnosis**:
  - Enter Chief Complaints, Clinical Observations, Provisional Diagnosis, and Advice.
- **Electronic Prescriptions**:
  - Add medications with Drug Name, Dosage, Frequency, Duration, and Instructions (Before/After Food).
- **In-Cabin Procedure Charges**:
  - Add charges for specialized treatments or tests (e.g., nebulization, ECG, dressing) to the patient's bill.
- **Doctor Revenue Audit**:
  - View total daily consultations, Cash collections, and UPI collections.
  - 1-tap `Cash <-> UPI` correction button to rectify any cashier entry mistakes before closing.

### 3.4 Cash Handover & Financial Ledger
- **Shift Cash Transfer**:
  - Reception staff can initiate a physical cash handover to the doctor at shift end.
  - Doctor reviews the amount and confirms receipt, maintaining an accountable audit trail.

### 3.5 Session Persistence & Smart Navigation
- **Persistent Auto-Login ("Save Login")**:
  - On login, the session is saved securely on the device.
  - Closing and reopening the app opens directly into the user's dashboard (Admin Console, Doctor Cabin, or Reception Desk) without prompting for passwords or displaying the patient welcome screen.
  - A "Save login" option is available on the staff sign-in screen, with email remembering enabled.
  - Sessions remain active until explicitly terminated via the **Sign out** button.
- **Root App Back-Button Navigation**:
  - Pressing the Android back button inside sub-tabs returns smoothly to the home tab.
  - Pressing the back button on the root dashboard minimizes the application to the background rather than kicking the user back to the login screen.

---

## 4. Quick Setup & Device Installation

### 4.1 Installing the APK on Phone
The release APK is located in the repository under:
`apk/app-arm64-v8a-release.apk`

- **Via Direct Transfer**:
  1. Transfer `apk/app-arm64-v8a-release.apk` to your Android phone (via USB, Drive, or messaging).
  2. Tap the file in Downloads and allow installation from unknown sources.
- **Via USB Debugging (ADB)**:
  ```bash
  adb install -r apk/app-arm64-v8a-release.apk
  ```

### 4.2 Super Admin Initial Access & User Account Setup
The app provides a primary administrator account so the clinic owner / doctor can immediately enter and configure their clinic:

- **Super Admin Email**: `admin@clinic.com`
- **Super Admin Password**: `admin123`

#### How to set up Doctors and Staff accounts:
1. Sign in with the **Super Admin** credentials on the Staff Sign In screen.
2. In the Admin Panel, go to **Clinic Configuration → Doctors** to add your doctors (name, specialty, fees, timing).
3. Go to **Clinic Configuration → Login Accounts** and tap **+ New Account** to create login credentials (email & password) for each Doctor and Receptionist/Nurse.
4. Staff and Doctors can now sign in with their respective accounts to access their dedicated cabin and front-desk consoles.

### 4.3 Changing Super Admin Credentials
The clinic owner can change the administrator name, email, and password at any time:
1. Sign in as Super Admin (`admin@clinic.com` / `admin123`).
2. Go to **Admin Console**.
3. Under **Clinic Configuration**, tap **Admin Credentials**.
4. Enter the new Administrator Name, Email, and Password.
5. Tap **Save Changes**. The updated credentials take effect immediately across all sessions.
