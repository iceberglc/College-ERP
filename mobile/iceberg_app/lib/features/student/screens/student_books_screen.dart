import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/ice_tokens.dart';
import '../../../shared/widgets/ice_kit.dart';
import '../../../shared/widgets/ice_shell.dart';

/// Library — searchable, category-filtered book catalogue with availability.
class StudentBooksScreen extends ConsumerStatefulWidget {
  const StudentBooksScreen({super.key});

  @override
  ConsumerState<StudentBooksScreen> createState() => _StudentBooksScreenState();
}

class _StudentBooksScreenState extends ConsumerState<StudentBooksScreen> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksProvider);

    return books.when(
      loading: () => const PageSkeleton(),
      error: (e, _) =>
          ErrorState(error: e, onRetry: () => ref.invalidate(booksProvider)),
      data: (data) => _buildBody(context, data),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> data) {
    final t = context.ice;
    final s = ref.watch(stringsProvider);
    final all = ((data['books'] as List?) ?? []).cast<Map<String, dynamic>>();

    final categories = <String>{
      for (final b in all)
        if ((b['category'] as String?)?.isNotEmpty == true) b['category'],
    }.toList()..sort();

    final visible = all.where((b) {
      final matchesCat = _category == null || b['category'] == _category;
      final matchesQuery =
          _query.isEmpty ||
          (b['title'] ?? '').toString().toLowerCase().contains(_query) ||
          (b['author'] ?? '').toString().toLowerCase().contains(_query);
      return matchesCat && matchesQuery;
    }).toList();

    return IcePage(
      title: s('Library'),
      subtitle: 'Explore books and resources',
      backButton: true,
      onRefresh: () async => ref.refresh(booksProvider.future),
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          style: TextStyle(color: t.textHi, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Search books, author or subject…',
            prefixIcon: Icon(Icons.search_rounded, color: t.textMid, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        if (categories.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                ...categories.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _CategoryChip(
                      label: c,
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (all.isEmpty)
          const IceCard(
            child: EmptyState(
              icon: Icons.local_library_outlined,
              title: 'Library is empty',
              message: 'No books in the catalogue yet.',
            ),
          )
        else if (visible.isEmpty)
          const IceCard(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matches',
              message: 'Try a different search or category.',
            ),
          )
        else
          ...visible.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BookCard(book: b),
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? t.accent : t.inset,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? t.onAccent : t.textMid,
          ),
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    final available = book['is_available'] == true;

    return IceCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _showDetail(context),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 60,
            decoration: BoxDecoration(
              gradient: t.heroGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: t.textHi,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book['author'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: t.textMid),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if ((book['category'] as String?)?.isNotEmpty == true)
                      StatusBadge(book['category'], tone: BadgeTone.neutral),
                    const SizedBox(width: 8),
                    StatusBadge(
                      available ? 'Available' : 'On loan',
                      tone: available ? BadgeTone.accent : BadgeTone.amber,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final t = context.ice;
    final available = book['is_available'] == true;
    showModalBottomSheet(
      context: context,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 74,
                  decoration: BoxDecoration(
                    gradient: t.heroGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'] ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: t.textHi,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book['author'] ?? '',
                        style: TextStyle(fontSize: 13.5, color: t.textMid),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if ((book['category'] as String?)?.isNotEmpty == true)
                  StatusBadge(book['category'], tone: BadgeTone.sky),
                const SizedBox(width: 8),
                StatusBadge(
                  available ? 'Available' : 'On loan',
                  tone: available ? BadgeTone.accent : BadgeTone.amber,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              available
                  ? 'Visit the library desk with your student ID to borrow this book.'
                  : 'This book is currently on loan. Ask the library desk about a reservation.',
              style: TextStyle(fontSize: 13.5, color: t.textMid, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
