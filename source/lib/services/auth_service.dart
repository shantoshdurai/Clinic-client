import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
/// Three rules this service exists to enforce:
///
///  1. A staff, doctor or admin session requires a real Firebase Auth
///     sign-in. There is no offline or fallback path that hands out a
///     privileged session.
///  2. The role is read from `users/{uid}` in Firestore — never inferred from
///     the email address, and never chosen by the person signing in.
///  3. Admin accounts cannot be self-registered. The first one is claimed once
///     against a setup key on an unprovisioned project; every later account is
///     created by an existing admin, and the console only offers doctor and
///     reception roles.
class AuthService {
  static const String colUsers = 'users';
  static const String colSettings = 'clinic_settings';
  static const String bootstrapDocId = 'bootstrap';

  /// Name of the throwaway secondary Firebase app used to create accounts
  /// without disturbing the admin's own session.
  static const String _provisionerAppName = 'asclinic_user_provisioner';

  /// How long to wait for the role lookup before falling back to the offline
  /// cache. Keeps app launch bounded.
  static const Duration _profileReadTimeout = Duration(seconds: 10);

  /// Same bound for the unauthenticated bootstrap probe on the sign-in screen.
  static const Duration _probeTimeout = Duration(seconds: 6);

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  User? get currentFirebaseUser =>
      FirebaseConfig.isFirebaseConfigured ? _auth.currentUser : null;

  /// Fires on sign-in and sign-out so the app can drop a session the moment
  /// Firebase does.
  Stream<User?> authStateChanges() {
    if (!FirebaseConfig.isFirebaseConfigured) return const Stream.empty();
    return _auth.authStateChanges();
  }

  // ---------------------------------------------------------------------------
  // Sign in
  // ---------------------------------------------------------------------------

