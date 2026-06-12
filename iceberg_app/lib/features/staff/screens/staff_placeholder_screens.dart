import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/screens/notifications_screen.dart';
import '../../../shared/widgets/ice_page_header.dart';

class StaffMoreScreen2 extends StatelessWidget {
  const StaffMoreScreen2({super.key});

  static const _items = [
    _StaffAction(Icons.class_rounded, 'Classes', '/staff/classes'),
    _StaffAction(Icons.fact_check_rounded, 'Attendance', '/staff/attendance'),
    _StaffAction(
      Icons.edit_calendar_rounded,
      'Update Attendance',
      '/staff/attendance/update',
    ),
    _StaffAction(Icons.grade_rounded, 'Results', '/staff/results'),
    _StaffAction(Icons.assignment_rounded, 'Assignments', '/staff/assignments'),
    _StaffAction(Icons.menu_book_rounded, 'Vocabulary', '/staff/vocabulary'),
    _StaffAction(Icons.payment_rounded, 'Payments', '/staff/payments'),
    _StaffAction(
      Icons.notifications_rounded,
      'Notifications',
      '/staff/notifications',
    ),
  ];

  @override
  Widget build(BuildContext context) => _StaffActionGrid(
    title: 'Staff Tools',
    subtitle: 'Teaching, attendance, results, and communication',
    items: _items,
  );
}

class StaffPaymentsScreen extends StatefulWidget {
  const StaffPaymentsScreen({super.key});

  @override
  State<StaffPaymentsScreen> createState() => _StaffPaymentsScreenState();
}

class _StaffPaymentsScreenState extends State<StaffPaymentsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.dio.get(
        '/staff/payments/',
        queryParameters: {'month': _monthValue(_month)},
      );
      setState(() {
        _data = Map<String, dynamic>.from(res.data as Map);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
    _load();
  }

  String _monthValue(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  String _monthLabel(DateTime date) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final boards = (_data?['boards'] as List?) ?? [];
    final summary = (_data?['summary'] as Map?) ?? {};

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
                title: 'Payments Status',
                subtitle:
                    'Read-only tuition status for students in your groups',
                chips: [
                  IceHeaderChip(
                    icon: Icons.chevron_left_rounded,
                    label: 'Previous',
                    onTap: () => _shiftMonth(-1),
                  ),
                  IceHeaderChip(
                    icon: Icons.calendar_month_rounded,
                    label: _monthLabel(_month),
                    onTap: _load,
                  ),
                  IceHeaderChip(
                    icon: Icons.chevron_right_rounded,
                    label: 'Next',
                    onTap: () => _shiftMonth(1),
                  ),
                ],
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
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error: $_error',
                    style: const TextStyle(color: IceColors.danger),
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final cols = c.maxWidth >= 720 ? 4 : 2;
                      final width = (c.maxWidth - (cols - 1) * 10) / cols;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: width,
                            child: _SummaryTile(
                              label: 'Paid',
                              value: '${summary['paid'] ?? 0}',
                              icon: Icons.check_circle_rounded,
                              color: IceColors.success,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _SummaryTile(
                              label: 'Due',
                              value: '${summary['due'] ?? 0}',
                              icon: Icons.hourglass_bottom_rounded,
                              color: IceColors.info,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _SummaryTile(
                              label: 'Overdue',
                              value: '${summary['overdue'] ?? 0}',
                              icon: Icons.warning_rounded,
                              color: IceColors.danger,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _SummaryTile(
                              label: 'Not Invoiced',
                              value: '${summary['none'] ?? 0}',
                              icon: Icons.remove_circle_outline_rounded,
                              color: IceColors.muted,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (boards.isEmpty)
                const SliverToBoxAdapter(
                  child: _StaffEmptyState(
                    icon: Icons.group_work_outlined,
                    title: 'No groups assigned',
                    text:
                        'Once you are assigned to a group, payment status appears here.',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _PaymentBoardCard(board: boards[index] as Map),
                    childCount: boards.length,
                  ),
                ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class StaffNotificationsScreen extends StatelessWidget {
  const StaffNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => const NotificationsScreen();
}

class _PaymentBoardCard extends StatelessWidget {
  final Map board;
  const _PaymentBoardCard({required this.board});

  @override
  Widget build(BuildContext context) {
    final group = (board['group'] as Map?) ?? {};
    final rows = (board['rows'] as List?) ?? [];
    final schedule = group['schedule']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IceColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: IceColors.navyDeep.withAlpha(14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group_work_rounded,
                  color: IceColors.navyDeep,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['name']?.toString() ?? 'Group',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: IceColors.text,
                      ),
                    ),
                    if (schedule.isNotEmpty)
                      Text(
                        schedule,
                        style: const TextStyle(
                          fontSize: 12,
                          color: IceColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${rows.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: IceColors.navyDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const _InlineEmpty(text: 'No active students')
          else
            ...rows.map((row) => _PaymentRow(row: row as Map)),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final Map row;
  const _PaymentRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final student = (row['student'] as Map?) ?? {};
    final invoice = row['invoice'] as Map?;
    final state = row['state']?.toString() ?? 'none';
    final style = _StatusStyle.fromState(state, invoice);
    final amountDue = invoice?['amount_due']?.toString() ?? '';
    final dueDate = invoice?['due_date']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: style.color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.color.withAlpha(45)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: style.color.withAlpha(18),
            child: Text(
              _initial(student['name']?.toString() ?? ''),
              style: TextStyle(
                color: style.color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name']?.toString() ?? 'Student',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: IceColors.text,
                  ),
                ),
                if (dueDate.isNotEmpty)
                  Text(
                    amountDue.isEmpty
                        ? 'Due $dueDate'
                        : 'Due $dueDate · $amountDue',
                    style: const TextStyle(
                      fontSize: 11,
                      color: IceColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          _StatusPill(label: style.label, color: style.color),
        ],
      ),
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: IceColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: IceColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: IceColors.text,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: IceColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withAlpha(18),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
    ),
  );
}

class _StatusStyle {
  final String label;
  final Color color;
  const _StatusStyle(this.label, this.color);

  factory _StatusStyle.fromState(String state, Map? invoice) {
    switch (state) {
      case 'paid':
        return const _StatusStyle('Paid', IceColors.success);
      case 'overdue':
        return const _StatusStyle('Overdue', IceColors.danger);
      case 'due':
        return _StatusStyle(
          invoice?['status_display']?.toString() ?? 'Due',
          IceColors.info,
        );
      default:
        return const _StatusStyle('Not invoiced', IceColors.muted);
    }
  }
}

class _StaffActionGrid extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_StaffAction> items;
  const _StaffActionGrid({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900
        ? 4
        : width >= 600
        ? 3
        : 2;
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: IcePageHeader(title: title, subtitle: subtitle),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _StaffActionCard(item: items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffActionCard extends StatelessWidget {
  final _StaffAction item;
  const _StaffActionCard({required this.item});

  @override
  Widget build(BuildContext context) => Material(
    color: IceColors.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.go(item.path),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: IceColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: IceColors.navyDeep.withAlpha(14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: IceColors.navyDeep, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: IceColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StaffAction {
  final IconData icon;
  final String label;
  final String path;
  const _StaffAction(this.icon, this.label, this.path);
}

class _InlineEmpty extends StatelessWidget {
  final String text;
  const _InlineEmpty({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(
      child: Text(text, style: const TextStyle(color: IceColors.muted)),
    ),
  );
}

class _StaffEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _StaffEmptyState({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 52, color: IceColors.muted),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: IceColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: IceColors.muted),
        ),
      ],
    ),
  );
}
