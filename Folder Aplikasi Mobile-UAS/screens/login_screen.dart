import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:movie_collection_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controllerUsername = TextEditingController();
  final _controllerPassword = TextEditingController();

  bool _sedangMemuat = false;
  String _pesanError = '';

  Future<void> _prosesLogin() async {
    FocusScope.of(context).unfocus();

    if (_controllerUsername.text.isEmpty || _controllerPassword.text.isEmpty) {
      _tampilkanPesan('Username dan password wajib diisi', true);
      return;
    }

    setState(() {
      _sedangMemuat = true;
      _pesanError = '';
    });

    try {
      print('🔄 Memulai proses login...');
      final response = await ApiService.login(
        _controllerUsername.text.trim(),
        _controllerPassword.text,
      );

      print('📡 Response dari server: ${response.toString()}');

      if (response['status'] == 'success') {
        _tampilkanPesan('Login berhasil!', false);

        final prefs = await SharedPreferences.getInstance();

        // Simpan data user dengan benar
        if (response['user'] != null) {
          await prefs.setString('user_id', response['user']['id'].toString());
          await prefs.setString('username', response['user']['username'] ?? '');
          await prefs.setString('email', response['user']['email'] ?? '');
          await prefs.setString(
              'full_name', response['user']['full_name'] ?? '');
          await prefs.setString(
              'created_at', response['user']['created_at'] ?? '');
        }

        await prefs.setString('token', response['token'] ?? '');

        // Set semua flag login
        await prefs.setBool('sudah_login', true);
        await prefs.setBool('is_logged_in', true);
        await prefs.setBool('is_login', true);

        print('✅ Data disimpan ke SharedPreferences');
        print('   User ID: ${response['user']?['id']}');
        print('   Username: ${response['user']?['username']}');
        print('   Token: ${response['token'] != null ? "ada" : "tidak ada"}');

        // Navigasi ke home screen
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
        );
      } else {
        _tampilkanPesan(response['message'] ?? 'Login gagal', true);
      }
    } catch (e) {
      print('❌ Error login: $e');
      _tampilkanPesan('Terjadi kesalahan: ${e.toString()}', true);
    } finally {
      if (mounted) {
        setState(() => _sedangMemuat = false);
      }
    }
  }

  void _tampilkanPesan(String pesan, bool adalahError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: adalahError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigasiKeRegister() {
    print('👉 Navigasi ke Register Screen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.movie_creation,
                  size: 90,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Movie Collection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login untuk mengakses koleksi film',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _controllerUsername,
                  decoration: InputDecoration(
                    labelText: 'Username atau Email',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controllerPassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_pesanError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _pesanError,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _sedangMemuat ? null : _prosesLogin,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.deepPurple,
                    ),
                    child: _sedangMemuat
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      'LOGIN',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _navigasiKeRegister, // PERBAIKAN DISINI
                  child: const Text('Belum punya akun? Daftar di sini'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controllerUsername.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }
}