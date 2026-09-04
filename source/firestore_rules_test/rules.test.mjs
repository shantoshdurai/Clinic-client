// Behavioural check of firestore.rules against the Firestore emulator.
// Verifies the access boundaries the app now relies on.
import fs from 'node:fs';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, deleteDoc, collection, getDocs } from 'firebase/firestore';

const rules = fs.readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8');

const env = await initializeTestEnvironment({
  projectId: 'asclinic-rules-test',
  firestore: { rules, host: '127.0.0.1', port: 8080 },
});

let pass = 0, fail = 0;
async function check(name, fn) {
  try { await fn(); console.log('  PASS  ' + name); pass++; }
  catch (e) { console.log('  FAIL  ' + name + '\n        ' + (e.message || e)); fail++; }
}

// Seed the role documents and the bootstrap marker, bypassing rules.
await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, 'users/admin1'),  { name: 'Owner',   role: 'admin',  active: true });
  await setDoc(doc(db, 'users/doc1'),    { name: 'Doctor',  role: 'doctor', active: true });
  await setDoc(doc(db, 'users/nurse1'),  { name: 'Nurse',   role: 'staff',  active: true });
  await setDoc(doc(db, 'users/off1'),    { name: 'Ex',      role: 'staff',  active: false });
  await setDoc(doc(db, 'clinic_settings/bootstrap'), { adminCreated: true });
  await setDoc(doc(db, 'clinic_settings/main'), {
    clinicName: 'AS Clinic', tagline: 't', patientIdStart: 101,
    updatedAt: '2026-09-04T00:00:00.000Z', updatedByName: 'Owner',
  });
  await setDoc(doc(db, 'patients/p1'), { patientId: 'P-101', name: 'Ramesh' });
  await setDoc(doc(db, 'payments/pay1'), { billNumber: 'B1', totalAmount: 500 });
  await setDoc(doc(db, 'op_visits/v1'), { tokenNumber: 1 });
  await setDoc(doc(db, 'doctors/d1'), { id: 'd1', name: 'Dr A' });
});

const anon    = env.unauthenticatedContext().firestore();
const admin   = env.authenticatedContext('admin1').firestore();
const docCtx  = env.authenticatedContext('doc1').firestore();
const nurse   = env.authenticatedContext('nurse1').firestore();
const disabled= env.authenticatedContext('off1').firestore();
const stranger= env.authenticatedContext('nobody').firestore();  // authed, no users doc

console.log('\n--- Patient data is closed to the public ---');
await check('anonymous cannot read the patient list',    () => assertFails(getDocs(collection(anon, 'patients'))));
await check('anonymous cannot read a patient record',    () => assertFails(getDoc(doc(anon, 'patients/p1'))));
await check('anonymous cannot read payments',            () => assertFails(getDocs(collection(anon, 'payments'))));
await check('anonymous cannot read op_visits',           () => assertFails(getDocs(collection(anon, 'op_visits'))));
await check('anonymous cannot write a patient',          () => assertFails(setDoc(doc(anon, 'patients/p9'), { name: 'X' })));

console.log('\n--- A signed-in account with no role gets nothing ---');
await check('stranger cannot read patients',             () => assertFails(getDocs(collection(stranger, 'patients'))));
await check('stranger cannot read payments',             () => assertFails(getDocs(collection(stranger, 'payments'))));
await check('stranger cannot self-assign admin',         () => assertFails(setDoc(doc(stranger, 'users/nobody'), { role: 'admin', active: true })));
await check('stranger cannot create a staff role',       () => assertFails(setDoc(doc(stranger, 'users/nobody'), { role: 'staff', active: true })));

console.log('\n--- A deactivated account is locked out ---');
await check('deactivated staff cannot read patients',    () => assertFails(getDocs(collection(disabled, 'patients'))));
await check('deactivated staff cannot write a payment',  () => assertFails(setDoc(doc(disabled, 'payments/x'), { totalAmount: 1 })));
await check('deactivated staff cannot reactivate self',  () => assertFails(setDoc(doc(disabled, 'users/off1'), { role: 'staff', active: true })));

