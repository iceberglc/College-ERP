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
import '../../features/student/screens/student_more_screen.dart';

// Staff
import '../../features/staff/screens/staff_shell.dart';
import '../../features/staff/screens/staff_home_screen.dart';
import '../../features/staff/screens/staff_more_screen.dart';
import '../../features/staff/screens/staff_placeholder_screens.dart';

// Shared
import '../../shared/screens/profile_hub_screen.dart';
import '../../shared/screens/messages_screen.dart';

/// Routes:
///   - Students   → /student/* (full student experience)
///   - Staff      → /staff/*   (teacher portal)
///   - Admin      → /coming-soon (admin dashboard ships separately)
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

      final user = auth.user!;

      // Admin accounts → coming soon wall (admin web portal handles them).
      if (user.isAdmin) {
        return path == '/coming-soon' ? null : '/coming-soon';
      }

      // Staff (teachers) → staff portal.
      if (user.isStaff) {
        if (path.startsWith('/staff')) return null;
        return '/staff/home';
      }

      // Students → student app.
      if (path == '/login' || path == '/splash' || path == '/coming-soon') {
        return '/student/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/coming-soon', builder: (_, __) => const ComingSoonScreen()),

      // ── Staff shell (5 bottom-nav branches) ──────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            StaffShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/staff/home', builder: (_, __) => const StaffHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/staff/classes', builder: (_, __) => const StaffClassesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/staff/attendance', builder: (_, __) => const StaffAttendanceScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/staff/assignments', builder: (_, __) => const StaffAssignmentsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/staff/more', builder: (_, __) => const StaffMoreScreen()),
          ]),
        ],
      ),

      // ── Staff standalone routes ───────────────────────────────────────────
      GoRoute(path: '/staff/results',       builder: (_, __) => const StaffResultsScreen()),
      GoRoute(path: '/staff/vocabulary',    builder: (_, __) => const StaffVocabularyScreen()),
      GoRoute(
        path: '/staff/vocabulary/:id',
        builder: (_, state) => StaffVocabularyDetailScreen(
            vocabId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/staff/leave',         builder: (_, __) => const StaffLeaveScreen()),
      GoRoute(path: '/staff/feedback',      builder: (_, __) => const StaffFeedbackScreen()),
      GoRoute(path: '/staff/payments',      builder: (_, __) => const StaffPaymentsScreen()),
      GoRoute(path: '/staff/notifications', builder: (_, __) => const StaffNotificationsScreen()),
      GoRoute(path: '/staff/attendance/update', builder: (_, __) => const StaffUpdateAttendanceScreen()),
      GoRoute(path: '/staff/profile',       builder: (_, __) => const ProfileHubScreen()),
      GoRoute(path: '/staff/messages',      builder: (_, __) => const MessagesScreen()),

      // ── Student shell (6 bottom-nav branches) ────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            StudentShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/student/home', builder: (_, __) => const StudentHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/vocabulary',
              builder: (_, __) => const StudentVocabularyScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/student/progress', builder: (_, __) => const StudentProgressScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/student/attendance', builder: (_, __) => const StudentAttendanceScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/student/payments', builder: (_, __) => const StudentPaymentsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/student/more', builder: (_, __) => const StudentMoreScreen()),
          ]),
        ],
      ),

      // ── Student standalone routes ─────────────────────────────────────────
      GoRoute(path: '/student/results',      builder: (_, __) => const StudentResultsScreen()),
      GoRoute(path: '/student/assignments',  builder: (_, __) => const StudentAssignmentsScreen()),
      GoRoute(path: '/student/leaderboard',  builder: (_, __) => const StudentLeaderboardScreen()),
      GoRoute(path: '/student/leave',        builder: (_, __) => const StudentLeaveScreen()),
      GoRoute(path: '/student/feedback',     builder: (_, __) => const StudentFeedbackScreen()),
      GoRoute(path: '/student/notifications',builder: (_, __) => const StudentNotificationsScreen()),
      GoRoute(path: '/student/books',        builder: (_, __) => const StudentBooksScreen()),
      GoRoute(path: '/student/result-files', builder: (_, __) => const StudentResultFilesScreen()),
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
          GoRoute(
            path: 'learn',
            builder: (_, state) => StudentLearnScreen(
                vocabId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'quiz',
            builder: (_, state) => StudentVocabularyQuizScreen(
              dayId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              dayTitle: state.uri.queryParameters['title'] ?? 'Vocabulary Quiz',
            ),
          ),
        ],
      ),
      GoRoute(path: '/student/profile',      builder: (_, __) => const ProfileHubScreen()),
      GoRoute(path: '/student/settings',     builder: (_, __) => const StudentSettingsScreen()),
      GoRoute(path: '/student/messages',     builder: (_, __) => const MessagesScreen()),
      GoRoute(
        path: '/student/assignments/:id',
        builder: (_, state) => StudentAssignmentDetailScreen(
            assignmentId: int.tryParse(state.pathParameters['id']!) ?? 0),
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
