import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../models/clinic_settings.dart';
import '../models/user_role.dart';
import 'firebase_config.dart';

/// A sign-in / provisioning failure with a message safe to show a user.
class AuthFailure implements Exception {
  final String message;
  final String code;
  const AuthFailure(this.message, {this.code = 'unknown'});
  @override
  String toString() => message;
}

/// Authentication and account provisioning for AS Clinic.
///
/// Supports pre-configured accounts (Admin, Doctor, Staff/Nurse) out-of-the-box,
/// dynamically editable Admin credentials from Settings, local fallback, and
/// online Cloud Firebase syncing.
class AuthService {
  static const String colUsers = 'users';
  static const String colSettings = 'clinic_settings';
  static const String bootstrapDocId = 'bootstrap';

  static const String _prefAdminEmail = 'custom_admin_email';
  static const String _prefAdminPassword = 'custom_admin_password';
  static const String _prefAdminName = 'custom_admin_name';
  static const String _prefLocalUsers = 'custom_local_users';
  static const String _prefLastUser = 'last_authenticated_user';

  /// Name of the throwaway secondary Firebase app used to create accounts
  /// without disturbing the admin\'s own session.
  static const String _provisionerAppName = 'asclinic_user_provisioner';

  static const Duration _profileReadTimeout = Duration(seconds: 10);
  static const Duration _probeTimeout = Duration(seconds: 6);

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  User? get currentFirebaseUser =>
      FirebaseConfig.isFirebaseConfigured ? _auth.currentUser : null;

  Stream<User?> authStateChanges() {
    if (!FirebaseConfig.isFirebaseConfigured) return const Stream.empty();
    return _auth.authStateChanges();
  }

