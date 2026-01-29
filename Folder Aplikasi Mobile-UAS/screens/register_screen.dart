import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movie_collection_app/screens/login_screen.dart';
import 'package:movie_collection_app/screens/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _controllerNamaLengkap = TextEditingController();
  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerKonfirmasiPassword =
  TextEditingController();

  bool _sedangMemuat = false;
  bool _sembunyikanPassword = true;
  bool _sembunyikanKonfirmasiPassword = true;

  // Base URL API - SESUAIKAN DENGAN HOSTING ANDA
  static const String baseUrl =
      'https://pencarijawabankaisen.my.id/pencari2_sandi_api';

  Future<void> _registrasi() async {
    FocusScope.of(context).unfocus();

    // Validasi
    if (_controllerNamaLengkap.text.trim().isEmpty ||
        _controllerUsername.text.trim().isEmpty ||
        _controllerEmail.text.trim().isEmpty ||
        _controllerPassword.text.isEmpty ||
        _controllerKonfirmasiPassword.text.isEmpty) {
      _tampilkanPesan('Semua data wajib diisi', true);
      return;
    }

    if (_controllerPassword.text.length < 6) {
      _tampilkanPesan('Password minimal 6 karakter', true);
      return;
    }

    if (_controllerPassword.text != _controllerKonfirmasiPassword.text) {
      _tampilkanPesan('Konfirmasi password tidak sesuai', true);
      return;
    }

    final regexEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regexEmail.hasMatch(_controllerEmail.text.trim())) {
      _tampilkanPesan('Format email tidak valid', true);
      return;
    }

    setState(() => _sedangMemuat = true);

    try {
      print('🔄 Mengirim data registrasi ke: $baseUrl/register.php');

      final response = await http
          .post(
        Uri.parse('$baseUrl/register.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'full_name': _controllerNamaLengkap.text.trim(),
          'username': _controllerUsername.text.trim(),
          'email': _controllerEmail.text.trim(),
          'password': _controllerPassword.text,
        }),
      )
          .timeout(const Duration(seconds: 15));

      print('📡 Status Response: ${response.statusCode}');
      print('📦 Body Response: ${response.body}');

      if (response.statusCode != 200) {
        _tampilkanPesan('Server error: ${response.statusCode}', true);
        return;
      }

      if (response.body.isEmpty) {
        _tampilkanPesan('Server mengembalikan data kosong', true);
        return;
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        print('❌ Error decode JSON: $e');
        _tampilkanPesan('Format data server tidak valid', true);
        return;
      }

      print('📊 Data dari server: $data');

      if (data['status'] == 'success') {
        _tampilkanPesan('Registrasi berhasil!', false);

        // Simpan data user dari response API
        final prefs = await SharedPreferences.getInstance();

        // Periksa struktur data dari API
        if (data['user'] != null) {
          // Jika API mengembalikan dalam format {user: {...}}
          await prefs.setString('user_id', data['user']['id'].toString());
          await prefs.setString('username', data['user']['username']);
          await prefs.setString('email', data['user']['email']);
          await prefs.setString('full_name', data['user']['full_name']);
          await prefs.setString('created_at',
              data['user']['created_at'] ?? DateTime.now().toString());
        } else {
          // Jika API mengembalikan data langsung
          await prefs.setString('user_id', data['id']?.toString() ?? '0');
          await prefs.setString(
              'username', data['username'] ?? _controllerUsername.text);
          await prefs.setString(
              'email', data['email'] ?? _controllerEmail.text);
          await prefs.setString(
              'full_name', data['full_name'] ?? _controllerNamaLengkap.text);
          await prefs.setString(
              'created_at', data['created_at'] ?? DateTime.now().toString());
        }

        await prefs.setString('token', data['token'] ?? '');

        // Set status login
        await prefs.setBool('is_logged_in', true);
        await prefs.setBool('sudah_login', true);
        await prefs.setBool('is_login', true);

        print('✅ Registrasi sukses, data disimpan');
        print('   User ID: ${data['user']?['id'] ?? data['id']}');
        print('   Username: ${data['user']?['username'] ?? data['username']}');
        print('   Token: ${data['token'] != null ? "ada" : "tidak ada"}');

        // Delay sebentar
        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
        );
      } else {
        _tampilkanPesan(data['message'] ?? 'Registrasi gagal', true);
      }
    } catch (e) {
      print('❌ Error registrasi: $e');
      _tampilkanPesan('Gagal terhubung ke server: ${e.toString()}', true);
    } finally {
      if (mounted) setState(() => _sedangMemuat = false);
    }
  }

  void _tampilkanPesan(String pesan, bool adalahError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              adalahError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(pesan)),
          ],
        ),
        backgroundColor: adalahError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.person_add_alt_1,
                size: 70,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 16),
              const Text(
                'Buat Akun Baru',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Isi data diri Anda untuk mulai menggunakan aplikasi',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buatField('Nama Lengkap', _controllerNamaLengkap),
              _buatField('Username', _controllerUsername),
              _buatField(
                'Email',
                _controllerEmail,
                keyboard: TextInputType.emailAddress,
              ),
              _buatFieldPassword(
                'Password',
                _controllerPassword,
                _sembunyikanPassword,
                    () {
                  setState(() => _sembunyikanPassword = !_sembunyikanPassword);
                },
              ),
              _buatFieldPassword(
                'Konfirmasi Password',
                _controllerKonfirmasiPassword,
                _sembunyikanKonfirmasiPassword,
                    () {
                  setState(() => _sembunyikanKonfirmasiPassword =
                  !_sembunyikanKonfirmasiPassword);
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _sedangMemuat ? null : _registrasi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _sedangMemuat
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : const Text(
                    'DAFTAR SEKARANG',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah punya akun?'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Login di sini',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
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

  Widget _buatField(
      String label,
      TextEditingController controller, {
        TextInputType keyboard = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buatFieldPassword(
      String label,
      TextEditingController controller,
      bool sembunyikan,
      VoidCallback toggle,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: sembunyikan,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              sembunyikan ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: toggle,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controllerNamaLengkap.dispose();
    _controllerUsername.dispose();
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    _controllerKonfirmasiPassword.dispose();
    super.dispose();
  }
}