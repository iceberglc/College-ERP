import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_state.dart';
import 'role_nav.dart';
import '../../shared/widgets/ice_sidebar.dart';
import '../theme/app_theme.dart';
import '../../features/auth/screens/login_screen.dart';

// Student
import '../../features/student/screens/student_shell.dart';
import '../../features/student/screens/student_home_screen.dart';
import '../../features/student/screens/student_attendance_screen.dart';
import '../../features/student/screens/student_results_screen.dart';
import '../../features/student/screens/student_leave_screen.dart';
import '../../features/student/screens/student_feedback_screen.dart';
import '../../features/student/screens/student_assignments_screen.dart';
import '../../features/student/screens/student_payments_screen.dart';
import '../../features/student/screens/student_notifications_screen.dart';
import '../../features/student/screens/student_vocabulary_screen.dart';
import '../../features/student/screens/student_vocabulary_detail_screen.dart';
import '../../features/student/screens/student_flashcard_screen.dart';
import '../../features/student/screens/student_result_files_screen.dart';
import '../../features/student/screens/student_books_screen.dart';
import '../../features/student/screens/student_leaderboard_screen.dart';
import '../../features/student/screens/student_progress_screen.dart';
import '../../features/student/screens/student_more_screen.dart';

// Staff
import '../../features/staff/screens/staff_shell.dart';
import '../../features/staff/screens/staff_home_screen.dart';
import '../../features/staff/screens/staff_attendance_screen.dart';
import '../../features/staff/screens/staff_results_screen.dart';
import '../../features/staff/screens/staff_leave_screen.dart';
import '../../features/staff/screens/staff_feedback_screen.dart';
import '../../features/staff/screens/staff_assignments_screen.dart';
import '../../features/staff/screens/staff_classes_screen.dart';
import '../../features/staff/screens/staff_vocabulary_screen.dart';
import '../../features/staff/screens/staff_vocabulary_detail_screen.dart';
import '../../features/staff/screens/staff_update_attendance_screen.dart';
import '../../features/staff/screens/staff_more_screen.dart';
import '../../features/staff/screens/staff_placeholder_screens.dart';

// Admin
import '../../features/admin/screens/admin_shell.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/admin_students_screen.dart';
import '../../features/admin/screens/admin_staff_screen.dart';
import '../../features/admin/screens/admin_leads_screen.dart';
import '../../features/admin/screens/admin_groups_screen.dart';
import '../../features/admin/screens/admin_group_detail_screen.dart';
import '../../features/admin/screens/admin_add_edit_group_screen.dart';
import '../../features/admin/screens/admin_enrollment_screen.dart';
import '../../features/admin/screens/admin_manage_admins_screen.dart';
import '../../features/admin/screens/admin_add_student_screen.dart';
import '../../features/admin/screens/admin_edit_student_screen.dart';
import '../../features/admin/screens/admin_add_staff_screen.dart';
import '../../features/admin/screens/admin_edit_staff_screen.dart';
import '../../features/admin/screens/admin_more_screen.dart';
import '../../features/admin/screens/admin_placeholder_screens.dart';

// Superadmin
import '../../features/superadmin/screens/superadmin_shell.dart';
import '../../features/superadmin/screens/superadmin_home_screen.dart';
import '../../features/superadmin/screens/superadmin_placeholder_screens.dart';

