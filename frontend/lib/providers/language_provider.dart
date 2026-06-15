import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageState {
  final String locale; // 'en' or 'ms'
  LanguageState({this.locale = 'en'});
}

class LanguageNotifier extends StateNotifier<LanguageState> {
  LanguageNotifier() : super(LanguageState()) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = LanguageState(locale: prefs.getString('lang') ?? 'en');
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    final newLang = state.locale == 'en' ? 'ms' : 'en';
    await prefs.setString('lang', newLang);
    state = LanguageState(locale: newLang);
  }

  Future<void> setLang(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
    state = LanguageState(locale: lang);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>((ref) => LanguageNotifier());

// ─── i18n dictionary ───
const Map<String, Map<String, String>> translations = {
  'en': {
    // Common
    'welcome': 'Welcome',
    'cancel': 'Cancel',
    'save': 'Save',
    'done': 'Done',
    'close': 'Close',
    'back': 'Back',
    'next': 'Next',
    'continue': 'Continue',
    'confirm': 'Confirm',
    'delete': 'Delete',
    'edit': 'Edit',
    'search': 'Search',
    'loading': 'Loading...',
    'retry': 'Retry',
    'ok': 'OK',
    'yes': 'Yes',
    'no': 'No',
    'all': 'All',
    'today': 'Today',
    'yesterday': 'Yesterday',
    'earlier': 'Earlier',
    'view_all': 'View all',
    'see_more': 'See more',
    'see_less': 'See less',
    'coming_soon': 'Coming soon',

    // Dashboard / Home
    'modules': 'Modules',
    'quick_links': 'Quick Links',
    'featured': 'Featured',
    'facilities': 'Facilities',
    'announcements': 'Announcements',
    'registration': 'Registration',
    'attendance': 'Attendance',
    'activities': 'Activities',
    'tuition_fees': 'Tuition Fees',

    // Nav / Section
    'home': 'Home',
    'payment': 'Payment',
    'history': 'History',
    'alerts': 'Alerts',
    'dashboard': 'Dashboard',
    'students': 'Students',
    'profile': 'Profile',

    // Profile screen
    'student': 'Student',
    'admin': 'Admin',
    'treasury': 'Treasury',
    'personal': 'PERSONAL',
    'preferences': 'PREFERENCES',
    'account': 'ACCOUNT',
    'support': 'SUPPORT',
    'about': 'ABOUT',
    'student_id': 'Student ID',
    'faculty': 'Faculty',
    'program': 'Program',
    'semester': 'Semester',
    'email': 'Email',
    'phone': 'Phone',
    'not_set': 'Not set',
    'dark_mode': 'Dark mode',
    'light_mode': 'Light mode',
    'language': 'Language',
    'language_label': 'Bahasa Melayu',
    'notifications': 'Notifications',
    'change_password': 'Change password',
    'privacy_data': 'Privacy & data',
    'help_faq': 'Help & FAQ',
    'contact_us': 'Contact us',
    'rate_app': 'Rate app',
    'about_sams': 'About SAMs',
    'version_info': 'Version info',
    'sign_out': 'Sign out',
    'sign_out_confirm': 'Are you sure you want to sign out?',
    'logout': 'Logout',
    'current_password': 'Current password',
    'new_password': 'New password',
    'confirm_password': 'Confirm password',
    'passwords_dont_match': 'Passwords do not match',
    'password_updated': 'Password updated',

    // Notifications sheet
    'payment_reminders': 'Payment reminders',
    'new_fee_added': 'New fee added',
    'receipt_generated': 'Receipt generated',
    'system_announcements': 'System announcements',

    // Fees / Payment
    'total_due': 'Total Due',
    'paid': 'Paid',
    'balance': 'Balance',
    'balance_due': 'Balance Due',
    'days_left': 'Days Left',
    'pay_now': 'Pay Now',
    'fully_paid': 'Fully Paid',
    'all_settled': 'All settled',
    'no_outstanding': 'No outstanding fees right now.',
    'fee_breakdown': 'Fee Breakdown',
    'payment_progress': 'Payment Progress',
    'select_fee': 'Select Fee to Pay',
    'payment_method': 'Payment Method',
    'confirm_payment': 'Confirm Payment',
    'payment_successful': 'Payment Successful!',
    'make_payment': 'Make Payment',
    'unpaid': 'unpaid',
    'select': 'Select',
    'pay': 'Pay',
    'select_bank': 'Select bank',
    'select_bank_desc': 'Choose your FPX bank to continue payment.',
    'review_details': 'Please review the details before continuing.',
    'method': 'Method',
    'bank': 'Bank',
    'due_date': 'Due date',
    'processing_payment': 'Processing payment...',
    'dont_close': 'Please do not close this window.',
    'confirm_pay': 'Confirm & Pay',
    'receipt': 'Receipt',

    // History
    'no_transactions': 'No transactions found.',
    'search_transactions': 'Search transactions...',
    'transaction_detail': 'TRANSACTION DETAIL',
    'total_paid': 'TOTAL PAID',
    'no_alerts_category': 'No alerts in this category',
    'all_caught_up': 'All caught up!',
    'no_unread': 'No unread alerts remaining',
    'mark_all': 'Mark all',

    // Status badges
    'active': 'Active',
    'blocked': 'Blocked',
  },
  'ms': {
    // Common
    'welcome': 'Selamat Datang',
    'cancel': 'Batal',
    'save': 'Simpan',
    'done': 'Selesai',
    'close': 'Tutup',
    'back': 'Kembali',
    'next': 'Seterusnya',
    'continue': 'Teruskan',
    'confirm': 'Sahkan',
    'delete': 'Padam',
    'edit': 'Ubah',
    'search': 'Cari',
    'loading': 'Memuat...',
    'retry': 'Cuba lagi',
    'ok': 'OK',
    'yes': 'Ya',
    'no': 'Tidak',
    'all': 'Semua',
    'today': 'Hari ini',
    'yesterday': 'Semalam',
    'earlier': 'Sebelumnya',
    'view_all': 'Lihat semua',
    'see_more': 'Lihat lagi',
    'see_less': 'Lihat kurang',
    'coming_soon': 'Akan datang',

    // Dashboard / Home
    'modules': 'Modul',
    'quick_links': 'Pautan Pantas',
    'featured': 'Pilihan',
    'facilities': 'Kemudahan',
    'announcements': 'Pengumuman',
    'registration': 'Pendaftaran',
    'attendance': 'Kehadiran',
    'activities': 'Aktiviti',
    'tuition_fees': 'Yuran Pengajian',

    // Nav / Section
    'home': 'Utama',
    'payment': 'Bayaran',
    'history': 'Sejarah',
    'alerts': 'Makluman',
    'dashboard': 'Papan Pemuka',
    'students': 'Pelajar',
    'profile': 'Profil',

    // Profile screen
    'student': 'Pelajar',
    'admin': 'Pentadbir',
    'treasury': 'Bendahari',
    'personal': 'PERIBADI',
    'preferences': 'KEUTAMAAN',
    'account': 'AKAUN',
    'support': 'SOKONGAN',
    'about': 'TENTANG',
    'student_id': 'ID Pelajar',
    'faculty': 'Fakulti',
    'program': 'Program',
    'semester': 'Semester',
    'email': 'E-mel',
    'phone': 'Telefon',
    'not_set': 'Tidak ditetapkan',
    'dark_mode': 'Mod Gelap',
    'light_mode': 'Mod Cerah',
    'language': 'Bahasa',
    'language_label': 'English',
    'notifications': 'Pemberitahuan',
    'change_password': 'Tukar kata laluan',
    'privacy_data': 'Privasi & data',
    'help_faq': 'Bantuan & Soalan Lazim',
    'contact_us': 'Hubungi kami',
    'rate_app': 'Nilai aplikasi',
    'about_sams': 'Tentang SAMs',
    'version_info': 'Maklumat versi',
    'sign_out': 'Log Keluar',
    'sign_out_confirm': 'Anda pasti mahu log keluar?',
    'logout': 'Log Keluar',
    'current_password': 'Kata laluan semasa',
    'new_password': 'Kata laluan baru',
    'confirm_password': 'Sahkan kata laluan',
    'passwords_dont_match': 'Kata laluan tidak sepadan',
    'password_updated': 'Kata laluan dikemas kini',

    // Notifications sheet
    'payment_reminders': 'Peringatan bayaran',
    'new_fee_added': 'Yuran baru ditambah',
    'receipt_generated': 'Resit dijana',
    'system_announcements': 'Pengumuman sistem',

    // Fees / Payment
    'total_due': 'Jumlah Perlu Bayar',
    'paid': 'Telah Bayar',
    'balance': 'Baki',
    'balance_due': 'Baki Perlu Bayar',
    'days_left': 'Hari Lagi',
    'pay_now': 'Bayar Sekarang',
    'fully_paid': 'Selesai Bayar',
    'all_settled': 'Semua selesai',
    'no_outstanding': 'Tiada yuran tertunggak.',
    'fee_breakdown': 'Pecahan Yuran',
    'payment_progress': 'Kemajuan Bayaran',
    'select_fee': 'Pilih Yuran',
    'payment_method': 'Kaedah Bayaran',
    'confirm_payment': 'Sahkan Bayaran',
    'payment_successful': 'Bayaran Berjaya!',
    'make_payment': 'Buat Bayaran',
    'unpaid': 'belum bayar',
    'select': 'Pilih',
    'pay': 'Bayar',
    'select_bank': 'Pilih bank',
    'select_bank_desc': 'Pilih bank FPX untuk meneruskan bayaran.',
    'review_details': 'Sila semak butiran sebelum meneruskan.',
    'method': 'Kaedah',
    'bank': 'Bank',
    'due_date': 'Tarikh akhir',
    'processing_payment': 'Memproses bayaran...',
    'dont_close': 'Jangan tutup tetingkap ini.',
    'confirm_pay': 'Sahkan & Bayar',
    'receipt': 'Resit',

    // History
    'no_transactions': 'Tiada transaksi dijumpai.',
    'search_transactions': 'Cari transaksi...',
    'transaction_detail': 'BUTIRAN TRANSAKSI',
    'total_paid': 'JUMLAH DIBAYAR',
    'no_alerts_category': 'Tiada makluman dalam kategori ini',
    'all_caught_up': 'Semua selesai!',
    'no_unread': 'Tiada makluman belum dibaca',
    'mark_all': 'Tanda semua',

    // Status badges
    'active': 'Aktif',
    'blocked': 'Disekat',
  },
};

String t(String key, String locale) {
  return translations[locale]?[key] ?? translations['en']?[key] ?? key;
}

// ─── Notification preferences provider ───
class NotificationPrefsState {
  final bool paymentReminders;
  final bool newFee;
  final bool receipt;
  final bool system;

  const NotificationPrefsState({
    this.paymentReminders = true,
    this.newFee = true,
    this.receipt = true,
    this.system = true,
  });

  NotificationPrefsState copyWith({
    bool? paymentReminders,
    bool? newFee,
    bool? receipt,
    bool? system,
  }) =>
      NotificationPrefsState(
        paymentReminders: paymentReminders ?? this.paymentReminders,
        newFee: newFee ?? this.newFee,
        receipt: receipt ?? this.receipt,
        system: system ?? this.system,
      );

  /// Returns true if the given alert type should be SHOWN per current prefs.
  /// Mapping (frontend filter, no backend support needed):
  ///   - 'reminder' / 'warning'  -> paymentReminders
  ///   - 'new_fee'               -> newFee
  ///   - 'payment'               -> receipt   (success payment alerts)
  ///   - 'info' / 'system' / *   -> system
  bool isTypeEnabled(String? type) {
    final ty = (type ?? '').toLowerCase();
    if (ty == 'reminder' || ty == 'warning') return paymentReminders;
    if (ty == 'new_fee' || ty == 'newfee') return newFee;
    if (ty == 'payment') return receipt;
    return system; // info, system, anything else
  }
}

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefsState> {
  NotificationPrefsNotifier() : super(const NotificationPrefsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationPrefsState(
      paymentReminders: prefs.getBool('notif_payment_reminders') ?? true,
      newFee: prefs.getBool('notif_new_fee') ?? true,
      receipt: prefs.getBool('notif_receipt') ?? true,
      system: prefs.getBool('notif_system') ?? true,
    );
  }

  Future<void> setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    switch (key) {
      case 'notif_payment_reminders':
        state = state.copyWith(paymentReminders: value);
        break;
      case 'notif_new_fee':
        state = state.copyWith(newFee: value);
        break;
      case 'notif_receipt':
        state = state.copyWith(receipt: value);
        break;
      case 'notif_system':
        state = state.copyWith(system: value);
        break;
    }
  }
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefsState>(
        (ref) => NotificationPrefsNotifier());
