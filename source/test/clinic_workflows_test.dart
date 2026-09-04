import 'package:clinic_app/models/clinic_settings.dart';
import 'package:clinic_app/models/doctor.dart';
import 'package:clinic_app/models/op_visit.dart';
import 'package:clinic_app/models/patient.dart';
import 'package:clinic_app/models/payment.dart';
import 'package:clinic_app/models/prescription.dart';
import 'package:clinic_app/models/user_role.dart';
import 'package:clinic_app/providers/clinic_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// The clinic's own doctor roster lives in Firestore now, so tests supply the
/// consulting doctor explicitly — exactly as the OP desk does when reception
/// types in a visiting locum's name.
const String kDoctorId = 'doc_test_1';
const String kDoctorName = 'Dr. Test Physician, MBBS';

void main() {
  // SharedPreferences and the Firebase plugins need a binding; the provider
  // treats both as optional, and the tests exercise it with neither backing it.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Clinic Management System Workflows', () {
    late ClinicStateProvider provider;

    setUp(() {
      provider = ClinicStateProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    Patient register(String name, String mobile) => provider.registerPatient(
          name: name,
          mobile: mobile,
          gender: 'Male',
          age: 40,
          address: 'Test Address',
        );

    OpVisit issueToken(Patient patient, {double fee = 500.0, double? paid}) =>
        provider.createOpVisit(
          patientId: patient.patientId,
          patientName: patient.name,
          patientPhone: patient.mobile,
          doctorId: kDoctorId,
          doctorName: kDoctorName,
          reasonForVisit: 'General consultation',
          vitals: Vitals(bp: '120/80'),
          consultationFee: fee,
          initialPaid: paid ?? fee,
          initialMode: PaymentMode.cash,
          collectNow: true,
        );

    test('Patient Phone OTP login returns false for new phone and onboards profile',
        () {
      expect(provider.loginWithVerifiedPhone('9876543210'), false);

      final newPat = provider.registerAndLoginNewPatient(
        name: 'Karthik Raja',
        mobile: '9876543210',
        gender: 'Male',
        age: 38,
        address: '24 Anna Nagar, Main Road',
      );

      expect(newPat.patientId, startsWith('P-'));
      expect(provider.currentUser?.name, 'Karthik Raja');
      expect(provider.currentUser?.patientId, newPat.patientId);
      expect(provider.loginWithVerifiedPhone('9876543210'), true);
    });

    test('Blank or short phone numbers match no patient', () {
      register('Meenakshi Sundaram', '9842109876');

      // `endsWith('')` is always true, so an empty lookup used to return the
      // first patient in the list and quietly attach the visit to them.
      expect(provider.findPatientByPhone(''), isNull);
      expect(provider.findPatientByPhone('98421'), isNull);
      expect(provider.findPatientByPhone('9842109876')?.name,
          'Meenakshi Sundaram');
    });

    test('Nurse creates OP Visit, generates Token, and collects counter fee', () {
      final patient = register('Meenakshi Sundaram', '9842109876');
      final op = issueToken(patient);

      expect(op.tokenNumber, 1);
      expect(op.amountPaid, 500.0);
      expect(op.balance, 0.0);
      expect(op.paymentStatus, PaymentStatus.paid);
      expect(op.doctorId, kDoctorId);
      expect(provider.appointments.length, 1);
    });

    test('Token numbers never repeat after an earlier visit is deleted', () {
      final first = issueToken(register('Patient One', '9000000001'));
      final second = issueToken(register('Patient Two', '9000000002'));
      expect(first.tokenNumber, 1);
      expect(second.tokenNumber, 2);

      provider.deleteOpVisit(first.id);

      // Counting the list gave `length + 1`, which after a deletion handed the
      // next patient a token somebody in the queue was already holding.
      final third = issueToken(register('Patient Three', '9000000003'));
      expect(third.tokenNumber, 3);
      expect(provider.opVisits.map((v) => v.tokenNumber).toSet().length,
          provider.opVisits.length);
    });

    test('Patient IDs are sequential and are not reused after a deletion', () {
      final p1 = register('Patient One', '9000000001');
      final p2 = register('Patient Two', '9000000002');
      final p3 = register('Patient Three', '9000000003');

      expect(p1.patientId, 'P-101');
      expect(p2.patientId, 'P-102');
      expect(p3.patientId, 'P-103');

      provider.deletePatient(p3.patientId);

      final p4 = register('Patient Four', '9000000004');
      expect(p4.patientId, 'P-104');
    });

    test('Registering a known mobile returns the existing record, not a duplicate',
        () {
      final first = register('Meenakshi Sundaram', '9842109876');
      final again = register('Meenakshi S', '9842109876');

      expect(again.patientId, first.patientId);
      expect(provider.patients.length, 1);
    });

    test('Deleting a patient leaves a same-named patient untouched', () {
      final a = register('Ramesh Kumar', '9000000011');
      final b = register('Ramesh Kumar', '9000000022');
      issueToken(a);
      final bVisit = issueToken(b);

      // Deletion used to match on the patient's *name*, so wiping one Ramesh
      // Kumar took the other one's visit history with it.
      provider.deletePatient(a.patientId);

      expect(provider.patients.length, 1);
      expect(provider.patients.first.patientId, b.patientId);
      expect(provider.opVisits.length, 1);
      expect(provider.opVisits.first.id, bVisit.id);
    });

    test('Doctor adds in-cabin procedure charge and synchronizes revenue balance',
        () {
      final patient = register('Venkatesh Kumar', '9789012345');
      final op = issueToken(patient);

      provider.addDoctorProcedureCharge(
        opVisitId: op.id,
        title: 'Paracetamol IV Injection',
        amount: 150.0,
      );

      final updatedOp = provider.opVisits.firstWhere((v) => v.id == op.id);
      expect(updatedOp.procedureCharges.length, 1);
      expect(updatedOp.totalBill, 650.0);
      expect(updatedOp.balance, 150.0);
      expect(updatedOp.paymentStatus, PaymentStatus.partial);
    });

    test('Doctor collects in-cabin balance with audit tracking and completes visit',
        () {
      final patient = register('Suresh Babu', '9789012346');
      final op = issueToken(patient);

      provider.addDoctorProcedureCharge(
        opVisitId: op.id,
        title: 'Nebulization',
        amount: 150.0,
      );

      provider.completeConsultation(
        appointmentId: op.id,
        patientId: patient.patientId,
        doctorId: kDoctorId,
        doctorName: kDoctorName,
        chiefComplaint: 'Body aches',
        clinicalFindings: 'Clear lungs',
        diagnosis: 'Myalgia',
        treatmentAdvice: 'Rest and Paracetamol',
        feeCollected: 150.0,
        paymentMode: PaymentMode.upi,
      );

      final settledOp = provider.opVisits.firstWhere((v) => v.id == op.id);
      expect(settledOp.status, 'completed');
      expect(settledOp.balance, 0.0);
      expect(settledOp.paymentStatus, PaymentStatus.paid);
      expect(provider.caseNotes.length, 1);
    });

    test('Completing a consultation with a prescription survives an empty patient list',
        () {
      // Resolving the patient name reached for `_patients.first`, which threw
      // "Bad state: No element" whenever the patient stream had not arrived.
      expect(
        () => provider.completeConsultation(
          appointmentId: 'unknown-visit',
          patientId: 'P-999',
          doctorId: kDoctorId,
          doctorName: kDoctorName,
          chiefComplaint: 'Fever',
          clinicalFindings: 'Normal',
          diagnosis: 'Viral fever',
          treatmentAdvice: 'Rest',
          prescriptionItems: [
            PrescriptionItemStub.paracetamol(),
          ],
        ),
        returnsNormally,
      );
      expect(provider.prescriptions.length, 1);
    });

    test('Revenue splits count only today and reflect the real payment modes', () {
      issueToken(register('Cash Patient', '9000000031'));

      final upiPatient = register('Upi Patient', '9000000032');
      provider.createOpVisit(
        patientId: upiPatient.patientId,
        patientName: upiPatient.name,
        patientPhone: upiPatient.mobile,
        doctorId: kDoctorId,
        doctorName: kDoctorName,
        reasonForVisit: 'Review',
        vitals: Vitals(bp: '118/76'),
        consultationFee: 500.0,
        initialPaid: 500.0,
        initialMode: PaymentMode.upi,
        collectNow: true,
      );

      expect(provider.todayTotalRevenue, 1000.0);
      expect(provider.todayNurseCash, 500.0);
      expect(provider.todayNurseUpi, 500.0);
      expect(provider.todayCashSharePercent, 50.0);
      expect(provider.todayUpiSharePercent, 50.0);
      expect(provider.todayPatientCount, 2);
    });

    test('Cash in hand is bounded by what was actually collected in cash', () {
      issueToken(register('Cash Patient', '9000000041'));
      expect(provider.physicalCashInHand, 500.0);

      provider.recordCashHandover(amount: 200.0);
      expect(provider.physicalCashInHand, 300.0);

      provider.recordCashHandover(amount: 1000.0);
      expect(provider.physicalCashInHand, 0.0);
    });

    test('Vitals recording calculates BMI correctly', () {
      final vitals = Vitals(
        bp: '120/80',
        weightKg: 70.0,
        heightCm: 175.0,
        pulseBpm: 72,
        temperatureF: 98.6,
      );
      expect(vitals.bmi, 22.9);
    });

    test('Pharmacy Stock IN increases quantity and Stock OUT dispenses', () {
      final item = provider.pharmacyItems.first;
      final initialQty = item.currentQuantity;

      provider.addStockIn(
        pharmacyItemId: item.id,
        quantity: 50,
        batchNumber: 'TEST-BATCH-1',
        expiryDate: '12/2029',
        purchasePrice: item.purchasePrice,
        sellingPrice: item.sellingPrice,
      );
      expect(provider.pharmacyItems.firstWhere((i) => i.id == item.id).currentQuantity,
          initialQty + 50);

      provider.dispenseMedicine(
        pharmacyItemId: item.id,
        quantity: 10,
        reason: 'Patient prescription dispense',
      );
      expect(provider.pharmacyItems.firstWhere((i) => i.id == item.id).currentQuantity,
          initialQty + 40);
    });
  });

  group('Super Admin authorisation', () {
    late ClinicStateProvider provider;

    setUp(() => provider = ClinicStateProvider());
    tearDown(() => provider.dispose());

    AppUser userWithRole(UserRole role) => AppUser(
          id: 'uid-1',
          name: 'Test User',
          emailOrPhone: 'test@clinic.com',
          role: role,
        );

    test('No session means no admin rights', () {
      expect(provider.isSignedIn, false);
      expect(provider.isAdmin, false);
    });

    test('Reception and doctor sessions cannot edit clinic configuration', () async {
      for (final role in [UserRole.staff, UserRole.doctor]) {
        provider.setAuthenticatedUser(userWithRole(role));
        expect(provider.isAdmin, false);

        expect(
          await provider.saveClinicSettings(
              const ClinicSettings(clinicName: 'Hacked', tagline: '')),
          false,
        );
        expect(
          await provider.saveDoctor(const Doctor(
            id: 'doc_x',
            name: 'Ghost',
            qualification: '',
            specialty: '',
            experienceYears: '',
            consultationFee: 0,
            phone: '',
            availableBranchIds: [],
            schedules: [],
            photoUrl: '',
          )),
          false,
        );
        expect(await provider.resetClinicalData(), false);

        expect(provider.clinicName, isNot('Hacked'));
        expect(provider.doctors, isEmpty);
      }
    });

    test('An admin session is recognised', () {
      provider.setAuthenticatedUser(userWithRole(UserRole.admin));
      expect(provider.isAdmin, true);
      expect(provider.isSignedIn, true);
    });
  });
}

/// Small helper so the prescription test does not depend on the exact
/// PrescriptionItem constructor defaults.
class PrescriptionItemStub {
  static PrescriptionItem paracetamol() => PrescriptionItem(
        id: 'rx-item-1',
        medicineName: 'Paracetamol 650mg',
        dosage: '650mg',
        durationDays: 3,
      );
}
