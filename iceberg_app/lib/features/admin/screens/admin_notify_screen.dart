import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminNotifyScreen extends ConsumerStatefulWidget {
  const AdminNotifyScreen({super.key});

  @override
  ConsumerState<AdminNotifyScreen> createState() => _AdminNotifyScreenState();
}

class _AdminNotifyScreenState extends ConsumerState<AdminNotifyScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _target = 'all';
  int? _selectedGroupId;
  bool _sending = false;
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final res = await ApiClient.instance.dio.get('/admin/groups/');
      final raw = res.data;
      setState(() {
        _groups = List<Map<String, dynamic>>.from(
          raw is List ? raw : (raw['results'] ?? []),
        );
      });
    } catch (_) {}
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'target': _target,
        if (_selectedGroupId != null) 'group': _selectedGroupId,
      };
      await ApiClient.instance.dio.post(
        '/admin/send-notification/',
        data: data,
      );
      if (mounted) {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        setState(() {
          _target = 'all';
          _selectedGroupId = null;
          _sending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Notification sent successfully'),
              ],
            ),
            backgroundColor: IceColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send notification'),
            backgroundColor: IceColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: IcePageHeader(
              title: 'Send Notification',
              subtitle: 'Broadcast to students or staff',
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
                  Icons.notifications_active_rounded,
                  color: IceColors.navyDeep,
                  size: 22,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  _sectionLabel('TITLE'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _titleCtrl,
                    hint: 'Notification title',
                  ),
                  const SizedBox(height: 20),

                  // Message field
                  _sectionLabel('MESSAGE'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _bodyCtrl,
                    hint: 'Write your message here...',
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),

                  // Target selector
                  _sectionLabel('TARGET AUDIENCE'),
                  const SizedBox(height: 12),
                  _buildTargetSegment(),
                  const SizedBox(height: 20),

                  // Group dropdown
                  if (_groups.isNotEmpty) ...[
                    _sectionLabel('GROUP (OPTIONAL)'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      initialValue: _selectedGroupId,
                      decoration: _inputDeco('Select group or leave blank'),
                      borderRadius: BorderRadius.circular(12),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('No specific group'),
                        ),
                        ..._groups.map(
                          (g) => DropdownMenuItem<int?>(
                            value: g['id'] as int?,
                            child: Text(g['name']?.toString() ?? ''),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedGroupId = v),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: IceColors.navy,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _sending ? 'Sending…' : 'Send Notification',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: IceColors.lime,
                        foregroundColor: IceColors.navy,
                        disabledBackgroundColor: IceColors.lime.withAlpha(120),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ).animate().slideY(begin: 0.1, duration: 300.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: IceColors.muted,
      letterSpacing: 1.0,
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) => TextField(
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: IceColors.muted),
      filled: true,
      fillColor: IceColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: IceColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: IceColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: IceColors.navyDeep, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  Widget _buildTargetSegment() => Row(
    children: [
      _TargetOption(
        label: 'All',
        icon: Icons.groups_rounded,
        selected: _target == 'all',
        onTap: () => setState(() => _target = 'all'),
      ),
      const SizedBox(width: 10),
      _TargetOption(
        label: 'Students',
        icon: Icons.school_rounded,
        selected: _target == 'students',
        onTap: () => setState(() => _target = 'students'),
      ),
      const SizedBox(width: 10),
      _TargetOption(
        label: 'Staff',
        icon: Icons.badge_rounded,
        selected: _target == 'staff',
        onTap: () => setState(() => _target = 'staff'),
      ),
    ],
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: IceColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: IceColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: IceColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: IceColors.navyDeep, width: 1.5),
    ),
  );
}

class _TargetOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TargetOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? IceColors.navyDeep : IceColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? IceColors.navyDeep : IceColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: IceColors.navyDeep.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : IceColors.muted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : IceColors.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
