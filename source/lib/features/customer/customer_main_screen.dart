import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/clinic_state_provider.dart';
import '../auth/patient_login_screen.dart';
import '../common/widgets/clinic_app_bar.dart';
import 'customer_dashboard_tab.dart';
import 'customer_history_tab.dart';
import 'customer_prescriptions_tab.dart';

class CustomerMainScreen extends StatefulWidget {
  final int initialTabIndex;
  const CustomerMainScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  late int _currentIndex;
  bool _openBookingForm = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void _navigateToTab(int index, {bool openBooking = false}) {
    setState(() {
      _currentIndex = index;
      _openBookingForm = openBooking;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _openBookingForm = false;
          });
          return;
        }
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      backgroundColor: AppTheme.background,
      // Only show ClinicAppBar on non-home tabs to avoid duplicate headers/notifications
      appBar: _currentIndex == 0
          ? null
          : ClinicAppBar(title: context.watch<ClinicStateProvider>().clinicName),
      body: SafeArea(
        top: _currentIndex == 0,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            CustomerDashboardTab(
              onTabChange: (index, {openBooking = false}) => _navigateToTab(index, openBooking: openBooking),
            ),
            CustomerHistoryTab(
              key: ValueKey('appts_tab_$_openBookingForm'),
              initiallyOpenBooking: _openBookingForm,
              onTabChange: (index) => _navigateToTab(index),
            ),
            const CustomerPrescriptionsTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() {
              _currentIndex = i;
              if (i != 1) _openBookingForm = false;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today_rounded),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medication_outlined),
              activeIcon: Icon(Icons.medication_rounded),
              label: 'Prescriptions',
            ),
          ],
        ),
      ),
    ),
  );
}
}
