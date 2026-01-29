// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movie_collection_app/screens/login_screen.dart';
import 'package:movie_collection_app/screens/home_screen.dart';

/// Halaman splash screen untuk aplikasi Movie Collection
/// Menampilkan animasi awal dan mengecek status login pengguna
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Status login pengguna
  bool _sudahLogin = false;

  // Status loading
  bool _sedangMemuat = true;

  @override
  void initState() {
    super.initState();
    _inisialisasiAplikasi(); // Memulai proses inisialisasi
  }

  /// Fungsi utama untuk menginisialisasi aplikasi
  /// Mengecek status login dan menentukan halaman tujuan
  Future<void> _inisialisasiAplikasi() async {
    // Langkah 1: Cek status login dari SharedPreferences
    await _cekStatusLogin();

    // Langkah 2: Delay untuk menampilkan splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Langkah 3: Navigasi ke halaman berikutnya
    if (!mounted) return;
    _navigasiKeHalamanBerikutnya();
  }

  /// Mengecek status login pengguna dari SharedPreferences
  Future<void> _cekStatusLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cek semua kemungkinan key untuk status login
      final bool? isLogin1 = prefs.getBool('is_login');
      final bool? isLogin2 = prefs.getBool('is_logged_in');
      final bool? isLogin3 = prefs.getBool('sudah_login');

      // Cek apakah ada data user
      final String? userId = prefs.getString('user_id');
      final String? token = prefs.getString('token');

      // User dianggap sudah login jika ada minimal satu indikator
      _sudahLogin = (isLogin1 ?? false) ||
          (isLogin2 ?? false) ||
          (isLogin3 ?? false) ||
          (userId != null && userId.isNotEmpty && userId != '0') ||
          (token != null && token.isNotEmpty);

      // Log untuk debugging
      debugPrint('🔍 Status login: $_sudahLogin');
    } catch (e) {
      // Jika terjadi error, default ke false
      debugPrint('⚠️ Error saat mengecek login: $e');
      _sudahLogin = false;
    }

    // Update UI
    if (mounted) {
      setState(() => _sedangMemuat = false);
    }
  }

  /// Navigasi ke halaman berikutnya berdasarkan status login
  void _navigasiKeHalamanBerikutnya() {
    if (!mounted) return;

    // Tentukan halaman tujuan
    final Widget halamanTujuan =
    _sudahLogin ? const HomeScreen() : const LoginScreen();

    // Log untuk debugging
    debugPrint('🚀 Navigasi ke: ${_sudahLogin ? 'HomeScreen' : 'LoginScreen'}');

    // Lakukan navigasi dengan animasi fade
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => halamanTujuan,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo aplikasi dengan animasi
              AnimatedOpacity(
                opacity: _sedangMemuat ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 800),
                child: const Icon(
                  Icons.movie_creation_rounded,
                  size: 100,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              // Nama aplikasi dengan animasi
              AnimatedOpacity(
                opacity: _sedangMemuat ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 1000),
                child: const Text(
                  'MOVIE COLLECTION',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Tagline aplikasi
              AnimatedOpacity(
                opacity: _sedangMemuat ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 1200),
                child: const Text(
                  'Koleksi Film Pribadi Anda',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Indicator loading
              if (_sedangMemuat)
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                )
              else
                Column(
                  children: [
                    // Icon centang jika sudah selesai
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 8),

                    // Status navigasi
                    Text(
                      _sudahLogin
                          ? 'Mengarahkan ke beranda...'
                          : 'Mengarahkan ke login...',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}