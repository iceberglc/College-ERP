import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class StudentResultFilesScreen extends StatefulWidget {
  const StudentResultFilesScreen({super.key});

  @override
  State<StudentResultFilesScreen> createState() => _State();
}

class _State extends State<StudentResultFilesScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _files = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.instance.dio.get('/results/');
      final data = res.data;
      List<dynamic> all = [];
      if (data is List) {
        all = data;
      } else if (data is Map) {
        all = (data['results'] as List?) ?? [];
      }
      // Filter to file-type results (has file_url or type == 'file')
      final files = all.where((item) {
        final m = item as Map;
        return m['file_url'] != null ||
            m['file'] != null ||
            m['result_type']?.toString().toLowerCase() == 'file' ||
            m['type']?.toString().toLowerCase() == 'file';
      }).toList();
      setState(() { _files = files; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Result Files',
                subtitle: 'Your downloadable results',
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
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: IceColors.muted),
                      const SizedBox(height: 16),
                      Text('Error: $_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: IceColors.danger)),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _fetch,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: IceColors.navyDeep,
                            side: const BorderSide(
                                color: IceColors.navyDeep)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_files.isEmpty)
              const SliverToBoxAdapter(child: _EmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) =>
                      _ResultFileCard(file: _files[i] as Map, index: i),
                  childCount: _files.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ─── Result File Card ─────────────────────────────────────────────────────────

class _ResultFileCard extends StatelessWidget {
  final Map file;
  final int index;
  const _ResultFileCard({required this.file, required this.index});

  String get _title =>
      file['title']?.toString() ??
      file['name']?.toString() ??
      'Result File';

  String get _date {
    final raw = file['date']?.toString() ??
        file['created_at']?.toString() ??
        file['uploaded_at']?.toString() ??
        '';
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.substring(0, raw.length > 10 ? 10 : raw.length);
    }
  }

  String get _url =>
      file['file_url']?.toString() ?? file['file']?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IceColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: IceColors.navyDeep.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.insert_drive_file_rounded,
                size: 24, color: IceColors.navyDeep),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: IceColors.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (_date.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(_date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: IceColors.muted,
                      )),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _DownloadButton(url: _url),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 250.ms)
        .slideX(begin: 0.05, duration: 250.ms);
  }
}

class _DownloadButton extends StatelessWidget {
  final String url;
  const _DownloadButton({required this.url});

  Future<void> _open(BuildContext context) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No download link available.')),
      );
      return;
    }
    // Copy URL to clipboard as fallback (url_launcher may not be available)
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Link copied to clipboard'),
          backgroundColor: IceColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: url.isEmpty ? null : () => _open(context),
        icon: const Icon(Icons.download_rounded, size: 16),
        label: const Text('Download'),
        style: FilledButton.styleFrom(
          backgroundColor: IceColors.navyDeep,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 48, color: IceColors.muted),
            SizedBox(height: 16),
            Text(
              'No result files',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: IceColors.muted),
            ),
            SizedBox(height: 8),
            Text(
              'Your downloadable results will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: IceColors.muted),
            ),
          ],
        ),
      );
}
