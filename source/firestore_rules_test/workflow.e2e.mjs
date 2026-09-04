// End-to-end rehearsal of the clinic's real workflow against the Firebase
// emulators, using the same Auth + Firestore calls the app makes.
//
//   Super Admin claim -> add doctor -> create nurse & doctor logins
//   -> nurse signs in, registers a patient, issues a token, takes payment
//   -> doctor signs in, sees the queue, adds a charge, writes a case note
//   -> admin renames the clinic and the doctor; both are visible to staff
//
// Run:  npm run e2e     (see package.json)
import { initializeApp, deleteApp } from 'firebase/app';
import {
  getAuth, connectAuthEmulator, signInWithEmailAndPassword,
  createUserWithEmailAndPassword, signOut,
} from 'firebase/auth';
import {
  getFirestore, connectFirestoreEmulator, doc, setDoc, getDoc, getDocs,
  collection, query, where,
} from 'firebase/firestore';

const PROJECT = 'asclinic-6cd9b';
const HOST = '127.0.0.1';

let pass = 0, fail = 0;
async function check(name, fn) {
  try {
    const detail = await fn();
    console.log('  PASS  ' + name + (detail ? '  -> ' + detail : ''));
    pass++;
  } catch (e) {
    console.log('  FAIL  ' + name + '\n        ' + (e.message || e));
    fail++;
  }
}
function expect(cond, msg) { if (!cond) throw new Error(msg); }