  /// Signs a staff member, doctor or admin in and resolves their role from
  /// Firestore. Throws [AuthFailure] on bad credentials, a missing profile, or
  /// a deactivated account — it never returns a fallback session.
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (!FirebaseConfig.isFirebaseConfigured) {
      throw const AuthFailure(
        'Cannot reach the clinic server. Check the internet connection and try again.',
        code: 'no-backend',
      );
    }

    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || password.isEmpty) {
      throw const AuthFailure('Enter your email and password.', code: 'empty');
    }

    UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageForAuthCode(e.code), code: e.code);
    } catch (e) {
      debugPrint('[AuthService] signIn error: $e');
      throw const AuthFailure(
        'Could not sign in right now. Check the connection and try again.',
        code: 'network',
      );
    }

    final uid = credential.user?.uid;
    if (uid == null) {
      throw const AuthFailure('Sign-in failed. Try again.', code: 'no-uid');
    }

    return _loadProfileOrSignOut(uid, cleanEmail);
  }

  /// Re-reads the role for an already-signed-in user, e.g. on app launch.
  /// Returns null when there is no valid session.
  Future<AppUser?> restoreSession() async {
    if (!FirebaseConfig.isFirebaseConfigured) return null;
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await _loadProfileOrSignOut(user.uid, user.email ?? '');
    } on AuthFailure catch (e) {
      debugPrint('[AuthService] restoreSession rejected: ${e.message}');
      return null;
    }
  }

  /// Loads `users/{uid}`. A signed-in account with no profile, an unknown
  /// role, or `active: false` is signed straight back out — an authenticated
  /// stranger must not land on a clinical screen.
  Future<AppUser> _loadProfileOrSignOut(String uid, String email) async {
    DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      // Bounded, then cache-backed. An unbounded get() here would hold the
      // launch screen indefinitely on a clinic's flaky connection.
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
        await signOut();
        throw const AuthFailure(
          'Could not reach the clinic server to verify your access. Check the '
          'connection and try again.',
          code: 'profile-timeout',
        );
      }
    } catch (e) {
      debugPrint('[AuthService] profile read error: $e');
      await signOut();
      throw const AuthFailure(
        'Could not verify your access level. Check the connection and try again.',
        code: 'profile-read',
      );
    }

    if (!snap.exists || snap.data() == null) {
      await signOut();
      throw const AuthFailure(
        'This account has no clinic role assigned yet. Ask the clinic '
        'administrator to add you from the Admin console.',
        code: 'no-profile',
      );
    }

    final profile = AppUser.fromMap(snap.data()!, uid: uid);

    if (!profile.active) {
      await signOut();
      throw const AuthFailure(
        'This account has been deactivated. Contact the clinic administrator.',
        code: 'deactivated',
      );
    }

    if (!profile.role.isClinicStaff) {
      await signOut();
      throw const AuthFailure(
        'This login is for clinic staff only. Patients should use the mobile '
        'number sign-in.',
        code: 'wrong-portal',
      );
    }

    return profile.copyWith(
      emailOrPhone: profile.emailOrPhone.isNotEmpty ? profile.emailOrPhone : email,
      name: profile.name.isNotEmpty ? profile.name : email,
    );
  }

  Future<void> signOut() async {
    if (!FirebaseConfig.isFirebaseConfigured) return;
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] signOut error: $e');
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

  // ---------------------------------------------------------------------------
  // First-run Super Admin claim
  // ---------------------------------------------------------------------------

  /// True while the project has no Super Admin yet, which is the only time the
  /// bootstrap screen is offered. Backed by `clinic_settings/bootstrap`, whose
  /// existence the security rules also use to close the claim server-side, so
  /// a patched client cannot reopen it.
  Future<bool> needsSuperAdminSetup() async {
    if (!FirebaseConfig.isFirebaseConfigured) return false;
    try {
      final snap = await _db
          .collection(colSettings)
          .doc(bootstrapDocId)
          .get()
          .timeout(_probeTimeout);
      return !snap.exists;
    } catch (e) {
      // A rules denial or a network failure is not evidence that setup is
      // needed. Assume the clinic is provisioned and keep the screen hidden.
      debugPrint('[AuthService] bootstrap probe failed: $e');
      return false;
    }
  }

  /// Claims the one Super Admin account on a fresh project. Fails if a Super
  /// Admin already exists or the setup key is wrong.
  Future<AppUser> claimSuperAdmin({
    required String name,
    required String email,
    required String password,
    required String setupKey,
    required String clinicName,
  }) async {
    if (!FirebaseConfig.isFirebaseConfigured) {
      throw const AuthFailure('Cannot reach the clinic server.', code: 'no-backend');
    }
    if (setupKey.trim() != AppConfig.superAdminSetupKey) {
      throw const AuthFailure('Incorrect setup key.', code: 'bad-setup-key');
    }
    if (password.length < AppConfig.minPasswordLength) {
      throw AuthFailure(
        'Choose a password of at least ${AppConfig.minPasswordLength} characters.',
        code: 'weak-password',
      );
    }
    if (!await needsSuperAdminSetup()) {
      throw const AuthFailure(
        'A Super Admin already exists for this clinic. Sign in instead.',
        code: 'already-provisioned',
      );
    }

    final cleanEmail = email.trim().toLowerCase();
    UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // The Auth account was made in the Firebase console but the Firestore
        // profile is missing. Sign in and finish provisioning instead.
        try {
          credential = await _auth.signInWithEmailAndPassword(
            email: cleanEmail,
            password: password,
          );
        } on FirebaseAuthException catch (e2) {
          throw AuthFailure(_messageForAuthCode(e2.code), code: e2.code);
        }
      } else {
        throw AuthFailure(_messageForAuthCode(e.code), code: e.code);
      }
    }

    final uid = credential.user!.uid;
    final admin = AppUser(
      id: uid,
      name: name.trim(),
      emailOrPhone: cleanEmail,
      role: UserRole.admin,
      branchId: 'main_clinic',
      createdAt: DateTime.now(),
    );

    try {
      await _db.collection(colUsers).doc(uid).set(admin.toMap());

      // Closes the claim permanently, in the rules as well as the UI.
      await _db.collection(colSettings).doc(bootstrapDocId).set({
        'adminCreated': true,
        'createdAt': DateTime.now().toIso8601String(),
        'createdByUid': uid,
        'createdByEmail': cleanEmail,
      });

      // Seed the editable clinic profile so the admin has something to edit.
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
      debugPrint('[AuthService] bootstrap write failed: $e');
      await signOut();
      throw const AuthFailure(
        'Created the login but could not save the admin profile. Check that '
        'the Firestore security rules are deployed, then try again.',
        code: 'bootstrap-write',
      );
    }

    try {
      await credential.user!.updateDisplayName(name.trim());
    } catch (_) {
      // Cosmetic only.
    }

    return admin;
  }

  // ---------------------------------------------------------------------------
  // Admin-driven account provisioning
  // ---------------------------------------------------------------------------

  /// Creates a doctor or reception account on behalf of the signed-in admin.
  ///
  /// The Firebase client SDK swaps the active session whenever it creates a
  /// user, which would kick the admin out mid-task. So the account is created
  /// on a short-lived secondary [FirebaseApp] that is signed out and disposed
  /// immediately; the admin's own session on the default app is never touched.
  ///
  /// [role] is deliberately restricted — an admin cannot mint another admin
  /// from the app.
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
    if (!FirebaseConfig.isFirebaseConfigured) {
      throw const AuthFailure('Cannot reach the clinic server.', code: 'no-backend');
    }
    if (role != UserRole.doctor && role != UserRole.staff) {
      throw const AuthFailure(
        'Only Doctor and Reception accounts can be created here.',
        code: 'role-not-allowed',
      );
    }
    if (password.length < AppConfig.minPasswordLength) {
      throw AuthFailure(
        'Choose a password of at least ${AppConfig.minPasswordLength} characters.',
        code: 'weak-password',
      );
    }

    final cleanEmail = email.trim().toLowerCase();
    FirebaseApp? provisioner;
    try {
      provisioner = await _secondaryApp();
      final secondaryAuth = FirebaseAuth.instanceFor(app: provisioner);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final uid = credential.user!.uid;

      try {
        await credential.user!.updateDisplayName(name.trim());
      } catch (_) {
        // Cosmetic only.
      }

      // Release the secondary session before writing, so a failure here cannot
      // leave a stray signed-in account behind.
      await secondaryAuth.signOut();

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

      // Written from the default app, i.e. as the admin, so the rules see an
      // admin performing the create.
      await _db.collection(colUsers).doc(uid).set(newUser.toMap());
      return newUser;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageForAuthCode(e.code), code: e.code);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] createStaffAccount error: $e');
      throw const AuthFailure(
        'Could not create the account. Check the connection and try again.',
        code: 'create-failed',
      );
    } finally {
      if (provisioner != null) {
        try {
          await provisioner.delete();
        } catch (_) {
          // Already gone, or still in use — harmless either way.
        }
      }
    }
  }

  Future<FirebaseApp> _secondaryApp() async {
    try {
      return await Firebase.initializeApp(
        name: _provisionerAppName,
        options: Firebase.app().options,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        return Firebase.app(_provisionerAppName);
      }
      rethrow;
    }
  }

  /// Updates the editable fields of a user profile. Role changes are handled
  /// separately so they are always a deliberate act.
  Future<void> updateUserProfile(AppUser user) async {
    if (!FirebaseConfig.isFirebaseConfigured) return;
    await _db.collection(colUsers).doc(user.id).set(
      {
        'name': user.name,
        'phone': user.phone,
        'doctorId': user.doctorId,
        'staffId': user.staffId,
        'branchId': user.branchId,
        'active': user.active,
      },
      SetOptions(merge: true),
    );
  }

  /// Disables or re-enables an account. The Auth login survives, but
  /// [_loadProfileOrSignOut] refuses the session, so a disabled user cannot
  /// reach any clinic screen.
  Future<void> setUserActive(String uid, bool active) async {
    if (!FirebaseConfig.isFirebaseConfigured) return;
    await _db.collection(colUsers).doc(uid).set(
      {'active': active},
      SetOptions(merge: true),
    );
  }

  /// Removes the Firestore profile, which revokes all access. The Auth record
  /// itself can only be deleted from the Firebase console or the Admin SDK.
  Future<void> revokeUser(String uid) async {
    if (!FirebaseConfig.isFirebaseConfigured) return;
    await _db.collection(colUsers).doc(uid).delete();
  }

  Stream<List<AppUser>> streamClinicUsers() {
    if (!FirebaseConfig.isFirebaseConfigured) return Stream.value(const []);
    return _db.collection(colUsers).snapshots().map((snap) {
      return snap.docs
          .map((d) => AppUser.fromMap(d.data(), uid: d.id))
          .where((u) => u.role != UserRole.customer)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
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
        return 'That password is too weak. Use at least '
            '${AppConfig.minPasswordLength} characters.';
      case 'network-request-failed':
        return 'No internet connection. Check the network and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled on this Firebase '
            'project. Enable it under Authentication > Sign-in method.';
      default:
        return 'Sign-in failed ($code). Please try again.';
    }
  }
}
