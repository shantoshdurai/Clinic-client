import '../../models/appointment.dart';
import '../../models/case_note.dart';
import '../../models/clinic_branch.dart';
import '../../models/doctor.dart';
import '../../models/op_visit.dart';
import '../../models/patient.dart';
import '../../models/payment.dart';
import '../../models/pharmacy_item.dart';
import '../../models/prescription.dart';
import '../../models/staff_attendance.dart';

/// Starter data for a brand-new clinic.
///
/// There are deliberately no doctors, staff accounts or patients here. Those
/// are real clinic records: they are created by the Super Admin from the Admin
/// console and stored in Firestore, so renaming a doctor or adding a nurse is
/// a two-minute edit on the phone rather than a code change and a new APK.
///
/// The only seeded content is a small pharmacy catalogue, which is generic
/// enough to be useful on day one and fully editable afterwards.
class ClinicData {
  ClinicData._();

  /// Placeholder branch used until `clinic_settings/main` streams in. Its
  /// display fields are overwritten from settings — see
  /// `ClinicStateProvider.clinicName` and friends.
  static ClinicBranch mainClinic = ClinicBranch(
    id: 'main_clinic',
    name: 'Clinic',
    locality: '',
    address: '',
    phone: '',
    whatsapp: '',
    workingHours: '',
    mapUrl: '',
    isMainBranch: true,
    totalDoctors: 0,
    activeAppointmentsToday: 0,
  );

  static List<ClinicBranch> defaultBranches = [mainClinic];

  /// Empty by design. The Super Admin adds the clinic's real doctors under
  /// Admin > Doctors, and they sync to every device immediately.
  static List<Doctor> defaultDoctors = [];

  // Populated exclusively via Cloud Firestore and the Reception Desk.
  static List<Patient> defaultPatients = [];
  static List<Appointment> defaultAppointments = [];
  static List<OpVisit> defaultOpVisits = [];
  static List<CaseNote> defaultCaseNotes = [];
  static List<Prescription> defaultPrescriptions = [];
  static List<Payment> defaultPayments = [];
  static List<StaffAttendance> defaultAttendance = [];

  /// Generic starter catalogue, shown until the clinic stocks its own list.
  static List<PharmacyItem> defaultPharmacyItems = [
    PharmacyItem(
      id: 'med_1',
      medicineName: 'Paracetamol 650mg',
      genericName: 'Paracetamol IP',
      brand: 'Dolo 650 / Micro Labs',
      batchNumber: 'P1234',
      expiryDate: '12/2027',
      purchasePrice: 15.00,
      sellingPrice: 30.00,
      currentQuantity: 500,
      minStockAlertQuantity: 50,
      branchId: 'main_clinic',
    ),
    PharmacyItem(
      id: 'med_2',
      medicineName: 'Pan 40 Tablet',
      genericName: 'Pantoprazole 40mg',
      brand: 'Alkem Laboratories',
      batchNumber: 'PAN904',
      expiryDate: '04/2028',
      purchasePrice: 85.00,
      sellingPrice: 120.00,
      currentQuantity: 300,
      minStockAlertQuantity: 40,
      branchId: 'main_clinic',
    ),
    PharmacyItem(
      id: 'med_3',
      medicineName: 'Azithromycin 500mg',
      genericName: 'Azithromycin IP',
      brand: 'Azee 500 / Cipla',
      batchNumber: 'AZ302',
      expiryDate: '08/2027',
      purchasePrice: 95.00,
      sellingPrice: 140.00,
      currentQuantity: 200,
      minStockAlertQuantity: 30,
      branchId: 'main_clinic',
    ),
    PharmacyItem(
      id: 'med_4',
      medicineName: 'Cetirizine 10mg',
      genericName: 'Cetirizine Hydrochloride',
      brand: 'Cetzine / Dr. Reddy',
      batchNumber: 'CT891',
      expiryDate: '09/2027',
      purchasePrice: 20.00,
      sellingPrice: 45.00,
      currentQuantity: 400,
      minStockAlertQuantity: 30,
      branchId: 'main_clinic',
    ),
  ];
}
