import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminLeaveScreen extends ConsumerStatefulWidget {
  const AdminLeaveScreen({super.key});

  @override
  ConsumerState<AdminLeaveScreen> createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends ConsumerState<AdminLeaveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      dynamic data;
      try {
        final res = await ApiClient.instance.dio.get('/admin/leave-requests/');
        data = res.data;
      } catch (_) {
        final res = await ApiClient.instance.dio.get('/leave/');
        data = res.data;
      }
      setState(() {
        _requests = List<Map<String, dynamic>>.from(
          data is List ? data : (data['results'] ?? data),
        );
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final isStudent = _tabCtrl.index == 0;
    return _requests.where((r) {
      final type = (r['user_type'] ?? r['type'] ?? '').toString().toLowerCase();
      if (isStudent) {
        return type == 'student' || type == '' || !type.contains('staff');
      } else {
        return type.contains('staff') || type == 'teacher';
      }
    }).toList();
  }

  Future<void> _updateStatus(
    Map<String, dynamic> request,
    String status,
  ) async {
    try {
      try {
        await ApiClient.instance.dio.patch(
          '/admin/leave-requests/${request['id']}/',
          data: {'status': status},
        );
      } catch (_) {
        await ApiClient.instance.dio.patch(
          '/leave/${request['id']}/',
          data: {'status': status},
        );
      }
      _load();
      if (mounted) {
        final isApproved = status == 'approved';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isApproved ? 'Leave request approved' : 'Leave request rejected',
            ),
            backgroundColor: isApproved ? IceColors.success : IceColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Action failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Leave Requests',
                subtitle: 'Review and action leave applications',
                avatar: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: IceColors.navyDeep.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: IceColors.border),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.event_busy_rounded,
                    color: IceColors.navyDeep,
                    size: 22,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                decoration: BoxDecoration(
                  color: IceColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: IceColors.border),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: IceColors.navyDeep,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: IceColors.muted,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Students'),
                    Tab(text: 'Staff'),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: IceColors.navyDeep),
                  ),
                ),
              )
            else if (_filtered.isEmpty)
              SliverToBoxAdapter(child: _buildEmpty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  final list = _filtered;
                  if (i == list.length) return const SizedBox(height: 80);
                  return _LeaveCard(
                    request: list[i],
                    index: i,
                    onApprove: () => _updateStatus(list[i], 'approved'),
                    onReject: () => _updateStatus(list[i], 'rejected'),
                  );
                }, childCount: _filtered.length + 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.all(60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 48,
              color: IceColors.muted,
            ),
            SizedBox(height: 12),
            Text(
              'No leave requests',
              style: TextStyle(color: IceColors.muted, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final int index;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _LeaveCard({
    required this.request,
    required this.index,
    required this.onApprove,
    required this.onReject,
  });

  Color get _statusColor {
    final s = (request['status'] ?? '').toString().toLowerCase();
    if (s == 'approved') return IceColors.success;
    if (s == 'rejected') return IceColors.danger;
    return const Color(0xFFF59E0B);
  }

  String get _statusLabel {
    final s = (request['status'] ?? 'pending').toString();
    return s[0].toUpperCase() + s.substring(1);
  }

  bool get _isPending {
    final s = (request['status'] ?? '').toString().toLowerCase();
    return s == 'pending' || s == '';
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        request['student_name'] ??
        request['staff_name'] ??
        request['user_name'] ??
        request['user']?['name'] ??
        request['applicant'] ??
        'Unknown';
    final fromDate =
        request['from_date'] ?? request['start_date'] ?? request['date'] ?? '';
    final toDate = request['to_date'] ?? request['end_date'] ?? '';
    final reason = request['reason'] ?? request['description'] ?? '';

    return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: IceColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: IceColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: IceColors.navyDeep.withAlpha(15),
                    child: Text(
                      userName.toString().isNotEmpty
                          ? userName.toString()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: IceColors.navyDeep,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: IceColors.text,
                          ),
                        ),
                        if (fromDate.toString().isNotEmpty)
                          Text(
                            toDate.toString().isNotEmpty
                                ? '$fromDate → $toDate'
                                : fromDate.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: IceColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (reason.toString().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: IceColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    reason.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: IceColors.muted,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (_isPending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: IceColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 14),
                            SizedBox(width: 4),
                            Text('Approve'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onReject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: IceColors.danger,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded, size: 14),
                            SizedBox(width: 4),
                            Text('Reject'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 60 + index * 40))
        .slideX(begin: 0.05, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 250.ms);
  }
}
