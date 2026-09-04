# AS Clinic — Super Admin Setup & Handover

Everything the clinic owner can now change **from the phone, without a new app
build**: clinic name, address, phone, working hours, default consultation fee,
patient ID format, the doctor roster, and who is allowed to sign in.

---

## 1. One-time Firebase setup (5 minutes, do this first)

Open the [Firebase console](https://console.firebase.google.com/) for project
**`asclinic-6cd9b`**.

### a) Turn on Email/Password sign-in
`Build → Authentication → Sign-in method → Email/Password → Enable → Save`

Without this, nobody can sign in and you will see
*"Email/password sign-in is not enabled on this Firebase project."*

### b) Deploy the security rules
The rules in this repo are what actually protect patient data — the app's UI
hiding a screen is not protection on its own.

```bash
firebase deploy --only firestore:rules,storage
```

If you do not have the Firebase CLI, paste the contents of `firestore.rules`
into `Build → Firestore Database → Rules → Publish`, and `storage.rules` into
`Build → Storage → Rules → Publish`.

> **Do this before handing the app to anyone.** Until the rules are deployed,
> the database is running on whatever rules are currently live in the console.

The rules ship with their own test suite (38 checks: patient data closed to the
public, reception unable to act as admin, the Super Admin claim closing after
first use). Run it after any rules change:

```bash
cd firestore_rules_test && npm install && npm test
```

---

## 2. Claim the Super Admin account (once, on the first phone)

1. Install the APK and open it.
2. Tap **Clinic staff sign in** (top right of the patient screen).
3. A yellow **"Clinic not set up yet"** panel appears — tap **Set up Super Admin**.
4. Fill in:
   - **Clinic Name** — e.g. `AS Clinic`
   - **Administrator Full Name**
   - **Admin Email** — this becomes the login
   - **Password** — at least 8 characters
   - **Setup Key** — see below
5. Tap **Create Super Admin**. You land straight in the Admin console.

### The setup key
It is defined in [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart):

```dart
static const String superAdminSetupKey = 'AS-CLINIC-SETUP-9271';
```

**Change this string and rebuild before shipping the APK to anyone outside the
team.** It stops someone who gets an early copy of the APK from claiming the
clinic before the owner does.

### Why this screen disappears afterwards
Creating the Super Admin writes `clinic_settings/bootstrap` in Firestore. Both
the app *and* the security rules check for that document, so the setup screen
cannot be re-opened — not by reinstalling, not by clearing app data, and not by
a modified build. There is exactly one Super Admin, and it is claimed once.

**Alternative, if you prefer the console:** create the user under
`Authentication → Users → Add user`, then create a Firestore document at
`users/<that user's UID>` with:

```json
{
  "name": "Clinic Owner",
  "email": "admin@yourclinic.com",
  "emailOrPhone": "admin@yourclinic.com",
  "role": "admin",
  "active": true,
  "branchId": "main_clinic"
}
```

...and a document at `clinic_settings/bootstrap` with `{ "adminCreated": true }`.

---

## 3. What the Super Admin can do

The Admin console shows a **setup checklist** until all three are done.

### Clinic Profile
`Admin → Clinic Profile`

| Field | Where it shows up |
|---|---|
| Clinic Name | App bar, patient welcome screen, staff sign-in |
| Tagline | Under the clinic name |
| Address, Locality | Patient booking confirmation |
| Phone, WhatsApp | Quick-contact sheet |
| Working Hours | Patient-facing screens |
| Registration / GST number | Stored for billing |
| Default Consultation Fee | Pre-fills the OP desk fee box |
| Patient ID Prefix | `P-` gives `P-101`, `P-102`… |
| Bill Number Prefix | `BILL` gives `BILL-20260904-01` |

Saving writes one Firestore document. **Every signed-in phone updates within a
second** — no reinstall, no app-store update.

### Doctors
`Admin → Doctors`

Add, edit, hide or delete doctors: name, qualification, specialty, experience,
consultation fee, contact number. The name entered here is what appears on OP
tokens, the waiting queue, prescriptions and bills.

- **Hide** stops new bookings but keeps historical records intact.
- **Delete** removes the roster entry; past visits keep the recorded name.

### Login Accounts
`Admin → Login Accounts`

Create a real Firebase login for each doctor and each reception nurse. You can
also send a password-reset email, or deactivate an account (they are signed out
and blocked, but their records stay).

**The role picker offers Doctor and Reception only.** A second Super Admin
cannot be created from inside the app — that is deliberate, and the security
rules enforce it too.

> Creating an account does not sign you out. The app provisions the new user on
> a separate, short-lived Firebase connection so your admin session is
> untouched.

### Danger Zone
Clears every patient, visit, bill and prescription across all devices, behind a
typed `DELETE` confirmation. Staff accounts, doctors and clinic settings are
kept. Use it once after testing, before real patients start.

---

## 4. Who can see what

| | Patient | Reception | Doctor | Super Admin |
|---|---|---|---|---|
| Book / view own appointments | Yes | — | — | — |
| Register patients, issue OP tokens, collect fees | — | Yes | Yes | Yes |
| Waiting queue, consultation notes, prescriptions | — | — | Yes | Yes |
| Financial reports, cash handover | — | Yes | Yes | Yes |
| Delete a bill | — | — | — | Yes |
| Edit clinic name / doctors / accounts | — | — | — | Yes |
| Clear all clinic data | — | — | — | Yes |

Roles come from `users/{uid}` in Firestore and are checked on the server on
every read and write. They are never derived from the email address and never
chosen by the person signing in.

---

## 5. Known gap — patient sign-in is still a preview

The patient OTP is a fixed demo code (`123456`), not a real SMS. With the new
security rules in place, patient records are not written to the clinic database
from the patient portal, and the screen says so plainly.

Making it real means enabling **Firebase Phone Authentication**:

1. `Authentication → Sign-in method → Phone → Enable`.
2. Add the app's SHA-1 and SHA-256 fingerprints in Project Settings.
3. Replace the simulated OTP in
   [`lib/features/auth/patient_login_screen.dart`](lib/features/auth/patient_login_screen.dart)
   with `FirebaseAuth.verifyPhoneNumber` / `signInWithCredential`.
4. Add a `users/{uid}` document with `role: "customer"` on first sign-in, and
   extend `firestore.rules` so a patient can read only their own records.

Reception, Doctor and Super Admin sign-in are fully live and unaffected.

---

## 6. Build & install

```bash
flutter build apk --release --split-per-abi
```

Install on a USB-connected phone:

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Most modern phones need `app-arm64-v8a-release.apk`. Use
`app-armeabi-v7a-release.apk` for older 32-bit devices.

---

## 7. If something goes wrong

| Symptom | Cause | Fix |
|---|---|---|
| "Email/password sign-in is not enabled" | Auth provider off | Step 1a |
| "This account has no clinic role assigned yet" | Firebase Auth user exists, `users/{uid}` does not | Create the account from `Admin → Login Accounts`, or add the document by hand |
| "Sync blocked by security rules" banner | Rules not deployed, or deployed before this version | Step 1b |
| Setup screen never appears | A Super Admin already exists | Sign in, or delete `clinic_settings/bootstrap` in the console to re-open the claim |
| Admin edits do not save | Not signed in as Super Admin, or no connection | Check the account role; edits made offline queue and sync when the connection returns |
