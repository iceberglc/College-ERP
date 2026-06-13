/// Chrome + content localisation (EN / UZ / JA).
///
/// The English string doubles as the lookup key, so any screen can call
/// `s('Save')` and fall back to English when a translation is missing. Keep the
/// three maps in sync when adding new keys.
class S {
  final String langCode;
  const S(this.langCode);

  static const _uz = <String, String>{
    // ── Navigation & chrome ──────────────────────────────────────────────
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

    // ── Common actions ───────────────────────────────────────────────────
    'Save': 'Saqlash',
    'Submit': 'Yuborish',
    'Cancel': 'Bekor qilish',
    'Retry': 'Qayta urinish',
    'Try Again': 'Qayta urinish',
    'Download': 'Yuklab olish',
    'Log out': 'Chiqish',
    'Edit Profile': 'Profilni tahrirlash',
    'Change Password': 'Parolni oʻzgartirish',
    'View All': 'Hammasini koʻrish',
    'Mark all as read': 'Hammasini oʻqilgan deb belgilash',
    'Search': 'Qidirish',
    'Close': 'Yopish',
    'Done': 'Tayyor',
    'Apply': 'Qoʻllash',
    'Open': 'Ochish',
    'Read More': 'Batafsil',
    'Back to login': 'Kirishga qaytish',
    'Coming Soon': 'Tez kunda',
    'Loading…': 'Yuklanmoqda…',

    // ── Statuses / filters ───────────────────────────────────────────────
    'Flashcards': 'Kartochkalar',
    'Learn': 'Oʻrganish',
    'Test': 'Test',
    'Quiz': 'Test',
    'Completed': 'Bajarilgan',
    'Pending': 'Kutilmoqda',
    'All': 'Hammasi',
    'Present': 'Keldi',
    'Late': 'Kechikdi',
    'Absent': 'Kelmadi',
    'Overdue': 'Muddati oʻtgan',
    'Pay Now': 'Toʻlash',
    'No internet connection': 'Internet aloqasi yoʻq',
    'Something went wrong': 'Xatolik yuz berdi',

    // ── Dashboard ────────────────────────────────────────────────────────
    'My standing': 'Mening oʻrnim',
    'Performance Trend': 'Koʻrsatkichlar tendensiyasi',
    '8-Week History': '8 haftalik tarix',
    'Campus Pulse': 'Markaz yangiliklari',
    'Pending Tasks': 'Bajarilmagan vazifalar',
    'Unread Notifs': 'Oʻqilmagan xabarlar',
    'Vocab Words Ready': 'Yangi soʻzlar tayyor',
    'New': 'Yangi',
    'All caught up!': 'Hammasi bajarilgan!',
    'No pending assignments right now.': 'Hozircha bajarilmagan vazifalar yoʻq.',
    'Not ranked yet': 'Hali reytingda yoʻq',
    'Current Momentum': 'Joriy surʼat',
    'Day Streak': 'kunlik seriya',
    'Start your streak today': 'Bugun seriyani boshlang',
    'Target: 90%': 'Maqsad: 90%',

    // ── Payments ─────────────────────────────────────────────────────────
    'Outstanding Balance': 'Qoldiq toʻlov',
    'All paid 🎉': 'Hammasi toʻlangan 🎉',
    'Total Paid (soʻm)': 'Jami toʻlangan (soʻm)',
    'Total Invoices': 'Jami hisob-fakturalar',
    'Invoices': 'Hisob-fakturalar',
    'History': 'Tarix',
    'No invoices yet': 'Hozircha hisob-fakturalar yoʻq',
    'Your tuition invoices will appear here.':
        'Oʻquv toʻlovi hisob-fakturalaringiz shu yerda koʻrinadi.',
    'No payments recorded': 'Toʻlovlar qayd etilmagan',
    'Recorded payments will show up here.':
        'Qayd etilgan toʻlovlar shu yerda koʻrinadi.',
    'Paid': 'Toʻlangan',
    'Partial': 'Qisman',
    'Due': 'Muddati',
    'Cancelled': 'Bekor qilingan',
    'Amount': 'Summa',
    'Discount': 'Chegirma',
    'Outstanding': 'Qoldiq',

    // ── Attendance ───────────────────────────────────────────────────────
    'Overall Rate': 'Umumiy koʻrsatkich',
    'Streak': 'Seriya',
    'This Month': 'Bu oy',
    '12-Week Trend': '12 haftalik tendensiya',
    'Email Teacher': 'Oʻqituvchiga yozish',

    // ── Results ──────────────────────────────────────────────────────────
    'Exam': 'Imtihon',
    'Average': 'Oʻrtacha',
    'No results yet.': 'Hozircha natijalar yoʻq.',

    // ── Vocabulary ───────────────────────────────────────────────────────
    'Days': 'Kunlar',
    'Words': 'Soʻzlar',
    'Mastered': 'Oʻzlashtirilgan',
    'Start': 'Boshlash',
    'Review': 'Takrorlash',

    // ── Leaderboard ──────────────────────────────────────────────────────
    'Overall': 'Umumiy',
    'My Group': 'Mening guruhim',
    'Branch': 'Filial',
    'You': 'Siz',
    'Rank': 'Oʻrin',
    'Points': 'Ball',
    'No ranking data yet.': 'Hozircha reyting maʼlumotlari yoʻq.',

    // ── Profile ──────────────────────────────────────────────────────────
    'Account': 'Hisob',
    'Help': 'Yordam',
    'About': 'Ilova haqida',
    'Student ID': 'Talaba ID',
    'Email': 'Email',
    'Phone': 'Telefon',
    'Group': 'Guruh',

    // ── Settings ─────────────────────────────────────────────────────────
    'Appearance': 'Koʻrinish',
    'Theme': 'Mavzu',
    'Light': 'Yorugʻ',
    'Dark': 'Tungi',
    'System': 'Tizim',
    'Accent Color': 'Asosiy rang',
    'Font Size': 'Shrift oʻlchami',
    'Small': 'Kichik',
    'Medium': 'Oʻrta',
    'Large': 'Katta',
    'Language': 'Til',
    'Announcements': 'Eʼlonlar',

    // ── Empty states ─────────────────────────────────────────────────────
    'No notifications': 'Bildirishnomalar yoʻq',
    'No assignments': 'Vazifalar yoʻq',
    'Due Today': 'Bugun muddati',
    'Due Tomorrow': 'Ertaga muddati',
  };

