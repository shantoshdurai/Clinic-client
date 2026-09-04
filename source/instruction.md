# AS Clinic — AI Agent & Developer Master Guide (`instruction.md`)

> **Application**: AS Clinic (`com.maac.asclinic`)
> **Backend**: Google Firebase — Cloud Firestore + Firebase Auth (`asclinic-6cd9b`)
> **Framework**: Flutter 3.x / Dart (Android, iOS, Web)
> **State Management**: `Provider` (`ClinicStateProvider`)

---

## Table of Contents
1. [Project Overview & Architecture](#1-project-overview--architecture)
2. [Authentication & Roles](#2-authentication--roles)
3. [How to Manage Users, Doctors and Clinic Details](#3-how-to-manage-users-doctors-and-clinic-details)
4. [Firestore Database Schema & Collections](#4-firestore-database-schema--collections)
5. [File Navigation & Directory Structure](#5-file-navigation--directory-structure)
6. [Clinic Financial Ledger & Cash Handover Logic](#6-clinic-financial-ledger--cash-handover-logic)
7. [Developer Setup, Build & Deployment Commands](#7-developer-setup-build--deployment-commands)

---

## 1. Project Overview & Architecture

AS Clinic is an end-to-end outpatient healthcare management application designed
for real-world clinic workflows.

### Key Capabilities
- **Reception Desk (Staff)**
  - Patient registration with phone lookup (prevents duplicate records).
  - Structured patient IDs: `P-101`, `P-102`, … using a persisted high-water
    mark, so an ID is never handed to two people.
  - OP token generation with instant fee collection (`Cash` / `GPay / UPI`).
    Tokens restart at 1 each day and are derived from the tokens already issued
    today, so they never repeat.
  - Vitals capture with auto `/` formatting on BP and live BMI.
  - Cash handover ledger with multi-transfer batches to the doctor.
- **Doctor Cabin (Doctor)**
  - Live waiting queue and consultation history.
  - In-cabin procedure charges and collection.
  - Financial audit with 1-tap `Cash ↔ GPay` correction.
- **Super Admin Console**
  - Clinic identity, doctor roster and login accounts, all edited in-app and
    synced live. See [`SUPER_ADMIN_SETUP.md`](SUPER_ADMIN_SETUP.md).
- **Patient Mobile App**
  - Appointment booking. **Sign-in is still a preview** — see the Known Gap
    section of `SUPER_ADMIN_SETUP.md`.
- **Orientation & UI**
  - Portrait-locked. High-contrast clinical theme (`AppTheme`).

### Configuration is data, not code
Nothing clinical is hard-coded any more. Clinic name, address, phone, hours,
default fee, ID prefixes, the doctor roster and every login live in Firestore
and are edited from the Admin console. `lib/core/constants/clinic_data.dart`
holds only a placeholder branch and a generic starter pharmacy catalogue.

---

## 2. Authentication & Roles

### How a session is established
1. `AuthService.signInWithEmailPassword` authenticates against **Firebase Auth**.
2. The role is then read from **`users/{uid}`** in Firestore.
3. A signed-in account with no profile, an unknown role, or `active: false` is
   signed straight back out.

There is no offline or fallback path that hands out a privileged session, and
the role is never inferred from the email address.

### Roles (`UserRole` in `lib/models/user_role.dart`)
- `UserRole.admin` — Super Admin. Full clinic administration; inherits doctor
  and reception access.
- `UserRole.doctor` — Doctor Cabin (queue, clinical notes, procedure charges,
  revenue audit); inherits reception access.
- `UserRole.staff` — Reception Desk (OP token desk, patient DB, day closing,
  cash transfer).
- `UserRole.customer` — Patient self-service.

### Server-side enforcement
`firestore.rules` is the real access control; the UI hiding a screen is not.
Every rule is written against the collection names in
`lib/services/firestore_service.dart`. Deploy rules whenever they change:

```bash
firebase deploy --only firestore:rules,storage
```

### The single Super Admin
Claimed once via the in-app setup screen, gated by a setup key in
`lib/core/config/app_config.dart`. Claiming it writes
`clinic_settings/bootstrap`, which both the app and the security rules check —
so the claim closes permanently. The Admin console can create Doctor and
Reception accounts only; it cannot mint another admin.

---

## 3. How to Manage Users, Doctors and Clinic Details

**All of this is done in the running app. None of it requires a code change or
a new APK.**

### Change the doctor's name, qualification or fee
`Admin console → Doctors → tap the doctor → edit → Save`

The change reaches the OP desk, the waiting queue, prescriptions and bills on
every signed-in device immediately.

### Add a new doctor
`Admin console → Doctors → Add Doctor`

Then, to give them a login: `Admin console → Login Accounts → New Account →
Doctor`, and link it to the doctor profile you just created.

### Add a receptionist / staff nurse
`Admin console → Login Accounts → New Account → Reception`

Share the temporary password once; they can change it with **Forgot password**
on the sign-in screen.

### Change the clinic name, address, phone or hours
`Admin console → Clinic Profile`

### Remove someone's access
`Admin console → Login Accounts → Deactivate`. They are signed out immediately
and blocked from signing in again; their records stay intact.

> **For AI agents:** do not add doctors or users by editing
> `lib/core/constants/clinic_data.dart`. That file no longer carries clinic
> records, and anything added there would be overwritten by the Firestore
> stream on the next snapshot.

---

## 4. Firestore Database Schema & Collections

Real-time streams live in
[`lib/services/firestore_service.dart`](lib/services/firestore_service.dart).

| Collection | Written by | Notes |
|---|---|---|
| `clinic_settings/main` | Admin (plus staff for the patient-ID counter) | Clinic identity and billing defaults |
| `clinic_settings/bootstrap` | Setup, once | Marks the Super Admin as claimed |
| `users/{uid}` | Admin | Role, name, linked doctor/staff id, `active` |
| `doctors/{id}` | Admin | Roster shown at the OP desk |
| `patients/{id}` | Staff | Patient directory |
| `appointments/{id}` | Staff / Doctor | Queue sync |
| `op_visits/{id}` | Staff / Doctor | OP token, vitals, charges |
| `prescriptions/{id}` | Doctor | Rx with items |
| `case_notes/{id}` | Doctor | Consultation notes, incl. private notes |
| `payments/{id}` | Staff / Doctor | Bill and audit trail (delete: admin only) |
| `cash_handovers/{id}` | Staff | End-of-day cash transfers |
| `pharmacy_items/{id}` | Staff | Stock |
| `staff_attendance/{id}` | Staff | Daily check-in / check-out |

### `users`
```json
{
  "name": "Dr. Raj Saravanan",
  "email": "doctor@asclinic.com",
  "emailOrPhone": "doctor@asclinic.com",
  "role": "doctor",
  "doctorId": "doc_9f2a1c44",
  "staffId": null,
  "branchId": "main_clinic",
  "active": true,
  "createdAt": "2026-09-04T18:00:00.000Z"
}
```

### `clinic_settings/main`
```json
{
  "clinicName": "AS Clinic",
  "tagline": "General Health & Outpatient Care Centre",
  "address": "Main Road, Clinic Centre",
  "phone": "+91 94431 23456",
  "workingHours": "08:30 AM - 08:30 PM (Mon - Sat)",
  "defaultConsultationFee": 500,
  "patientIdPrefix": "P-",
  "patientIdStart": 104,
  "billPrefix": "BILL"
}
```

### `op_visits`
```json
{
  "id": "uuid-v4",
  "opNumber": "OP-20260904-01",
  "tokenNumber": 1,
  "patientId": "P-101",
  "patientName": "Ramesh Kannan",
  "doctorId": "doc_9f2a1c44",
  "doctorName": "Dr. Raj Saravanan, MD",
  "reasonForVisit": "Fever and headache",
  "status": "waiting",
  "consultationFee": 500.0,
  "amountPaid": 500.0,
  "balance": 0.0,
  "createdAt": "2026-09-04T10:05:00.000Z"
}
```

### `payments`
```json
{
  "billNumber": "BILL-20260904-01",
  "patientId": "P-101",
  "consultationFee": 500.0,
  "procedureCharges": 0.0,
  "totalAmount": 500.0,
  "paidToNurse": 500.0,
  "paidToDoctor": 0.0,
  "nursePaymentMode": "cash",
  "doctorPaymentMode": "upi",
  "collectedByName": "Revathi M.",
  "paymentDate": "2026-09-04T10:05:00.000Z"
}
```

---

## 5. File Navigation & Directory Structure

```
c:\WORk\Doc-project\
├── android/app/
│   ├── build.gradle.kts               # Application ID: com.maac.asclinic
│   └── google-services.json           # Firebase config (asclinic-6cd9b)
├── firestore.rules                    # Server-side access control (deploy this)
├── storage.rules
├── SUPER_ADMIN_SETUP.md               # Owner-facing setup & handover guide
├── lib/
│   ├── main.dart                      # Entry point, portrait lock, session restore
│   ├── core/
│   │   ├── config/app_config.dart     # Setup key + pre-login fallbacks
│   │   ├── constants/clinic_data.dart # Placeholder branch + starter pharmacy only
│   │   └── theme/app_theme.dart
│   ├── models/                        # Patient, OpVisit, Payment, Doctor, ClinicSettings, AppUser…
│   ├── providers/
│   │   └── clinic_state_provider.dart # Central state + Firestore stream lifecycle
│   ├── services/
│   │   ├── auth_service.dart          # Sign-in, role resolution, account provisioning
│   │   ├── firebase_config.dart
│   │   └── firestore_service.dart     # Real-time CRUD + streams
│   └── features/
│       ├── admin/                     # Console, Clinic Profile, Doctors, Login Accounts
│       ├── auth/                      # Patient OTP, staff sign-in, Super Admin bootstrap
│       ├── billing/                   # Revenue audit & cash handover
│       ├── common/widgets/            # ClinicAppBar, quick contact, stat card
│       ├── customer/                  # Patient self-service
│       ├── doctor/                    # Queue, consultation, in-cabin billing
│       ├── pharmacy/                  # Inventory
│       └── staff/                     # OP token desk, patient DB, vitals
├── test/
│   ├── clinic_workflows_test.dart     # Workflow + authorisation tests
│   └── widget_test.dart
└── instruction.md
```

---

## 6. Clinic Financial Ledger & Cash Handover Logic

### Core formulas
- **Total clinic revenue** = nurse counter collections + doctor cabin collections
- **Nurse counter collections** = physical cash collected + GPay/UPI collected
- **Physical cash in hand** = `max(0, cash collected today − cash handed over today)`

Exposed as `ClinicStateProvider.physicalCashInHand`.

### Rules
1. **Bounded transfers** — a transfer is capped at physical cash in hand.
2. **UPI separation** — UPI goes to the bank and is never counted as cash in hand.
3. **Multi-transfers** — cash can be handed over in batches through the day.
4. **Auto-reactivation** — a new cash payment raises cash in hand and re-enables
   the transfer button with no manual reset.
5. **1-tap mode switcher** — the doctor can flip a transaction between
   `💵 Cash` and `📱 GPay` to correct a reception entry error.
6. **Today only** — every revenue figure is filtered to the current calendar
   date. There are no illustrative or padded numbers anywhere in the reports.

---

## 7. Developer Setup, Build & Deployment Commands

### Static analysis and tests
```bash
flutter analyze
flutter test
```

### Deploy security rules (required after changing them)
```bash
firebase deploy --only firestore:rules,storage
```

### Debug on a USB device
```bash
flutter run
```

### Release APK (split per ABI)
```bash
flutter build apk --release --split-per-abi
```
Outputs to `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` — modern 64-bit phones
- `app-armeabi-v7a-release.apk` — older 32-bit phones

### Install on a connected phone
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
```

### Launch on device
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell am start -n com.maac.asclinic/com.example.clinic_app.MainActivity
```