// Shared
import '../../shared/screens/profile_screen.dart';
import '../../shared/screens/profile_hub_screen.dart';
import '../../shared/screens/messages_screen.dart';
import '../../shared/screens/notifications_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthListenable(ref);

  return GoRouter(
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.matchedLocation;

      if (auth.status == AuthStatus.loading) return '/splash';

      if (auth.status == AuthStatus.unauthenticated) {
        return path == '/login' ? null : '/login';
      }

      if (path == '/login' || path == '/splash') {
        final user = auth.user!;
        if (user.isSuperAdmin) return '/superadmin/home';
        if (user.isAdmin)      return '/admin/home';
        if (user.isStaff)      return '/staff/home';
        return '/student/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const _SplashScreen()),
      GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),

      // ── Superadmin shell (4 branches) ────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            SuperadminShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/superadmin/home',
              builder: (_, __) => const SuperadminHomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/superadmin/branches',
              builder: (_, __) => const AdminGroupsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/superadmin/analytics',
              builder: (_, __) => const SuperadminAnalyticsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/superadmin/more',
              builder: (_, __) => const SuperadminMoreScreen(),
            ),
          ]),
        ],
      ),

      // ── Superadmin standalone routes (sidebar persists on desktop) ──
      ShellRoute(
        builder: (_, __, child) =>
            DesktopPageShell(sections: superadminSidebarSections, child: child),
        routes: [
        // ── Superadmin standalone routes ──────────────────────────────────────
        GoRoute(path: '/superadmin/students',
            builder: (_, __) => const AdminStudentsScreen()),
        GoRoute(path: '/superadmin/staff',
            builder: (_, __) => const AdminStaffScreen()),
        GoRoute(path: '/superadmin/leads',
            builder: (_, __) => const AdminLeadsScreen()),
        GoRoute(path: '/superadmin/notifications',
            builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/superadmin/profile',
            builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Student shell (6 branches) ────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            StudentShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: Home
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/home',
              builder: (_, __) => const StudentHomeScreen(),
            ),
          ]),
          // Branch 1: Learn (vocabulary)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/vocabulary',
              builder: (_, __) => const StudentVocabularyScreen(),
            ),
          ]),
          // Branch 2: Progress
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/progress',
              builder: (_, __) => const StudentProgressScreen(),
            ),
          ]),
          // Branch 3: Attendance
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/attendance',
              builder: (_, __) => const StudentAttendanceScreen(),
            ),
          ]),
          // Branch 4: Payments
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/payments',
              builder: (_, __) => const StudentPaymentsScreen(),
            ),
          ]),
          // Branch 5: More
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/more',
              builder: (_, __) => const StudentMoreScreen(),
            ),
          ]),
        ],
      ),

      // ── Student standalone routes (sidebar persists on desktop) ──
      ShellRoute(
        builder: (_, __, child) =>
            DesktopPageShell(sections: studentSidebarSections, child: child),
        routes: [
        GoRoute(path: '/student/results',
            builder: (_, __) => const StudentResultsScreen()),
        GoRoute(path: '/student/assignments',
            builder: (_, __) => const StudentAssignmentsScreen()),
        GoRoute(path: '/student/leaderboard',
            builder: (_, __) => const StudentLeaderboardScreen()),
        GoRoute(path: '/student/leave',
            builder: (_, __) => const StudentLeaveScreen()),
        GoRoute(path: '/student/feedback',
            builder: (_, __) => const StudentFeedbackScreen()),
        GoRoute(path: '/student/notifications',
            builder: (_, __) => const StudentNotificationsScreen()),
        GoRoute(path: '/student/books',
            builder: (_, __) => const StudentBooksScreen()),
        GoRoute(path: '/student/result-files',
            builder: (_, __) => const StudentResultFilesScreen()),
        GoRoute(
          path: '/student/vocabulary/:id',
          builder: (_, state) => StudentVocabularyDetailScreen(
              vocabId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'flashcards',
              builder: (_, state) => StudentFlashcardScreen(
                  vocabId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(path: '/student/profile',
            builder: (_, __) => const ProfileHubScreen()),
        GoRoute(path: '/student/messages',
            builder: (_, __) => const MessagesScreen()),
        ],
      ),

      // ── Staff shell (6 branches) ──────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            StaffShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/staff/home',
              builder: (_, __) => const StaffHomeScreen(),
            ),
          ]),
          // Branch 1: Classes
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/staff/classes',
              builder: (_, __) => const StaffClassesScreen(),
            ),
          ]),
          // Branch 2: Attendance
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/staff/attendance',
              builder: (_, __) => const StaffAttendanceScreen(),
            ),
          ]),
          // Branch 3: Results
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/staff/results',
              builder: (_, __) => const StaffResultsScreen(),
            ),
          ]),
          // Branch 4: Assignments
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/staff/assignments',
              builder: (_, __) => const StaffAssignmentsScreen(),
            ),
          ]),
          // Branch 5: More
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/staff/more',
              builder: (_, __) => const StaffMoreScreen(),
            ),
          ]),
        ],
      ),

      // ── Staff standalone routes (sidebar persists on desktop) ──
      ShellRoute(
        builder: (_, __, child) =>
            DesktopPageShell(sections: staffSidebarSections, child: child),
        routes: [
        GoRoute(path: '/staff/vocabulary',
            builder: (_, __) => const StaffVocabularyScreen()),
        GoRoute(path: '/staff/leave',
            builder: (_, __) => const StaffLeaveScreen()),
        GoRoute(path: '/staff/feedback',
            builder: (_, __) => const StaffFeedbackScreen()),
        GoRoute(path: '/staff/payments',
            builder: (_, __) => const StaffPaymentsScreen()),
        GoRoute(path: '/staff/notifications',
            builder: (_, __) => const StaffNotificationsScreen()),
        GoRoute(path: '/staff/attendance/update',
            builder: (_, __) => const StaffUpdateAttendanceScreen()),
        GoRoute(
          path: '/staff/vocabulary/:id',
          builder: (_, state) => StaffVocabularyDetailScreen(
              vocabId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/staff/profile',
            builder: (_, __) => const ProfileHubScreen()),
        GoRoute(path: '/staff/messages',
            builder: (_, __) => const MessagesScreen()),
        ],
      ),

      // ── Admin shell (6 branches) ──────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/home',
              builder: (_, __) => const AdminHomeScreen(),
            ),
          ]),
          // Branch 1: Students
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/students',
              builder: (_, __) => const AdminStudentsScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (_, __) => const AdminAddStudentScreen(),
                ),
                GoRoute(
                  path: ':id/edit',
                  builder: (_, state) => AdminEditStudentScreen(
                      studentId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          // Branch 2: Groups
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/groups',
              builder: (_, __) => const AdminGroupsScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (_, __) => const AdminAddEditGroupScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => AdminGroupDetailScreen(
                      groupId: state.pathParameters['id']!),
                ),
                GoRoute(
                  path: ':id/edit',
                  builder: (_, state) => AdminAddEditGroupScreen(
                      groupId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          // Branch 3: Payments
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/payments',
              builder: (_, __) => const AdminPaymentsScreen(),
            ),
          ]),
          // Branch 4: Leads
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/leads',
              builder: (_, __) => const AdminLeadsScreen(),
            ),
          ]),
          // Branch 5: More
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/more',
              builder: (_, __) => const AdminMoreScreen(),
            ),
          ]),
        ],
      ),

      // ── Admin standalone routes (sidebar persists on desktop) ──
      ShellRoute(
        builder: (_, __, child) =>
            DesktopPageShell(sections: adminSidebarSections, child: child),
        routes: [
        GoRoute(path: '/admin/staff',
            builder: (_, __) => const AdminStaffScreen(),
            routes: [
              GoRoute(path: 'add',
                  builder: (_, __) => const AdminAddStaffScreen()),
              GoRoute(
                path: ':id/edit',
                builder: (_, state) => AdminEditStaffScreen(
                    staffId: state.pathParameters['id']!),
              ),
            ]),
        GoRoute(path: '/admin/courses',
            builder: (_, __) => const AdminCoursesScreen()),
        GoRoute(path: '/admin/branches',
            builder: (_, __) => const AdminBranchesScreen()),
        GoRoute(path: '/admin/sessions',
            builder: (_, __) => const AdminSessionsScreen()),
        GoRoute(path: '/admin/subjects',
            builder: (_, __) => const AdminSubjectsScreen()),
        GoRoute(path: '/admin/enroll',
            builder: (_, __) => const AdminEnrollmentScreen()),
        GoRoute(path: '/admin/admins',
            builder: (_, __) => const AdminManageAdminsScreen()),
        GoRoute(path: '/admin/attendance',
            builder: (_, __) => const AdminAttendanceScreen()),
        GoRoute(path: '/admin/leave',
            builder: (_, __) => const AdminLeaveScreen()),
        GoRoute(path: '/admin/notify',
            builder: (_, __) => const AdminNotifyScreen()),
        GoRoute(path: '/admin/stories',
            builder: (_, __) => const AdminStoriesScreen()),
        GoRoute(path: '/admin/profile',
            builder: (_, __) => const ProfileHubScreen()),
        GoRoute(path: '/admin/messages',
            builder: (_, __) => const MessagesScreen()),
        ],
      ),

      // ── Shared routes ─────────────────────────────────────────────────────
      GoRoute(path: '/messages',
          builder: (_, __) => const MessagesScreen()),
      GoRoute(path: '/profile',
          builder: (_, __) => const ProfileHubScreen()),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: IceColors.navy,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.school_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white)),
            ],
          ),
        ),
      );
}