  static const _ja = <String, String>{
    // ── Navigation & chrome ──────────────────────────────────────────────
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

    // ── Common actions ───────────────────────────────────────────────────
    'Save': '保存',
    'Submit': '提出',
    'Cancel': 'キャンセル',
    'Retry': '再試行',
    'Try Again': '再試行',
    'Download': 'ダウンロード',
    'Log out': 'ログアウト',
    'Edit Profile': 'プロフィール編集',
    'Change Password': 'パスワード変更',
    'View All': 'すべて見る',
    'Mark all as read': 'すべて既読にする',
    'Search': '検索',
    'Close': '閉じる',
    'Done': '完了',
    'Apply': '適用',
    'Open': '開く',
    'Read More': '続きを読む',
    'Back to login': 'ログインに戻る',
    'Coming Soon': '近日公開',
    'Loading…': '読み込み中…',

    // ── Statuses / filters ───────────────────────────────────────────────
    'Flashcards': 'フラッシュカード',
    'Learn': '学習',
    'Test': 'テスト',
    'Quiz': 'クイズ',
    'Completed': '完了',
    'Pending': '未完了',
    'All': 'すべて',
    'Present': '出席',
    'Late': '遅刻',
    'Absent': '欠席',
    'Overdue': '期限切れ',
    'Pay Now': '支払う',
    'No internet connection': 'インターネット接続がありません',
    'Something went wrong': 'エラーが発生しました',

    // ── Dashboard ────────────────────────────────────────────────────────
    'My standing': '自分の順位',
    'Performance Trend': '成績の推移',
    '8-Week History': '8週間の履歴',
    'Campus Pulse': 'キャンパス情報',
    'Pending Tasks': '未提出の課題',
    'Unread Notifs': '未読通知',
    'Vocab Words Ready': '新しい単語',
    'New': '新着',
    'All caught up!': 'すべて完了！',
    'No pending assignments right now.': '未提出の課題はありません。',
    'Not ranked yet': 'まだランク外',
    'Current Momentum': '現在の勢い',
    'Day Streak': '日連続',
    'Start your streak today': '今日から連続記録を始めましょう',
    'Target: 90%': '目標: 90%',

    // ── Payments ─────────────────────────────────────────────────────────
    'Outstanding Balance': '未払い残高',
    'All paid 🎉': 'すべて支払済 🎉',
    'Total Paid (soʻm)': '支払い済み合計 (soʻm)',
    'Total Invoices': '請求書合計',
    'Invoices': '請求書',
    'History': '履歴',
    'No invoices yet': '請求書はまだありません',
    'Your tuition invoices will appear here.': '授業料の請求書がここに表示されます。',
    'No payments recorded': '支払い記録はありません',
    'Recorded payments will show up here.': '記録された支払いがここに表示されます。',
    'Paid': '支払済',
    'Partial': '一部支払',
    'Due': '未払い',
    'Cancelled': 'キャンセル',
    'Amount': '金額',
    'Discount': '割引',
    'Outstanding': '残高',

    // ── Attendance ───────────────────────────────────────────────────────
    'Overall Rate': '総合出席率',
    'Streak': '連続記録',
    'This Month': '今月',
    '12-Week Trend': '12週間の推移',
    'Email Teacher': '先生にメール',

    // ── Results ──────────────────────────────────────────────────────────
    'Exam': '試験',
    'Average': '平均',
    'No results yet.': 'まだ成績がありません。',

    // ── Vocabulary ───────────────────────────────────────────────────────
    'Days': 'デイ',
    'Words': '単語',
    'Mastered': '習得済み',
    'Start': '開始',
    'Review': '復習',

    // ── Leaderboard ──────────────────────────────────────────────────────
    'Overall': '総合',
    'My Group': '自分のグループ',
    'Branch': '校舎',
    'You': 'あなた',
    'Rank': '順位',
    'Points': 'ポイント',
    'No ranking data yet.': 'ランキングデータはまだありません。',

    // ── Profile ──────────────────────────────────────────────────────────
    'Account': 'アカウント',
    'Help': 'ヘルプ',
    'About': 'アプリについて',
    'Student ID': '学生ID',
    'Email': 'メール',
    'Phone': '電話',
    'Group': 'グループ',

    // ── Settings ─────────────────────────────────────────────────────────
    'Appearance': '外観',
    'Theme': 'テーマ',
    'Light': 'ライト',
    'Dark': 'ダーク',
    'System': 'システム',
    'Accent Color': 'アクセントカラー',
    'Font Size': '文字サイズ',
    'Small': '小',
    'Medium': '中',
    'Large': '大',
    'Language': '言語',
    'Announcements': 'お知らせ',

    // ── Empty states ─────────────────────────────────────────────────────
    'No notifications': '通知はありません',
    'No assignments': '課題はありません',
    'Due Today': '今日締切',
    'Due Tomorrow': '明日締切',
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
