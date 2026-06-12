import 'package:flutter/material.dart';

// Re-export fully-implemented screens so the router's single import still
// resolves all class names without modification.
export 'admin_courses_screen.dart';
export 'admin_branches_screen.dart';
export 'admin_sessions_screen.dart';
export 'admin_subjects_screen.dart';
export 'admin_payments_screen.dart';
export 'admin_attendance_screen.dart';
export 'admin_stories_screen.dart';
export 'admin_notify_screen.dart';
export 'admin_leave_screen.dart';

class AdminManageHubScreen extends StatelessWidget {
  const AdminManageHubScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Manage')),
        body: const Center(child: Text('Coming soon')),
      );
}
