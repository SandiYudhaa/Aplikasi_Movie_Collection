// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'; // ✅ PASTIKAN IMPORT DI ATAS
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Kelas untuk mengelola komunikasi dengan API server
/// Sesuai dengan materi dosen tentang HTTP request dan REST API
class ApiService {
  /// Base URL API yang sudah di-hosting
  static const String baseUrl =
      'https://pencarijawabankaisen.my.id/pencari2_sandi_api';

  /// Timeout untuk setiap request (sesuai materi tentang error handling)
  static const Duration timeout = Duration(seconds: 15);

  /// Header default untuk request JSON
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// ==================== FUNGSI BANTUAN ====================

  /// Meng-handle response dari server
  /// Sesuai materi dosen tentang parsing dan error handling JSON
  static Map<String, dynamic> _handleResponse(http.Response response) {
    // Debug log untuk melihat response
    if (kDebugMode) {
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
    }

    if (response.statusCode != 200) {
      return {
        'status': 'error',
        'message': 'Kesalahan server (${response.statusCode})',
      };
    }

    try {
      final dynamic decodedData = json.decode(response.body);

      // Standardize response format dengan type casting yang benar
      if (decodedData is Map<String, dynamic>) {
        return decodedData;
      } else if (decodedData is Map) {
        // Convert Map<dynamic, dynamic> to Map<String, dynamic>
        return Map<String, dynamic>.from(decodedData);
      } else if (decodedData is List) {
        return {
          'status': 'success',
          'data': decodedData,
          'count': decodedData.length,
        };
      } else {
        return {
          'status': 'success',
          'data': decodedData,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ JSON decode error: $e');
      }
      return {
        'status': 'error',
        'message': 'Format response server tidak valid',
      };
    }
  }

  /// ==================== AUTENTIKASI ====================

  /// Fungsi untuk login pengguna
  /// Mengirim username dan password ke server
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/login.php'),
        headers: _headers,
        body: json.encode({
          'username': username.trim(),
          'password': password.trim(),
        }),
      )
          .timeout(timeout);

      final data = _handleResponse(response);

      if (data['status'] == 'success' && data['user'] != null) {
        await _simpanDataPengguna(data['user']);
      }

