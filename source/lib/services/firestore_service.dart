import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../models/appointment.dart';
import '../models/case_note.dart';
import '../models/cash_handover.dart';
import '../models/clinic_settings.dart';
import '../models/doctor.dart';
import '../models/op_visit.dart';
import '../models/patient.dart';
import '../models/payment.dart';
import '../models/pharmacy_item.dart';
import '../models/prescription.dart';
import '../models/staff_attendance.dart';
import 'firebase_config.dart';

/// Real-time Cloud Firestore access layer.
///
/// Every collection the app reads is exposed as a broadcast stream so an edit
/// on one device — a nurse booking a token, or the admin renaming the clinic —
/// reaches every other signed-in device without a refresh.
class FirestoreService {
  static const String colPatients = 'patients';
  static const String colAppointments = 'appointments';
  static const String colVisits = 'op_visits';
  static const String colPrescriptions = 'prescriptions';
  static const String colCaseNotes = 'case_notes';
  static const String colPayments = 'payments';
  static const String colCashHandovers = 'cash_handovers';
  static const String colDoctors = 'doctors';
  static const String colSettings = 'clinic_settings';
  static const String colPharmacy = 'pharmacy_items';
  static const String colAttendance = 'staff_attendance';

  /// Collections wiped by the admin "reset clinic data" action. Deliberately
  /// excludes `users`, `doctors` and `clinic_settings` — resetting test data
  /// must never delete the staff accounts or the clinic's own identity.
  static const List<String> resettableCollections = [
    colVisits,
    colPatients,
    colPayments,
    colAppointments,
    colPrescriptions,
    colCaseNotes,
    colCashHandovers,
  ];

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Set by [ClinicStateProvider] so a rules denial or connection drop becomes
  /// a visible banner instead of a silently empty screen.
  void Function(String collection, Object error)? onStreamError;

  /// Maps a snapshot stream to models, logging and reporting any failure
  /// rather than letting it tear down the listener silently.
  Stream<List<T>> _collectionStream<T>(
    String collection,
    T Function(Map<String, dynamic> data) parse, {
    String? orderBy,
    bool descending = true,
  }) {
    if (!FirebaseConfig.isFirebaseConfigured) {
      return Stream.value(<T>[]);
    }
    Query<Map<String, dynamic>> query = _db.collection(collection);
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    return query.snapshots().map((snapshot) {
      final out = <T>[];
      for (final doc in snapshot.docs) {
        try {
          out.add(parse(doc.data()));
        } catch (e) {
          // One malformed document must not blank out the whole list.
          debugPrint('[FirestoreService] $collection/${doc.id} parse error: $e');
        }
      }
      return out;
    }).handleError((Object e) {
      debugPrint('[FirestoreService] $collection stream error: $e');
      onStreamError?.call(collection, e);
    });
  }

  // ---------------------------------------------------------------------------
  // Clinic settings (admin-editable identity)
  // ---------------------------------------------------------------------------

