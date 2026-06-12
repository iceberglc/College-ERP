import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/theme/app_theme.dart';

class StudentLeaderboardScreen extends ConsumerStatefulWidget {
  const StudentLeaderboardScreen({super.key});

  @override
  ConsumerState<StudentLeaderboardScreen> createState() =>
      _StudentLeaderboardScreenState();
}

class _StudentLeaderboardScreenState
    extends ConsumerState<StudentLeaderboardScreen> {
  int _scopeIndex = 0; // 0=Filialim, 1=Guruhim, 2=Hammasi
  int _timeIndex  = 0; // 0=Kunlik, 1=7 kun, 2=30 kun, 3=Barchasi

  static const _scopeLabels = ['Filialim', 'Guruhim', 'Hammasi'];
  static const _timeLabels  = ['Kunlik', '7 kun', '30 kun', 'Barchasi'];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(leaderboardProvider);
    final me    = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(leaderboardProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Dark teal gradient header ─────────────────────────────────
            SliverToBoxAdapter(
              child: async.when(
                loading: () => _buildHeader(context, 'Mavsim', [], me),
                error: (_, __) => _buildHeader(context, 'Mavsim', [], me),
                data: (season) {
                  final entries = (season['entries'] as List?) ?? [];
                  final name    = season['name']?.toString() ?? 'Mavsim';
                  return _buildHeader(context, name, entries, me);
                },
              ),
            ),

            // ── Filter pills ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    _PillToggle(
                      labels: _scopeLabels,
                      selected: _scopeIndex,
                      onChanged: (i) => setState(() => _scopeIndex = i),
                    ),
                    const SizedBox(height: 10),
                    _PillToggle(
                      labels: _timeLabels,
                      selected: _timeIndex,
                      onChanged: (i) => setState(() => _timeIndex = i),
                      small: true,
                    ),
                  ],
                ),
              ),
            ),

            // ── Ranked list ───────────────────────────────────────────────
            async.when(
              loading: () =>
                  const SliverToBoxAdapter(child: _Skeleton()),
              error: (e, _) {
                final msg = e.toString();
                if (msg.contains('404') || msg.contains('No active')) {
                  return const SliverToBoxAdapter(child: _Empty());
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Xatolik: $e',
                        style: const TextStyle(color: IceColors.danger)),
                  ),
                );
              },
              data: (season) {
                final entries = (season['entries'] as List?) ?? [];
                if (entries.isEmpty) {
                  return const SliverToBoxAdapter(child: _Empty());
                }
                return SliverList(
                  delegate: SliverChildListDelegate([
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Reyting jadvali',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: IceColors.muted,
                        ),
                      ),
                    ),
                    ...entries.asMap().entries.map((e) {
                      final entry = e.value as Map;
                      final myName =
                          '${me?.firstName ?? ''} ${me?.lastName ?? ''}'
                              .trim();
                      final isMe =
                          entry['student_name'] == myName;
                      return _RankRow(
                          entry: entry, index: e.key, isMe: isMe);
                    }),
                    const SizedBox(height: 100),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String seasonName,
    List entries,
    IceUser? me,
  ) {
    final top     = MediaQuery.paddingOf(context).top;
    final top3    = entries.take(3).toList();
    final hasTop3 = top3.length >= 3;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [IceColors.navy, IceColors.navyDeep],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(20, top + 20, 20, 32),
      child: Column(
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reyting',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: IceColors.lime,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  seasonName,
                  style: const TextStyle(
                    color: IceColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          // Podium
          if (hasTop3) ...[
            const SizedBox(height: 28),
            _Podium(entries: top3),
          ],
        ],
      ),
    );
  }
}

// ── Pill toggle ────────────────────────────────────────────────────────────────
class _PillToggle extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool small;

  const _PillToggle({
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: labels.asMap().entries.map((e) {
          final active = e.key == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                    vertical: small ? 8 : 10),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: active
                      ? [
                          const BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: small ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: active ? IceColors.navy : IceColors.muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Podium ─────────────────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List entries;
  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Order: 2nd left, 1st center (elevated), 3rd right
    final order = entries.length >= 3
        ? [entries[1], entries[0], entries[2]]
        : entries;
    final ranks        = [2, 1, 3];
    final borderColors = [
      Colors.grey[400]!,   // silver
      const Color(0xFFFFD700), // gold
      const Color(0xFFCD7F32), // bronze
    ];
    final sizes    = [52.0, 64.0, 52.0];
    final offsets  = [8.0, 0.0, 8.0];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(order.length, (i) {
        final entry = order[i] as Map;
        final name  = entry['student_name']?.toString() ?? '';
        final score = (entry['score'] as num?)?.toStringAsFixed(1) ?? '0';
        final inits = _initials(name);

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: offsets[i]),
                child: Column(
                  children: [
                    Container(
                      width: sizes[i],
                      height: sizes[i],
                      decoration: BoxDecoration(
                        color: IceColors.lime,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: borderColors[i], width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        inits,
                        style: TextStyle(
                          color: IceColors.navy,
                          fontSize: sizes[i] * 0.28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name.split(' ').first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$score%',
                      style: TextStyle(
                        color: borderColors[i],
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${ranks[i]}',
                      style: TextStyle(
                        color: borderColors[i],
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    )
        .animate()
        .slideY(begin: 0.15, duration: 500.ms, curve: Curves.easeOut)
        .fadeIn(duration: 400.ms);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    final f = parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    final l = parts.length > 1 && parts[1].isNotEmpty
        ? parts[1][0].toUpperCase()
        : '';
    return '$f$l'.isNotEmpty ? '$f$l' : '?';
  }
}

// ── Rank row ───────────────────────────────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final Map entry;
  final int index;
  final bool isMe;
  const _RankRow(
      {required this.entry, required this.index, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final rank  = entry['rank'] ?? (index + 1);
    final name  = entry['student_name']?.toString() ?? '';
    final score = (entry['score'] as num?)?.toStringAsFixed(1) ?? '0';
    final inits = _initials(name);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? IceColors.lime.withAlpha(60)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? IceColors.lime
              : const Color(0xFFEEEEEE),
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        SizedBox(
          width: 32,
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: rank <= 3
                  ? IceColors.warning
                  : IceColors.muted,
            ),
          ),
        ),
        // Lime avatar
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: IceColors.lime,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            inits,
            style: const TextStyle(
              color: IceColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isMe ? IceColors.navy : IceColors.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isMe) ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: IceColors.navy,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'Siz',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          '$score%',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: IceColors.navy,
          ),
        ),
      ]),
    )
        .animate(delay: Duration(milliseconds: 30 * index))
        .fadeIn(duration: 250.ms)
        .slideX(begin: 0.05, duration: 260.ms);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    final f = parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    final l = parts.length > 1 && parts[1].isNotEmpty
        ? parts[1][0].toUpperCase()
        : '';
    return '$f$l'.isNotEmpty ? '$f$l' : '?';
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────────
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            for (int i = 0; i < 7; i++) ...[
              Container(
                height: 56,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
              ),
              const SizedBox(height: 8),
            ],
          ]),
        ),
      );
}

// ── Empty ──────────────────────────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Column(children: [
          Icon(Icons.emoji_events_outlined,
              size: 56, color: IceColors.muted),
          SizedBox(height: 16),
          Text('Hozircha reyting yo\'q',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: IceColors.muted)),
          SizedBox(height: 8),
          Text(
            'Faol mavsum boshlanganda reyting ko\'rinadi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: IceColors.muted),
          ),
        ]),
      );
}
