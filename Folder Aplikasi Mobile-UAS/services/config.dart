// lib/services/config.dart

/// Kelas konfigurasi untuk endpoint API
/// Berisi semua URL endpoint yang digunakan dalam aplikasi
/// Disesuaikan dengan struktur folder API di hosting
class ApiConfig {
  /// Base URL API aplikasi
  /// Mengarah ke folder API di hosting
  static const String baseUrl =
      'https://pencarijawabankaisen.my.id/pencari2_sandi_api';

  // ==================== ENDPOINT AUTENTIKASI ====================

  /// Endpoint untuk login pengguna
  /// Format: POST {baseUrl}/login.php
  static String get login => '$baseUrl/login.php';

  /// Endpoint untuk registrasi pengguna baru
  /// Format: POST {baseUrl}/register.php
  static String get register => '$baseUrl/register.php';

  // ==================== ENDPOINT MANAJEMEN FILM ====================

  /// Endpoint untuk mendapatkan daftar film
  /// Format: GET {baseUrl}/get_movies.php?user_id={userId}
  static String get getMovies => '$baseUrl/get_movies.php';

  /// Endpoint untuk menambahkan film baru
  /// Format: POST {baseUrl}/add_movie.php
  static String get addMovie => '$baseUrl/add_movie.php';

  /// Endpoint untuk memperbarui data film
  /// Format: POST {baseUrl}/update_movie.php
  static String get updateMovie => '$baseUrl/update_movie.php';

  /// Endpoint untuk menghapus film
  /// Format: POST {baseUrl}/delete_movie.php
  static String get deleteMovie => '$baseUrl/delete_movie.php';

  // ==================== ENDPOINT ULASAN ====================

  /// Endpoint untuk menambahkan ulasan film
  /// Format: POST {baseUrl}/add_review.php
  static String get addReview => '$baseUrl/add_review.php';

  // ==================== KONFIGURASI JARINGAN ====================

  /// Timeout untuk koneksi jaringan (30 detik)
  /// Sesuai dengan materi dosen tentang error handling
  static const Duration connectTimeout = Duration(seconds: 30);

  /// Timeout untuk menerima response (30 detik)
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Header default untuk request JSON
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}