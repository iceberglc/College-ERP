import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_state.dart';
import '../theme/ice_tokens.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/coming_soon_screen.dart';

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
import '../../features/student/screens/student_vocabulary_quiz_screen.dart';
import '../../features/student/screens/student_result_files_screen.dart';
import '../../features/student/screens/student_books_screen.dart';
import '../../features/student/screens/student_leaderboard_screen.dart';
import '../../features/student/screens/student_progress_screen.dart';
import '../../features/student/screens/student_profile_screen.dart';
import '../../features/student/screens/student_settings_screen.dart';
import '../../features/student/screens/student_messages_screen.dart';
import '../../features/student/screens/student_assignment_detail_screen.dart';
import '../../features/student/screens/student_learn_screen.dart';

/// The mobile/web app ships the **student experience only**. Staff, admin and
/// super-admin accounts authenticate successfully but are sent to a
/// "coming soon" wall — their dashboards live on the Django web portal.
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

      // Authenticated.
      final user = auth.user!;

      // Non-students never reach the student app — hold them at the wall.
      if (!user.isStudent) {
        return path == '/coming-soon' ? null : '/coming-soon';
      }

      // Students land on their dashboard from auth/transitional routes.
      if (path == '/login' || path == '/splash' || path == '/coming-soon') {
        return '/student/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/coming-soon',
        builder: (_, __) => const ComingSoonScreen(),
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
  Widget build(BuildContext context) {
    final t = IceTokens.dark();
    return Scaffold(
      backgroundColor: t.bg,
      body: Container(
        decoration: BoxDecoration(gradient: t.heroGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: t.accent.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 58,
                  height: 58,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.school_rounded, size: 52, color: t.accent),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ICEBERG',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                  color: t.mint,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation(t.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
