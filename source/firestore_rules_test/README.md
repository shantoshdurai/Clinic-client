# Firestore rules tests

Checks that `firestore.rules` actually enforces the clinic's access boundaries —
patient data closed to the public, reception unable to act as admin, and the
Super Admin claim closing after first use.

Needs Java on PATH (the JDK bundled with Android Studio works) and the Firebase
CLI.

```bash
cd firestore_rules_test
npm install
npm test
```

Run this after any change to `firestore.rules`, before deploying.

## End-to-end workflow rehearsal

`workflow.e2e.mjs` replays the whole clinic workflow against the Auth and
Firestore emulators, using the same calls the app makes: Super Admin claim →
add doctor → create nurse and doctor logins → nurse registers a patient,
issues a token and takes payment → doctor sees the queue, adds a charge and
completes the visit → admin renames the clinic and the doctor, and staff see it
live.

```bash
npm run e2e
```

Nothing touches the live project — the emulators are wiped at the start of the
run.

## Rehearsing in the app itself

To click through the same flow by hand without creating real accounts:

```bash
firebase emulators:start --only firestore,auth
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```
