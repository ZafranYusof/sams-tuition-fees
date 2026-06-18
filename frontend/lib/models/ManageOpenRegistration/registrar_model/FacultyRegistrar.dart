class FacultyRegistrar {
  final String id;
  final String name;
  final String department;
  final List<String> authorizedPermissions;
  final bool canOverrideQuotas;

  FacultyRegistrar({
    required this.id,
    required this.name,
    required this.department,
    this.authorizedPermissions = const ['MANAGE_SESSIONS', 'EDIT_CATALOG'],
    this.canOverrideQuotas = true,
  });

  // Example administrative logic
  bool hasPermission(String permission) {
    return authorizedPermissions.contains(permission);
  }

  // Logic for administrative actions could be added here
  void performSystemAudit() {
    // Audit implementation for Registrar activities
  }
}