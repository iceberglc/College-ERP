import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/ice_tokens.dart';
import '../../../shared/widgets/ice_kit.dart';
import '../../../shared/widgets/ice_shell.dart';

/// Result Files — downloadable result documents with category filter.
class StudentResultFilesScreen extends ConsumerStatefulWidget {
  const StudentResultFilesScreen({super.key});

  @override
  ConsumerState<StudentResultFilesScreen> createState() =>
      _StudentResultFilesScreenState();
}

class _StudentResultFilesScreenState
    extends ConsumerState<StudentResultFilesScreen> {
  int _tab = 0; // All / per-group is dynamic
  final Set<int> _downloading = {};

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(resultFilesProvider);

    return files.when(
      loading: () => const PageSkeleton(),
      error: (e, _) => ErrorState(
        error: e,
        onRetry: () => ref.invalidate(resultFilesProvider),
      ),
      data: (data) => _buildBody(context, data),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> data) {
    final files = ((data['files'] as List?) ?? []).cast<Map<String, dynamic>>();

    // Build group-name filter tabs from the data.
    final groups = <String>{
      for (final f in files)
        if ((f['group_name'] as String?)?.isNotEmpty == true) f['group_name'],
    }.toList();
    final tabs = ['All Files', ...groups];
    final selectedGroup = _tab == 0 ? null : tabs[_tab];

    final visible = selectedGroup == null
        ? files
        : files.where((f) => f['group_name'] == selectedGroup).toList();

    return IcePage(
      title: 'Result Files',
      subtitle: 'Download your result documents',
      backButton: true,
      onRefresh: () async => ref.refresh(resultFilesProvider.future),
      children: [
        if (tabs.length > 1) ...[
          IceChipTabs(
            tabs: tabs,
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 16),
        ],
        if (files.isEmpty)
          const IceCard(
            child: EmptyState(
              icon: Icons.folder_open_rounded,
              title: 'No files yet',
              message:
                  'Result documents shared by your teachers will appear here.',
            ),
          )
        else if (visible.isEmpty)
          const IceCard(
            child: EmptyState(
              icon: Icons.filter_alt_off_rounded,
              title: 'Nothing in this filter',
            ),
          )
        else
          ...visible.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FileCard(
                file: f,
                downloading: _downloading.contains(f['id']),
                onDownload: () => _download(f),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _download(Map<String, dynamic> f) async {
    final id = f['id'] as int;
    setState(() => _downloading.add(id));
    try {
      final dir = await getApplicationDocumentsDirectory();
      final name = (f['filename'] as String?)?.isNotEmpty == true
          ? f['filename']
          : 'result_$id';
      final path = '${dir.path}/$name';
      await ApiClient.instance.dio.download(f['download_url'], path);
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to $path')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download failed. Check your connection.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading.remove(id));
    }
  }
}

class _FileCard extends StatelessWidget {
  final Map<String, dynamic> file;
  final bool downloading;
  final VoidCallback onDownload;

  const _FileCard({
    required this.file,
    required this.downloading,
    required this.onDownload,
  });

  IconData get _icon {
    final name = (file['filename'] as String?)?.toLowerCase() ?? '';
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (name.endsWith('.xlsx') || name.endsWith('.csv')) {
      return Icons.table_chart_rounded;
    }
    if (name.endsWith('.doc') || name.endsWith('.docx')) {
      return Icons.description_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  String _fmtSize(num bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    final uploaded = DateTime.tryParse(file['uploaded_at'] ?? '');
    final size = _fmtSize((file['size'] as num?) ?? 0);

    return IceCard(
      padding: const EdgeInsets.all(14),
      onTap: downloading ? null : onDownload,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: t.coralSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, size: 20, color: t.coral),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file['title'] ?? 'Result file',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: t.textHi,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if ((file['group_name'] as String?)?.isNotEmpty == true)
                      file['group_name'],
                    if (size.isNotEmpty) size,
                    if (uploaded != null)
                      DateFormat('MMM d, yyyy').format(uploaded),
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: t.textMid),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          downloading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: t.accent,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: t.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.download_rounded,
                    size: 18,
                    color: t.accent,
                  ),
                ),
        ],
      ),
    );
  }
}
