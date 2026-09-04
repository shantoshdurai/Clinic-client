import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/clinic_state_provider.dart';
import '../admin/admin_panel_screen.dart';
import '../auth/patient_login_screen.dart';
import '../billing/billing_reports_screen.dart';
import '../staff/patient_database_tab.dart';
import '../staff/staff_main_screen.dart';
import 'doctor_queue_tab.dart';

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedTab();
  }

  void _loadSavedTab() async {
    final prefs = await SharedPreferences.getInstance();
    final tab = prefs.getInt('saved_doctor_tab');
    if (tab != null && tab >= 0 && tab < 3 && mounted) {
      setState(() => _currentIndex = tab);
    }
  }

  void _onTabTapped(int index) async {
    setState(() => _currentIndex = index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_doctor_tab', index);
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PatientLoginScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppTheme.textPrimary),
            onPressed: () {
              if (_currentIndex != 0) {
                setState(() => _currentIndex = 0);
                return;
              }
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientLoginScreen()),
                );
              }
            },
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medical_services_rounded, color: AppTheme.secondary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.currentUser?.name ?? state.primaryDoctorName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Doctor Cabin • ${state.clinicName}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textPrimary, size: 22),
              tooltip: 'Menu',
              onSelected: (val) async {
                if (val == 'reception_desk') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StaffMainScreen()),
                  );
                } else if (val == 'admin_console') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                  );
                } else if (val == 'logout') {
                  final navigator = Navigator.of(context);
                  await state.logout();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const PatientLoginScreen()),
                    (route) => false,
                  );
                }
              },
              itemBuilder: (ctx) => [
                if (state.isAdmin) ...[
                  const PopupMenuItem(
                    value: 'admin_console',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings_rounded, size: 18, color: AppTheme.purple),
                        SizedBox(width: 10),
                        Text('Admin Console', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reception_desk',
                    child: Row(
                      children: [
                        Icon(Icons.support_agent_rounded, size: 18, color: AppTheme.secondary),
                        SizedBox(width: 10),
                        Text('Reception Desk', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                ],
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: AppTheme.danger),
                      SizedBox(width: 10),
                      Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.danger)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            DoctorQueueTab(),
            PatientDatabaseTab(),
            BillingReportsScreen(isDoctor: true),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.textMuted,
            selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 11.5),
            unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 11.5),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline_rounded),
                activeIcon: Icon(Icons.people_alt_rounded),
                label: 'Patient Queue',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_shared_outlined),
                activeIcon: Icon(Icons.folder_shared_rounded),
                label: 'Patient DB',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                activeIcon: Icon(Icons.analytics_rounded),
                label: 'Revenue Audit',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