  // ---------------------------------------------------------------------------
  // Admin Credentials Management
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> getAdminCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_prefAdminEmail) ?? AppConfig.defaultAdminEmail;
      final password = prefs.getString(_prefAdminPassword) ?? AppConfig.defaultAdminPassword;
      final name = prefs.getString(_prefAdminName) ?? 'Super Admin';
      return {
        'email': email,
        'password': password,
        'name': name,
      };
    } catch (_) {
      return {
        'email': AppConfig.defaultAdminEmail,
        'password': AppConfig.defaultAdminPassword,
        'name': 'Super Admin',
      };
    }
  }

  Future<void> updateAdminCredentials({
    required String newEmail,
    required String newPassword,
    String? newName,
  }) async {
    final cleanEmail = newEmail.trim().toLowerCase();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefAdminEmail, cleanEmail);
      await prefs.setString(_prefAdminPassword, newPassword);
      if (newName != null && newName.trim().isNotEmpty) {
        await prefs.setString(_prefAdminName, newName.trim());
      }
    } catch (e) {
      debugPrint('[AuthService] local updateAdminCredentials error: ');
    }

    if (FirebaseConfig.isFirebaseConfigured) {
      try {
        await _db.collection(colSettings).doc('admin_credentials').set({
          'email': cleanEmail,
          'name': newName ?? 'Super Admin',
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        await _db.collection(colUsers).doc('admin_master').set({
          'email': cleanEmail,
          'emailOrPhone': cleanEmail,
          'name': newName ?? 'Super Admin',
          'role': 'admin',
          'active': true,
          'branchId': 'main_clinic',
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[AuthService] Firestore updateAdminCredentials error: ');
      }
    }
  }

  Future<void> _saveSession(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLastUser, jsonEncode(user.toMap()..['id'] = user.id));
    } catch (_) {}
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefLastUser);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Sign in
  // ---------------------------------------------------------------------------

  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      throw const AuthFailure('Enter your email and password.', code: 'empty');
    }

    // 1. Check Super Admin (Default or Custom saved from Settings)
    final adminCreds = await getAdminCredentials();
    if (cleanEmail == adminCreds['email']!.toLowerCase() && cleanPass == adminCreds['password']) {
      final user = AppUser(
        id: 'admin_master',
        name: adminCreds['name'] ?? 'Super Admin',
        emailOrPhone: cleanEmail,
        role: UserRole.admin,
        branchId: 'main_clinic',
        createdAt: DateTime(2026, 1, 1),
      );
      await _saveSession(user);
      return user;
    }

    // 2. Check Pre-built Doctor
    if (cleanEmail == AppConfig.defaultDoctorEmail.toLowerCase() &&
        cleanPass == AppConfig.defaultDoctorPassword) {
      final user = AppUser(
        id: 'doc_1',
        name: 'Dr. A. Sharma',
        emailOrPhone: cleanEmail,
        role: UserRole.doctor,
        doctorId: 'doc_1',
        branchId: 'main_clinic',
        createdAt: DateTime(2026, 1, 1),
      );
      await _saveSession(user);
      return user;
    }

    // 3. Check Pre-built Staff / Reception Nurse
    if ((cleanEmail == AppConfig.defaultStaffEmail.toLowerCase() || cleanEmail == 'nurse@clinic.com') &&
        (cleanPass == AppConfig.defaultStaffPassword || cleanPass == 'nurse123')) {
      final user = AppUser(
        id: 'staff_1',
        name: 'Reception Nurse',
        emailOrPhone: cleanEmail,
        role: UserRole.staff,
        staffId: 'staff_1',
        branchId: 'main_clinic',
        createdAt: DateTime(2026, 1, 1),
      );
      await _saveSession(user);
      return user;
    }

    // 4. Check locally registered accounts from Admin Console
    try {
      final prefs = await SharedPreferences.getInstance();
      final localUsersJson = prefs.getString(_prefLocalUsers);
      if (localUsersJson != null) {
        final List<dynamic> list = jsonDecode(localUsersJson);
        for (final item in list) {
          if (item['email'] == cleanEmail && item['password'] == cleanPass) {
            final user = AppUser(
              id: item['id'] ?? 'user_',
              name: item['name'] ?? cleanEmail,
              emailOrPhone: cleanEmail,
              role: item['role'] == 'doctor' ? UserRole.doctor : UserRole.staff,
              branchId: item['branchId'] ?? 'main_clinic',
              doctorId: item['doctorId'],
              staffId: item['staffId'],
              createdAt: DateTime.now(),
            );
            await _saveSession(user);
            return user;
          }
        }
      }
    } catch (_) {}

    // 5. Try online Firebase Auth if configured
    if (FirebaseConfig.isFirebaseConfigured) {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPass,
        );
        final uid = credential.user?.uid;
        if (uid != null) {
          final user = await _loadProfileOrSignOut(uid, cleanEmail);
          await _saveSession(user);
          return user;
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          throw const AuthFailure('Incorrect email or password.', code: 'bad-credentials');
        }
      } catch (_) {}
    }

    throw const AuthFailure('Incorrect email or password.', code: 'invalid-credentials');
  }

  Future<AppUser?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserJson = prefs.getString(_prefLastUser);
      if (savedUserJson != null) {
        final map = jsonDecode(savedUserJson) as Map<String, dynamic>;
        return AppUser.fromMap(map, uid: map['id'] ?? 'user_restored');
      }
    } catch (_) {}

    if (!FirebaseConfig.isFirebaseConfigured) return null;
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await _loadProfileOrSignOut(user.uid, user.email ?? '');
    } on AuthFailure catch (e) {
      debugPrint('[AuthService] restoreSession rejected: ');
      return null;
    }
  }

  Future<AppUser> _loadProfileOrSignOut(String uid, String email) async {
    DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _db
          .collection(colUsers)
          .doc(uid)
          .get()
          .timeout(_profileReadTimeout);
    } on TimeoutException {
      try {
        snap = await _db
            .collection(colUsers)
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
      } catch (_) {
        throw const AuthFailure(
          'Connecting to the clinic database is taking longer than expected. Check the connection and try again.',
          code: 'timeout',
        );
      }
    } catch (e) {
      debugPrint('[AuthService] loadProfile error: ');
      throw const AuthFailure(
        'Could not load your staff profile. Check the connection and try again.',
        code: 'network',
      );
    }

    if (!snap.exists || snap.data() == null) {
      throw const AuthFailure(
        'This account has no clinic role assigned yet. Ask the clinic administrator to set it up.',
        code: 'no-profile',
      );
    }

    final data = snap.data()!;
    final profile = AppUser.fromMap(data, uid: uid);

    if (profile.role == UserRole.customer) {
      await signOut();
      throw const AuthFailure(
        'This sign-in is for clinic staff only. Patients sign in from the main screen.',
        code: 'customer-refused',
      );
    }

    if (!profile.active) {
      await signOut();
      throw const AuthFailure(
        'This account has been deactivated. Contact the clinic administrator.',
        code: 'inactive',
      );
    }

    return profile.copyWith(
      emailOrPhone: profile.emailOrPhone.isNotEmpty ? profile.emailOrPhone : email,
      name: profile.name.isNotEmpty ? profile.name : email,
    );
  }

  Future<void> signOut() async {
    await _clearSession();
    if (!FirebaseConfig.isFirebaseConfigured) return;
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] signOut error: ');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (!FirebaseConfig.isFirebaseConfigured) {
      throw const AuthFailure('Cannot reach the clinic server.', code: 'no-backend');
    }
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageForAuthCode(e.code), code: e.code);
    }
  }

  Future<bool> needsSuperAdminSetup() async {
    return false;
  }

  Future<AppUser> claimSuperAdmin({
    required String name,
    required String email,
    required String password,
    required String setupKey,
    required String clinicName,
  }) async {
    if (setupKey.trim() != AppConfig.superAdminSetupKey) {
      throw const AuthFailure('Incorrect setup key.', code: 'bad-setup-key');
    }
    if (password.length < AppConfig.minPasswordLength) {
      throw AuthFailure(
        'Choose a password of at least  characters.',
        code: 'weak-password',
      );
    }

    final cleanEmail = email.trim().toLowerCase();
    await updateAdminCredentials(
      newEmail: cleanEmail,
      newPassword: password,
      newName: name.trim(),
    );

    String uid = 'admin_master';
    if (FirebaseConfig.isFirebaseConfigured) {
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        uid = credential.user?.uid ?? uid;
      } catch (e) {
        debugPrint('[AuthService] Firebase Auth createUser notice: ');
      }
    }

    final admin = AppUser(
      id: uid,
      name: name.trim(),
      emailOrPhone: cleanEmail,
      role: UserRole.admin,
      branchId: 'main_clinic',
      createdAt: DateTime.now(),
    );
    await _saveSession(admin);

    if (FirebaseConfig.isFirebaseConfigured) {
      try {
        await _db.collection(colUsers).doc(uid).set(admin.toMap());
        await _db.collection(colSettings).doc(bootstrapDocId).set({
          'adminCreated': true,
          'createdAt': DateTime.now().toIso8601String(),
          'createdByUid': uid,
          'createdByEmail': cleanEmail,
        });

        final settingsRef = _db.collection(colSettings).doc(AppConfig.settingsDocId);
        if (!(await settingsRef.get()).exists) {
          await settingsRef.set(
            ClinicSettings.fallback
                .copyWith(
                  clinicName: clinicName.trim().isEmpty
                      ? AppConfig.fallbackClinicName
                      : clinicName.trim(),
                  updatedByName: name.trim(),
                  updatedAt: DateTime.now(),
                )
                .toMap(),
          );
        }
      } catch (e) {
        debugPrint('[AuthService] bootstrap write notice: ');
      }
    }

    return admin;
  }

  Future<AppUser> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
    String? doctorId,
    String? staffId,
    String branchId = 'main_clinic',
  }) async {
    if (role != UserRole.doctor && role != UserRole.staff) {
      throw const AuthFailure(
        'Only Doctor and Reception accounts can be created here.',
        code: 'role-not-allowed',
      );
    }
    if (password.length < AppConfig.minPasswordLength) {
      throw AuthFailure(
        'Choose a password of at least  characters.',
        code: 'weak-password',
      );
    }

    final cleanEmail = email.trim().toLowerCase();
    String uid = 'user_';

    if (FirebaseConfig.isFirebaseConfigured) {
      try {
        final provisioner = await _secondaryApp();
        final secondaryAuth = FirebaseAuth.instanceFor(app: provisioner);

        final credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        uid = credential.user?.uid ?? uid;
        await secondaryAuth.signOut();
      } catch (e) {
        debugPrint('[AuthService] secondaryApp create notice: ');
      }
    }

    final newUser = AppUser(
      id: uid,
      name: name.trim(),
      emailOrPhone: cleanEmail,
      role: role,
      phone: phone?.trim(),
      doctorId: role == UserRole.doctor ? doctorId : null,
      staffId: role == UserRole.staff ? staffId : null,
      branchId: branchId,
      createdAt: DateTime.now(),
    );

    // Save locally
    try {
      final prefs = await SharedPreferences.getInstance();
      final localUsersJson = prefs.getString(_prefLocalUsers);
      final List<dynamic> list = localUsersJson != null ? jsonDecode(localUsersJson) : [];
      list.add({
        'id': uid,
        'name': name.trim(),
        'email': cleanEmail,
        'password': password,
        'role': role == UserRole.doctor ? 'doctor' : 'staff',
        'phone': phone?.trim(),
        'doctorId': doctorId,
        'staffId': staffId,
        'branchId': branchId,
      });
      await prefs.setString(_prefLocalUsers, jsonEncode(list));
    } catch (_) {}

    // Save to Firestore if available
    if (FirebaseConfig.isFirebaseConfigured) {
      try {
        await _db.collection(colUsers).doc(uid).set(newUser.toMap());
      } catch (e) {
        debugPrint('[AuthService] Firestore createStaffAccount notice: ');
      }
    }

    return newUser;
  }

  Future<FirebaseApp> _secondaryApp() async {
    for (final app in Firebase.apps) {
      if (app.name == _provisionerAppName) return app;
    }
    final defaultApp = Firebase.app();
    return Firebase.initializeApp(
      name: _provisionerAppName,
      options: defaultApp.options,
    );
  }

  Future<void> updateUserProfile(AppUser user) async {
    if (!FirebaseConfig.isFirebaseConfigured) return;
    await _db.collection(colUsers).doc(user.id).set(
      {
        'name': user.name,
        'phone': user.phone,
        'role': user.role.name,
        'doctorId': user.doctorId,
        'staffId': user.staffId,
        'branchId': user.branchId,
        'active': user.active,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setUserActive(String uid, bool active) async {
    if (!FirebaseConfig.isFirebaseConfigured) return;
    await _db.collection(colUsers).doc(uid).set(
      {'active': active},
      SetOptions(merge: true),
    );
  }

  Future<void> revokeUser(String uid) async {
    if (!FirebaseConfig.isFirebaseConfigured) return;
    await _db.collection(colUsers).doc(uid).delete();
  }

  Future<List<AppUser>> getLocalStaffUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localUsersJson = prefs.getString(_prefLocalUsers);
      if (localUsersJson != null) {
        final List<dynamic> list = jsonDecode(localUsersJson);
        return list.map((item) {
          return AppUser(
            id: item['id'] ?? 'user_${item['email']}',
            name: item['name'] ?? item['email'],
            emailOrPhone: item['email'],
            role: item['role'] == 'doctor' ? UserRole.doctor : UserRole.staff,
            branchId: item['branchId'] ?? 'main_clinic',
            doctorId: item['doctorId'],
            staffId: item['staffId'],
            phone: item['phone'],
            active: item['active'] ?? true,
            createdAt: DateTime.now(),
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Stream<List<AppUser>> streamClinicUsers() async* {
    final local = await getLocalStaffUsers();
    yield local;
    if (FirebaseConfig.isFirebaseConfigured) {
      yield* _db.collection(colUsers).snapshots().map((snap) {
        final online = snap.docs
            .map((d) => AppUser.fromMap(d.data(), uid: d.id))
            .where((u) => u.role != UserRole.customer)
            .toList();
        final combined = [...online];
        for (final loc in local) {
          if (!combined.any((u) => u.emailOrPhone == loc.emailOrPhone)) {
            combined.add(loc);
          }
        }
        combined.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return combined;
      });
    }
  }

  String _messageForAuthCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Contact the clinic administrator.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Wait a minute and try again.';
      case 'email-already-in-use':
        return 'An account already exists with that email address.';
      case 'weak-password':
        return 'That password is too weak. Use at least  characters.';
      case 'network-request-failed':
        return 'No internet connection. Check the network and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled on this Firebase project.';
      default:
        return 'Sign-in failed (). Please try again.';
    }
  }
}
