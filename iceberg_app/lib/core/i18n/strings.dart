/// Lightweight chrome localisation (EN / UZ / JA).
///
/// Covers navigation, common actions and screen titles. Deep content strings
/// remain English for now — extend the maps as translations are produced.
class S {
  final String langCode;
  const S(this.langCode);

  static const _uz = <String, String>{
    'Dashboard': 'Asosiy',
    'Progress': 'Natijalar',
    'Vocabulary': 'Lugʻat',
    'Leaderboard': 'Reyting',
    'Profile': 'Profil',
    'Attendance': 'Davomat',
    'Assignments': 'Vazifalar',
    'Results': 'Baholar',
    'Result Files': 'Natija fayllari',
    'Library': 'Kutubxona',
    'Payments': 'Toʻlovlar',
    'Leave Requests': 'Javob soʻrash',
    'Feedback': 'Fikr-mulohaza',
    'Notifications': 'Bildirishnomalar',
    'Messages': 'Xabarlar',
    'Settings': 'Sozlamalar',
    'Save': 'Saqlash',
    'Submit': 'Yuborish',
    'Cancel': 'Bekor qilish',
    'Retry': 'Qayta urinish',
    'Download': 'Yuklab olish',
    'Log out': 'Chiqish',
    'Edit Profile': 'Profilni tahrirlash',
    'Change Password': 'Parolni oʻzgartirish',
    'Flashcards': 'Kartochkalar',
    'Learn': 'Oʻrganish',
    'Test': 'Test',
    'Completed': 'Bajarilgan',
    'Pending': 'Kutilmoqda',
    'All': 'Hammasi',
    'Present': 'Keldi',
    'Late': 'Kechikdi',
    'Absent': 'Kelmadi',
    'Pay Now': 'Toʻlash',
    'View All': 'Hammasini koʻrish',
    'Mark all as read': 'Hammasini oʻqilgan deb belgilash',
    'Search': 'Qidirish',
    'No internet connection': 'Internet aloqasi yoʻq',
    'Something went wrong': 'Xatolik yuz berdi',
  };

  static const _ja = <String, String>{
    'Dashboard': 'ホーム',
    'Progress': '進捗',
    'Vocabulary': '単語',
    'Leaderboard': 'ランキング',
    'Profile': 'プロフィール',
    'Attendance': '出席',
    'Assignments': '課題',
    'Results': '成績',
    'Result Files': '成績ファイル',
    'Library': '図書館',
    'Payments': '支払い',
    'Leave Requests': '休暇申請',
    'Feedback': 'フィードバック',
    'Notifications': '通知',
    'Messages': 'メッセージ',
    'Settings': '設定',
    'Save': '保存',
    'Submit': '提出',
    'Cancel': 'キャンセル',
    'Retry': '再試行',
    'Download': 'ダウンロード',
    'Log out': 'ログアウト',
    'Edit Profile': 'プロフィール編集',
    'Change Password': 'パスワード変更',
    'Flashcards': 'フラッシュカード',
    'Learn': '学習',
    'Test': 'テスト',
    'Completed': '完了',
    'Pending': '未完了',
    'All': 'すべて',
    'Present': '出席',
    'Late': '遅刻',
    'Absent': '欠席',
    'Pay Now': '支払う',
    'View All': 'すべて見る',
    'Mark all as read': 'すべて既読にする',
    'Search': '検索',
    'No internet connection': 'インターネット接続がありません',
    'Something went wrong': 'エラーが発生しました',
  };

  /// Translate [key] (the English string doubles as the key).
  String call(String key) {
    switch (langCode) {
      case 'uz':
        return _uz[key] ?? key;
      case 'ja':
        return _ja[key] ?? key;
      default:
        return key;
    }
  }
}
