// lib/screens/add_movie_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Halaman untuk menambahkan film baru ke dalam koleksi
/// Mengimplementasikan HTTP POST untuk mengirim data ke server
class AddMovieScreen extends StatefulWidget {
  const AddMovieScreen({super.key});

  @override
  State<AddMovieScreen> createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends State<AddMovieScreen> {
  // Controller untuk setiap field input form
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _directorController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _posterUrlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Variabel untuk status menonton film
  String _watchStatus = 'plan_to_watch';

  // Variabel untuk status favorit film
  bool _isFavorite = false;

  // Variabel untuk status loading saat proses penambahan
  bool _isLoading = false;

  // URL dasar untuk endpoint API - SESUAIKAN DENGAN HOSTING ANDA
  static const String baseUrl = 'https://pencarijawabankaisen.my.id/pencari2_sandi_api';

  @override
  void dispose() {
    // Membersihkan semua controller untuk mencegah memory leak
    _titleController.dispose();
    _yearController.dispose();
    _genreController.dispose();
    _directorController.dispose();
    _durationController.dispose();
    _posterUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Fungsi utama untuk menambahkan film baru ke server
  /// Melakukan validasi input dan mengirim data ke endpoint add_movie.php
  Future<void> _addMovie() async {
    // Validasi input wajib: judul film tidak boleh kosong
    if (_titleController.text.trim().isEmpty) {
      _showMessage('Judul film harus diisi', isError: true);
      return;
    }

    // Validasi tahun: harus berupa angka dan tidak kosong
    if (_yearController.text.trim().isEmpty) {
      _showMessage('Tahun rilis harus diisi', isError: true);
      return;
    }

    // Set status loading menjadi true
    setState(() {
      _isLoading = true;
    });

    try {
      // Ambil user_id dari SharedPreferences untuk identifikasi pengguna
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');

      // PERBAIKAN: Validasi user_id tidak boleh null
      if (userId == null || userId.isEmpty) {
        _showMessage('Sesi tidak valid. Silakan login kembali', isError: true);
        setState(() { _isLoading = false; });
        return;
      }

      // Siapkan data film untuk dikirim ke server
      // PERBAIKAN: Format data sesuai dengan API
      final Map<String, dynamic> movieData = {
        'user_id': int.parse(userId), // Konversi ke integer
        'title': _titleController.text.trim(),
        'year': _yearController.text.trim(),
        'genre': _genreController.text.trim().isEmpty ? 'Unknown' : _genreController.text.trim(),
        'director': _directorController.text.trim().isEmpty ? 'Unknown' : _directorController.text.trim(),
        'duration': _durationController.text.trim().isEmpty ? '0 min' : _durationController.text.trim(),
        'poster_url': _posterUrlController.text.trim().isEmpty ? '' : _posterUrlController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? 'Tidak ada deskripsi' : _descriptionController.text.trim(),
        'watch_status': _watchStatus,
        'is_favorite': _isFavorite ? 1 : 0,
      };

      // Debug: Print data yang akan dikirim
      print('Data yang dikirim ke server: $movieData');

      // Kirim permintaan HTTP POST ke server
      final response = await http.post(
        Uri.parse('$baseUrl/add_movie.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(movieData),
      );

      // Debug: Print response dari server
      print('Status Response: ${response.statusCode}');
      print('Body Response: ${response.body}');

      // Cek status response dari server
      if (response.statusCode != 200) {
        _showMessage('Gagal terhubung ke server (Status: ${response.statusCode})', isError: true);
        return;
      }

      // Parse response JSON dari server
      final Map<String, dynamic> data = json.decode(response.body);

      // PERBAIKAN: Handle response dengan benar
      if (data['status'] == 'success') {
        // Penambahan berhasil, tampilkan pesan sukses
        _showMessage('Film berhasil ditambahkan!');

        // Clear semua field setelah berhasil
        _clearFields();

        // Tunggu sebentar untuk memberikan feedback visual
        await Future.delayed(const Duration(milliseconds: 1500));

        // Kembali ke halaman utama
        if (!mounted) return;
        Navigator.pop(context, true); // Mengirim signal refresh
      } else {
        // Penambahan gagal, tampilkan pesan error dari server
        String errorMessage = data['message'] ?? 'Gagal menambahkan film';
        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      // Tangani exception jika terjadi error koneksi atau lainnya
      print('Error: $e');
      _showMessage('Terjadi kesalahan: ${e.toString()}', isError: true);
    } finally {
      // Reset status loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Fungsi untuk membersihkan semua field setelah submit berhasil
  void _clearFields() {
    _titleController.clear();
    _yearController.clear();
    _genreController.clear();
    _directorController.clear();
    _durationController.clear();
    _posterUrlController.clear();
    _descriptionController.clear();
    setState(() {
      _watchStatus = 'plan_to_watch';
      _isFavorite = false;
    });
  }

  /// Menampilkan pesan feedback kepada pengguna
  /// Dapat berupa pesan sukses atau error
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Widget lainnya tetap sama seperti sebelumnya...
  // _buildFormField, _buildStatusChip, _buildHeader, dll...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Film Baru'),
        centerTitle: true,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF7C3AED)),
            SizedBox(height: 20),
            Text(
              'Menambahkan film...',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Widget lainnya tetap sama...
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF7C3AED)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Isi data film dengan lengkap. Field dengan * wajib diisi.',
                        style: TextStyle(color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form input judul film
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Judul Film *',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan judul film',
                      prefixIcon: Icon(Icons.movie, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Baris untuk tahun dan durasi
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tahun *',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '2026',
                            prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Durasi',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _durationController,
                          decoration: InputDecoration(
                            hintText: '120 min',
                            prefixIcon: Icon(Icons.timer, color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Form input genre
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Genre',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _genreController,
                    decoration: InputDecoration(
                      hintText: 'Action, Drama, Comedy',
                      prefixIcon: Icon(Icons.category, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Form input sutradara
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sutradara',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _directorController,
                    decoration: InputDecoration(
                      hintText: 'Nama sutradara',
                      prefixIcon: Icon(Icons.person, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Form input URL poster
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'URL Poster (opsional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _posterUrlController,
                    decoration: InputDecoration(
                      hintText: 'https://example.com/poster.jpg',
                      prefixIcon: Icon(Icons.image, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Field deskripsi
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tulis deskripsi film...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Pilihan status menonton
              Text(
                'Status Menonton',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _watchStatus = 'plan_to_watch';
                      });
                    },
                    child: Chip(
                      label: Text('Rencana'),
                      avatar: Icon(Icons.schedule,
                          color: _watchStatus == 'plan_to_watch' ? Colors.blue : Colors.grey),
                      backgroundColor: _watchStatus == 'plan_to_watch'
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.grey.shade200,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _watchStatus = 'watching';
                      });
                    },
                    child: Chip(
                      label: Text('Menonton'),
                      avatar: Icon(Icons.play_circle,
                          color: _watchStatus == 'watching' ? Colors.orange : Colors.grey),
                      backgroundColor: _watchStatus == 'watching'
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.grey.shade200,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _watchStatus = 'watched';
                      });
                    },
                    child: Chip(
                      label: Text('Selesai'),
                      avatar: Icon(Icons.check_circle,
                          color: _watchStatus == 'watched' ? Colors.green : Colors.grey),
                      backgroundColor: _watchStatus == 'watched'
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Toggle favorit
              SwitchListTile(
                title: Text(
                  'Tambahkan ke Favorit',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                value: _isFavorite,
                onChanged: (val) {
                  setState(() {
                    _isFavorite = val;
                  });
                },
                secondary: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.grey,
                ),
              ),
              SizedBox(height: 32),

              // Tombol tambah film
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addMovie,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : Text(
                    'TAMBAH FILM',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Tombol reset form
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _clearFields,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    'RESET FORM',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}