  Stream<ClinicSettings?> streamClinicSettings() {
    if (!FirebaseConfig.isFirebaseConfigured) {
      return Stream.value(null);
    }
    return _db
        .collection(colSettings)
        .doc(AppConfig.settingsDocId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return ClinicSettings.fromMap(data);
    }).handleError((Object e) {
      debugPrint('[FirestoreService] settings stream error: $e');
      onStreamError?.call(colSettings, e);
    });
  }

  Future<bool> saveClinicSettings(ClinicSettings settings) async {
    if (!FirebaseConfig.isFirebaseConfigured) return false;
    try {
      await _db
          .collection(colSettings)
          .doc(AppConfig.settingsDocId)
          .set(settings.toMap(), SetOptions(merge: true))
          .timeout(writeAckTimeout);
      return true;
    } on TimeoutException {
      debugPrint('[FirestoreService] saveClinicSettings queued offline');
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] saveClinicSettings error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Doctors (admin-editable roster)
  // ---------------------------------------------------------------------------

  Stream<List<Doctor>> streamDoctors() =>
      _collectionStream(colDoctors, Doctor.fromMap);

  Future<bool> saveDoctor(Doctor doctor) async {
    if (!FirebaseConfig.isFirebaseConfigured) return false;
    try {
      await _db
          .collection(colDoctors)
          .doc(doctor.id)
          .set(doctor.toMap(), SetOptions(merge: true))
          .timeout(writeAckTimeout);
      return true;
    } on TimeoutException {
      debugPrint('[FirestoreService] saveDoctor queued offline');
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] saveDoctor error: $e');
      return false;
    }
  }

  Future<bool> deleteDoctor(String doctorId) async {
    if (!FirebaseConfig.isFirebaseConfigured) return false;
    try {
      await _db.collection(colDoctors).doc(doctorId).delete();
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] deleteDoctor error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Clinical + billing streams
  // ---------------------------------------------------------------------------

  Stream<List<OpVisit>> streamOpVisits() =>
      _collectionStream(colVisits, OpVisit.fromMap, orderBy: 'createdAt');

  Stream<List<Patient>> streamPatients() =>
      _collectionStream(colPatients, Patient.fromMap, orderBy: 'registeredAt');

  Stream<List<Payment>> streamPayments() =>
      _collectionStream(colPayments, Payment.fromMap, orderBy: 'paymentDate');

  Stream<List<CashHandover>> streamCashHandovers() =>
      _collectionStream(colCashHandovers, CashHandover.fromMap, orderBy: 'settledAt');

  Stream<List<Prescription>> streamPrescriptions() =>
      _collectionStream(colPrescriptions, Prescription.fromMap, orderBy: 'createdAt');

  Stream<List<CaseNote>> streamCaseNotes() =>
      _collectionStream(colCaseNotes, CaseNote.fromMap, orderBy: 'createdAt');

  Stream<List<PharmacyItem>> streamPharmacyItems() =>
      _collectionStream(colPharmacy, PharmacyItem.fromMap);

  Stream<List<StaffAttendance>> streamAttendance() =>
      _collectionStream(colAttendance, StaffAttendance.fromMap, orderBy: 'date');

  Stream<List<Appointment>> streamAppointments() => _collectionStream(
        colAppointments,
        (d) => Appointment(
          id: d['id'] as String? ?? '',
          branchId: d['branchId'] as String? ?? 'main_clinic',
          patientId: d['patientId'] as String? ?? '',
          patientName: d['patientName'] as String? ?? '',
          patientPhone: d['patientPhone'] as String? ?? '',
          doctorId: d['doctorId'] as String? ?? '',
          doctorName: d['doctorName'] as String? ?? '',
          doctorSpecialty: d['doctorSpecialty'] as String? ?? 'General Physician',
          date: d['date'] as String? ?? '',
          timeSlot: d['timeSlot'] as String? ?? '',
          reason: d['reason'] as String? ?? '',
          status: AppointmentStatus.values.firstWhere(
            (s) => s.name == (d['status'] as String? ?? 'checkedIn'),
            orElse: () => AppointmentStatus.checkedIn,
          ),
          tokenNumber: (d['tokenNumber'] as num?)?.toInt() ?? 1,
          createdByType: d['createdByType'] as String? ?? 'staff',
          createdAt: DateTime.tryParse(d['createdAt'] as String? ?? '') ?? DateTime.now(),
          fee: (d['fee'] as num?)?.toDouble() ?? 0.0,
          isFeePaid: d['isFeePaid'] as bool? ?? false,
        ),
        orderBy: 'createdAt',
      );

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  Future<bool> savePatient(Patient patient) =>
      _set(colPatients, patient.id, patient.toMap(), 'savePatient');

  Future<bool> saveOpVisit(OpVisit visit) =>
      _set(colVisits, visit.id, visit.toMap(), 'saveOpVisit');

  Future<bool> savePayment(Payment payment) =>
      _set(colPayments, payment.id, payment.toMap(), 'savePayment');

  Future<bool> savePrescription(Prescription prescription) =>
      _set(colPrescriptions, prescription.id, prescription.toMap(), 'savePrescription');

  Future<bool> saveCaseNote(CaseNote note) =>
      _set(colCaseNotes, note.id, note.toMap(), 'saveCaseNote');

  Future<bool> saveCashHandover(CashHandover handover) =>
      _set(colCashHandovers, handover.id, handover.toMap(), 'saveCashHandover');

  Future<bool> savePharmacyItem(PharmacyItem item) =>
      _set(colPharmacy, item.id, item.toMap(), 'savePharmacyItem');

  Future<bool> saveAttendance(StaffAttendance record) =>
      _set(colAttendance, record.id, record.toMap(), 'saveAttendance');

  Future<bool> saveAppointment(Appointment appointment) => _set(
        colAppointments,
        appointment.id,
        {
          'id': appointment.id,
          'branchId': appointment.branchId,
          'patientId': appointment.patientId,
          'patientName': appointment.patientName,
          'patientPhone': appointment.patientPhone,
          'doctorId': appointment.doctorId,
          'doctorName': appointment.doctorName,
          'doctorSpecialty': appointment.doctorSpecialty,
          'date': appointment.date,
          'timeSlot': appointment.timeSlot,
          'reason': appointment.reason,
          'status': appointment.status.name,
          'tokenNumber': appointment.tokenNumber,
          'createdByType': appointment.createdByType,
          'createdAt': appointment.createdAt.toIso8601String(),
          'fee': appointment.fee,
          'isFeePaid': appointment.isFeePaid,
        },
        'saveAppointment',
      );

  /// How long to wait for the server to acknowledge a write before treating it
  /// as queued. Firestore's offline cache applies a `set` locally straight
  /// away but leaves the Future pending until the server confirms — so on a
  /// dropped connection an un-bounded `await` would hang the UI forever.
  static const Duration writeAckTimeout = Duration(seconds: 8);

  Future<bool> _set(
    String collection,
    String id,
    Map<String, dynamic> data,
    String label,
  ) async {
    if (!FirebaseConfig.isFirebaseConfigured) return false;
    if (id.isEmpty) {
      debugPrint('[FirestoreService] $label skipped: empty document id');
      return false;
    }
    try {
      await _db
          .collection(collection)
          .doc(id)
          .set(data, SetOptions(merge: true))
          .timeout(writeAckTimeout);
      return true;
    } on TimeoutException {
      // Written to the local cache and queued; Firestore will push it when the
      // connection returns. Reporting success here is accurate for the user.
      debugPrint('[FirestoreService] $label queued offline');
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] $label error: $e');
      return false;
    }
  }

  Future<bool> updateOpVisitStatus(String id, String status) async {
    if (!FirebaseConfig.isFirebaseConfigured) return false;
    try {
      await _db.collection(colVisits).doc(id).update({'status': status});
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] updateOpVisitStatus error: $e');
      return false;
    }
  }

  Future<bool> updateAppointmentStatus(String id, AppointmentStatus status) async {
    if (!FirebaseConfig.isFirebaseConfigured) return false;
    try {
      await _db.collection(colAppointments).doc(id).update({'status': status.name});
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] updateAppointmentStatus error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Deletes
  // ---------------------------------------------------------------------------

  /// Removes a patient and everything that hangs off them. [docId] is the
  /// Firestore document id; [patientCode] is the human-facing `P-101`, which
  /// child records may reference instead.
  Future<bool> deletePatient(String docId, {String? patientCode}) async {
    if (!FirebaseConfig.isFirebaseConfigured) return false;
    try {
      final ids = <String>{docId, if (patientCode != null) patientCode}
        ..removeWhere((s) => s.isEmpty);
      if (ids.isEmpty) return false;

      await _db.collection(colPatients).doc(docId).delete();

      for (final id in ids) {
        for (final col in [
          colPayments,
          colVisits,
          colAppointments,
          colPrescriptions,
          colCaseNotes,
        ]) {
          await _deleteWhere(col, 'patientId', id);
        }
      }
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] deletePatient error: $e');
      return false;
    }
  }

  Future<bool> deleteOpVisit(String opId) async {
    if (!FirebaseConfig.isFirebaseConfigured) return false;
    try {
      await _db.collection(colVisits).doc(opId).delete();
      await _db.collection(colAppointments).doc(opId).delete();
      await _deleteWhere(colPayments, 'appointmentId', opId);
      await _deleteWhere(colPrescriptions, 'appointmentId', opId);
      await _deleteWhere(colCaseNotes, 'appointmentId', opId);
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] deleteOpVisit error: $e');
      return false;
    }
  }

  Future<bool> deletePayment(String paymentId) async {
    if (!FirebaseConfig.isFirebaseConfigured) return false;
    try {
      await _db.collection(colPayments).doc(paymentId).delete();
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] deletePayment error: $e');
      return false;
    }
  }

  Future<bool> deleteCashHandover(String handoverId) async {
    if (!FirebaseConfig.isFirebaseConfigured) return false;
    try {
      await _db.collection(colCashHandovers).doc(handoverId).delete();
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] deleteCashHandover error: $e');
      return false;
    }
  }

  /// Wipes patient, visit, billing and clinical records. Staff accounts, the
  /// doctor roster and clinic settings are left alone.
  Future<bool> clearClinicalData() async {
    if (!FirebaseConfig.isFirebaseConfigured) return false;
    try {
      for (final col in resettableCollections) {
        await _deleteAll(col);
      }
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] clearClinicalData error: $e');
      return false;
    }
  }

  Future<void> _deleteWhere(String collection, String field, String value) async {
    final snap = await _db.collection(collection).where(field, isEqualTo: value).get();
    await _commitInBatches(snap.docs.map((d) => d.reference));
  }

  Future<void> _deleteAll(String collection) async {
    // Paged so a large collection cannot blow the 500-write batch limit or
    // pull the whole table into memory at once.
    while (true) {
      final snap = await _db.collection(collection).limit(400).get();
      if (snap.docs.isEmpty) break;
      await _commitInBatches(snap.docs.map((d) => d.reference));
      if (snap.docs.length < 400) break;
    }
  }

  Future<void> _commitInBatches(Iterable<DocumentReference> refs) async {
    final all = refs.toList();
    for (var i = 0; i < all.length; i += 400) {
      final batch = _db.batch();
      for (final ref in all.skip(i).take(400)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }
}
