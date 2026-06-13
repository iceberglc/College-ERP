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

// Staff
import '../../features/staff/screens/staff_shell.dart';
import '../../features/staff/screens/staff_home_screen.dart';
import '../../features/staff/screens/staff_more_screen.dart';
import '../../features/staff/screens/staff_placeholder_screens.dart';

// Shared
import '../../shared/screens/profile_hub_screen.dart';
import '../../shared/screens/messages_screen.dart';

/// Routing by role:
///   - Student (user_type 3) → full /student/* experience
///   - Staff   (user_type 2) → teacher portal /staff/*
///   - Admin   (user_type 1) → /coming-soon (admin web portal handles them)
///
/// Each role's sub-screens are nested inside the role's StatefulShellRoute
/// branches so the bottom navigation bar persists and back-navigation works.
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

      // Admin → coming-soon wall (admin dashboard ships on the web portal).
      if (user.isAdmin) {
        return path == '/coming-soon' ? null : '/coming-soon';
      }

      // Staff (teachers) → teacher portal.
      if (user.isStaff) {
        if (path.startsWith('/staff')) return null;
        return '/staff/home';
      }

      // Students → student app; bounce off auth/transitional routes.
      if (path == '/login' ||
          path == '/splash' ||
          path == '/coming-soon' ||
          path.startsWith('/staff')) {
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
          // 0 · Home + drill-downs (notifications, messages, profile)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/staff/home',
              builder: (_, __) => const StaffHomeScreen(),
              routes: [
                GoRoute(
                  path: 'notifications',
                  builder: (_, __) => const StaffNotificationsScreen(),
                ),
                GoRoute(
                  path: 'messages',
                  builder: (_, __) => const MessagesScreen(),
                ),
                GoRoute(
                  path: 'profile',
                  builder: (_, __) => const ProfileHubScreen(),
                ),
              ],
            ),
          ]),
          // 1 · Classes
          StatefulShellBranch(routes: [
            GoRoute(path: '/staff/classes', builder: (_, __) => const StaffClassesScreen()),
          ]),
          // 2 · Attendance + update
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/staff/attendance',
              builder: (_, __) => const StaffAttendanceScreen(),
              routes: [
                GoRoute(
                  path: 'update',
                  builder: (_, __) => const StaffUpdateAttendanceScreen(),
                ),
              ],
            ),
          ]),
          // 3 · Assignments
          StatefulShellBranch(routes: [
            GoRoute(path: '/staff/assignments', builder: (_, __) => const StaffAssignmentsScreen()),
          ]),
          // 4 · More + staff services
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/staff/more',
              builder: (_, __) => const StaffMoreScreen(),
              routes: [
                GoRoute(path: 'results', builder: (_, __) => const StaffResultsScreen()),
                GoRoute(
                  path: 'vocabulary',
                  builder: (_, __) => const StaffVocabularyScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (_, state) => StaffVocabularyDetailScreen(
                          vocabId: state.pathParameters['id']!),
                    ),
                  ],
                ),
                GoRoute(path: 'leave', builder: (_, __) => const StaffLeaveScreen()),
                GoRoute(path: 'feedback', builder: (_, __) => const StaffFeedbackScreen()),
                GoRoute(path: 'payments', builder: (_, __) => const StaffPaymentsScreen()),
              ],
            ),
          ]),
        ],
      ),
      // Staff routes referenced directly by the More screen (kept at the same
      // path the StaffMoreScreen tiles point at, nested under /staff/more).
      GoRoute(path: '/staff/results',       builder: (_, __) => const StaffResultsScreen()),
      GoRoute(path: '/staff/vocabulary',    builder: (_, __) => const StaffVocabularyScreen()),
      GoRoute(path: '/staff/leave',         builder: (_, __) => const StaffLeaveScreen()),
      GoRoute(path: '/staff/feedback',      builder: (_, __) => const StaffFeedbackScreen()),
      GoRoute(path: '/staff/payments',      builder: (_, __) => const StaffPaymentsScreen()),
      GoRoute(path: '/staff/notifications', builder: (_, __) => const StaffNotificationsScreen()),
      GoRoute(path: '/staff/profile',       builder: (_, __) => const ProfileHubScreen()),
      GoRoute(path: '/staff/messages',      builder: (_, __) => const MessagesScreen()),

      // ── Student shell (5 bottom-nav branches) ────────────────────────────
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
