import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/admin/admin_panel_screen.dart';
import 'features/auth/patient_login_screen.dart';
import 'features/doctor/doctor_main_screen.dart';
import 'features/staff/staff_main_screen.dart';
import 'models/user_role.dart';
import 'providers/clinic_state_provider.dart';
import 'services/auth_service.dart';
import 'services/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  GoogleFonts.config.allowRuntimeFetching = true;
  await FirebaseConfig.initialize();

  // Restore the previous session only if Firebase still recognises it and the
  // account still carries a clinic role. A stale preference on the device can
  // no longer, on its own, open a staff screen.
  final restoredUser = await AuthService().restoreSession();

  runApp(ClinicApp(restoredUser: restoredUser));
}

class ClinicApp extends StatelessWidget {
  final AppUser? restoredUser;
  const ClinicApp({super.key, this.restoredUser});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = ClinicStateProvider();
            if (restoredUser != null) {
              provider.setAuthenticatedUser(restoredUser!);
            }
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'AS Clinic',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _homeForUser(restoredUser),
      ),
    );
  }

  Widget _homeForUser(AppUser? user) {
    if (user == null) return const PatientLoginScreen();
    switch (user.role) {
      case UserRole.admin:
        return const AdminPanelScreen();
      case UserRole.doctor:
        return const DoctorMainScreen();
      case UserRole.staff:
        return const StaffMainScreen();
      case UserRole.customer:
        return const PatientLoginScreen();
    }
  }
}
