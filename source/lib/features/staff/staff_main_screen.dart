import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../models/patient.dart';
import '../../providers/clinic_state_provider.dart';
import '../admin/admin_panel_screen.dart';
import '../auth/patient_login_screen.dart';
import '../billing/billing_reports_screen.dart';
import '../doctor/doctor_main_screen.dart';
import 'op_entry_tab.dart';
import 'patient_database_tab.dart';

class StaffMainScreen extends StatefulWidget {
  const StaffMainScreen({super.key});

  @override
  State<StaffMainScreen> createState() => _StaffMainScreenState();
}

class _StaffMainScreenState extends State<StaffMainScreen> {
  int _currentIndex = 0;
  Patient? _selectedPatientForOp;
  Key _opTabKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadSavedTab();
  }

  void _loadSavedTab() async {
    final prefs = await SharedPreferences.getInstance();
    final tab = prefs.getInt('saved_staff_tab');
    if (tab != null && tab >= 0 && tab < 3 && mounted) {
      setState(() => _currentIndex = tab);
    }
  }

  void _onTabTapped(int index) async {
    setState(() => _currentIndex = index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_staff_tab', index);
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ClinicStateProvider>(context);

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          titleSpacing: 16,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Reception Desk',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${state.currentUser?.name ?? 'Reception'} • ${state.clinicName}',
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
                if (val == 'doctor_cabin') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorMainScreen()),
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
                    value: 'doctor_cabin',
                    child: Row(
                      children: [
                        Icon(Icons.medical_services_rounded, size: 18, color: AppTheme.primary),
                        SizedBox(width: 10),
                        Text('Doctor Cabin', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
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
          children: [
            OpEntryTab(
              key: _opTabKey,
              preselectedPatient: _selectedPatientForOp,
            ),
            PatientDatabaseTab(
              onIssueToken: (patient) {
                setState(() {
                  _selectedPatientForOp = patient;
                  _opTabKey = UniqueKey();
                  _currentIndex = 0;
                });
              },
            ),
            const BillingReportsScreen(isDoctor: false),
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
                icon: Icon(Icons.how_to_reg_outlined),
                activeIcon: Icon(Icons.how_to_reg_rounded),
                label: 'OP Token Desk',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline_rounded),
                activeIcon: Icon(Icons.people_alt_rounded),
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
