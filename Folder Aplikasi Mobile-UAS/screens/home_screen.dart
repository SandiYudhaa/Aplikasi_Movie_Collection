// lib/screens/home_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movie_collection_app/screens/login_screen.dart';
import 'package:movie_collection_app/screens/profile_screen.dart';
import 'package:movie_collection_app/screens/add_movie_screen.dart';
import 'package:movie_collection_app/screens/movie_detail_screen.dart';
import 'package:movie_collection_app/services/api_service.dart';

/// Halaman utama aplikasi Movie Collection
/// Menampilkan dashboard dengan statistik dan koleksi film pengguna
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variabel untuk data pengguna
  String _username = 'Pengguna';
  String _fullName = '';
  String _email = '';
  String _userId = '';
  String _joinDate = '';

  // Variabel untuk status loading
  bool _sedangMemuat = true;

  // Variabel untuk data film
  List<dynamic> _movies = [];
  int _jumlahFilm = 0;
  int _jumlahFilmSelesai = 0;
  int _jumlahFilmSedangDitonton = 0;
  int _jumlahFilmFavorit = 0;

  // Variabel untuk bottom navigation
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _muatDataAwal(); // Memuat data saat halaman pertama kali dibuka
  }

  /// Fungsi untuk memuat data awal aplikasi
  /// Termasuk data pengguna dan koleksi film
  Future<void> _muatDataAwal() async {
    try {
      // 1. Muat data pengguna dari penyimpanan lokal
      await _muatDataPengguna();

      // 2. Muat data film dari server API
      await _muatDataFilm();

      // 3. Hitung statistik berdasarkan data film
      _hitungStatistik();
    } catch (e) {
      debugPrint('Error memuat data awal: $e');
      // Fallback data untuk pengembangan
      _movies = _getContohFilm();
      _jumlahFilm = _movies.length;
      _hitungStatistik();
    } finally {
      if (mounted) {
        setState(() => _sedangMemuat = false);
      }
    }
  }

  /// Memuat data pengguna dari SharedPreferences
  Future<void> _muatDataPengguna() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _userId = prefs.getString('user_id') ?? '0';
      _username = prefs.getString('username') ?? 'Pengguna';
      _email = prefs.getString('email') ?? 'Email tidak tersedia';
      _fullName = prefs.getString('full_name') ?? 'Pengguna Tamu';

      // Format tanggal bergabung dari berbagai kemungkinan key
      final rawDate = prefs.getString('created_at') ??
          prefs.getString('join_date') ??
          DateTime.now().toString();
      _joinDate = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    });
  }

  /// Memuat data film dari server menggunakan API Service
  Future<void> _muatDataFilm() async {
    try {
      // Pastikan user ID valid sebelum mengambil data
      if (_userId.isNotEmpty && _userId != '0') {
        final response = await ApiService.getMovies(
          userId: int.parse(_userId),
        );

        // Cek jika response sukses dan memiliki data
        if (response['status'] == 'success' && response['data'] != null) {
          setState(() {
            _movies = response['data'] as List;
            _jumlahFilm = _movies.length;
          });
        }
      }
    } catch (e) {
      debugPrint('Error memuat data film: $e');
      // Gunakan data contoh jika API error (untuk pengembangan)
      _movies = _getContohFilm();
      _jumlahFilm = _movies.length;
    }
  }

  /// Menghitung berbagai statistik dari koleksi film
  void _hitungStatistik() {
    int selesai = 0;
    int sedang = 0;
    int favorit = 0;

    // Iterasi melalui semua film untuk menghitung statistik
    for (var film in _movies) {
      if (film['watch_status'] == 'watched') selesai++;
      if (film['watch_status'] == 'watching') sedang++;
      if (film['is_favorite'] == true || film['is_favorite'] == 1) favorit++;
    }

    setState(() {
      _jumlahFilmSelesai = selesai;
      _jumlahFilmSedangDitonton = sedang;
      _jumlahFilmFavorit = favorit;
    });
  }

  /// Data film contoh untuk pengembangan (fallback jika API tidak tersedia)
  List<Map<String, dynamic>> _getContohFilm() {
    return [
      {
        'id': 1,
        'title': 'Inception',
        'year': '2010',
        'genre': 'Action, Sci-Fi, Thriller',
        'director': 'Christopher Nolan',
        'duration': '148 min',
        'poster_url':
        'https://m.media-amazon.com/images/M/MV5BMjAxMzY3NjcxNF5BMl5BanBnXkFtZTcwNTI5OTM0Mw@@._V1_.jpg',
        'watch_status': 'watched',
        'is_favorite': true,
      },
      {
        'id': 2,
        'title': 'The Shawshank Redemption',
        'year': '1994',
        'genre': 'Drama',
        'director': 'Frank Darabont',
        'duration': '142 min',
        'poster_url':
        'https://m.media-amazon.com/images/M/MV5BNDE3ODcxYzMtY2YzZC00NmNlLWJiNDMtZDViZWM2MzIxZDYwXkEyXkFqcGdeQXVyNjAwNDUxODI@._V1_.jpg',
        'watch_status': 'watched',
        'is_favorite': true,
      },
      {
        'id': 3,
        'title': 'Parasite',
        'year': '2019',
        'genre': 'Comedy, Drama, Thriller',
        'director': 'Bong Joon Ho',
        'duration': '132 min',
        'poster_url':
        'https://m.media-amazon.com/images/M/MV5BYWZjMjk3ZTItODQ2ZC00NTY5LWE0ZDYtZTI3MjcwN2Q5NTVkXkEyXkFqcGdeQXVyODk4OTc3MTY@._V1_.jpg',
        'watch_status': 'watching',
        'is_favorite': false,
      },
    ];
  }

  /// Navigasi ke halaman profil pengguna
  void _navigasiKeProfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  /// Navigasi ke halaman tambah film
  void _navigasiKeTambahFilm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddMovieScreen(),
      ),
    );
  }

  /// Navigasi ke halaman detail film
  void _navigasiKeDetailFilm(Map<String, dynamic> film) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(film: film),
      ),
    );
  }

  /// Fungsi untuk logout pengguna dengan konfirmasi
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Hapus semua data sesi

              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  /// Fungsi untuk merefresh data dari server
  Future<void> _refreshData() async {
    setState(() => _sedangMemuat = true);
    await _muatDataAwal();
  }

  /// Widget untuk header selamat datang dengan gradien
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.deepPurple,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _fullName.isNotEmpty ? _fullName : _username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            '${_jumlahFilm} film dalam koleksi • Bergabung: $_joinDate',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan statistik film dalam bentuk card
  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.check_circle, _jumlahFilmSelesai.toString(),
              'Selesai', Colors.green),
          _buildStatItem(Icons.play_circle,
              _jumlahFilmSedangDitonton.toString(), 'Ditonton', Colors.blue),
          _buildStatItem(
              Icons.movie, _jumlahFilm.toString(), 'Total', Colors.deepPurple),
          _buildStatItem(Icons.favorite, _jumlahFilmFavorit.toString(),
              'Favorit', Colors.red),
        ],
      ),
    );
  }

  /// Widget untuk item statistik individual
  Widget _buildStatItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Widget untuk menampilkan daftar film
  Widget _buildMoviesList() {
    // Tampilkan pesan jika tidak ada film
    if (_movies.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.movie_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 15),
            const Text(
              'Belum ada film dalam koleksi',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tambahkan film pertama Anda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _navigasiKeTambahFilm,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Film Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Tampilkan daftar film jika ada
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Film Terbaru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implementasi halaman semua film
                },
                child: const Row(
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios,
                        size: 12, color: Colors.deepPurple),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 16),
            itemCount: _movies.length,
            itemBuilder: (context, index) {
              final film = _movies[index];
              return _buildMovieCard(film);
            },
          ),
        ),
      ],
    );
  }

  /// Widget untuk card film individual
  Widget _buildMovieCard(Map<String, dynamic> film) {
    return GestureDetector(
      onTap: () => _navigasiKeDetailFilm(film),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 180,
                width: 160,
                color: Colors.grey[200],
                child: film['poster_url'] != null
                    ? Image.network(
                  film['poster_url'].toString(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.movie,
                        size: 50, color: Colors.grey);
                  },
                )
                    : const Icon(Icons.movie, size: 50, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              film['title'].toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${film['year']} • ${film['genre'].toString().split(',').first}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(film['watch_status']),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(film['watch_status']),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (film['is_favorite'] == true || film['is_favorite'] == 1)
                  Icon(Icons.favorite, color: Colors.red[400], size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Mendapatkan warna berdasarkan status menonton
  Color _getStatusColor(String status) {
    switch (status) {
      case 'watched':
        return Colors.green;
      case 'watching':
        return Colors.blue;
      case 'plan_to_watch':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Mendapatkan teks status dalam bahasa Indonesia
  String _getStatusText(String status) {
    switch (status) {
      case 'watched':
        return 'SELESAI';
      case 'watching':
        return 'DITONTON';
      case 'plan_to_watch':
        return 'RENCANA';
      default:
        return status.toUpperCase();
    }
  }

  /// Widget untuk quick actions (aksi cepat)
  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Cepat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickActionItem(Icons.add, 'Tambah Film',
                  _navigasiKeTambahFilm, Colors.deepPurple),
              _buildQuickActionItem(
                  Icons.search, 'Cari Film', () {}, Colors.blue),
              _buildQuickActionItem(
                  Icons.favorite, 'Favorit', () {}, Colors.red),
              _buildQuickActionItem(
                  Icons.person, 'Profil', _navigasiKeProfil, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget untuk item quick action
  Widget _buildQuickActionItem(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget untuk bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });

        // Handle navigation berdasarkan index yang dipilih
        switch (index) {
          case 0: // Beranda
            break;
          case 1: // Film
          // TODO: Implementasi navigasi ke semua film
            break;
          case 2: // Favorit
          // TODO: Implementasi navigasi ke film favorit
            break;
          case 3: // Profil
            _navigasiKeProfil();
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: const TextStyle(fontSize: 12),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.movie),
          label: 'Film',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Favorit',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading screen jika data masih dimuat
    if (_sedangMemuat) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.deepPurple),
              const SizedBox(height: 20),
              Text(
                'Memuat koleksi film...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Tampilkan halaman utama dengan semua komponen
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Movie Collection',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 24),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.deepPurple,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildStats(),
              const SizedBox(height: 20),
              _buildMoviesList(),
              _buildQuickActions(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigasiKeTambahFilm,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}