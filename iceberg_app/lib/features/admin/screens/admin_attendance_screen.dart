import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminAttendanceScreen extends ConsumerStatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  ConsumerState<AdminAttendanceScreen> createState() =>
      _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends ConsumerState<AdminAttendanceScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Try attendance report endpoint first, fall back to stats
      dynamic data;
      try {
        final res =
            await ApiClient.instance.dio.get('/admin/attendance-report/');
        data = res.data;
      } catch (_) {
        final res = await ApiClient.instance.dio.get('/stats/');
        data = res.data;
      }

      List<Map<String, dynamic>> groups = [];
      if (data is List) {
        groups = List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        final raw = data['groups'] ?? data['results'] ?? data['attendance'];
        if (raw is List) {
          groups = List<Map<String, dynamic>>.from(raw);
        }
      }

      setState(() {
        _groups = groups;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _barColor(double pct) {
    if (pct >= 80) return IceColors.success;
    if (pct >= 60) return const Color(0xFFF59E0B);
    return IceColors.danger;
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
                title: 'Attendance',
                subtitle: 'Per-group attendance overview',
                avatar: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: IceColors.navyDeep.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: IceColors.border),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.bar_chart_rounded,
                      color: IceColors.navyDeep, size: 22),
                ),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                  child: Center(
                      child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                              color: IceColors.navyDeep))))
            else if (_groups.isEmpty)
              SliverToBoxAdapter(child: _buildEmpty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i == _groups.length) return const SizedBox(height: 80);
                    return _GroupAttendanceCard(
                      group: _groups[i],
                      index: i,
                      barColor: _barColor,
                    );
                  },
                  childCount: _groups.length + 1,
                ),
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
            Icon(Icons.bar_chart_outlined, size: 48, color: IceColors.muted),
            SizedBox(height: 12),
            Text('No attendance data',
                style: TextStyle(color: IceColors.muted, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _GroupAttendanceCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final int index;
  final Color Function(double) barColor;

  const _GroupAttendanceCard(
      {required this.group,
      required this.index,
      required this.barColor});

  @override
  Widget build(BuildContext context) {
    final name = group['group_name'] ?? group['name'] ?? 'Unknown Group';
    final rawPct = group['attendance_percentage'] ??
        group['attendance_percent'] ??
        group['percentage'] ??
        0;
    final pct = (rawPct is num ? rawPct.toDouble() : 0.0).clamp(0.0, 100.0);
    final color = barColor(pct);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IceColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(name.toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: IceColors.text)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: color.withAlpha(20),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 80 + index * 40))
        .slideX(begin: 0.05, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 250.ms);
  }
}
