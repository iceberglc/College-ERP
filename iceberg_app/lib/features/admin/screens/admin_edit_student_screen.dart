import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminEditStudentScreen extends ConsumerStatefulWidget {
  final String studentId;
  const AdminEditStudentScreen({super.key, required this.studentId});

  @override
  ConsumerState<AdminEditStudentScreen> createState() =>
      _AdminEditStudentScreenState();
}

class _AdminEditStudentScreenState
    extends ConsumerState<AdminEditStudentScreen> {
  final _form = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName  = TextEditingController();
  final _phone     = TextEditingController();
  final _address   = TextEditingController();
  String _gender = 'M';
  String? _dob;
  String? _status = 'active';
  int? _courseId;
  int? _branchId;
  String? _loginId;
  bool _loading = false;
  bool _saving  = false;
  String? _error;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio
          .get('/admin/students/${widget.studentId}/');
      final d = res.data as Map<String, dynamic>;
      _firstName.text = d['first_name']?.toString() ?? '';
      _lastName.text  = d['last_name']?.toString()  ?? '';
      _phone.text     = d['phone']?.toString()       ?? '';
      _address.text   = d['address']?.toString()     ?? '';
      _gender  = d['gender']?.toString() == 'F' ? 'F' : 'M';
      _status  = d['status']?.toString() ?? 'active';
      _loginId = d['login_id']?.toString();
      _dob     = d['date_of_birth']?.toString();
      final course = d['course'];
      _courseId = course is int ? course : (course is Map ? course['id'] as int? : null);
      final branch = d['branch'];
      _branchId = branch is int ? branch : (branch is Map ? branch['id'] as int? : null);
      setState(() { _loading = false; _loaded = true; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ApiClient.instance.dio.patch(
        '/admin/students/${widget.studentId}/',
        data: {
          'first_name': _firstName.text.trim(),
          'last_name':  _lastName.text.trim(),
          'phone':      _phone.text.trim(),
          'address':    _address.text.trim(),
          'gender':     _gender,
          'status':     _status,
          if (_dob != null) 'date_of_birth': _dob,
          if (_courseId != null) 'course': _courseId,
          if (_branchId != null) 'branch': _branchId,
        },
      );
      ref.invalidate(adminStudentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student updated successfully'),
            backgroundColor: IceColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/admin/students');
      }
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses  = ref.watch(coursesProvider);
    final branches = ref.watch(adminBranchesProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: IceColors.navyDeep))
          : _error != null && !_loaded
              ? _ErrorBody(error: _error!, onRetry: _loadStudent)
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: IcePageHeader(
                        title: 'Edit Student',
                        subtitle: _loginId != null ? 'ID: $_loginId' : 'Update student info',
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        child: Form(
                          key: _form,
                          child: Column(children: [
                            if (_loginId != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: IceColors.navyDeep.withAlpha(12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: IceColors.navyDeep.withAlpha(40)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.badge_rounded,
                                      color: IceColors.navyDeep, size: 18),
                                  const SizedBox(width: 10),
                                  Text('Login ID: $_loginId',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: IceColors.navyDeep)),
                                ]),
                              ),
                            if (_error != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: IceColors.danger.withAlpha(20),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: IceColors.danger.withAlpha(60)),
                                ),
                                child: Text(_error!,
                                    style: const TextStyle(
                                        color: IceColors.danger)),
                              ),
                            _field(_firstName, 'First Name', required: true),
                            _field(_lastName, 'Last Name'),
                            _field(_phone, 'Phone', keyboard: TextInputType.phone),
                            _field(_address, 'Address', maxLines: 2),
                            _dropdownField(
                              'Gender',
                              _gender,
                              {'M': 'Male', 'F': 'Female'},
                              (v) => setState(() => _gender = v!),
                            ),
                            _dropdownField(
                              'Status',
                              _status ?? 'active',
                              {
                                'active':    'Active',
                                'inactive':  'Inactive',
                                'graduated': 'Graduated',
                              },
                              (v) => setState(() => _status = v),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () async {
                                DateTime initial = DateTime(2005);
                                if (_dob != null) {
                                  try {
                                    initial = DateTime.parse(_dob!);
                                  } catch (_) {}
                                }
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initial,
                                  firstDate: DateTime(1980),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _dob =
                                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
                                }
                              },
                              child: InputDecorator(
                                decoration: _decoration('Date of Birth'),
                                child: Text(
                                  _dob ?? 'Select date (optional)',
                                  style: TextStyle(
                                      color: _dob != null
                                          ? IceColors.text
                                          : IceColors.muted),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            courses.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (list) => DropdownButtonFormField<int>(
                                value: _courseId,
                                decoration: _decoration('Course'),
                                hint: const Text('Select course'),
                                items: list.map((c) {
                                  final m = c as Map;
                                  return DropdownMenuItem<int>(
                                    value: m['id'] as int,
                                    child: Text(m['name']?.toString() ?? ''),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _courseId = v),
                              ),
                            ),
                            const SizedBox(height: 12),
                            branches.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (list) => DropdownButtonFormField<int>(
                                value: _branchId,
                                decoration: _decoration('Branch'),
                                hint: const Text('Select branch'),
                                items: list.map((b) {
                                  final m = b as Map;
                                  return DropdownMenuItem<int>(
                                    value: m['id'] as int,
                                    child: Text(m['name']?.toString() ?? ''),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _branchId = v),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _saving ? null : _save,
                                style: FilledButton.styleFrom(
                                  backgroundColor: IceColors.navyDeep,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Text('Save Changes',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: _decoration(label),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
      ),
    );
  }

  Widget _dropdownField(String label, String value,
      Map<String, String> options, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _decoration(label),
        items: options.entries
            .map((e) =>
                DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: IceColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: IceColors.border),
        ),
      );
}

class _ErrorBody extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBody({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: IceColors.danger),
            const SizedBox(height: 16),
            Text('Failed to load student',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(error,
                style: const TextStyle(color: IceColors.muted, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: IceColors.navyDeep,
                  foregroundColor: Colors.white),
            ),
          ]),
        ),
      );
}
