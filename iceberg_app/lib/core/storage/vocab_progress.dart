import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local per-word learning progress for a vocabulary day, split by direction
/// (word→translation and translation→word). The backend tracks day-level
/// completion and quiz scores; the per-card "known" sets live on-device.
class VocabProgress {
  static String _key(int dayId, String direction) =>
      'vocab_known_${dayId}_$direction';

  static Future<Set<int>> known(int dayId, String direction) async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_key(dayId, direction)) ?? [])
        .map(int.parse)
        .toSet();
  }

  static Future<void> setKnown(
    int dayId,
    String direction,
    Set<int> wordIds,
  ) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _key(dayId, direction),
      wordIds.map((e) => e.toString()).toList(),
    );
  }

  static Future<void> mark(
    int dayId,
    String direction,
    int wordId, {
    required bool isKnown,
  }) async {
    final ids = await known(dayId, direction);
    if (isKnown) {
      ids.add(wordId);
    } else {
      ids.remove(wordId);
    }
    await setKnown(dayId, direction, ids);
  }
}

/// `(dayId, direction)` → known word-id set. Invalidate after writes.
final vocabKnownProvider = FutureProvider.family<Set<int>, (int, String)>(
  (_, key) => VocabProgress.known(key.$1, key.$2),
);
