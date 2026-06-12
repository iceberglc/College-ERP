import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminAddStaffScreen extends ConsumerStatefulWidget {
  const AdminAddStaffScreen({super.key});

  @override
  ConsumerState<AdminAddStaffScreen> createState() =>
      _AdminAddStaffScreenState();
}

class _AdminAddStaffScreenState extends ConsumerState<AdminAddStaffScreen> {
  final _form = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _specialization = TextEditingController();
  String _gender = 'M';
  String? _dob;
  int? _courseId;
  int? _branchId;
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _password.dispose();
    _phone.dispose();
    _specialization.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      final res = await ApiClient.instance.dio.post('/admin/staff/', data: {
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'password': _password.text,
        'phone': _phone.text.trim(),
        'specialization': _specialization.text.trim(),
        'gender': _gender,
        if (_dob != null) 'date_of_birth': _dob,
        if (_courseId != null) 'course': _courseId,
        if (_branchId != null) 'branch': _branchId,
      });
      final loginId = (res.data as Map)['login_id'] ?? '';
      ref.invalidate(adminStaffProvider);
      setState(() {
        _success = 'Staff created! Login ID: $loginId';
        _loading = false;
      });
      _form.currentState!.reset();
      _firstName.clear(); _lastName.clear();
      _password.clear(); _phone.clear(); _specialization.clear();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider);
    final branches = ref.watch(adminBranchesProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: IcePageHeader(
              title: 'Add Staff',
              subtitle: 'Create a new teacher account',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Form(
                key: _form,
                child: Column(children: [
                  if (_success != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: IceColors.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: IceColors.success.withAlpha(60)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            color: IceColors.success, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_success!,
                              style: const TextStyle(
                                  color: IceColors.success,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: IceColors.danger.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: IceColors.danger.withAlpha(60)),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(color: IceColors.danger)),
                    ),
                  _field(_firstName, 'First Name', required: true),
                  _field(_lastName, 'Last Name'),
                  _field(_password, 'Password', required: true, obscure: true),
                  _field(_phone, 'Phone'),
                  _field(_specialization, 'Specialization'),
                  _dropdownField('Gender', _gender, {'M': 'Male', 'F': 'Female'},
                      (v) => setState(() => _gender = v!)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(1990),
                        firstDate: DateTime(1960),
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
                            color: _dob != null ? IceColors.text : IceColors.muted),
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
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: IceColors.navyDeep,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Create Staff',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
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
    bool obscure = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        maxLines: maxLines,
        decoration: _decoration(label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
      ),
    );
  }

  Widget _dropdownField(String label, String value, Map<String, String> options,
      void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _decoration(label),
        items: options.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
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
