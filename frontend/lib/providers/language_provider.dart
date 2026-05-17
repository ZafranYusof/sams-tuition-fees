import 'package:flutter/material.dart';
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

// Simple i18n map
const Map<String, Map<String, String>> translations = {
  'en': {
    'welcome': 'Welcome',
    'modules': 'Modules',
    'quick_links': 'Quick Links',
    'featured': 'Featured',
    'facilities': 'Facilities',
    'announcements': 'Announcements',
    'view_all': 'View all',
    'registration': 'Registration',
    'attendance': 'Attendance',
    'activities': 'Activities',
    'tuition_fees': 'Tuition Fees',
    'profile': 'Profile',
    'logout': 'Logout',
    'light_mode': 'Light Mode',
    'dark_mode': 'Dark Mode',
    'language': 'Bahasa Melayu',
    'home': 'Home',
    'payment': 'Payment',
    'history': 'History',
    'alerts': 'Alerts',
    'dashboard': 'Dashboard',
    'students': 'Students',
    'total_due': 'Total Due',
    'paid': 'Paid',
    'balance': 'Balance',
    'days_left': 'Days Left',
    'pay_now': 'Pay Now',
    'fully_paid': 'Fully Paid',
    'fee_breakdown': 'Fee Breakdown',
    'payment_progress': 'Payment Progress',
    'select_fee': 'Select Fee to Pay',
    'payment_method': 'Payment Method',
    'confirm_payment': 'Confirm Payment',
    'payment_successful': 'Payment Successful!',
    'no_transactions': 'No transactions found.',
    'search_transactions': 'Search transactions...',
  },
  'ms': {
    'welcome': 'Selamat Datang',
    'modules': 'Modul',
    'quick_links': 'Pautan Pantas',
    'featured': 'Pilihan',
    'facilities': 'Kemudahan',
    'announcements': 'Pengumuman',
    'view_all': 'Lihat semua',
    'registration': 'Pendaftaran',
    'attendance': 'Kehadiran',
    'activities': 'Aktiviti',
    'tuition_fees': 'Yuran Pengajian',
    'profile': 'Profil',
    'logout': 'Log Keluar',
    'light_mode': 'Mod Cerah',
    'dark_mode': 'Mod Gelap',
    'language': 'English',
    'home': 'Utama',
    'payment': 'Bayaran',
    'history': 'Sejarah',
    'alerts': 'Makluman',
    'dashboard': 'Papan Pemuka',
    'students': 'Pelajar',
    'total_due': 'Jumlah Perlu Bayar',
    'paid': 'Telah Bayar',
    'balance': 'Baki',
    'days_left': 'Hari Lagi',
    'pay_now': 'Bayar Sekarang',
    'fully_paid': 'Selesai Bayar',
    'fee_breakdown': 'Pecahan Yuran',
    'payment_progress': 'Kemajuan Bayaran',
    'select_fee': 'Pilih Yuran',
    'payment_method': 'Kaedah Bayaran',
    'confirm_payment': 'Sahkan Bayaran',
    'payment_successful': 'Bayaran Berjaya!',
    'no_transactions': 'Tiada transaksi.',
    'search_transactions': 'Cari transaksi...',
  },
};

String t(String key, String locale) {
  return translations[locale]?[key] ?? translations['en']?[key] ?? key;
}
