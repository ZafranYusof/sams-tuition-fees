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

    // Auth (login / register / splash)
    'sign_in': 'Sign in',
    'sign_up': 'Sign up',
    'create_account': 'Create an account',
    'create_account_title': 'Create account',
    'join_sams': 'Join SAMs',
    'new_student': 'NEW STUDENT',
    'login_subtitle': 'Sign in to your student account',
    'register_subtitle': 'Start your SAMs journey',
    'full_name': 'Full name',
    'password': 'Password',
    'forgot_password': 'Forgot password?',
    'already_have_account': 'Already have an account?',
    'dont_have_account': "Don't have an account?",
    'invalid_credentials': 'Invalid credentials',
    'registration_failed': 'Registration failed',
    'splash_tagline': 'Student Academic Management System',
    'splash_subtitle': 'Tuition & Fee Management',
    'welcome_login_subtitle': 'Sign in to continue your\nacademic journey.',
    'join_sams_subtitle': "A few details and you're in.",
    'sign_in_btn': 'Sign In',
    'new_to_sams': 'New to SAMs?  ',
    'email_label': 'EMAIL',
    'password_label': 'PASSWORD',
    'student_id_label': 'STUDENT ID',
    'full_name_label': 'FULL NAME',
    'confirm_password_label': 'CONFIRM PASSWORD',
    'faculty_label': 'FACULTY',
    'program_label': 'PROGRAM',
    'email_required': 'Email is required',
    'email_invalid': 'Enter a valid email address',
    'password_required': 'Password is required',
    'password_min': 'Password must be at least 6 characters',
    'student_id_required': 'Student ID is required',
    'full_name_required': 'Full name is required',
    'confirm_password_required': 'Please confirm your password',
    'select_faculty_hint': 'Select faculty',
    'select_program_hint': 'Select program',
    'faculty_required': 'Please select a faculty',
    'program_required': 'Please select a program',
    'your_name_hint': 'Your name',
    'contact_admin_reset': 'Contact admin to reset password',

    // History
    'transaction_history': 'Transaction History',
    'no_transactions_yet': 'No transactions yet',
    'transactions_appear': 'Your payment history will appear here',
    'amount': 'Amount',
    'date': 'Date',
    'reference': 'Reference',
    'status': 'Status',
    'paid_on': 'Paid on',
    'view_receipt': 'View receipt',
    'share_receipt': 'Share receipt',
    'success': 'Success',
    'pending': 'Pending',
    'failed': 'Failed',
    'this_month': 'This month',
    'last_month': 'Last month',
    'sort_by': 'Sort by',
    'newest_first': 'Newest first',
    'oldest_first': 'Oldest first',
    'amount_high_low': 'Amount (high to low)',
    'amount_low_high': 'Amount (low to high)',

    // Treasury / Admin
    'admin_portal': 'Admin Portal',
    'collection': 'Collection',
    'collection_rate': 'Collection Rate',
    'total_students': 'Total Students',
    'paid_students': 'Paid Students',
    'unpaid_students': 'Unpaid Students',
    'overdue': 'Overdue',
    'revenue': 'Revenue',
    'this_semester': 'This Semester',
    'student_list': 'Student List',
    'send_reminder': 'Send reminder',
    'add_fee': 'Add fee',
    'export_report': 'Export report',
    'recent_payments': 'Recent payments',
    'top_outstanding': 'Top outstanding',
    'no_students': 'No students yet',
    'filter': 'Filter',
    'outstanding': 'Outstanding',
    'collected': 'Collected',
    'total_fees': 'Total Fees',
    'partial': 'Partial',
    'actions': 'Actions',
    'view_students': 'View Students',
    'all_payments': 'All Payments',
    'recent': 'Recent',
    'cleared': 'Cleared',
    'partial_paid': 'Partial Paid',
    'all_students': 'All Students',
    'fees': 'Fees',
    'search_id_name': 'Search by ID or Name...',
    'no_students_found': 'No students found',
    'try_different': 'Try a different name or student ID.',
    'clear_search': 'Clear search',
    'send': 'Send',
    'send_reminder_confirm': 'Send payment reminder to unpaid students?',
    'unknown': 'Unknown',

    // Misc UI
    'last_payment': 'Last Payment',
    'deadline': 'Deadline',
    'payment_due': 'Payment Due',
    'week': 'Week',
    'overdue_days': 'overdue in',
    'days': 'days',
    'pay_before': 'Pay before',
    'maintain_access': 'to maintain academic access',
    'tap_to_pay': 'Tap to pay',
    'of': 'of',
    'total': 'total',
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

    // Auth (login / register / splash)
    'sign_in': 'Log masuk',
    'sign_up': 'Daftar',
    'create_account': 'Buat akaun',
    'create_account_title': 'Cipta akaun',
    'join_sams': 'Sertai SAMs',
    'new_student': 'PELAJAR BARU',
    'login_subtitle': 'Log masuk ke akaun pelajar anda',
    'register_subtitle': 'Mulakan perjalanan SAMs anda',
    'full_name': 'Nama penuh',
    'password': 'Kata laluan',
    'forgot_password': 'Lupa kata laluan?',
    'already_have_account': 'Sudah ada akaun?',
    'dont_have_account': 'Belum ada akaun?',
    'invalid_credentials': 'Maklumat log masuk tidak sah',
    'registration_failed': 'Pendaftaran gagal',
    'splash_tagline': 'Sistem Pengurusan Akademik Pelajar',
    'splash_subtitle': 'Pengurusan Yuran & Bayaran',
    'welcome_login_subtitle': 'Log masuk untuk meneruskan\nperjalanan akademik anda.',
    'join_sams_subtitle': 'Beberapa butiran dan anda selesai.',
    'sign_in_btn': 'Log Masuk',
    'new_to_sams': 'Baru ke SAMs?  ',
    'email_label': 'E-MEL',
    'password_label': 'KATA LALUAN',
    'student_id_label': 'ID PELAJAR',
    'full_name_label': 'NAMA PENUH',
    'confirm_password_label': 'SAHKAN KATA LALUAN',
    'faculty_label': 'FAKULTI',
    'program_label': 'PROGRAM',
    'email_required': 'E-mel diperlukan',
    'email_invalid': 'Masukkan alamat e-mel yang sah',
    'password_required': 'Kata laluan diperlukan',
    'password_min': 'Kata laluan mesti sekurang-kurangnya 6 aksara',
    'student_id_required': 'ID Pelajar diperlukan',
    'full_name_required': 'Nama penuh diperlukan',
    'confirm_password_required': 'Sila sahkan kata laluan',
    'select_faculty_hint': 'Pilih fakulti',
    'select_program_hint': 'Pilih program',
    'faculty_required': 'Sila pilih fakulti',
    'program_required': 'Sila pilih program',
    'your_name_hint': 'Nama anda',
    'contact_admin_reset': 'Hubungi pentadbir untuk set semula kata laluan',

    // History
    'transaction_history': 'Sejarah Transaksi',
    'no_transactions_yet': 'Tiada transaksi lagi',
    'transactions_appear': 'Sejarah bayaran anda akan muncul di sini',
    'amount': 'Amaun',
    'date': 'Tarikh',
    'reference': 'Rujukan',
    'status': 'Status',
    'paid_on': 'Dibayar pada',
    'view_receipt': 'Lihat resit',
    'share_receipt': 'Kongsi resit',
    'success': 'Berjaya',
    'pending': 'Menunggu',
    'failed': 'Gagal',
    'this_month': 'Bulan ini',
    'last_month': 'Bulan lepas',
    'sort_by': 'Susun ikut',
    'newest_first': 'Terbaru dahulu',
    'oldest_first': 'Terlama dahulu',
    'amount_high_low': 'Amaun (tinggi ke rendah)',
    'amount_low_high': 'Amaun (rendah ke tinggi)',

    // Treasury / Admin
    'admin_portal': 'Portal Pentadbir',
    'collection': 'Kutipan',
    'collection_rate': 'Kadar Kutipan',
    'total_students': 'Jumlah Pelajar',
    'paid_students': 'Pelajar Sudah Bayar',
    'unpaid_students': 'Pelajar Belum Bayar',
    'overdue': 'Tertunggak',
    'revenue': 'Hasil',
    'this_semester': 'Semester Ini',
    'student_list': 'Senarai Pelajar',
    'send_reminder': 'Hantar peringatan',
    'add_fee': 'Tambah yuran',
    'export_report': 'Eksport laporan',
    'recent_payments': 'Bayaran terkini',
    'top_outstanding': 'Tertunggak tertinggi',
    'no_students': 'Tiada pelajar lagi',
    'filter': 'Tapis',
    'outstanding': 'Tertunggak',
    'collected': 'Dikutip',
    'total_fees': 'Jumlah Yuran',
    'partial': 'Separa',
    'actions': 'Tindakan',
    'view_students': 'Lihat Pelajar',
    'all_payments': 'Semua Bayaran',
    'recent': 'Terkini',
    'cleared': 'Selesai',
    'partial_paid': 'Separa Bayar',
    'all_students': 'Semua Pelajar',
    'fees': 'Yuran',
    'search_id_name': 'Cari ikut ID atau Nama...',
    'no_students_found': 'Tiada pelajar dijumpai',
    'try_different': 'Cuba nama atau ID pelajar yang berbeza.',
    'clear_search': 'Kosongkan carian',
    'send': 'Hantar',
    'send_reminder_confirm': 'Hantar peringatan bayaran kepada pelajar belum bayar?',
    'unknown': 'Tidak diketahui',

    // Misc UI
    'last_payment': 'Bayaran Terakhir',
    'deadline': 'Tarikh Akhir',
    'payment_due': 'Bayaran Perlu Dibuat',
    'week': 'Minggu',
    'overdue_days': 'tertunggak dalam',
    'days': 'hari',
    'pay_before': 'Bayar sebelum',
    'maintain_access': 'untuk kekalkan akses akademik',
    'tap_to_pay': 'Tekan untuk bayar',
    'of': 'daripada',
    'total': 'jumlah',
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
