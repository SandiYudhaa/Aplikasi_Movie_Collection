import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aplikasi_movie_collection/services/api_service.dart';
import 'package:aplikasi_movie_collection/utils/error_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AddMovieScreen extends StatefulWidget {
  final VoidCallback? onMovieAdded;
  final VoidCallback? onSuccessCallback;

  const AddMovieScreen({
    super.key,
    this.onMovieAdded,
    this.onSuccessCallback,
  });

  @override
  State<AddMovieScreen> createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends State<AddMovieScreen> {
  // ==================== VARIABEL DAN CONTROLLER ====================
  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  final _genreController = TextEditingController();
  final _directorController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ratingController = TextEditingController();

  String _watchStatus = 'plan_to_watch';
  bool _isFavorite = false;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String _errorMessage = '';
  bool _showValidationErrors = false;
  Map<String, dynamic>? _currentUser;
  double _rating = 0.0;

  // Variabel untuk upload foto
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  final ImagePicker _picker = ImagePicker();

  // ==================== INITIALIZATION ====================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentUser();
    });
  }

  // Fungsi untuk memuat data pengguna yang sedang login
  Future<void> _loadCurrentUser() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userData = await ApiService.getCurrentUser();

      if (!mounted) return;

      if (userData != null) {
        setState(() {
          _currentUser = userData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackbar('Anda harus login terlebih dahulu', true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==================== FUNGSI UPLOAD FOTO (MULTI-PLATFORM) ====================
  // Menampilkan bottom sheet untuk memilih sumber gambar
  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Opsi kamera hanya tersedia di platform mobile
              if (!kIsWeb)
                ListTile(
                  leading:
                      const Icon(Icons.camera_alt, color: Colors.deepPurple),
                  title: const Text('Ambil Foto dari Kamera'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _getImageFromCamera();
                  },
                ),
              // Opsi galeri tersedia di semua platform
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Colors.deepPurple),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImageFromGallery();
                },
              ),
              // Opsi hapus foto jika ada foto yang dipilih
              if (_selectedImage != null || _selectedImageBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Hapus Foto',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    } catch (e) {
      _showSnackbar('Gagal membuka pemilih gambar', true);
    }
  }

  // Mengambil gambar dari kamera
  Future<void> _getImageFromCamera() async {
    try {
      if (kIsWeb) {
        _showSnackbar('Fitur kamera tidak tersedia di web', true);
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        await _processSelectedImage(image);
        _showSnackbar('Foto berhasil diambil', false);
      }
    } catch (e) {
      _showSnackbar('Gagal mengambil foto', true);
    }
  }

  // Mengambil gambar dari galeri
  Future<void> _getImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        await _processSelectedImage(image);
        _showSnackbar('Foto berhasil dipilih', false);
      }
    } catch (e) {
      _showSnackbar('Gagal memilih gambar', true);
    }
  }

  // Memproses gambar yang dipilih
  Future<void> _processSelectedImage(XFile image) async {
    if (kIsWeb) {
      // Untuk platform web: membaca gambar sebagai bytes
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = image.name;
        _selectedImage = image;
      });
    } else {
      // Untuk platform mobile: menyimpan sebagai File
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = null;
        _selectedImageName = image.name;
      });
    }
  }

  // Menghapus gambar yang dipilih
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
    _showSnackbar('Foto dihapus', false);
  }

  // ==================== UPLOAD GAMBAR KE SERVER ====================
  // Mengunggah gambar ke server dan mengembalikan URL gambar
  Future<String?> _uploadImageToServer() async {
    if (_selectedImage == null && _selectedImageBytes == null) {
      return null;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Menggunakan fungsi uploadImage dari ApiService
      if (kIsWeb && _selectedImageBytes != null) {
        final result = await ApiService.uploadImage(
          _selectedImageBytes!,
          _selectedImageName ?? 'movie_poster.jpg',
          userId: _currentUser?['id'],
        );

        if (result['success'] == true) {
          return result['image_url'];
        } else {
          throw Exception(result['message'] ?? 'Gagal upload gambar');
        }
      } else if (!kIsWeb && _selectedImage != null) {
        // Untuk mobile: membaca file sebagai bytes
        final bytes = await _selectedImage!.readAsBytes();
        final result = await ApiService.uploadImage(
          bytes,
          _selectedImageName ?? 'movie_poster.jpg',
          userId: _currentUser?['id'],
        );

        if (result['success'] == true) {
          return result['image_url'];
        } else {
          throw Exception(result['message'] ?? 'Gagal upload gambar');
        }
      }

      return null;
    } catch (e) {
      return null;
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  // ==================== FUNGSI TAMBAH FILM ====================
  // Menambahkan film baru ke sistem
  Future<void> _addMovie() async {
    FocusScope.of(context).unfocus();

    final validation = _validateInput();
    if (validation != null) {
      _showSnackbar(validation, true);
      setState(() => _showValidationErrors = true);
      return;
    }

    if (_currentUser == null || _currentUser!['id'] == null) {
      _showSnackbar('Anda harus login terlebih dahulu', true);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Upload gambar terlebih dahulu (jika ada)
      String? posterUrl;
      if (_selectedImage != null || _selectedImageBytes != null) {
        posterUrl = await _uploadImageToServer();
        if (posterUrl == null) {
          _showSnackbar('Gagal upload gambar, lanjut tanpa gambar', false);
        }
      }

      final ratingValue = double.tryParse(_ratingController.text.trim()) ?? 0.0;

      final movieData = {
        'user_id': _currentUser!['id'],
        'title': _titleController.text.trim(),
        'year': _yearController.text.trim(),
        'genre': _genreController.text.trim(),
        'director': _directorController.text.trim(),
        'duration': _durationController.text.trim(),
        'poster_url': posterUrl ?? '',
        'description': _descriptionController.text.trim(),
        'watch_status': _watchStatus,
        'is_favorite': _isFavorite ? 1 : 0,
        'rating': ratingValue,
      };

      final apiResult = await ApiService.addMovie(movieData);

      if (apiResult['success'] == true) {
        _showSnackbar('Film berhasil ditambahkan!', false);

        await Future.delayed(const Duration(milliseconds: 1500));

        // Menjalankan callback yang tersedia
        if (widget.onMovieAdded != null) {
          widget.onMovieAdded!();
        }

        if (widget.onSuccessCallback != null) {
          widget.onSuccessCallback!();
        }

        if (!mounted) return;
        Navigator.of(context).pop({'success': true, 'refresh': true});
      } else {
        throw Exception(apiResult['message'] ?? 'Gagal menyimpan film');
      }
    } catch (e) {
      final errorMsg = ErrorHandler.getErrorMessage(e);
      _showSnackbar('Gagal menambahkan film: $errorMsg', true);

      if (mounted) {
        setState(() => _errorMessage = errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== VALIDASI INPUT ====================
  // Memvalidasi input form, mengembalikan pesan error jika tidak valid
  String? _validateInput() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return 'Judul film wajib diisi';
    }
    if (title.length < 2) {
      return 'Judul minimal 2 karakter';
    }

    final year = _yearController.text.trim();
    if (year.isEmpty) {
      return 'Tahun rilis wajib diisi';
    }

    final yearRegex = RegExp(r'^\d{4}$');
    if (!yearRegex.hasMatch(year)) {
      return 'Tahun harus berupa 4 digit angka (contoh: 2024)';
    }

    final yearValue = int.tryParse(year) ?? 0;
    if (yearValue < 1900) {
      return 'Tahun tidak boleh kurang dari 1900';
    }
    if (yearValue > DateTime.now().year + 5) {
      return 'Tahun tidak boleh lebih dari ${DateTime.now().year + 5}';
    }

    return null;
  }

  // ==================== FUNGSI BANTUAN ====================
  // Mengosongkan semua field form
  void _clearForm() {
    _titleController.clear();
    _yearController.clear();
    _genreController.clear();
    _directorController.clear();
    _durationController.clear();
    _descriptionController.clear();
    _ratingController.clear();
    setState(() {
      _watchStatus = 'plan_to_watch';
      _isFavorite = false;
      _rating = 0.0;
      _errorMessage = '';
      _showValidationErrors = false;
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  // Menampilkan snackbar dengan pesan tertentu
  void _showSnackbar(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Mengisi form dengan data contoh
  void _fillExampleData() {
    if (_titleController.text.isEmpty) {
      setState(() {
        _titleController.text = 'Avengers: Endgame';
        _yearController.text = '2019';
        _genreController.text = 'Action, Adventure, Sci-Fi';
        _directorController.text = 'Anthony Russo, Joe Russo';
        _durationController.text = '181 min';
        _descriptionController.text =
            'Setelah peristiwa menghancurkan dari Infinity War, Avengers yang tersisa harus melakukan upaya terakhir untuk mengalahkan Thanos.';
        _ratingController.text = '8.4';
        _watchStatus = 'watched';
        _isFavorite = true;
        _rating = 8.4;
      });
      _showSnackbar('Form diisi dengan data contoh', false);
    }
  }

  // ==================== NAVIGASI KE HOME ====================
  // Kembali ke halaman sebelumnya
  void _navigateToHome() {
    Navigator.pop(context);
  }

  // ==================== WIDGET UPLOAD FOTO ====================
  // Membangun widget untuk bagian upload foto
  Widget _buildImageUploadSection() {
    final hasImage = _selectedImage != null || _selectedImageBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Foto (Opsional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasImage ? Colors.deepPurple : Colors.grey[300]!,
                width: hasImage ? 2 : 1,
              ),
            ),
            child: hasImage
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb && _selectedImageBytes != null
                            ? Image.memory(
                                _selectedImageBytes!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : !kIsWeb && _selectedImage != null
                                ? Image.file(
                                    File(_selectedImage!.path),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.photo, size: 50),
                                  ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 16),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap untuk menambahkan foto',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 4),
        if (hasImage)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text(
                  'Foto siap diupload',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _removeImage,
                  child: const Text(
                    'Hapus',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        if (_isUploadingImage)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(
              color: Colors.deepPurple,
            ),
          ),
      ],
    );
  }

  // ==================== UI BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Film Baru'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToHome,
          tooltip: 'Kembali',
        ),
      ),
      body: _buildBody(),
    );
  }

  // Membangun body utama dari halaman
  Widget _buildBody() {
    if (_isLoading && _currentUser == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 20),
            Text('Memuat data pengguna...'),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== INFO PENGGUNA ====================
            if (_currentUser != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.green[700]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ditambahkan oleh:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _currentUser!['full_name'] ??
                                _currentUser!['username'] ??
                                'User',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ==================== FORM UTAMA ====================
            _buildImageUploadSection(),
            const SizedBox(height: 20),

            // Field input judul film
            _buildTextField(
              controller: _titleController,
              label: 'Judul Film *',
              hint: 'Contoh: The Shawshank Redemption',
              icon: Icons.movie,
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // Field input tahun rilis dan durasi
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _yearController,
                    label: 'Tahun Rilis *',
                    hint: '1994',
                    icon: Icons.calendar_today,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    isRequired: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _durationController,
                    label: 'Durasi',
                    hint: '120 min',
                    icon: Icons.timer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Field input genre
            _buildTextField(
              controller: _genreController,
              label: 'Genre',
              hint: 'Action, Drama, Comedy',
              icon: Icons.category,
            ),
            const SizedBox(height: 16),

            // Field input sutradara
            _buildTextField(
              controller: _directorController,
              label: 'Sutradara',
              hint: 'Nama sutradara',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),

            // Field input deskripsi
            _buildTextField(
              controller: _descriptionController,
              label: 'Deskripsi (opsional)',
              hint: 'Deskripsi singkat tentang film...',
              icon: Icons.description,
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // ==================== RATING DAN FAVORIT ====================
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _ratingController,
                    label: 'Rating (0-10)',
                    hint: '8.5',
                    icon: Icons.star,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tandai Favorit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _isFavorite ? 'Favorit' : 'Bukan Favorit',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isFavorite ? Colors.red : Colors.grey,
                          ),
                        ),
                        value: _isFavorite,
                        onChanged: (value) {
                          setState(() {
                            _isFavorite = value;
                          });
                        },
                        activeColor: Colors.red,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ==================== STATUS MENONTON ====================
            const Text(
              'Status Menonton *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatusChip(
                    label: 'Rencana',
                    icon: Icons.schedule,
                    isSelected: _watchStatus == 'plan_to_watch',
                    color: Colors.orange,
                    onTap: () => setState(() => _watchStatus = 'plan_to_watch'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusChip(
                    label: 'Sedang',
                    icon: Icons.play_circle,
                    isSelected: _watchStatus == 'watching',
                    color: Colors.blue,
                    onTap: () => setState(() => _watchStatus = 'watching'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusChip(
                    label: 'Selesai',
                    icon: Icons.check_circle,
                    isSelected: _watchStatus == 'watched',
                    color: Colors.green,
                    onTap: () => setState(() => _watchStatus = 'watched'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ==================== PESAN ERROR ====================
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ==================== TOMBOL AKSI ====================
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    (_isLoading || _isUploadingImage || _currentUser == null)
                        ? null
                        : _addMovie,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _currentUser == null
                    ? const Text('Loading...')
                    : _isLoading || _isUploadingImage
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Menyimpan...'),
                            ],
                          )
                        : const Text(
                            'TAMBAH FILM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 12),

            // ==================== TOMBOL UTILITAS ====================
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _clearForm,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('Reset Form'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _fillExampleData,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.deepPurple),
                      ),
                      child: const Text(
                        'Contoh Lengkap',
                        style: TextStyle(color: Colors.deepPurple),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Membangun widget text field dengan konfigurasi tertentu
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    int? maxLength,
    bool isRequired = false,
  }) {
    final hasError =
        _showValidationErrors && controller.text.isEmpty && isRequired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: hasError ? Colors.red : Colors.black87,
                fontSize: 14,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor:
                hasError ? Colors.red.withOpacity(0.05) : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            errorText: hasError ? 'Field ini wajib diisi' : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 14,
            ),
          ),
        ),
      ],
    );
  }

  // Membangun widget untuk chip status menonton
  Widget _buildStatusChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _genreController.dispose();
    _directorController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _ratingController.dispose();
    super.dispose();
  }
}