console.log('\n--- Reception can do its job ---');
await check('nurse reads patients',                      () => assertSucceeds(getDocs(collection(nurse, 'patients'))));
await check('nurse creates a patient',                   () => assertSucceeds(setDoc(doc(nurse, 'patients/p2'), { patientId: 'P-102', name: 'Latha' })));
await check('nurse records a payment',                   () => assertSucceeds(setDoc(doc(nurse, 'payments/pay2'), { billNumber: 'B2', totalAmount: 500 })));
await check('nurse records a cash handover',             () => assertSucceeds(setDoc(doc(nurse, 'cash_handovers/h1'), { date: '2026-09-04', nurseCash: 500 })));
await check('nurse advances the patient-ID counter',     () => assertSucceeds(setDoc(doc(nurse, 'clinic_settings/main'), {
                                                              clinicName: 'AS Clinic', tagline: 't', patientIdStart: 102,
                                                              updatedAt: '2026-09-04T00:00:00.000Z', updatedByName: 'Owner',
                                                            }, { merge: true })));

console.log('\n--- Reception cannot act as admin ---');
await check('nurse cannot rename the clinic',            () => assertFails(setDoc(doc(nurse, 'clinic_settings/main'), { clinicName: 'Hacked' }, { merge: true })));
await check('nurse cannot add a doctor',                 () => assertFails(setDoc(doc(nurse, 'doctors/d2'), { id: 'd2', name: 'Ghost' })));
await check('nurse cannot create a login account',       () => assertFails(setDoc(doc(nurse, 'users/new1'), { role: 'staff', active: true })));
await check('nurse cannot delete a bill',                () => assertFails(deleteDoc(doc(nurse, 'payments/pay1'))));
await check('nurse cannot promote themselves to admin',  () => assertFails(setDoc(doc(nurse, 'users/nurse1'), { role: 'admin', active: true }, { merge: true })));

console.log('\n--- Doctor ---');
await check('doctor reads the queue',                    () => assertSucceeds(getDocs(collection(docCtx, 'op_visits'))));
await check('doctor writes a case note',                 () => assertSucceeds(setDoc(doc(docCtx, 'case_notes/n1'), { diagnosis: 'Viral fever' })));
await check('doctor cannot rename the clinic',           () => assertFails(setDoc(doc(docCtx, 'clinic_settings/main'), { clinicName: 'Hacked' }, { merge: true })));
await check('doctor cannot create a login account',      () => assertFails(setDoc(doc(docCtx, 'users/new2'), { role: 'doctor', active: true })));

console.log('\n--- Super Admin ---');
await check('admin renames the clinic',                  () => assertSucceeds(setDoc(doc(admin, 'clinic_settings/main'), { clinicName: 'New Name' }, { merge: true })));
await check('admin adds a doctor',                       () => assertSucceeds(setDoc(doc(admin, 'doctors/d2'), { id: 'd2', name: 'Dr B' })));
await check('admin creates a reception login',           () => assertSucceeds(setDoc(doc(admin, 'users/new3'), { role: 'staff', active: true, name: 'N' })));
await check('admin deactivates an account',              () => assertSucceeds(setDoc(doc(admin, 'users/nurse1'), { active: false }, { merge: true })));
await check('admin deletes a bill',                      () => assertSucceeds(deleteDoc(doc(admin, 'payments/pay1'))));

console.log('\n--- The Super Admin claim is closed once used ---');
await check('admin cannot mint a second admin',          () => assertFails(setDoc(doc(admin, 'users/new4'), { role: 'admin', active: true })));
await check('nobody can delete the bootstrap marker',    () => assertFails(deleteDoc(doc(admin, 'clinic_settings/bootstrap'))));
await check('stranger cannot claim admin after setup',   () => assertFails(setDoc(doc(stranger, 'users/nobody'), { role: 'admin', active: true })));

console.log('\n--- Pre-login reads the app genuinely needs ---');
await check('anonymous reads the bootstrap marker',      () => assertSucceeds(getDoc(doc(anon, 'clinic_settings/bootstrap'))));
await check('anonymous reads clinic name/settings',      () => assertSucceeds(getDoc(doc(anon, 'clinic_settings/main'))));
await check('anonymous reads the doctor roster',         () => assertSucceeds(getDocs(collection(anon, 'doctors'))));

console.log('\n--- Undeclared collections are closed ---');
await check('nobody can write an unlisted collection',   () => assertFails(setDoc(doc(admin, 'random_stuff/x'), { a: 1 })));

await env.cleanup();
console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
