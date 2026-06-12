import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminSessionsScreen extends ConsumerStatefulWidget {
  const AdminSessionsScreen({super.key});

  @override
  ConsumerState<AdminSessionsScreen> createState() =>
      _AdminSessionsScreenState();
}

class _AdminSessionsScreenState extends ConsumerState<AdminSessionsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.dio.get('/admin/sessions/');
      setState(() {
        _sessions = List<Map<String, dynamic>>.from(
          res.data is List ? res.data : (res.data['results'] ?? res.data),
        );
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showForm({Map<String, dynamic>? session}) {
    final startCtrl = TextEditingController(
      text: session?['start_year']?.toString() ?? '',
    );
    final endCtrl = TextEditingController(
      text: session?['end_year']?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SessionFormSheet(
        title: session == null ? 'Add Session' : 'Edit Session',
        startCtrl: startCtrl,
        endCtrl: endCtrl,
        showDelete: session != null,
        onSave: () async {
          final start = int.tryParse(startCtrl.text.trim());
          final end = int.tryParse(endCtrl.text.trim());
          if (start == null || end == null) return;
          final data = {'start_year': start, 'end_year': end};
          try {
            if (session == null) {
              await ApiClient.instance.dio.post('/admin/sessions/', data: data);
            } else {
              await ApiClient.instance.dio.patch(
                '/admin/sessions/${session['id']}/',
                data: data,
              );
            }
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          } catch (_) {}
        },
        onDelete: session == null
            ? null
            : () async {
                try {
                  await ApiClient.instance.dio.delete(
                    '/admin/sessions/${session['id']}/',
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (_) {}
              },
      ),
    );
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
                title: 'Academic Sessions',
                subtitle: 'Manage academic years',
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
                    Icons.calendar_today_rounded,
                    color: IceColors.navyDeep,
                    size: 22,
                  ),
                ),
                actions: [
                  ElevatedButton.icon(
                    onPressed: () => _showForm(),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'Add Session',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IceColors.lime,
                      foregroundColor: IceColors.navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
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
            else if (_sessions.isEmpty)
              SliverToBoxAdapter(child: _buildEmpty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  if (i == _sessions.length) return const SizedBox(height: 80);
                  return _SessionCard(
                    session: _sessions[i],
                    index: i,
                    onEdit: () => _showForm(session: _sessions[i]),
                  );
                }, childCount: _sessions.length + 1),
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
              Icons.calendar_month_outlined,
              size: 48,
              color: IceColors.muted,
            ),
            SizedBox(height: 12),
            Text(
              'No sessions yet',
              style: TextStyle(color: IceColors.muted, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final int index;
  final VoidCallback onEdit;
  const _SessionCard({
    required this.session,
    required this.index,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final start = session['start_year']?.toString() ?? '';
    final end = session['end_year']?.toString() ?? '';
    final label = '$start–$end';
    final isCurrent = session['is_current'] == true;

    return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: IceColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? IceColors.navyDeep.withAlpha(60)
                  : IceColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? IceColors.lime
                      : IceColors.navyDeep.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: isCurrent ? IceColors.navy : IceColors.navyDeep,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: IceColors.text,
                      ),
                    ),
                    if (isCurrent)
                      const Text(
                        'Current Session',
                        style: TextStyle(
                          fontSize: 11,
                          color: IceColors.navyDeep,
                        ),
                      ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: IceColors.lime,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'CURRENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: IceColors.navy,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: IceColors.muted,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 80 + index * 40))
        .slideX(begin: 0.05, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 250.ms);
  }
}

class _SessionFormSheet extends StatelessWidget {
  final String title;
  final TextEditingController startCtrl;
  final TextEditingController endCtrl;
  final bool showDelete;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  const _SessionFormSheet({
    required this.title,
    required this.startCtrl,
    required this.endCtrl,
    required this.onSave,
    this.showDelete = false,
    this.onDelete,
  });

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: IceColors.surface2,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: IceColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: IceColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: IceColors.navyDeep, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        left: 16,
        right: 16,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IceColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: IceColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: IceColors.text,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: startCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Start Year'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: endCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('End Year'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: IceColors.lime,
                    foregroundColor: IceColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (showDelete && onDelete != null) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: IceColors.danger,
                  ),
                  tooltip: 'Delete',
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
