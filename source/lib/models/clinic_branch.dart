class ClinicBranch {
  final String id;
  final String name;
  final String locality;
  final String address;
  final String phone;
  final String whatsapp;
  final String workingHours;
  final String mapUrl;
  final bool isMainBranch;
  final int totalDoctors;
  final int activeAppointmentsToday;

  ClinicBranch({
    required this.id,
    required this.name,
    required this.locality,
    required this.address,
    required this.phone,
    required this.whatsapp,
    required this.workingHours,
    required this.mapUrl,
    this.isMainBranch = false,
    this.totalDoctors = 4,
    this.activeAppointmentsToday = 18,
  });
}
