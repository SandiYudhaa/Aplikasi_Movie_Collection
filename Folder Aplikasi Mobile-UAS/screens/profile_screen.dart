import 'package:flutter/material.dart'; // Library untuk UI Flutter
import 'package:movie_collection_app/screens/login_screen.dart'; // Halaman login
import 'package:shared_preferences/shared_preferences.dart'; // Penyimpanan data lokal
import 'package:movie_collection_app/services/api_service.dart'; // Service API untuk mengambil data film

/// Halaman profil pengguna
/// Menampilkan informasi pengguna, statistik, dan pengaturan akun
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Data pengguna dari SharedPreferences
  Map<String, dynamic> _dataPengguna = {};

  // Status loading
  bool _sedangMemuat = false;

  // Jumlah film yang dimiliki pengguna
  int _jumlahFilm = 0;

  // Tanggal bergabung pengguna
  String _tanggalBergabung = '-';

  // ID pengguna saat ini
  String? _idPengguna;

  @override
  void initState() {
    super.initState();
    _muatDataPengguna(); // Memuat data saat halaman dibuka
  }

  /// Memuat data pengguna dari SharedPreferences
  /// Sesuai materi dosen tentang penyimpanan lokal
  Future<void> _muatDataPengguna() async {
    setState(() => _sedangMemuat = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Mengambil data dari penyimpanan lokal
      setState(() {
        _dataPengguna = {
          'user_id': prefs.getString('user_id') ?? '0',
          'username': prefs.getString('username') ?? 'Pengguna',
          'email': prefs.getString('email') ?? 'Email tidak tersedia',
          'full_name': prefs.getString('full_name') ?? 'Pengguna Tamu',
        };
        _idPengguna = prefs.getString('user_id');

        // Format tanggal bergabung
        _tanggalBergabung = prefs.getString('join_date') ??
            DateTime.now().toString().substring(0, 10);
      });

      // Memuat jumlah film dari server
      await _muatJumlahFilm();
    } catch (e) {
      debugPrint('Error memuat data pengguna: $e');
    } finally {
      if (mounted) {
        setState(() => _sedangMemuat = false);
      }
    }
  }

  /// Memuat jumlah film yang dimiliki pengguna
  /// Menggunakan ApiService untuk mengambil data dari server
  Future<void> _muatJumlahFilm() async {
    try {
      // Jika ID pengguna tersedia, ambil data film dari server
      if (_idPengguna != null && _idPengguna!.isNotEmpty) {
        final response = await ApiService.getMovies(
          userId: int.parse(_idPengguna!),
        );

        if (response['status'] == 'success') {
          final daftarFilm = response['data'] as List? ?? [];
          setState(() {
            _jumlahFilm = daftarFilm.length;
          });
        } else {
          // Fallback jika API error
          setState(() => _jumlahFilm = 0);
        }
      } else {
        // Default jika tidak ada user ID
        setState(() => _jumlahFilm = 0);
      }
    } catch (e) {
      debugPrint('Error memuat jumlah film: $e');
      setState(() => _jumlahFilm = 0);
    }
  }

  /// Fungsi untuk logout pengguna
  /// Menghapus semua data sesi dari SharedPreferences
  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Menghapus semua data penyimpanan lokal

      if (!mounted) return;

      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil logout'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigasi ke halaman login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Fungsi untuk menghapus akun (data lokal saja)
  /// Menampilkan dialog konfirmasi sebelum menghapus
  Future<void> _hapusAkun() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: const Text(
          'Semua data lokal akan dihapus permanen. '
              'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          // Tombol batal
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          // Tombol hapus
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog

              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Hapus semua data lokal

                if (!mounted) return;

                // Tampilkan pesan sukses
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data akun berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Navigasi ke halaman login
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              } catch (e) {
                // Tampilkan pesan error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog informasi tentang aplikasi
  void _tampilkanInformasiAplikasi() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Informasi Aplikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nama Aplikasi: Movie Collection'),
            const SizedBox(height: 8),
            const Text('Versi: 1.0.0'),
            const SizedBox(height: 8),
            const Text('Build: UAS - Mobile Computing (Praktik)'),
            const SizedBox(height: 8),
            Text('User ID: ${_dataPengguna['user_id'] ?? '-'}'),
            const SizedBox(height: 8),
            Text(
                'Status Server: ${_idPengguna != null ? 'Terhubung' : 'Offline'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        actions: [
          // Tombol informasi aplikasi
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _tampilkanInformasiAplikasi,
            tooltip: 'Informasi Aplikasi',
          ),
        ],
      ),
      body: _sedangMemuat
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header profil
            _buatHeader(),
            const SizedBox(height: 30),

            // Kartu informasi pengguna
            _buatKartuInformasiPengguna(),
            const SizedBox(height: 20),

            // Kartu informasi aplikasi
            _buatKartuInformasiAplikasi(),
            const SizedBox(height: 30),

            // Tombol aksi
            _buatTombolAksi(),
            const SizedBox(height: 20),

            // Footer
            const Text(
              'Aplikasi Movie Collection © 2026',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk header profil
  Widget _buatHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Avatar pengguna
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            child: Text(
              (_dataPengguna['full_name']?.toString().isNotEmpty ?? false)
                  ? _dataPengguna['full_name']!
                  .toString()
                  .substring(0, 1)
                  .toUpperCase()
                  : 'P',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nama lengkap
          Text(
            _dataPengguna['full_name']?.toString() ?? 'Pengguna Guest',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          // Username
          Text(
            '@${_dataPengguna['username']?.toString() ?? 'pengguna'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Statistik
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buatItemStatistik('Film', _jumlahFilm.toString(), Icons.movie),
              _buatItemStatistik(
                  'Bergabung', _tanggalBergabung, Icons.calendar_today),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget untuk kartu informasi pengguna
  Widget _buatKartuInformasiPengguna() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Email
          ListTile(
            leading: const Icon(Icons.email, color: Colors.deepPurple),
            title: const Text(
              'Email',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _dataPengguna['email']?.toString() ?? 'Email tidak tersedia',
            ),
          ),
          const Divider(height: 1),

          // Username
          ListTile(
            leading: const Icon(Icons.person, color: Colors.deepPurple),
            title: const Text(
              'Username',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _dataPengguna['username']?.toString() ?? 'pengguna',
            ),
          ),
          const Divider(height: 1),

          // User ID
          ListTile(
            leading: const Icon(Icons.badge, color: Colors.deepPurple),
            title: const Text(
              'User ID',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _dataPengguna['user_id']?.toString() ?? '0',
            ),
          ),
        ],
      ),
    );
  }

  /// Widget untuk kartu informasi aplikasi
  Widget _buatKartuInformasiAplikasi() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Aplikasi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buatBarisInformasi('Versi', '1.0.0'),
            _buatBarisInformasi('Build', 'UAS - Mobile Computing (Praktik)'),
            _buatBarisInformasi('Pengembang', 'Koleksi Movie Teams (Sandi Yudha)'),
            _buatBarisInformasi('Status', 'Aktif'),
          ],
        ),
      ),
    );
  }

  /// Widget untuk baris informasi
  Widget _buatBarisInformasi(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              nilai,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget untuk tombol aksi (logout dan hapus akun)
  Widget _buatTombolAksi() {
    return Column(
      children: [
        // Tombol logout
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 20),
            label: const Text(
              'LOGOUT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tombol hapus akun
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _hapusAkun,
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text(
              'HAPUS AKUN',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Widget untuk item statistik
  Widget _buatItemStatistik(String label, String nilai, IconData ikon) {
    return Column(
      children: [
        Icon(ikon, color: Colors.white, size: 24),
        const SizedBox(height: 6),
        Text(
          nilai,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}