      return data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Login error: $e');
      }
      return {
        'status': 'error',
        'message': 'Tidak dapat terhubung ke server: $e',
      };
    }
  }

  /// Fungsi untuk registrasi pengguna baru
  static Future<Map<String, dynamic>> register(
      String fullName, String username, String email, String password) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/register.php'),
        headers: _headers,
        body: json.encode({
          'full_name': fullName.trim(),
          'username': username.trim(),
          'email': email.trim(),
          'password': password.trim(),
        }),
      )
          .timeout(timeout);

      final data = _handleResponse(response);

      if (data['status'] == 'success') {
        // Simpan data user dari response
        final userData = {
          'id': data['user_id']?.toString() ?? '0',
          'username': data['username'] ?? username,
          'email': data['email'] ?? email,
          'full_name': data['full_name'] ?? fullName,
        };
        await _simpanDataPengguna(userData);
      }

      return data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Register error: $e');
      }
      return {
        'status': 'error',
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  }

  /// ==================== MANAJEMEN FILM ====================

  /// Mengambil daftar film dari server
  /// Parameter userId opsional untuk filter
  static Future<Map<String, dynamic>> getMovies({int? userId}) async {
    try {
      String url = '$baseUrl/get_movies.php';
      if (userId != null && userId > 0) {
        url = '$url?user_id=$userId';
      }

      final response = await http
          .get(
        Uri.parse(url),
        headers: _headers,
      )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get movies error: $e');
      }
      return {
        'status': 'error',
        'message': 'Gagal mengambil data film: $e',
        'data': [],
      };
    }
  }

  /// Menambahkan film baru ke server
  static Future<Map<String, dynamic>> addMovie(
      Map<String, dynamic> dataFilm) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userIdStr = prefs.getString('user_id');

      if (userIdStr == null || userIdStr.isEmpty) {
        return {'status': 'error', 'message': 'Pengguna belum login'};
      }

      // Konversi user_id ke integer
      final userId = int.tryParse(userIdStr) ?? 0;
      if (userId == 0) {
        return {'status': 'error', 'message': 'User ID tidak valid'};
      }

      dataFilm['user_id'] = userId;

      final response = await http
          .post(
        Uri.parse('$baseUrl/add_movie.php'),
        headers: _headers,
        body: json.encode(dataFilm),
      )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Add movie error: $e');
      }
      return {'status': 'error', 'message': 'Gagal menambahkan film: $e'};
    }
  }

  /// Update data film yang sudah ada
  static Future<Map<String, dynamic>> updateMovie({
    required int movieId,
    required Map<String, dynamic> movieData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userIdStr = prefs.getString('user_id');

      if (userIdStr == null || userIdStr.isEmpty) {
        return {'status': 'error', 'message': 'Pengguna belum login'};
      }

      // Siapkan data lengkap untuk update
      final dataToSend = {
        'id': movieId,
        'user_id': int.tryParse(userIdStr) ?? 0,
        ...movieData,
      };

      final response = await http
          .post(
        Uri.parse('$baseUrl/update_movie.php'),
        headers: _headers,
        body: json.encode(dataToSend),
      )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Update movie error: $e');
      }
      return {'status': 'error', 'message': 'Gagal memperbarui film: $e'};
    }
  }

  /// Menghapus film dari server
  static Future<Map<String, dynamic>> deleteMovie(int idFilm) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userIdStr = prefs.getString('user_id');

      if (userIdStr == null || userIdStr.isEmpty) {
        return {'status': 'error', 'message': 'Pengguna belum login'};
      }

      final dataToSend = {
        'movie_id': idFilm,
        'user_id': int.tryParse(userIdStr) ?? 0,
      };

      final response = await http
          .post(
        Uri.parse('$baseUrl/delete_movie.php'),
        headers: _headers,
        body: json.encode(dataToSend),
      )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Delete movie error: $e');
      }
      return {'status': 'error', 'message': 'Gagal menghapus film: $e'};
    }
  }

  /// ==================== MANAJEMEN SESI ====================

  /// Menyimpan data pengguna ke SharedPreferences
  /// Sesuai materi dosen tentang penyimpanan lokal
  static Future<void> _simpanDataPengguna(Map<String, dynamic> pengguna) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Simpan semua data user
      await prefs.setString('user_id', pengguna['id']?.toString() ?? '0');
      await prefs.setString('username', pengguna['username']?.toString() ?? '');
      await prefs.setString('email', pengguna['email']?.toString() ?? '');
      await prefs.setString(
          'full_name', pengguna['full_name']?.toString() ?? '');
      await prefs.setBool('sudah_login', true);

      // Tambahkan tanggal bergabung jika belum ada
      if (prefs.getString('join_date') == null) {
        await prefs.setString(
            'join_date', DateTime.now().toString().substring(0, 10));
      }

      if (kDebugMode) {
        print('✅ User data saved to SharedPreferences');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving user data: $e');
      }
    }
  }

  /// Mengambil data pengguna dari SharedPreferences
  static Future<Map<String, dynamic>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'user_id': prefs.getString('user_id'),
        'username': prefs.getString('username'),
        'email': prefs.getString('email'),
        'full_name': prefs.getString('full_name'),
        'join_date': prefs.getString('join_date'),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user data: $e');
      }
      return {};
    }
  }

  /// Mengecek apakah pengguna sudah login
  /// Cek multiple keys untuk kompatibilitas
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cek semua kemungkinan key
      final bool? sudahLogin1 = prefs.getBool('sudah_login');
      final bool? sudahLogin2 = prefs.getBool('is_logged_in');
      final bool? sudahLogin3 = prefs.getBool('is_login');

      // Juga cek jika user_id ada
      final String? userId = prefs.getString('user_id');

      return (sudahLogin1 ?? sudahLogin2 ?? sudahLogin3 ?? false) &&
          (userId != null && userId.isNotEmpty);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking login status: $e');
      }
      return false;
    }
  }

  /// Melakukan logout dengan menghapus semua data sesi
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (kDebugMode) {
        print('✅ User logged out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during logout: $e');
      }
    }
  }

  /// Fungsi untuk ping server (testing koneksi)
  static Future<bool> pingServer() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/get_movies.php'))
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Server ping failed: $e');
      }
      return false;
    }
  }
}