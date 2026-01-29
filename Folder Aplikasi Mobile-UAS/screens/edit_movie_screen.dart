// lib/screens/edit_movie_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Halaman untuk mengedit data film yang sudah ada dalam koleksi
/// Mengimplementasikan HTTP POST untuk mengupdate data ke server
class EditMovieScreen extends StatefulWidget {
  final Map<String, dynamic> film;

  const EditMovieScreen({super.key, required this.film});

  @override
  State<EditMovieScreen> createState() => _EditMovieScreenState();
}

class _EditMovieScreenState extends State<EditMovieScreen> {
  // Controller untuk setiap field input form
  final TextEditingController _controllerJudul = TextEditingController();
  final TextEditingController _controllerTahun = TextEditingController();
  final TextEditingController _controllerGenre = TextEditingController();
  final TextEditingController _controllerSutradara = TextEditingController();
  final TextEditingController _controllerDurasi = TextEditingController();
  final TextEditingController _controllerUrlPoster = TextEditingController();
  final TextEditingController _controllerDeskripsi = TextEditingController();

  // Variabel untuk status menonton film
  String _statusNonton = 'plan_to_watch';

  // Variabel untuk status favorit film
  bool _adalahFavorit = false;

  // Variabel untuk status loading saat proses update
  bool _sedangMemuat = false;

  // URL dasar untuk endpoint API
  static const String baseUrl =
      'https://pencarijawabankaisen.my.id/pencari2_sandi_api';

  @override
  void initState() {
    super.initState();
    _isiDataAwal(); // Mengisi form dengan data film yang akan diedit
  }

  /// Mengisi semua field form dengan data film yang diterima sebagai parameter
  void _isiDataAwal() {
    final film = widget.film;

    // Isi semua controller dengan data film
    _controllerJudul.text = film['title'] ?? '';
    _controllerTahun.text = film['year']?.toString() ?? '';
    _controllerGenre.text = film['genre'] ?? '';
    _controllerSutradara.text = film['director'] ?? '';
    _controllerDurasi.text = film['duration'] ?? '';
    _controllerUrlPoster.text = film['poster_url'] ?? '';
    _controllerDeskripsi.text = film['description'] ?? '';

    // Set status menonton dan favorit berdasarkan data film
    _statusNonton = film['watch_status']?.toString() ?? 'plan_to_watch';
    _adalahFavorit = film['is_favorite'] == 1 || film['is_favorite'] == true;
  }

  /// Fungsi utama untuk memperbarui data film di server
  /// Melakukan validasi input dan mengirim data ke endpoint update_movie.php
  Future<void> _perbaruiFilm() async {
    // Validasi input wajib: judul dan tahun
    if (_controllerJudul.text.isEmpty) {
      _tampilkanPesan('Judul film harus diisi', true);
      return;
    }

    if (_controllerTahun.text.isEmpty) {
      _tampilkanPesan('Tahun rilis harus diisi', true);
      return;
    }

    // Set status loading menjadi true
    setState(() {
      _sedangMemuat = true;
    });

    try {
      // Ambil user_id dari SharedPreferences untuk verifikasi kepemilikan
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');

      if (userId == null || userId.isEmpty) {
        _tampilkanPesan('Sesi login tidak valid', true);
        return;
      }

      // Siapkan data film untuk dikirim ke server
      final dataFilm = {
        'id': widget.film['id'], // ID film yang akan diupdate
        'user_id': int.parse(userId),
        'title': _controllerJudul.text.trim(),
        'year': _controllerTahun.text.trim(),
        'genre': _controllerGenre.text.trim(),
        'director': _controllerSutradara.text.trim(),
        'duration': _controllerDurasi.text.trim(),
        'poster_url': _controllerUrlPoster.text.trim(),
        'description': _controllerDeskripsi.text.trim(),
        'watch_status': _statusNonton,
        'is_favorite': _adalahFavorit ? 1 : 0,
      };

      // Kirim permintaan HTTP POST ke server
      final response = await http.post(
        Uri.parse('$baseUrl/update_movie.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(dataFilm),
      );

      // Cek status response dari server
      if (response.statusCode != 200) {
        _tampilkanPesan(
            'Gagal terhubung ke server: ${response.statusCode}', true);
        return;
      }

      // Parse response JSON dari server
      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        // Update berhasil, tampilkan pesan sukses
        _tampilkanPesan('Film berhasil diperbarui', false);

        // Tunggu sebentar untuk memberikan feedback visual
        await Future.delayed(const Duration(milliseconds: 500));

        // Kembali ke halaman sebelumnya dengan data terbaru
        if (!mounted) return;
        Navigator.pop(context, dataFilm);
      } else {
        // Update gagal, tampilkan pesan error dari server
        _tampilkanPesan(data['message'] ?? 'Gagal memperbarui film', true);
      }
    } catch (e) {
      // Tangani exception jika terjadi error
      _tampilkanPesan('Terjadi kesalahan: $e', true);
    } finally {
      // Reset status loading
      if (mounted) {
        setState(() {
          _sedangMemuat = false;
        });
      }
    }
  }

