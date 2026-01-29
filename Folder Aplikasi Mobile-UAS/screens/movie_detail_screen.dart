// lib/screens/movie_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movie_collection_app/services/api_service.dart';
import 'package:movie_collection_app/screens/edit_movie_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovieDetailScreen extends StatefulWidget {
  final Map<String, dynamic> film;

  const MovieDetailScreen({super.key, required this.film});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Map<String, dynamic> _film;
  bool _sedangMemuat = false;
  bool _sedangMenghapus = false;
  bool _adalahFavorit = false;
  int _idPenggunaSaatIni = 0;

  @override
  void initState() {
    super.initState();
    _film = Map<String, dynamic>.from(widget.film);
    _adalahFavorit = _film['is_favorite'] == 1;
    _muatDataPengguna();
  }

  Future<void> _muatDataPengguna() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('user_id') ?? 0;

      if (mounted) {
        setState(() => _idPenggunaSaatIni = id);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _tampilkanPesan(String pesan, {bool adalahError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              adalahError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
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

  /// ✅ FUNGSI INI HARUS ADA DI DALAM CLASS _MovieDetailScreenState
  Future<void> _toggleFavorit() async {
    if (_sedangMemuat) return;

    final statusSebelumnya = _adalahFavorit;

    setState(() {
      _adalahFavorit = !_adalahFavorit;
      _film['is_favorite'] = _adalahFavorit ? 1 : 0;
      _sedangMemuat = true;
    });

    try {
      final dataUpdate = {
        'is_favorite': _adalahFavorit ? 1 : 0,
      };

      final response = await ApiService.updateMovie(
        movieId: int.parse(_film['id'].toString()),
        movieData: dataUpdate,
      );

      if (response['status'] == 'success') {
        _tampilkanPesan(
          _adalahFavorit
              ? 'Film ditambahkan ke favorit'
              : 'Film dihapus dari favorit',
        );
      } else {
        throw Exception(response['message'] ?? 'Gagal memperbarui favorit');
      }
    } catch (e) {
      setState(() {
        _adalahFavorit = statusSebelumnya;
        _film['is_favorite'] = statusSebelumnya ? 1 : 0;
      });
      _tampilkanPesan('Gagal memperbarui favorit: $e', adalahError: true);
    } finally {
      if (mounted) {
        setState(() => _sedangMemuat = false);
      }
    }
  }

  Future<void> _hapusFilm() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus film ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    setState(() => _sedangMenghapus = true);

    try {
      final idFilm = int.parse(_film['id'].toString());
      final response = await ApiService.deleteMovie(idFilm);

      if (response['status'] == 'success') {
        _tampilkanPesan('Film berhasil dihapus');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _tampilkanPesan(response['message'] ?? 'Gagal menghapus film',
            adalahError: true);
      }
    } catch (e) {
      _tampilkanPesan('Terjadi kesalahan: $e', adalahError: true);
    } finally {
      if (mounted) {
        setState(() => _sedangMenghapus = false);
      }
    }
  }

  void _navigasiKeHalamanEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMovieScreen(film: _film),
      ),
    ).then((hasil) {
      if (hasil != null && mounted) {
        setState(() {
          _film = Map<String, dynamic>.from(hasil);
          _adalahFavorit = _film['is_favorite'] == 1;
        });
        _tampilkanPesan('Data film berhasil diperbarui');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool adalahPemilik = _film['user_id'] == _idPenggunaSaatIni;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _film['title'] ?? 'Detail Film',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: _sedangMemuat
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Icon(
              _adalahFavorit ? Icons.favorite : Icons.favorite_border,
              color: _adalahFavorit ? Colors.red : null,
            ),
            onPressed: _sedangMemuat ? null : _toggleFavorit,
            tooltip:
            _adalahFavorit ? 'Hapus dari favorit' : 'Tambahkan ke favorit',
          ),
          if (adalahPemilik)
            IconButton(
              icon: _sedangMenghapus
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.delete_outline),
              onPressed: _sedangMenghapus ? null : _hapusFilm,
              tooltip: 'Hapus film',
            ),
        ],
      ),
      floatingActionButton: adalahPemilik
          ? FloatingActionButton.extended(
        onPressed: _navigasiKeHalamanEdit,
        icon: const Icon(Icons.edit),
        label: const Text('Edit'),
        backgroundColor: const Color(0xFF7C3AED),
      )
          : null,
      body: _sedangMenghapus
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_film['poster_url'] != null &&
                _film['poster_url'].toString().isNotEmpty)
              Container(
                height: 300,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: _film['poster_url'].toString(),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.movie_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.movie_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
              ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _film['title'] ?? 'Tanpa Judul',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        if (_film['year'] != null)
                          Chip(
                            label: Text(_film['year'].toString()),
                            backgroundColor: Colors.blue.withOpacity(0.1),
                          ),
                        if (_film['genre'] != null)
                          Chip(
                            label: Text(_film['genre'].toString()),
                            backgroundColor:
                            Colors.green.withOpacity(0.1),
                          ),
                        if (_film['duration'] != null)
                          Chip(
                            label: Text(_film['duration'].toString()),
                            backgroundColor:
                            Colors.orange.withOpacity(0.1),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_film['director'] != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sutradara: ${_film['director']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_film['watch_status'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Icon(
                              _film['watch_status'] == 'watched'
                                  ? Icons.check_circle
                                  : _film['watch_status'] == 'watching'
                                  ? Icons.play_circle_outline
                                  : Icons.schedule,
                              size: 18,
                              color: _film['watch_status'] == 'watched'
                                  ? Colors.green
                                  : _film['watch_status'] == 'watching'
                                  ? Colors.orange
                                  : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _film['watch_status'] == 'watched'
                                  ? 'Sudah ditonton'
                                  : _film['watch_status'] == 'watching'
                                  ? 'Sedang menonton'
                                  : 'Rencana nonton',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _film['description']?.isNotEmpty == true
                          ? _film['description']!
                          : 'Tidak ada deskripsi tersedia.',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                'ID Film: ${_film['id']} • Ditambahkan: ${_film['created_at'] ?? 'Tanggal tidak tersedia'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}