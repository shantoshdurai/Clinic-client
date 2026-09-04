import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/clinic_data.dart';
import '../models/appointment.dart';
import '../models/case_note.dart';
import '../models/cash_handover.dart';
import '../models/clinic_branch.dart';
import '../models/clinic_settings.dart';
import '../models/doctor.dart';
import '../models/op_visit.dart';
import '../models/patient.dart';
import '../models/payment.dart';
import '../models/pharmacy_item.dart';
import '../models/prescription.dart';
import '../models/staff_attendance.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ClinicStateProvider extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  // Active Clinic Branch & Auth
  late ClinicBranch _selectedBranch;
  AppUser? _currentUser;

  /// Admin-editable clinic identity, streamed from Firestore.
  ClinicSettings _settings = ClinicSettings.fallback;
  bool _settingsLoaded = false;

  /// Set when a Firestore listener fails, so screens can show a sync warning
  /// instead of an empty list that looks like real, empty data.
  String? _syncError;

  // In-Memory Mirrors of the Firestore Collections
  List<ClinicBranch> _branches = [];
  List<Doctor> _doctors = [];
  List<Patient> _patients = [];
  List<Appointment> _appointments = [];
  List<OpVisit> _opVisits = [];
  List<CaseNote> _caseNotes = [];
  List<Prescription> _prescriptions = [];
  List<Payment> _payments = [];
  List<CashHandover> _cashHandovers = [];
  List<PharmacyItem> _pharmacyItems = [];
  final List<StockTransaction> _stockTransactions = [];
  List<StaffAttendance> _attendanceRecords = [];
  List<AppUser> _staffUsers = [];

  /// Listeners on data anyone may read (clinic name, doctor roster). Live for
  /// the whole app session.
  final List<StreamSubscription<dynamic>> _publicSubscriptions = [];

  /// Listeners on patient, clinical and billing data. Opened on sign-in and
  /// closed on sign-out — a Firestore snapshot stream that hits
  /// `permission-denied` is dead for good, so starting these before there is a
  /// session would leave every screen empty even after a successful login.
  final List<StreamSubscription<dynamic>> _privateSubscriptions = [];

  bool _disposed = false;

  // Notifications Queue
  final List<Map<String, dynamic>> _notifications = [];

  ClinicStateProvider() {
    _initData();
  }

  void _initData() {
    _branches = List.from(ClinicData.defaultBranches);
    _selectedBranch = _branches.first;
    _doctors = List.from(ClinicData.defaultDoctors);
    _pharmacyItems = List.from(ClinicData.defaultPharmacyItems);

    _firestoreService.onStreamError = _handleStreamError;
    _bindPublicStreams();
  }

  void seedInitialRosterIfEmpty() {
    if (_doctors.isEmpty) {
      _doctors = [
        const Doctor(
          id: 'doc_1',
          name: 'Dr. A. Sharma',
          qualification: 'MBBS, MD (General Medicine)',
          specialty: 'General Physician',
          experienceYears: '12',
          consultationFee: 300.0,
          phone: '+91 98765 43210',
          availableBranchIds: ['main_clinic'],
          schedules: [
            DoctorScheduleSlot(
              dayOfWeek: 'Monday - Saturday',
              branchId: 'main_clinic',
              startTime: '09:00 AM',
              endTime: '01:00 PM',
            ),
          ],
          photoUrl: '',
          rating: 4.9,
          reviewsCount: 120,
          active: true,
        ),
        const Doctor(
          id: 'doc_2',
          name: 'Dr. Priya Patel',
          qualification: 'MBBS, DCH (Pediatrics)',
          specialty: 'Pediatrician',
          experienceYears: '8',
          consultationFee: 350.0,
          phone: '+91 98765 43211',
          availableBranchIds: ['main_clinic'],
          schedules: [
            DoctorScheduleSlot(
              dayOfWeek: 'Monday - Saturday',
              branchId: 'main_clinic',
              startTime: '02:00 PM',
              endTime: '07:00 PM',
            ),
          ],
          photoUrl: '',
          rating: 4.8,
          reviewsCount: 95,
          active: true,
        ),
      ];
    }
    if (_patients.isEmpty) {
      _patients = [
        Patient(
          id: 'pat_1',
          patientId: 'P-101',
          name: 'Ramesh Kumar',
          mobile: '+91 98765 11111',
          gender: 'Male',
          age: 42,
          address: '12 Gandhi Road, Cantonment',
          bloodGroup: 'B+',
          registeredAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Patient(
          id: 'pat_2',
          patientId: 'P-102',
          name: 'Sita Devi',
          mobile: '+91 98765 22222',
          gender: 'Female',
          age: 35,
          address: '45 Cross Street, Anna Nagar',
          bloodGroup: 'O+',
          registeredAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ];
    }
    if (_opVisits.isEmpty) {
      _opVisits = [
        OpVisit(
          id: 'op_visit_1',
          opNumber: 'OP-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-01',
          tokenNumber: 1,
          branchId: 'main_clinic',
          patientId: 'pat_1',
          patientName: 'Ramesh Kumar',
          patientPhone: '+91 98765 11111',
          doctorId: 'doc_1',
          doctorName: 'Dr. A. Sharma',
          date: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
          time: '09:30 AM',
          reasonForVisit: 'Fever and cold since 2 days',
          vitals: Vitals(bp: '120/80', pulseBpm: 76, temperatureF: 99.2, weightKg: 70, heightCm: 172),
          status: 'waiting',
          consultationFee: 300.0,
          amountPaid: 300.0,
          paymentStatus: PaymentStatus.paid,
          collectedByType: 'Nurse',
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        OpVisit(
          id: 'op_visit_2',
          opNumber: 'OP-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-02',
          tokenNumber: 2,
          branchId: 'main_clinic',
          patientId: 'pat_2',
          patientName: 'Sita Devi',
          patientPhone: '+91 98765 22222',
          doctorId: 'doc_1',
          doctorName: 'Dr. A. Sharma',
          date: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
          time: '10:00 AM',
          reasonForVisit: 'General checkup & headache',
          vitals: Vitals(bp: '118/78', pulseBpm: 72, temperatureF: 98.4, weightKg: 58, heightCm: 160),
          status: 'in_consultation',
          consultationFee: 300.0,
          amountPaid: 300.0,
          paymentStatus: PaymentStatus.paid,
          collectedByType: 'Nurse',
          createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
      ];
    }
    if (_payments.isEmpty) {
      _payments = [
        Payment(
          id: 'pay_1',
          billNumber: 'BILL-01',
          appointmentId: 'op_visit_1',
          patientId: 'pat_1',
          patientName: 'Ramesh Kumar',
          patientPhone: '+91 98765 11111',
          consultationFee: 300.0,
          paidToNurse: 300.0,
          nursePaymentMode: PaymentMode.cash,
          collectedByType: 'Nurse',
          collectedByName: 'Reception Staff',
          paymentDate: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        Payment(
          id: 'pay_2',
          billNumber: 'BILL-02',
          appointmentId: 'op_visit_2',
          patientId: 'pat_2',
          patientName: 'Sita Devi',
          patientPhone: '+91 98765 22222',
          consultationFee: 300.0,
          paidToNurse: 300.0,
          nursePaymentMode: PaymentMode.upi,
          collectedByType: 'Nurse',
          collectedByName: 'Reception Staff',
          paymentDate: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
      ];
    }
    _safeNotify();
  }

  void _handleStreamError(String collection, Object error) {
    debugPrint('[ClinicStateProvider] Firestore stream notice ($collection): $error');
  }

  StreamSubscription<dynamic> _bind<T>(
    Stream<T> stream,
    void Function(T value) onData,
    String label,
  ) {
    return stream.listen(
      (value) {
        onData(value);
        _safeNotify();
      },
      onError: (Object e) => _handleStreamError(label, e),
    );
  }

  void _bindPublicStreams() {
    _publicSubscriptions.addAll([
      _bind(_firestoreService.streamClinicSettings(), (ClinicSettings? s) {
        if (s != null) {
          _settings = s;
          _settingsLoaded = true;
          _syncError = null;
        }
      }, 'clinic_settings'),
      _bind(_firestoreService.streamDoctors(), (List<Doctor> l) {
        if (l.isNotEmpty) {
          _doctors = l;
        } else if (_doctors.isEmpty) {
          _doctors = List.from(ClinicData.defaultDoctors);
        }
      }, 'doctors'),
    ]);
  }

  void _bindPrivateStreams() {
    if (_privateSubscriptions.isNotEmpty) return;

    _privateSubscriptions.addAll([
      _bind(_firestoreService.streamPatients(), (List<Patient> l) {
        if (l.isNotEmpty) {
          _patients = l;
        } else if (_patients.isEmpty) {
          _patients = List.from(ClinicData.defaultPatients);
        }
      }, 'patients'),
      _bind(_firestoreService.streamOpVisits(), (List<OpVisit> l) {
        if (l.isNotEmpty) {
          _opVisits = l;
        } else if (_opVisits.isEmpty) {
          _opVisits = List.from(ClinicData.defaultOpVisits);
        }
      }, 'op_visits'),
      _bind(_firestoreService.streamAppointments(), (List<Appointment> l) {
        if (l.isNotEmpty) _appointments = l;
      }, 'appointments'),
      _bind(_firestoreService.streamPayments(), (List<Payment> l) {
        if (l.isNotEmpty) {
          _payments = l;
        } else if (_payments.isEmpty) {
          _payments = List.from(ClinicData.defaultPayments);
        }
      }, 'payments'),
      _bind(_firestoreService.streamCashHandovers(),
          (List<CashHandover> l) => _cashHandovers = l, 'cash_handovers'),
      _bind(_firestoreService.streamPrescriptions(),
          (List<Prescription> l) => _prescriptions = l, 'prescriptions'),
      _bind(_firestoreService.streamCaseNotes(),
          (List<CaseNote> l) => _caseNotes = l, 'case_notes'),
      _bind(_firestoreService.streamAttendance(),
          (List<StaffAttendance> l) => _attendanceRecords = l, 'staff_attendance'),
      _bind(_firestoreService.streamPharmacyItems(), (List<PharmacyItem> l) {
        if (l.isNotEmpty) _pharmacyItems = l;
      }, 'pharmacy_items'),
      _bind(_authService.streamClinicUsers(), (List<AppUser> l) {
        if (l.isNotEmpty) {
          _staffUsers = l;
          _enforceOwnAccountStillValid(l);
        }
      }, 'users'),
    ]);
  }

  Future<void> _unbindPrivateStreams() async {
    for (final sub in _privateSubscriptions) {
      await sub.cancel();
    }
    _privateSubscriptions.clear();

    _patients = List.from(ClinicData.defaultPatients);
    _opVisits = List.from(ClinicData.defaultOpVisits);
    _appointments = List.from(ClinicData.defaultAppointments);
    _payments = List.from(ClinicData.defaultPayments);
    _cashHandovers = [];
    _prescriptions = [];
    _caseNotes = [];
    _attendanceRecords = [];
    _staffUsers = [];
  }

  /// If the admin deactivates or deletes an account while that person is using
  /// the app, drop their session at the next snapshot rather than waiting for
  /// the next cold start.
  void _enforceOwnAccountStillValid(List<AppUser> users) {
    final me = _currentUser;
    if (me == null || me.role == UserRole.customer) return;
    final mine = users.where((u) => u.id == me.id).toList();
    if (mine.isEmpty) return; // Not yet loaded, or a patient session.
    if (!mine.first.active) {
      // Deactivated mid-session: drop the session and the data listeners now,
      // rather than at the next cold start.
      logout();
    } else if (mine.first.role != me.role || mine.first.name != me.name) {
      _currentUser = mine.first;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final sub in [..._publicSubscriptions, ..._privateSubscriptions]) {
      sub.cancel();
    }
    _publicSubscriptions.clear();
    _privateSubscriptions.clear();
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  ClinicBranch get selectedBranch => _selectedBranch;
  AppUser? get currentUser => _currentUser;
  ClinicSettings get settings => _settings;
  bool get settingsLoaded => _settingsLoaded;
  String? get syncError => _syncError;

  String get clinicName => _settings.clinicName;
  String get clinicTagline => _settings.tagline;
  String get patientIdPrefix => _settings.patientIdPrefix;
  double get defaultConsultationFee => _settings.defaultConsultationFee;

  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isSignedIn => _currentUser != null;

  List<ClinicBranch> get branches => _branches;
  List<Doctor> get doctors => _doctors;

  /// Doctors selectable at the OP desk and in the patient app.
  List<Doctor> get activeDoctors => _doctors.where((d) => d.active).toList();

  List<Patient> get patients => _patients;
  List<Appointment> get appointments => _appointments;
  List<OpVisit> get opVisits => _opVisits;
  List<CaseNote> get caseNotes => _caseNotes;
  List<Prescription> get prescriptions => _prescriptions;
  List<Payment> get payments => _payments;
  List<CashHandover> get cashHandovers => _cashHandovers;
  List<PharmacyItem> get pharmacyItems => _pharmacyItems;
  List<StockTransaction> get stockTransactions => _stockTransactions;
  List<StaffAttendance> get attendanceRecords => _attendanceRecords;
  List<AppUser> get staffUsers => _staffUsers;
  List<Map<String, dynamic>> get notifications => _notifications;

  List<Doctor> get branchDoctors => activeDoctors;
  List<Appointment> get branchAppointments => _appointments;
  List<OpVisit> get branchOpVisits => _opVisits;
  List<Payment> get branchPayments => _payments;
  List<PharmacyItem> get branchPharmacyItems => _pharmacyItems;
  List<PharmacyItem> get lowStockItems =>
      _pharmacyItems.where((i) => i.isLowStock).toList();

  /// The doctor whose name goes on tokens and bills. Falls back to the first
  /// active doctor so the OP desk keeps working if the signed-in user is a
  /// nurse rather than a doctor.
  Doctor? get primaryDoctor {
    final linkedId = _currentUser?.doctorId;
    if (linkedId != null) {
      final matches = _doctors.where((d) => d.id == linkedId);
      if (matches.isNotEmpty) return matches.first;
    }
    final active = activeDoctors;
    return active.isEmpty ? null : active.first;
  }

  String get primaryDoctorName => primaryDoctor?.displayName ?? 'Doctor';

  void selectBranch(ClinicBranch branch) {
    _selectedBranch = branch;
    _safeNotify();
  }

  void clearSyncError() {
    _syncError = null;
    _safeNotify();
  }

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  /// Installs a session that [AuthService] has already verified against
  /// Firebase Auth and the `users` collection. This is the only way a
  /// privileged session is created — there is no local role assignment.
  void setAuthenticatedUser(AppUser user) {
    _currentUser = user;
    _syncError = null;
    if (user.role.isClinicStaff) {
      _bindPrivateStreams();
    }
    // Best-effort only. The role stored here is a UI hint; the authority is
    // always Firebase Auth plus `users/{uid}`, re-checked on every launch.
    _rememberRole(user.role.name);
    _safeNotify();
  }

  Future<void> _rememberRole(String? roleName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (roleName == null) {
        await prefs.remove('saved_user_role');
        await prefs.remove('saved_staff_tab');
        await prefs.remove('saved_doctor_tab');
      } else {
        await prefs.setString('saved_user_role', roleName);
      }
    } catch (e) {
      debugPrint('[ClinicStateProvider] preference write skipped: $e');
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _syncError = null;
    await _unbindPrivateStreams();
    await _authService.signOut();
    await _rememberRole(null);
    _safeNotify();
  }

  // ---------------------------------------------------------------------------
  // Admin: clinic settings
  // ---------------------------------------------------------------------------

  /// Saves the clinic identity. Rejected unless the caller is an admin — the
  /// Firestore rules enforce the same thing server-side.
  Future<bool> saveClinicSettings(ClinicSettings updated) async {
    if (!isAdmin) return false;
    final stamped = updated.copyWith(
      updatedAt: DateTime.now(),
      updatedByName: _currentUser?.name ?? 'Admin',
    );
    final ok = await _firestoreService.saveClinicSettings(stamped);
    if (ok) {
      _settings = stamped;
      _settingsLoaded = true;
      _safeNotify();
    }
    return ok;
  }

  // ---------------------------------------------------------------------------
  // Admin: doctor roster
  // ---------------------------------------------------------------------------

  Future<bool> saveDoctor(Doctor doctor) async {
    if (!isAdmin) return false;
    final ok = await _firestoreService.saveDoctor(doctor);
    if (ok) {
      final idx = _doctors.indexWhere((d) => d.id == doctor.id);
      if (idx == -1) {
        _doctors = [..._doctors, doctor];
      } else {
        _doctors = [..._doctors]..[idx] = doctor;
      }
      _safeNotify();
    }
    return ok;
  }

  /// Hides a doctor from new bookings without touching the visits, bills and
  /// prescriptions that already carry their name.
  Future<bool> setDoctorActive(String doctorId, bool active) async {
    final matches = _doctors.where((d) => d.id == doctorId);
    if (matches.isEmpty) return false;
    return saveDoctor(matches.first.copyWith(active: active));
  }

  Future<bool> deleteDoctor(String doctorId) async {
    if (!isAdmin) return false;
    final ok = await _firestoreService.deleteDoctor(doctorId);
    if (ok) {
      _doctors = _doctors.where((d) => d.id != doctorId).toList();
      _safeNotify();
    }
    return ok;
  }

  /// Stable, collision-free id for a new doctor record.
  String newDoctorId() {
    final slug = _uuid.v4().split('-').first;
    return 'doc_$slug';
  }

  // ---------------------------------------------------------------------------
  // Today's live revenue & financial audit metrics
  // ---------------------------------------------------------------------------

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get todayKey => _dateKey(DateTime.now());

  Iterable<Payment> get _todayPayments => _payments.where((p) => _isToday(p.paymentDate));

  double get todayTotalRevenue =>
      _todayPayments.fold(0.0, (sum, p) => sum + p.amountPaid);

  double get todayBilledAmount =>
      _todayPayments.fold(0.0, (sum, p) => sum + p.totalAmount);

  double get todayNurseCollected =>
      _todayPayments.fold(0.0, (sum, p) => sum + p.paidToNurse);

  double get todayNurseCash => _todayPayments
      .where((p) => p.nursePaymentMode == PaymentMode.cash)
      .fold(0.0, (sum, p) => sum + p.paidToNurse);

  double get todayNurseUpi => _todayPayments
      .where((p) => p.nursePaymentMode == PaymentMode.upi)
      .fold(0.0, (sum, p) => sum + p.paidToNurse);

  double get todayDoctorCollected =>
      _todayPayments.fold(0.0, (sum, p) => sum + p.paidToDoctor);

  double get todayDoctorUpi => _todayPayments
      .where((p) => p.doctorPaymentMode == PaymentMode.upi)
      .fold(0.0, (sum, p) => sum + p.paidToDoctor);

  double get todayDoctorCash => _todayPayments
      .where((p) => p.doctorPaymentMode == PaymentMode.cash)
      .fold(0.0, (sum, p) => sum + p.paidToDoctor);

  double get todayPendingDues =>
      _todayPayments.fold(0.0, (sum, p) => sum + p.balance);

  /// Share of today's takings received by card/UPI rather than cash, as a
  /// percentage. Returns 0 when nothing has been collected yet.
  double get todayUpiSharePercent {
    final total = todayTotalRevenue;
    if (total <= 0) return 0;
    return ((todayNurseUpi + todayDoctorUpi) / total) * 100;
  }

  double get todayCashSharePercent {
    final total = todayTotalRevenue;
    if (total <= 0) return 0;
    return ((todayNurseCash + todayDoctorCash) / total) * 100;
  }

  int get todayPatientCount =>
      _opVisits.where((v) => _isToday(v.createdAt)).length;

  List<Payment> get pendingPayments => _payments.where((p) => p.balance > 0).toList();

  List<OpVisit> get pendingDuesOpVisits =>
      _opVisits.where((v) => v.balance > 0).toList();

  // ---------------------------------------------------------------------------
  // End-of-day cash handover
  // ---------------------------------------------------------------------------

  CashHandover? get todayHandover {
    final matches = _cashHandovers.where((h) => h.date == todayKey);
    return matches.isEmpty ? null : matches.first;
  }

  List<CashHandover> getTodayHandovers() =>
      _cashHandovers.where((h) => h.date == todayKey).toList();

  double getTodayTotalHandedOverCash() => _cashHandovers
      .where((h) => h.date == todayKey)
      .fold(0.0, (sum, h) => sum + h.nurseCash);

  /// Cash physically in the reception drawer: what was taken in cash today,
  /// less what has already been handed to the doctor.
  double get physicalCashInHand =>
      math.max(0.0, todayNurseCash - getTodayTotalHandedOverCash());

  void recordCashHandover({
    required double amount,
    String? handedOverByName,
    String? receivedByName,
    String? notes,
  }) {
    final now = DateTime.now();
    final handover = CashHandover(
      id: _uuid.v4(),
      date: todayKey,
      nurseCash: amount,
      nurseUpi: 0.0,
      doctorUpi: 0.0,
      totalRevenue: 0.0,
      handedOverByName: handedOverByName ?? _currentUser?.name ?? 'Reception Desk',
      receivedByName: receivedByName ?? primaryDoctorName,
      settledAt: now,
      status: 'confirmed',
      notes: notes,
    );

    _cashHandovers.insert(0, handover);
    _firestoreService.saveCashHandover(handover);
    _safeNotify();
  }

  void deleteCashHandover(String handoverId) {
    _cashHandovers.removeWhere((h) => h.id == handoverId);
    _firestoreService.deleteCashHandover(handoverId);
    _safeNotify();
  }

  void resetCashHandover() {
    for (final h in _cashHandovers.where((h) => h.date == todayKey)) {
      _firestoreService.deleteCashHandover(h.id);
    }
    _cashHandovers.removeWhere((h) => h.date == todayKey);
    _safeNotify();
  }

  /// Wipes patients, visits, bills and clinical records across every device.
  /// Admin-only, and it deliberately leaves staff accounts, the doctor roster
  /// and the clinic profile intact.
  Future<bool> resetClinicalData() async {
    if (!isAdmin) return false;
    final ok = await _firestoreService.clearClinicalData();
    if (ok) {
      _patients = [];
      _opVisits = [];
      _payments = [];
      _appointments = [];
      _cashHandovers = [];
      _caseNotes = [];
      _prescriptions = [];
      _safeNotify();
    }
    return ok;
  }

  void updatePaymentMode(String paymentId, PaymentMode newMode) {
    final idx = _payments.indexWhere((p) => p.id == paymentId);
    if (idx == -1) return;
    final old = _payments[idx];
    final updated = old.copyWith(
      nursePaymentMode: old.paidToNurse > 0 ? newMode : old.nursePaymentMode,
      doctorPaymentMode: old.paidToDoctor > 0 ? newMode : old.doctorPaymentMode,
    );
    _payments[idx] = updated;
    _firestoreService.savePayment(updated);
    _safeNotify();
  }

  // ---------------------------------------------------------------------------
  // Patients
  // ---------------------------------------------------------------------------

  /// Looks a patient up by the last 10 digits of their mobile number. An
  /// empty or too-short number matches nothing, so a blank field can never
  /// resolve to some unrelated patient's record.
  Patient? findPatientByPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 10) return null;
    final tail = cleaned.substring(cleaned.length - 10);
    for (final p in _patients) {
      final digits = p.mobile.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 10 && digits.endsWith(tail)) return p;
    }
    return null;
  }

  bool loginWithVerifiedPhone(String phone) {
    final existingPatient = findPatientByPhone(phone);
    if (existingPatient == null) return false;
    _currentUser = AppUser(
      id: existingPatient.id,
      name: existingPatient.name,
      emailOrPhone: existingPatient.mobile,
      role: UserRole.customer,
      patientId: existingPatient.patientId,
      branchId: _selectedBranch.id,
    );
    _safeNotify();
    return true;
  }

  Patient registerAndLoginNewPatient({
    required String name,
    required String mobile,
    required String gender,
    required int age,
    required String address,
    String bloodGroup = 'O+',
    String? emergencyContact,
    String? allergies,
  }) {
    final newPatient = registerPatient(
      name: name,
      mobile: mobile,
      gender: gender,
      age: age,
      address: address,
      bloodGroup: bloodGroup,
      emergencyContact: emergencyContact,
      allergies: allergies,
    );

    _currentUser = AppUser(
      id: newPatient.id,
      name: newPatient.name,
      emailOrPhone: newPatient.mobile,
      role: UserRole.customer,
      patientId: newPatient.patientId,
      branchId: _selectedBranch.id,
    );

    _safeNotify();
    return newPatient;
  }

  /// Next patient number, taken as a high-water mark over the records that
  /// actually exist and the counter stored in settings. Deleting the newest
  /// patient therefore cannot hand their ID to somebody else.
  int get _nextPatientSequence {
    final prefix = _settings.patientIdPrefix;
    var maxSeq = _settings.patientIdStart - 1;
    for (final p in _patients) {
      if (!p.patientId.startsWith(prefix)) continue;
      final n = int.tryParse(p.patientId.substring(prefix.length));
      if (n != null && n > maxSeq) maxSeq = n;
    }
    return maxSeq + 1;
  }

  int get patientIdSequence => _nextPatientSequence;

  String generateNextPatientId() =>
      '${_settings.patientIdPrefix}$_nextPatientSequence';

  Patient registerPatient({
    required String name,
    required String mobile,
    required String gender,
    required int age,
    required String address,
    String bloodGroup = 'O+',
    String? dateOfBirth,
    String? emergencyContact,
    String? allergies,
  }) {
    final existing = findPatientByPhone(mobile);
    if (existing != null) return existing;

    final seq = _nextPatientSequence;
    final newPatId = '${_settings.patientIdPrefix}$seq';

    final newPatient = Patient(
      id: _uuid.v4(),
      patientId: newPatId,
      name: name,
      mobile: mobile,
      gender: gender,
      age: age,
      dateOfBirth: dateOfBirth,
      address: address,
      bloodGroup: bloodGroup,
      emergencyContact: emergencyContact,
      allergies: allergies,
      registeredAt: DateTime.now(),
    );

    _patients.insert(0, newPatient);
    _firestoreService.savePatient(newPatient);

    // Persist the high-water mark so the sequence survives deletions and
    // reinstalls.
    if (seq >= _settings.patientIdStart) {
      _settings = _settings.copyWith(patientIdStart: seq + 1);
      _firestoreService.saveClinicSettings(_settings);
    }

    _safeNotify();
    return newPatient;
  }

  void updatePatient(Patient patient) {
    final idx = _patients.indexWhere(
        (p) => p.id == patient.id || p.patientId == patient.patientId);
    if (idx != -1) _patients[idx] = patient;
    _firestoreService.savePatient(patient);
    _safeNotify();
  }

  /// Deletes a patient and their linked records. Matching is by identifier
  /// only — an earlier version also matched on the patient's name, which wiped
  /// the visit history of anyone who happened to share it.
  void deletePatient(String patientIdOrDocId) {
    final matches = _patients.where(
        (p) => p.id == patientIdOrDocId || p.patientId == patientIdOrDocId);
    if (matches.isEmpty) return;
    final pat = matches.first;

    final ids = {pat.id, pat.patientId}..removeWhere((s) => s.isEmpty);

    final matchingOpIds = _opVisits
        .where((v) => ids.contains(v.patientId))
        .map((v) => v.id)
        .toSet();

    _patients.removeWhere((p) => p.id == pat.id);
    _opVisits.removeWhere((v) => ids.contains(v.patientId));
    _appointments.removeWhere(
        (a) => ids.contains(a.patientId) || matchingOpIds.contains(a.id));
    _payments.removeWhere((p) =>
        ids.contains(p.patientId) || matchingOpIds.contains(p.appointmentId));
    _prescriptions.removeWhere((rx) =>
        ids.contains(rx.patientId) || matchingOpIds.contains(rx.appointmentId));
    _caseNotes.removeWhere((n) =>
        ids.contains(n.patientId) || matchingOpIds.contains(n.appointmentId));

    _firestoreService.deletePatient(pat.id, patientCode: pat.patientId);
    for (final opId in matchingOpIds) {
      _firestoreService.deleteOpVisit(opId);
    }
    _safeNotify();
  }

  void deleteOpVisit(String opVisitId) {
    _opVisits.removeWhere((v) => v.id == opVisitId);
    _appointments.removeWhere((a) => a.id == opVisitId);
    _payments.removeWhere((p) => p.appointmentId == opVisitId);
    _prescriptions.removeWhere((rx) => rx.appointmentId == opVisitId);
    _caseNotes.removeWhere((n) => n.appointmentId == opVisitId);
    _firestoreService.deleteOpVisit(opVisitId);
    _safeNotify();
  }

  List<Patient> searchPatients(String query) {
    if (query.trim().isEmpty) return _patients;
    final q = query.toLowerCase().trim();
    return _patients.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.mobile.contains(q) ||
          p.patientId.toLowerCase().contains(q);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Tokens, visits and appointments
  // ---------------------------------------------------------------------------

  /// Token numbers restart at 1 each morning and are derived from the tokens
  /// already issued today, so they neither run away over time nor repeat after
  /// a visit is deleted.
  int get nextTokenNumber {
    final todays = _opVisits.where((v) => _isToday(v.createdAt));
    final todaysAppointments =
        _appointments.where((a) => _isToday(a.createdAt));
    var maxToken = 0;
    for (final v in todays) {
      if (v.tokenNumber > maxToken) maxToken = v.tokenNumber;
    }
    for (final a in todaysAppointments) {
      if (a.tokenNumber > maxToken) maxToken = a.tokenNumber;
    }
    return maxToken + 1;
  }

  Appointment bookAppointment({
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required String date,
    required String timeSlot,
    required String reason,
    String createdByType = 'patient',
    double? fee,
    bool isFeePaid = false,
  }) {
    final token = nextTokenNumber;
    final id = _uuid.v4();
    final now = DateTime.now();

    final appt = Appointment(
      id: id,
      branchId: _selectedBranch.id,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      date: date,
      timeSlot: timeSlot,
      reason: reason,
      status: AppointmentStatus.checkedIn,
      tokenNumber: token,
      createdByType: createdByType,
      createdAt: now,
      fee: fee ?? _settings.defaultConsultationFee,
      isFeePaid: isFeePaid,
    );

    _appointments.insert(0, appt);
    _firestoreService.saveAppointment(appt);
    _safeNotify();
    return appt;
  }

  OpVisit createOpVisit({
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String doctorId,
    required String doctorName,
    required String reasonForVisit,
    required Vitals vitals,
    double? consultationFee,
    double? initialPaid,
    PaymentMode initialMode = PaymentMode.cash,
    bool collectNow = true,
  }) {
    final fee = consultationFee ?? _settings.defaultConsultationFee;
    final paid = initialPaid ?? fee;
    final token = nextTokenNumber;
    final opId = _uuid.v4();
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final opNumber = 'OP-$stamp-${token.toString().padLeft(2, '0')}';

    final paidToNurse = collectNow ? paid : 0.0;
    final balance = math.max(0.0, fee - paidToNurse);
    final status = collectNow
        ? (balance <= 0 ? PaymentStatus.paid : PaymentStatus.partial)
        : PaymentStatus.pending;

    final newVisit = OpVisit(
      id: opId,
      opNumber: opNumber,
      tokenNumber: token,
      branchId: _selectedBranch.id,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      doctorId: doctorId,
      doctorName: doctorName,
      date: '${now.day} ${_monthName(now.month)} ${now.year}',
      time: _formatTime(now),
      reasonForVisit: reasonForVisit,
      vitals: vitals,
      status: 'waiting',
      consultationFee: fee,
      amountPaid: paidToNurse,
      balance: balance,
      paymentStatus: status,
      collectedByType: collectNow ? 'Nurse' : 'Pending',
      createdAt: now,
    );

    _opVisits.insert(0, newVisit);
    _firestoreService.saveOpVisit(newVisit);

    final doctorMatches = _doctors.where((d) => d.id == doctorId);
    final specialty =
        doctorMatches.isEmpty ? 'General Physician' : doctorMatches.first.specialty;

    final appt = Appointment(
      id: opId,
      branchId: _selectedBranch.id,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: specialty,
      date: newVisit.date,
      timeSlot: newVisit.time,
      reason: reasonForVisit,
      status: AppointmentStatus.checkedIn,
      tokenNumber: token,
      createdByType: 'staff',
      createdAt: now,
      fee: fee,
      isFeePaid: balance <= 0,
    );
    _appointments.insert(0, appt);
    _firestoreService.saveAppointment(appt);

    final billNo =
        '${_settings.billPrefix}-$stamp-${token.toString().padLeft(2, '0')}';
    final payment = Payment(
      id: _uuid.v4(),
      billNumber: billNo,
      appointmentId: opId,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      branchId: _selectedBranch.id,
      consultationFee: fee,
      totalAmount: fee,
      paidToNurse: paidToNurse,
      paidToDoctor: 0.0,
      nursePaymentMode: initialMode,
      doctorPaymentMode: PaymentMode.upi,
      amountPaid: paidToNurse,
      balance: balance,
      status: status,
      collectedByType: collectNow ? 'Nurse' : 'Pending',
      collectedByName: _currentUser?.name ?? 'Reception Desk',
      paymentDate: now,
      notes: collectNow
          ? '₹${paidToNurse.toInt()} collected at counter (${initialMode.label})'
          : 'Pending payment at Doctor cabin / counter',
    );
    _payments.insert(0, payment);
    _firestoreService.savePayment(payment);

    _safeNotify();
    return newVisit;
  }

  void addDoctorProcedureCharge({
    required String opVisitId,
    required String title,
    required double amount,
  }) {
    final opIndex = _opVisits.indexWhere((v) => v.id == opVisitId);
    if (opIndex == -1) return;

    final old = _opVisits[opIndex];
    final charge = ProcedureCharge(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      addedBy: 'Doctor',
      addedAt: DateTime.now(),
    );

    final newCharges = List<ProcedureCharge>.from(old.procedureCharges)..add(charge);
    final newTotal =
        old.consultationFee + newCharges.fold(0.0, (s, c) => s + c.amount);
    final newBalance = math.max(0.0, newTotal - old.amountPaid);
    final newStatus = newBalance <= 0 ? PaymentStatus.paid : PaymentStatus.partial;

    _opVisits[opIndex] = old.copyWith(
      procedureCharges: newCharges,
      balance: newBalance,
      paymentStatus: newStatus,
    );
    _firestoreService.saveOpVisit(_opVisits[opIndex]);

    final payIndex = _payments.indexWhere((p) => p.appointmentId == opVisitId);
    if (payIndex != -1) {
      final pOld = _payments[payIndex];
      _payments[payIndex] = pOld.copyWith(
        procedureCharges: newCharges,
        totalAmount: newTotal,
        balance: newBalance,
        status: newStatus,
      );
      _firestoreService.savePayment(_payments[payIndex]);
    }

    _safeNotify();
  }

  void collectPaymentInDoctorCabin({
    required String opVisitId,
    required double amount,
    required PaymentMode mode,
    required String doctorName,
    String? notes,
  }) {
    final opIndex = _opVisits.indexWhere((v) => v.id == opVisitId);
    if (opIndex == -1) return;

    final old = _opVisits[opIndex];
    final newPaid = old.amountPaid + amount;
    final newBalance = math.max(0.0, old.totalBill - newPaid);
    final newStatus = newBalance <= 0 ? PaymentStatus.paid : PaymentStatus.partial;

    _opVisits[opIndex] = old.copyWith(
      amountPaid: newPaid,
      balance: newBalance,
      paymentStatus: newStatus,
      collectedByType: old.collectedByType == 'Nurse' ? 'Split' : 'Doctor',
    );
    _firestoreService.saveOpVisit(_opVisits[opIndex]);

    final payIndex = _payments.indexWhere((p) => p.appointmentId == opVisitId);
    if (payIndex != -1) {
      final pOld = _payments[payIndex];
      final newDocPaid = pOld.paidToDoctor + amount;
      _payments[payIndex] = pOld.copyWith(
        paidToDoctor: newDocPaid,
        doctorPaymentMode: mode,
        amountPaid: pOld.paidToNurse + newDocPaid,
        balance: newBalance,
        status: newStatus,
        collectedByType: pOld.paidToNurse > 0 ? 'Split' : 'Doctor',
        collectedByName: '$doctorName / ${pOld.collectedByName}',
        notes: notes ??
            '₹${amount.toInt()} collected in cabin by $doctorName (${mode.label})',
      );
      _firestoreService.savePayment(_payments[payIndex]);
    }

    _safeNotify();
  }

  Payment recordStaffPayment({
    required String appointmentId,
    required String patientId,
    required String patientName,
    required double consultationFee,
    required double amountPaid,
    required PaymentMode paymentMode,
    String? notes,
  }) {
    final payIndex = _payments.indexWhere((p) => p.appointmentId == appointmentId);
    final opIndex = _opVisits.indexWhere((v) => v.id == appointmentId);
    final now = DateTime.now();

    if (payIndex != -1) {
      final pOld = _payments[payIndex];
      final newNursePaid = pOld.paidToNurse + amountPaid;
      final totalPaid = newNursePaid + pOld.paidToDoctor;
      final newBal = math.max(0.0, pOld.totalAmount - totalPaid);
      final newStat = newBal <= 0 ? PaymentStatus.paid : PaymentStatus.partial;

      _payments[payIndex] = pOld.copyWith(
        paidToNurse: newNursePaid,
        nursePaymentMode: paymentMode,
        amountPaid: totalPaid,
        balance: newBal,
        status: newStat,
        collectedByType: pOld.paidToDoctor > 0 ? 'Split' : 'Nurse',
        collectedByName: _currentUser?.name ?? 'Reception Desk',
        paymentDate: now,
        notes: notes ??
            'Balance ₹${amountPaid.toInt()} collected at counter (${paymentMode.label})',
      );
      _firestoreService.savePayment(_payments[payIndex]);

      if (opIndex != -1) {
        _opVisits[opIndex] = _opVisits[opIndex].copyWith(
          amountPaid: totalPaid,
          balance: newBal,
          paymentStatus: newStat,
          collectedByType: pOld.paidToDoctor > 0 ? 'Split' : 'Nurse',
        );
        _firestoreService.saveOpVisit(_opVisits[opIndex]);
      }

      _safeNotify();
      return _payments[payIndex];
    }

    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final billNo =
        '${_settings.billPrefix}-$stamp-${(_payments.length + 1).toString().padLeft(2, '0')}';
    final bal = math.max(0.0, consultationFee - amountPaid);
    final payment = Payment(
      id: _uuid.v4(),
      billNumber: billNo,
      appointmentId: appointmentId,
      patientId: patientId,
      patientName: patientName,
      consultationFee: consultationFee,
      totalAmount: consultationFee,
      paidToNurse: amountPaid,
      nursePaymentMode: paymentMode,
      amountPaid: amountPaid,
      balance: bal,
      status: bal <= 0 ? PaymentStatus.paid : PaymentStatus.partial,
      collectedByType: 'Nurse',
      collectedByName: _currentUser?.name ?? 'Reception Desk',
      paymentDate: now,
      notes: notes,
    );
    _payments.insert(0, payment);
    _firestoreService.savePayment(payment);
    _safeNotify();
    return payment;
  }

  void completeConsultation({
    required String appointmentId,
    required String patientId,
    required String doctorId,
    required String doctorName,
    required String chiefComplaint,
    required String clinicalFindings,
    required String diagnosis,
    required String treatmentAdvice,
    String? privateNotes,
    List<PrescriptionItem>? prescriptionItems,
    String? followUpDate,
    String? followUpReason,
    double? feeCollected,
    PaymentMode? paymentMode,
  }) {
    final now = DateTime.now();

    final caseNote = CaseNote(
      id: _uuid.v4(),
      appointmentId: appointmentId,
      patientId: patientId,
      doctorId: doctorId,
      doctorName: doctorName,
      date: '${now.day} ${_monthName(now.month)} ${now.year}',
      chiefComplaint: chiefComplaint,
      clinicalFindings: clinicalFindings,
      diagnosis: diagnosis,
      treatmentAdvice: treatmentAdvice,
      privateDoctorNotes: privateNotes,
      createdAt: now,
    );
    _caseNotes.insert(0, caseNote);
    _firestoreService.saveCaseNote(caseNote);

    if (prescriptionItems != null && prescriptionItems.isNotEmpty) {
      // Resolve the patient from the visit, and fall back to the name already
      // on the OP record. Reaching for `_patients.first` here used to throw
      // whenever the patient list had not streamed in yet.
      final patientMatches = _patients.where(
          (p) => p.patientId == patientId || p.id == patientId);
      final visitMatches = _opVisits.where((v) => v.id == appointmentId);
      final patientName = patientMatches.isNotEmpty
          ? patientMatches.first.name
          : (visitMatches.isNotEmpty ? visitMatches.first.patientName : 'Patient');

      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final rxNumber =
          'RX-$stamp-${(_prescriptions.length + 1).toString().padLeft(2, '0')}';

      final rx = Prescription(
        id: _uuid.v4(),
        prescriptionNumber: rxNumber,
        appointmentId: appointmentId,
        patientId: patientId,
        patientName: patientName,
        doctorId: doctorId,
        doctorName: doctorName,
        branchId: _selectedBranch.id,
        date: '${now.day} ${_monthName(now.month)} ${now.year}',
        items: prescriptionItems,
        followUpDate: followUpDate,
        followUpReason: followUpReason,
        doctorNotes: treatmentAdvice,
        isDispensed: false,
        createdAt: now,
      );
      _prescriptions.insert(0, rx);
      _firestoreService.savePrescription(rx);
    }

    if (feeCollected != null && feeCollected > 0) {
      collectPaymentInDoctorCabin(
        opVisitId: appointmentId,
        amount: feeCollected,
        mode: paymentMode ?? PaymentMode.upi,
        doctorName: doctorName,
      );
    }

    final opIndex = _opVisits.indexWhere((v) => v.id == appointmentId);
    if (opIndex != -1) {
      _opVisits[opIndex] = _opVisits[opIndex].copyWith(
        status: 'completed',
        diagnosis: diagnosis,
        clinicalFindings: clinicalFindings,
        treatmentAdvice: treatmentAdvice,
      );
      _firestoreService.saveOpVisit(_opVisits[opIndex]);
    }

    updateAppointmentStatus(appointmentId, AppointmentStatus.completed);
    _safeNotify();
  }

  void updateAppointmentStatus(String appointmentId, AppointmentStatus status) {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      _appointments[index] = _appointments[index].copyWith(status: status);
      _firestoreService.saveAppointment(_appointments[index]);
    }

    final opIndex = _opVisits.indexWhere((v) => v.id == appointmentId);
    if (opIndex != -1) {
      var opStatus = 'waiting';
      if (status == AppointmentStatus.inConsultation) opStatus = 'in_consultation';
      if (status == AppointmentStatus.completed) opStatus = 'completed';
      if (status == AppointmentStatus.cancelled) opStatus = 'cancelled';
      _opVisits[opIndex] = _opVisits[opIndex].copyWith(status: opStatus);
      _firestoreService.saveOpVisit(_opVisits[opIndex]);
    }

    _safeNotify();
  }

  // ---------------------------------------------------------------------------
  // Staff attendance
  // ---------------------------------------------------------------------------

  void checkInStaff(String staffId, String staffName) {
    final now = DateTime.now();
    final dateStr = todayKey;
    final existingIndex = _attendanceRecords
        .indexWhere((a) => a.staffId == staffId && a.date == dateStr);
    if (existingIndex != -1) return;

    final rec = StaffAttendance(
      id: '${staffId}_$dateStr',
      staffId: staffId,
      staffName: staffName,
      branchId: _selectedBranch.id,
      date: dateStr,
      checkInTime: _formatTime(now),
      status: AttendanceStatus.present,
      notes: 'Clocked in',
    );
    _attendanceRecords.insert(0, rec);
    _firestoreService.saveAttendance(rec);
    _safeNotify();
  }

  void checkOutStaff(String staffId) {
    final now = DateTime.now();
    final index = _attendanceRecords
        .indexWhere((a) => a.staffId == staffId && a.date == todayKey);
    if (index == -1) return;
    _attendanceRecords[index] =
        _attendanceRecords[index].copyWith(checkOutTime: _formatTime(now));
    _firestoreService.saveAttendance(_attendanceRecords[index]);
    _safeNotify();
  }

  // ---------------------------------------------------------------------------
  // Vitals
  // ---------------------------------------------------------------------------

  void recordPatientVitals({
    required String appointmentId,
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required String bp,
    required int pulse,
    required double temp,
    required double weight,
    required double height,
    int? spo2,
    int? bloodSugar,
  }) {
    final vitals = Vitals(
      bp: bp,
      weightKg: weight,
      heightCm: height,
      pulseBpm: pulse,
      temperatureF: temp,
      spo2Percent: spo2 ?? 98,
      bloodSugarMgDl: bloodSugar,
    );

    final opIndex = _opVisits.indexWhere((v) => v.id == appointmentId);
    if (opIndex != -1) {
      _opVisits[opIndex] = _opVisits[opIndex].copyWith(vitals: vitals);
      _firestoreService.saveOpVisit(_opVisits[opIndex]);
    }
    updateAppointmentStatus(appointmentId, AppointmentStatus.checkedIn);
    _safeNotify();
  }

  // ---------------------------------------------------------------------------
  // Pharmacy inventory
  // ---------------------------------------------------------------------------

  void addStockIn({
    required String pharmacyItemId,
    required int quantity,
    required String batchNumber,
    required String expiryDate,
    required double purchasePrice,
    required double sellingPrice,
  }) {
    final index = _pharmacyItems.indexWhere((i) => i.id == pharmacyItemId);
    if (index == -1) return;

    final old = _pharmacyItems[index];
    _pharmacyItems[index] = old.copyWith(
      currentQuantity: old.currentQuantity + quantity,
      batchNumber: batchNumber,
      expiryDate: expiryDate,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
    );
    _firestoreService.savePharmacyItem(_pharmacyItems[index]);

    _stockTransactions.insert(
      0,
      StockTransaction(
        id: _uuid.v4(),
        pharmacyItemId: pharmacyItemId,
        medicineName: old.medicineName,
        type: StockTransactionType.stockIn,
        quantity: quantity,
        reason: 'Purchase Stock IN - Batch $batchNumber',
        performedBy: _currentUser?.name ?? 'Reception Desk',
        timestamp: DateTime.now(),
      ),
    );
    _safeNotify();
  }

  void dispenseMedicine({
    required String pharmacyItemId,
    required int quantity,
    required String reason,
  }) {
    final index = _pharmacyItems.indexWhere((i) => i.id == pharmacyItemId);
    if (index == -1) return;

    final old = _pharmacyItems[index];
    final newQty = math.max(0, old.currentQuantity - quantity);
    _pharmacyItems[index] = old.copyWith(currentQuantity: newQty);
    _firestoreService.savePharmacyItem(_pharmacyItems[index]);

    _stockTransactions.insert(
      0,
      StockTransaction(
        id: _uuid.v4(),
        pharmacyItemId: pharmacyItemId,
        medicineName: old.medicineName,
        type: StockTransactionType.stockOut,
        quantity: quantity,
        reason: reason,
        performedBy: _currentUser?.name ?? 'Reception Desk',
        timestamp: DateTime.now(),
      ),
    );
    _safeNotify();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }

  String _monthName(int month) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return m[month - 1];
  }
}
