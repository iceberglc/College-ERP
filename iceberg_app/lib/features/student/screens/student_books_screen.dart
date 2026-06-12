import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class StudentBooksScreen extends StatefulWidget {
  const StudentBooksScreen({super.key});

  @override
  State<StudentBooksScreen> createState() => _State();
}

class _State extends State<StudentBooksScreen> {
  bool _loading = true;
  List<dynamic> _books = [];
  bool _notAvailable = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _notAvailable = false; });
    try {
      final res = await ApiClient.instance.dio.get('/books/');
      final data = res.data;
      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = (data['results'] as List?) ?? (data['books'] as List?) ?? [];
      }
      setState(() { _books = list; _loading = false; });
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('404') || msg.contains('not found')) {
        setState(() { _notAvailable = true; _loading = false; });
      } else {
        setState(() { _notAvailable = false; _loading = false; });
      }
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
                title: 'Library',
                subtitle: 'Browse available books',
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
            else if (_notAvailable)
              const SliverToBoxAdapter(child: _ComingSoonState())
            else if (_books.isEmpty)
              const SliverToBoxAdapter(child: _EmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _BookCard(book: _books[i] as Map, index: i),
                  childCount: _books.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ─── Book Card ────────────────────────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  final Map book;
  final int index;
  const _BookCard({required this.book, required this.index});

  @override
  Widget build(BuildContext context) {
    final title = book['title']?.toString() ?? 'Untitled';
    final author = book['author']?.toString() ?? '';
    final isAvailable = book['is_available'] == true ||
        book['status']?.toString().toLowerCase() == 'available';
    final coverUrl = book['cover_url']?.toString() ?? '';

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
          // Cover
          Container(
            width: 56,
            height: 72,
            decoration: BoxDecoration(
              color: IceColors.navyDeep.withAlpha(12),
              borderRadius: BorderRadius.circular(8),
              image: coverUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(coverUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: coverUrl.isEmpty
                ? const Icon(Icons.menu_book_rounded,
                    size: 28, color: IceColors.navyDeep)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: IceColors.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (author.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(author,
                      style: const TextStyle(
                        fontSize: 12,
                        color: IceColors.muted,
                      )),
                ],
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? IceColors.success.withAlpha(15)
                        : IceColors.warning.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Issued',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color:
                          isAvailable ? IceColors.success : IceColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 250.ms)
        .slideX(begin: 0.05, duration: 250.ms);
  }
}

// ─── States ───────────────────────────────────────────────────────────────────

class _ComingSoonState extends StatelessWidget {
  const _ComingSoonState();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_library_outlined, size: 56, color: IceColors.muted),
            SizedBox(height: 16),
            Text(
              'Library coming soon',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: IceColors.text),
            ),
            SizedBox(height: 8),
            Text(
              'The library feature is being set up.\nCheck back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: IceColors.muted),
            ),
          ],
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
            Icon(Icons.menu_book_outlined, size: 48, color: IceColors.muted),
            SizedBox(height: 16),
            Text(
              'No books available',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: IceColors.muted),
            ),
            SizedBox(height: 8),
            Text(
              'No books have been added to the library yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: IceColors.muted),
            ),
          ],
        ),
      );
}
