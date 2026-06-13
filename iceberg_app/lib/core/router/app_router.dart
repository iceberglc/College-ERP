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

      // ── Student shell (5 branches: Dashboard·Progress·Vocab·Ranks·Profile) ─
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            StudentShell(navigationShell: navigationShell),
        branches: [
          // 0 · Dashboard + its drill-downs
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/home',
                builder: (_, __) => const StudentHomeScreen(),
              ),
              GoRoute(
                path: '/student/notifications',
                builder: (_, __) => const StudentNotificationsScreen(),
              ),
              GoRoute(
                path: '/student/messages',
                builder: (_, __) => const StudentMessagesScreen(),
                routes: [
                  GoRoute(
                    path: ':groupId',
                    builder: (_, state) => StudentChatScreen(
                      groupId:
                          int.tryParse(state.pathParameters['groupId']!) ?? 0,
                      groupName: state.uri.queryParameters['name'] ?? 'Chat',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '/student/assignments',
                builder: (_, __) => const StudentAssignmentsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => StudentAssignmentDetailScreen(
                      assignmentId:
                          int.tryParse(state.pathParameters['id']!) ?? 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 1 · Progress + Attendance Hub
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/progress',
                builder: (_, __) => const StudentProgressScreen(),
              ),
              GoRoute(
                path: '/student/attendance',
                builder: (_, __) => const StudentAttendanceScreen(),
              ),
            ],
          ),
          // 2 · Vocabulary
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/vocabulary',
                builder: (_, __) => const StudentVocabularyScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => StudentVocabularyDetailScreen(
                      vocabId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'flashcards',
                        builder: (_, state) => StudentFlashcardScreen(
                          vocabId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'learn',
                        builder: (_, state) => StudentLearnScreen(
                          vocabId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'quiz',
                        builder: (_, state) => StudentVocabularyQuizScreen(
                          dayId:
                              int.tryParse(state.pathParameters['id'] ?? '') ??
                              0,
                          dayTitle:
                              state.uri.queryParameters['title'] ??
                              'Vocabulary Quiz',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // 3 · Leaderboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/leaderboard',
                builder: (_, __) => const StudentLeaderboardScreen(),
              ),
            ],
          ),
          // 4 · Profile + student services
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/profile',
                builder: (_, __) => const StudentProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, __) => const StudentEditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'avatar',
                    builder: (_, __) => const StudentAvatarScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: '/student/settings',
                builder: (_, __) => const StudentSettingsScreen(),
              ),
              GoRoute(
                path: '/student/results',
                builder: (_, __) => const StudentResultsScreen(),
              ),
              GoRoute(
                path: '/student/result-files',
                builder: (_, __) => const StudentResultFilesScreen(),
              ),
              GoRoute(
                path: '/student/library',
                builder: (_, __) => const StudentBooksScreen(),
              ),
              GoRoute(
                path: '/student/books',
                builder: (_, __) => const StudentBooksScreen(),
              ),
              GoRoute(
                path: '/student/payments',
                builder: (_, __) => const StudentPaymentsScreen(),
              ),
              GoRoute(
                path: '/student/leave',
                builder: (_, __) => const StudentLeaveScreen(),
              ),
              GoRoute(
                path: '/student/feedback',
                builder: (_, __) => const StudentFeedbackScreen(),
              ),
            ],
          ),
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
