/// Build-time configuration for AS Clinic.
///
/// Nothing clinical lives here — clinic name, doctors, staff and fees are all
/// stored in Firestore and edited from the in-app Super Admin console.
/// This file only holds values that must be known before any user signs in.
class AppConfig {
  AppConfig._();

  /// One-time key required to claim the Super Admin account on a fresh
  /// Firebase project. Once an admin exists in `users`, the bootstrap screen
  /// is permanently unreachable and this key stops doing anything.
  ///
  /// Change this before handing the APK to anyone.
  static const String superAdminSetupKey = 'AS-CLINIC-SETUP-9271';

  /// Firestore document that holds editable clinic identity + operational
  /// settings. Written only by an admin.
  static const String settingsDocId = 'main';

  /// Fallbacks used only while the settings document is still loading, or if
  /// the device is offline on first launch and has no cache yet.
  static const String fallbackClinicName = 'AS Clinic';
  static const String fallbackTagline = 'General Health & Outpatient Care Centre';

  /// Minimum password length enforced on accounts created from the admin
  /// console (Firebase itself enforces 6).
  static const int minPasswordLength = 6;

  /// Pre-configured initial credentials.
  /// The admin can change their email & password anytime in Admin Settings.
  static const String defaultAdminEmail = 'admin@clinic.com';
  static const String defaultAdminPassword = 'admin123';

  static const String defaultDoctorEmail = 'doctor@clinic.com';
  static const String defaultDoctorPassword = 'doctor123';

  static const String defaultStaffEmail = 'staff@clinic.com';
  static const String defaultStaffPassword = 'staff123';
}
