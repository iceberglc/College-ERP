import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

// Generic async data fetch helper
Future<Map<String, dynamic>> apiGet(String path) async {
  final res = await ApiClient.instance.dio.get(path);
  return res.data as Map<String, dynamic>;
}

Future<List<dynamic>> apiGetList(String path) async {
  final res = await ApiClient.instance.dio.get(path);
  final data = res.data;
  if (data is List) return data;
  if (data is Map && data.containsKey('results')) {
    return data['results'] as List;
  }
  return [];
}

// Student dashboard
final studentDashProvider = FutureProvider<Map<String, dynamic>>(
  (_) => apiGet('/student/home/'),
);

// Student attendance
final studentAttendanceProvider = FutureProvider<Map<String, dynamic>>(
  (_) => apiGet('/attendance/'),
);

// Student results
final studentResultsProvider = FutureProvider<Map<String, dynamic>>(
  (_) => apiGet('/results/'),
);

// Student / staff leaves
final leaveProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/leave/'),
);

// Staff dashboard (stats)
final staffStatsProvider = FutureProvider<Map<String, dynamic>>(
  (_) => apiGet('/stats/'),
);

// Staff groups
final staffGroupsProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/groups/'),
);

// Admin dashboard
final adminDashProvider = FutureProvider<Map<String, dynamic>>(
  (_) => apiGet('/admin/home/'),
);

// Admin students list
final adminStudentsProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/admin/students/'),
);

// Admin staff list
final adminStaffProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/admin/staff/'),
);

// Admin registration leads
final adminLeadsProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/admin/leads/'),
);

// Groups (all roles — branch-scoped on server side)
final groupsProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/groups/'),
);

// Courses
final coursesProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/courses/'),
);

// Assignments (role-scoped on server)
final assignmentsProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/assignments/'),
);

// Notifications
final notificationsProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/notifications/'),
);

// Invoices (student: own; admin: all)
final invoicesProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/invoices/'),
);

// Feedback (student/staff: own; admin: all)
final feedbackProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/feedback/'),
);

// Vocabulary days (student: own groups; released)
final vocabularyProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/vocabulary/'),
);

// Leaderboard (active season)
final leaderboardProvider = FutureProvider<Map<String, dynamic>>(
  (_) => apiGet('/leaderboard/'),
);

// Admin branches
final adminBranchesProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/admin/branches/'),
);

// Admin stats (for superadmin overview)
final adminStatsProvider = FutureProvider<Map<String, dynamic>>(
  (_) => apiGet('/admin/stats/'),
);

// Stories (student sees own groups; admin/staff see all)
final storiesProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/stories/'),
);

// Student progress charts
final studentProgressProvider = FutureProvider<Map<String, dynamic>>(
  (_) => apiGet('/student/progress/'),
);

// Vocabulary quiz for a specific day
final vocabQuizProvider = FutureProvider.family<List<dynamic>, int>(
  (_, pk) => apiGetList('/vocabulary/$pk/quiz/'),
);

// Staff vocabulary days
final staffVocabularyProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/staff/vocabulary/'),
);

// Staff vocabulary day detail
final staffVocabDetailProvider =
    FutureProvider.family<Map<String, dynamic>, int>(
      (_, pk) => apiGet('/staff/vocabulary/$pk/'),
    );

// Admin groups list
final adminGroupsProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/admin/groups/'),
);

// Admin groups (CRUD endpoint — includes enrolled_count, monthly_fee, start_date)
final adminGroupsManageProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/admin/groups-manage/'),
);

// Staff list (for teacher dropdown in add/edit group)
final adminStaffListProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/admin/staff/'),
);

// Admin users list (HOD accounts — superadmin only)
final adminAdminsProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/admin/admins/'),
);

// Staff payments (invoices for teacher's groups)
final staffPaymentsProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/staff/payments/'),
);

// Admin branches with full detail (for superadmin analytics)
final adminBranchesDetailProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/admin/branches-manage/'),
);

// Admin attendance report (all groups)
final adminAttendanceReportProvider = FutureProvider<List<dynamic>>(
  (_) => apiGetList('/admin/attendance-report/'),
);
