# Phone Testing & USB Debugging Guide (`TESTING_AND_DEVICE_SETUP.md`)

> **APK Location**: `apk/app-arm64-v8a-release.apk`  
> **Package ID**: `com.maac.asclinic`  
> **Target Architecture**: 64-bit ARM (`arm64-v8a`)  

---

## 1. Quick Install via USB (ADB)

Connect your Android phone to your PC via USB cable.

### Step 1: Enable Developer Options & USB Debugging
1. On your phone, go to **Settings -> About Phone**.
2. Tap **Build Number** 7 times until you see *"You are now a developer!"*.
3. Go back to **Settings -> System -> Developer Options** (or search for *Developer Options*).
4. Turn on **USB Debugging**.
5. When connecting the cable to your PC, accept the prompt: **"Allow USB debugging from this computer?"** (check *Always allow*).

### Step 2: Install via Command Line
Run the following from your terminal:

```bash
# Check if device is recognized
adb devices

# Install the arm64 release APK directly
adb install -r apk/app-arm64-v8a-release.apk
```

If multiple devices are listed:
```bash
adb -d install -r apk/app-arm64-v8a-release.apk
```

---

## 2. Direct Install (No PC required / WhatsApp / Drive)

1. Copy `apk/app-arm64-v8a-release.apk` to your phone (via USB file transfer, Google Drive, WhatsApp, or email).
2. On your phone, tap the file in your File Manager or Downloads.
3. If prompted with *"Install unknown apps"*, toggle **Allow from this source**.
4. Tap **Install** and open **AS Clinic**.

---

## 3. First-Time App Walkthrough

1. **Patient Screen**: App launches into the high-contrast outpatient screen.
2. **Setup Super Admin**:
   - Tap **Clinic staff sign in** in the top-right corner.
   - You will see a banner: **"Clinic not set up yet"**.
   - Tap **Set up Super Admin**.
   - Fill in:
     - **Clinic Name**: e.g., `AS Clinic`
     - **Administrator Name**: e.g., `Dr. Shantosh`
     - **Email**: Your admin email
     - **Password**: Minimum 8 characters
     - **Setup Key**: Found in `source/lib/core/config/app_config.dart` (`asclinic-superadmin-setup-2026`)
   - Tap **Create Super Admin**.
3. **Configure Clinic & Doctors**:
   - In the Admin Panel, tap **Clinic Profile** to set clinic name, phone, address, and default consultation fee.
   - Tap **Doctor Roster** to add your real doctors (Name, Specialization, Consultation fee, Room number).
   - Tap **Staff & Doctor Accounts** to create receptionist and doctor logins.
4. **Receptionist Flow**:
   - Log out, sign in with staff account.
   - Register a patient (`P-101`), record vitals, and issue today's OP token #1.
5. **Doctor Flow**:
   - Sign in with doctor account.
   - View OP queue, open patient token, write clinical notes, prescribe drugs, add procedure charges, and review daily revenue.