// Fresh emulator state so the one-time Super Admin claim is genuinely untaken.
await fetch(`http://${HOST}:8080/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
await fetch(`http://${HOST}:9099/emulator/v1/projects/${PROJECT}/accounts`, { method: 'DELETE' });

const cfg = { apiKey: 'demo-key', projectId: PROJECT, appId: '1:1:web:1' };

/** A separate Firebase app per person, mirroring one phone per user. */
function session(name) {
  const app = initializeApp(cfg, name);
  const auth = getAuth(app);
  connectAuthEmulator(auth, `http://${HOST}:9099`, { disableWarnings: true });
  const db = getFirestore(app);
  connectFirestoreEmulator(db, HOST, 8080);
  return { app, auth, db };
}

const adminS = session('admin');
const nurseS = session('nurse');
const doctorS = session('doctor');
const outsiderS = session('outsider');

const ADMIN = { email: 'owner@asclinic.com', pass: 'ClinicOwner123' };
const NURSE = { email: 'revathi@asclinic.com', pass: 'NursePass123' };
const DOCTOR = { email: 'raj@asclinic.com', pass: 'DoctorPass123' };

let doctorId = 'doc_e2e_1';

console.log('\n=== 1. Super Admin claim (one time, on a fresh clinic) ===');

await check('setup is offered while no admin exists', async () => {
  const snap = await getDoc(doc(outsiderS.db, 'clinic_settings/bootstrap'));
  expect(!snap.exists(), 'bootstrap marker already present');
  return 'bootstrap marker absent';
});

await check('owner claims Super Admin', async () => {
  const cred = await createUserWithEmailAndPassword(adminS.auth, ADMIN.email, ADMIN.pass);
  const uid = cred.user.uid;
  await setDoc(doc(adminS.db, 'users/' + uid), {
    id: uid, name: 'Clinic Owner', email: ADMIN.email, emailOrPhone: ADMIN.email,
    role: 'admin', active: true, branchId: 'main_clinic',
  });
  await setDoc(doc(adminS.db, 'clinic_settings/bootstrap'), { adminCreated: true, createdByUid: uid });
  await setDoc(doc(adminS.db, 'clinic_settings/main'), {
    clinicName: 'AS Clinic', tagline: 'General Health & Outpatient Care Centre',
    address: 'Main Road', phone: '+91 94431 23456', defaultConsultationFee: 500,
    patientIdPrefix: 'P-', patientIdStart: 101, billPrefix: 'BILL',
    updatedAt: '2026-09-04T00:00:00.000Z', updatedByName: 'Clinic Owner',
  });
  return 'uid ' + uid.slice(0, 8);
});

await check('the claim is now closed to everyone else', async () => {
  const cred = await createUserWithEmailAndPassword(outsiderS.auth, 'random@x.com', 'Whatever123');
  let denied = false;
  try {
    await setDoc(doc(outsiderS.db, 'users/' + cred.user.uid), { role: 'admin', active: true });
  } catch { denied = true; }
  expect(denied, 'an outsider was able to claim admin after setup');
  await signOut(outsiderS.auth);
  return 'second admin claim refused';
});

console.log('\n=== 2. Admin sets up the clinic ===');

await check('admin adds the real doctor', async () => {
  await setDoc(doc(adminS.db, 'doctors/' + doctorId), {
    id: doctorId, name: 'Dr. Raj Saravanan', qualification: 'MBBS, MD (General Medicine)',
    specialty: 'General Medicine & Diabetology', experienceYears: '14+ Years',
    consultationFee: 500, phone: '+91 98424 11223',
    availableBranchIds: ['main_clinic'], schedules: [], photoUrl: '', active: true,
  });
  const snap = await getDoc(doc(adminS.db, 'doctors/' + doctorId));
  expect(snap.data().name === 'Dr. Raj Saravanan', 'doctor not stored');
  return 'Dr. Raj Saravanan';
});

// The app creates the Auth user on a throwaway secondary app so the admin's
// own session is untouched, then writes the role document as the admin.
async function provision(person, role, extra) {
  const tmp = session('provisioner_' + role);
  const cred = await createUserWithEmailAndPassword(tmp.auth, person.email, person.pass);
  await signOut(tmp.auth);
  await deleteApp(tmp.app);
  await setDoc(doc(adminS.db, 'users/' + cred.user.uid), {
    id: cred.user.uid, name: extra.name, email: person.email, emailOrPhone: person.email,
    role, active: true, branchId: 'main_clinic', ...extra,
  });
  return cred.user.uid;
}

await check('admin creates the reception login', async () => {
  const uid = await provision(NURSE, 'staff', { name: 'Revathi M.', staffId: 'STF-101' });
  return NURSE.email + ' (uid ' + uid.slice(0, 8) + ')';
});

await check('admin creates the doctor login, linked to the profile', async () => {
  const uid = await provision(DOCTOR, 'doctor', { name: 'Dr. Raj Saravanan', doctorId });
  return DOCTOR.email + ' (uid ' + uid.slice(0, 8) + ')';
});

await check('the admin was not signed out by provisioning', async () => {
  expect(adminS.auth.currentUser !== null, 'admin session was lost');
  expect(adminS.auth.currentUser.email === ADMIN.email, 'admin session was swapped');
  return 'still ' + adminS.auth.currentUser.email;
});

console.log('\n=== 3. Reception desk: patient DB + OP token + payment ===');

let patientDocId, opId;

await check('nurse signs in and resolves her role', async () => {
  const cred = await signInWithEmailAndPassword(nurseS.auth, NURSE.email, NURSE.pass);
  const profile = await getDoc(doc(nurseS.db, 'users/' + cred.user.uid));
  expect(profile.exists(), 'no role document');
  expect(profile.data().role === 'staff', 'wrong role: ' + profile.data().role);
  return 'role = staff';
});

await check('nurse sees the admin-managed doctor roster', async () => {
  const snap = await getDocs(collection(nurseS.db, 'doctors'));
  expect(snap.size === 1, 'expected 1 doctor, saw ' + snap.size);
  expect(snap.docs[0].data().name === 'Dr. Raj Saravanan', 'wrong doctor name');
  return snap.docs[0].data().name;
});

await check('nurse registers a patient', async () => {
  patientDocId = 'pat-uuid-1';
  await setDoc(doc(nurseS.db, 'patients/' + patientDocId), {
    id: patientDocId, patientId: 'P-101', name: 'Meenakshi Sundaram',
    mobile: '9842109876', gender: 'Female', age: 54, address: '12 Gandhi Street',
    registeredAt: new Date().toISOString(),
  });
  const snap = await getDoc(doc(nurseS.db, 'patients/' + patientDocId));
  expect(snap.data().patientId === 'P-101', 'patient not stored');
  return 'P-101 Meenakshi Sundaram';
});

await check('nurse advances the patient-ID counter', async () => {
  await setDoc(doc(nurseS.db, 'clinic_settings/main'), {
    patientIdStart: 102, updatedAt: '2026-09-04T00:00:00.000Z', updatedByName: 'Clinic Owner',
  }, { merge: true });
  const snap = await getDoc(doc(nurseS.db, 'clinic_settings/main'));
  expect(snap.data().patientIdStart === 102, 'counter not advanced');
  return 'next patient will be P-102';
});

await check('nurse issues an OP token and takes ₹500 cash', async () => {
  opId = 'op-uuid-1';
  await setDoc(doc(nurseS.db, 'op_visits/' + opId), {
    id: opId, opNumber: 'OP-20260904-01', tokenNumber: 1, patientId: 'P-101',
    patientName: 'Meenakshi Sundaram', doctorId, doctorName: 'Dr. Raj Saravanan, MD',
    status: 'waiting', consultationFee: 500, amountPaid: 500, balance: 0,
    createdAt: new Date().toISOString(),
  });
  await setDoc(doc(nurseS.db, 'appointments/' + opId), {
    id: opId, patientId: 'P-101', patientName: 'Meenakshi Sundaram',
    doctorId, doctorName: 'Dr. Raj Saravanan, MD', tokenNumber: 1,
    status: 'checkedIn', createdAt: new Date().toISOString(),
  });
  await setDoc(doc(nurseS.db, 'payments/pay-uuid-1'), {
    id: 'pay-uuid-1', billNumber: 'BILL-20260904-01', appointmentId: opId,
    patientId: 'P-101', patientName: 'Meenakshi Sundaram',
    consultationFee: 500, totalAmount: 500, paidToNurse: 500, paidToDoctor: 0,
    nursePaymentMode: 'cash', amountPaid: 500, balance: 0,
    collectedByName: 'Revathi M.', paymentDate: new Date().toISOString(),
  });
  return 'token 1, BILL-20260904-01, ₹500 cash';
});

await check('nurse hands cash over at day close', async () => {
  await setDoc(doc(nurseS.db, 'cash_handovers/h-uuid-1'), {
    id: 'h-uuid-1', date: '2026-09-04', nurseCash: 500,
    handedOverByName: 'Revathi M.', receivedByName: 'Dr. Raj Saravanan, MD',
    settledAt: new Date().toISOString(), status: 'confirmed',
  });
  return '₹500 handed to the doctor';
});

console.log('\n=== 4. Reception cannot act as admin ===');

await check('nurse cannot rename the clinic', async () => {
  let denied = false;
  try {
    await setDoc(doc(nurseS.db, 'clinic_settings/main'), { clinicName: 'Hacked' }, { merge: true });
  } catch { denied = true; }
  expect(denied, 'reception was able to rename the clinic');
  return 'denied';
});

await check('nurse cannot change the doctor name', async () => {
  let denied = false;
  try {
    await setDoc(doc(nurseS.db, 'doctors/' + doctorId), { name: 'Dr. Fake' }, { merge: true });
  } catch { denied = true; }
  expect(denied, 'reception was able to rename the doctor');
  return 'denied';
});

await check('nurse cannot create a login account', async () => {
  let denied = false;
  try {
    await setDoc(doc(nurseS.db, 'users/sneaky'), { role: 'staff', active: true });
  } catch { denied = true; }
  expect(denied, 'reception was able to create an account');
  return 'denied';
});

console.log('\n=== 5. Doctor cabin: queue, charges, notes ===');

await check('doctor signs in and resolves the linked profile', async () => {
  const cred = await signInWithEmailAndPassword(doctorS.auth, DOCTOR.email, DOCTOR.pass);
  const profile = await getDoc(doc(doctorS.db, 'users/' + cred.user.uid));
  expect(profile.data().role === 'doctor', 'wrong role');
  expect(profile.data().doctorId === doctorId, 'doctor profile not linked');
  return 'linked to ' + profile.data().doctorId;
});

await check('doctor sees the waiting patient in the queue', async () => {
  const snap = await getDocs(query(collection(doctorS.db, 'appointments'), where('status', '==', 'checkedIn')));
  expect(snap.size === 1, 'expected 1 waiting patient, saw ' + snap.size);
  return snap.docs[0].data().patientName + ' (token ' + snap.docs[0].data().tokenNumber + ')';
});

await check('doctor adds an in-cabin procedure charge', async () => {
  await setDoc(doc(doctorS.db, 'op_visits/' + opId), {
    procedureCharges: [{ id: 'c1', title: 'Nebulization', amount: 150, addedBy: 'Doctor' }],
    balance: 150, paymentStatus: 'partial',
  }, { merge: true });
  await setDoc(doc(doctorS.db, 'payments/pay-uuid-1'), {
    totalAmount: 650, balance: 150, status: 'partial',
  }, { merge: true });
  return '₹150 Nebulization, balance ₹150';
});

await check('doctor collects the balance and completes the visit', async () => {
  await setDoc(doc(doctorS.db, 'payments/pay-uuid-1'), {
    paidToDoctor: 150, doctorPaymentMode: 'upi', amountPaid: 650, balance: 0, status: 'paid',
  }, { merge: true });
  await setDoc(doc(doctorS.db, 'case_notes/note-1'), {
    id: 'note-1', appointmentId: opId, patientId: 'P-101', doctorId,
    diagnosis: 'Myalgia', treatmentAdvice: 'Rest and Paracetamol',
    createdAt: new Date().toISOString(),
  });
  await setDoc(doc(doctorS.db, 'op_visits/' + opId), { status: 'completed', balance: 0 }, { merge: true });
  const pay = await getDoc(doc(doctorS.db, 'payments/pay-uuid-1'));
  expect(pay.data().balance === 0, 'balance not cleared');
  expect(pay.data().amountPaid === 650, 'total collected wrong');
  return '₹650 total (₹500 cash desk + ₹150 UPI cabin)';
});

await check('doctor cannot create a login account', async () => {
  let denied = false;
  try { await setDoc(doc(doctorS.db, 'users/sneaky2'), { role: 'doctor', active: true }); }
  catch { denied = true; }
  expect(denied, 'doctor was able to create an account');
  return 'denied';
});

console.log('\n=== 6. Admin changes reach staff live ===');

await check('admin renames the clinic', async () => {
  await setDoc(doc(adminS.db, 'clinic_settings/main'), { clinicName: 'AS Health Centre' }, { merge: true });
  const seen = await getDoc(doc(nurseS.db, 'clinic_settings/main'));
  expect(seen.data().clinicName === 'AS Health Centre', 'nurse still sees the old name');
  return 'reception now sees "AS Health Centre"';
});

await check('admin renames the doctor and changes the fee', async () => {
  await setDoc(doc(adminS.db, 'doctors/' + doctorId), {
    name: 'Dr. R. Saravanan', consultationFee: 600,
  }, { merge: true });
  const seen = await getDoc(doc(nurseS.db, 'doctors/' + doctorId));
  expect(seen.data().name === 'Dr. R. Saravanan', 'nurse still sees the old doctor name');
  expect(seen.data().consultationFee === 600, 'fee not updated');
  return 'OP desk now shows "Dr. R. Saravanan", ₹600';
});

await check('admin deactivates the nurse; she is locked out', async () => {
  const uid = nurseS.auth.currentUser.uid;
  await setDoc(doc(adminS.db, 'users/' + uid), { active: false }, { merge: true });
  // The app re-reads the role and refuses the session when active is false.
  const profile = await getDoc(doc(adminS.db, 'users/' + uid));
  expect(profile.data().active === false, 'not deactivated');
  let denied = false;
  try { await setDoc(doc(nurseS.db, 'patients/blocked'), { name: 'X' }); } catch { denied = true; }
  expect(denied, 'a deactivated nurse could still write patient data');
  return 'writes refused immediately';
});

for (const s of [adminS, nurseS, doctorS, outsiderS]) { await deleteApp(s.app); }

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