  /// Menampilkan pesan feedback kepada pengguna
  /// Dapat berupa pesan sukses atau error
  void _tampilkanPesan(String pesan, bool adalahError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              adalahError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(pesan)),
          ],
        ),
        backgroundColor: adalahError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Widget untuk membuat field form input dengan label dan icon
  Widget _buatFieldForm(
      String label,
      String petunjuk,
      TextEditingController controller,
      IconData ikon, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: petunjuk,
            prefixIcon: Icon(ikon, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// Widget untuk pilihan status menonton dengan visual yang menarik
  Widget _buatPilihanStatus(
      String label,
      String nilai,
      IconData ikon,
      Color warna,
      ) {
    final terpilih = _statusNonton == nilai;
    return GestureDetector(
      onTap: () {
        setState(() {
          _statusNonton = nilai;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: terpilih ? warna.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: terpilih ? warna : const Color(0xFFE2E8F0),
            width: terpilih ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ikon,
              color: terpilih ? warna : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: terpilih ? warna : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk header informasi film yang sedang diedit
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.edit_note,
            color: Color(0xFF3B82F6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mengedit film: "${widget.film['title']}"',
              style: TextStyle(
                color: const Color(0xFF475569).withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget untuk field deskripsi film dengan textarea multi-line
  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deskripsi Film',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controllerDeskripsi,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tulis deskripsi film...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  /// Widget untuk toggle favorit dalam bentuk card
  Widget _buildFavoriteToggle() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: const Text(
          'Tambahkan ke Favorit',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: const Text('Film akan muncul di daftar favorit'),
        value: _adalahFavorit,
        onChanged: (nilai) {
          setState(() {
            _adalahFavorit = nilai;
          });
        },
        secondary: Icon(
          _adalahFavorit ? Icons.favorite : Icons.favorite_border,
          color: _adalahFavorit ? Colors.red : const Color(0xFF64748B),
        ),
      ),
    );
  }

  /// Widget untuk tombol aksi (batal dan simpan)
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _sedangMemuat ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('BATAL'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _sedangMemuat ? null : _perbaruiFilm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _sedangMemuat
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            )
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, size: 20),
                SizedBox(width: 10),
                Text(
                  'SIMPAN PERUBAHAN',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Film'),
        centerTitle: true,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        actions: [
          // Tombol simpan di appbar untuk akses cepat
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _sedangMemuat ? null : _perbaruiFilm,
            tooltip: 'Simpan perubahan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header informasi
              _buildHeader(),
              const SizedBox(height: 24),

              // Form input judul film
              _buatFieldForm(
                'Judul Film *',
                'Masukkan judul film',
                _controllerJudul,
                Icons.movie,
              ),
              const SizedBox(height: 16),

              // Baris untuk tahun dan durasi
              Row(
                children: [
                  Expanded(
                    child: _buatFieldForm(
                      'Tahun Rilis *',
                      'Contoh: 2024',
                      _controllerTahun,
                      Icons.calendar_today,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buatFieldForm(
                      'Durasi',
                      'Contoh: 120 menit',
                      _controllerDurasi,
                      Icons.timer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Form input genre
              _buatFieldForm(
                'Genre',
                'Contoh: Action, Drama, Comedy',
                _controllerGenre,
                Icons.category,
              ),
              const SizedBox(height: 16),

              // Form input sutradara
              _buatFieldForm(
                'Sutradara',
                'Nama sutradara film',
                _controllerSutradara,
                Icons.person,
              ),
              const SizedBox(height: 16),

              // Form input URL poster
              _buatFieldForm(
                'URL Poster (opsional)',
                'https://example.com/poster.jpg',
                _controllerUrlPoster,
                Icons.image,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Field deskripsi
              _buildDescriptionField(),
              const SizedBox(height: 24),

              // Pilihan status menonton
              const Text(
                'Status Menonton',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buatPilihanStatus(
                    'Rencana Nonton',
                    'plan_to_watch',
                    Icons.schedule,
                    Colors.blue,
                  ),
                  _buatPilihanStatus(
                    'Sedang Menonton',
                    'watching',
                    Icons.play_circle,
                    Colors.orange,
                  ),
                  _buatPilihanStatus(
                    'Sudah Ditonton',
                    'watched',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Toggle favorit
              _buildFavoriteToggle(),
              const SizedBox(height: 32),

              // Tombol aksi
              _buildActionButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Membersihkan semua controller untuk mencegah memory leak
    _controllerJudul.dispose();
    _controllerTahun.dispose();
    _controllerGenre.dispose();
    _controllerSutradara.dispose();
    _controllerDurasi.dispose();
    _controllerUrlPoster.dispose();
    _controllerDeskripsi.dispose();
    super.dispose();
  }
}
