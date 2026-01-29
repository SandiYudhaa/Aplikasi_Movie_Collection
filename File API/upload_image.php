<?php
/**
 * FILE: upload_image.php
 * DESKRIPSI: Upload gambar untuk film (optimized for serv00.net)
 * VERSI: 2.0
 */

// ============================================
// LOAD CONFIG DAN FUNGSI
// ============================================
require_once 'config.php';

try {
    // ============================================
    // CEK METHOD REQUEST
    // ============================================
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendError("Method not allowed. Use POST method.", 405);
    }
    
    // ============================================
    // CEK APAKAH ADA FILE YANG DIUPLOAD
    // ============================================
    if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
        sendError("No image uploaded or upload error", 400);
    }
    
    $file = $_FILES['image'];
    
    // ============================================
    // VALIDASI FILE
    // ============================================
    $allowedTypes = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/gif' => 'gif',
        'image/webp' => 'webp'
    ];
    
    // Cek MIME type
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $fileType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);
    
    if (!array_key_exists($fileType, $allowedTypes)) {
        sendError("Invalid file type. Allowed: JPG, PNG, GIF, WebP", 400);
    }
    
    // ============================================
    // VALIDASI UKURAN FILE (MAX 3MB)
    // ============================================
    $maxSize = 3 * 1024 * 1024; // 3MB
    if ($file['size'] > $maxSize) {
        sendError("File size too large. Maximum 3MB", 400);
    }
    
    // ============================================
    // VALIDASI DIMENSI GAMBAR (OPSIONAL)
    // ============================================
    $imageInfo = getimagesize($file['tmp_name']);
    if (!$imageInfo) {
        sendError("Invalid image file", 400);
    }
    
    // Dimensi maksimal
    $maxWidth = 2000;
    $maxHeight = 2000;
    
    if ($imageInfo[0] > $maxWidth || $imageInfo[1] > $maxHeight) {
        sendError("Image dimensions too large. Maximum: {$maxWidth}x{$maxHeight}px", 400);
    }
    
    // ============================================
    // GENERATE NAMA FILE YANG AMAN
    // ============================================
    $extension = $allowedTypes[$fileType];
    $safeFilename = preg_replace('/[^a-zA-Z0-9\-\._]/', '', basename($file['name']));
    $safeFilename = substr($safeFilename, 0, 100);
    $timestamp = time();
    $randomString = bin2hex(random_bytes(8));
    
    $fileName = "movie_{$timestamp}_{$randomString}.{$extension}";
    
    // ============================================
    // FOLDER PENYIMPANAN
    // ============================================
    $uploadDir = 'uploads/';
    
    // Buat folder jika belum ada
    if (!file_exists($uploadDir)) {
        if (!mkdir($uploadDir, 0755, true)) {
            sendError("Failed to create upload directory", 500);
        }
        
        // Tambah .htaccess untuk proteksi
        $htaccess = $uploadDir . '.htaccess';
        if (!file_exists($htaccess)) {
            file_put_contents($htaccess, "Options -Indexes\nDeny from all\n<FilesMatch '\.(jpg|jpeg|png|gif|webp)$'>\nOrder Allow,Deny\nAllow from all\n</FilesMatch>");
        }
    }
    
    // ============================================
    // PATH LENGKAP UNTUK DISIMPAN
    // ============================================
    $uploadPath = $uploadDir . $fileName;
    
    // ============================================
    // PINDHKAN FILE KE SERVER
    // ============================================
    if (!move_uploaded_file($file['tmp_name'], $uploadPath)) {
        sendError("Failed to save uploaded file", 500);
    }
    
    // ============================================
    // COMPRESS IMAGE (OPSIONAL - UNTUK MENGURANGI UKURAN)
    // ============================================
    if ($fileType === 'image/jpeg') {
        compressImage($uploadPath, 75); // Quality 75%
    } elseif ($fileType === 'image/png') {
        compressImage($uploadPath, 7); // Compression level 7 (0-9)
    }
    
    // ============================================
    // GENERATE URL UNTUK AKSES GAMBAR
    // ============================================
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
    $host = $_SERVER['HTTP_HOST'];
    $scriptPath = dirname($_SERVER['SCRIPT_NAME']);
    
    // Bersihkan path
    $scriptPath = rtrim($scriptPath, '/');
    $uploadDir = trim($uploadDir, './');
    
    $baseUrl = "{$protocol}://{$host}{$scriptPath}/{$uploadDir}";
    $imageUrl = "{$baseUrl}{$fileName}";
    
    // ============================================
    // SIMPAN INFO GAMBAR KE DATABASE (OPSIONAL)
    // ============================================
    try {
        $userId = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
        
        $insertQuery = "INSERT INTO uploaded_images 
                       (filename, original_name, file_type, file_size, user_id, created_at) 
                       VALUES (?, ?, ?, ?, ?, NOW())";
        
        $stmt = $connection->prepare($insertQuery);
        $originalName = cleanInput($file['name']);
        
        $stmt->bind_param("sssii", 
            $fileName, 
            $originalName, 
            $fileType, 
            $file['size'],
            $userId
        );
        
        if ($stmt->execute()) {
            $imageId = $stmt->insert_id;
        }
        
        $stmt->close();
    } catch (Exception $dbError) {
        // Ignore database error, continue with response
        error_log("Database log error (non-critical): " . $dbError->getMessage());
    }
    
    // ============================================
    // RESPONSE SUKSES
    // ============================================
    $responseData = [
        "success" => true,
        "message" => "Image uploaded successfully",
        "image_url" => $imageUrl,
        "image_info" => [
            "filename" => $fileName,
            "original_name" => $file['name'],
            "file_type" => $fileType,
            "file_size" => $file['size'],
            "dimensions" => [
                "width" => $imageInfo[0],
                "height" => $imageInfo[1]
            ],
            "uploaded_at" => date('Y-m-d H:i:s')
        ]
    ];
    
    // Tambah image_id jika berhasil disimpan ke database
    if (isset($imageId)) {
        $responseData["image_id"] = $imageId;
    }
    
    sendSuccess("Image uploaded successfully", $responseData);
    
} catch (Exception $e) {
    error_log("Upload Image Error: " . $e->getMessage());
    sendError("Failed to upload image: " . $e->getMessage(), 500);
}

// ============================================
// FUNGSI KOMPRESI GAMBAR
// ============================================
function compressImage($sourcePath, $quality = 75) {
    $imageInfo = getimagesize($sourcePath);
    if (!$imageInfo) {
        return false;
    }
    
    $mime = $imageInfo['mime'];
    
    try {
        switch ($mime) {
            case 'image/jpeg':
                $image = imagecreatefromjpeg($sourcePath);
                if ($image) {
                    imagejpeg($image, $sourcePath, $quality);
                    imagedestroy($image);
                }
                break;
                
            case 'image/png':
                $image = imagecreatefrompng($sourcePath);
                if ($image) {
                    // PNG quality adalah 0-9 (0 = no compression, 9 = max compression)
                    $compression = ($quality > 9) ? 9 : (int)$quality;
                    imagepng($image, $sourcePath, $compression);
                    imagedestroy($image);
                }
                break;
                
            case 'image/gif':
                $image = imagecreatefromgif($sourcePath);
                if ($image) {
                    imagegif($image, $sourcePath);
                    imagedestroy($image);
                }
                break;
                
            case 'image/webp':
                $image = imagecreatefromwebp($sourcePath);
                if ($image) {
                    imagewebp($image, $sourcePath, $quality);
                    imagedestroy($image);
                }
                break;
        }
        
        return true;
    } catch (Exception $e) {
        error_log("Image compression error: " . $e->getMessage());
        return false;
    }
}

// ============================================
// FUNGSI TAMBAHAN UNTUK CLEANUP FILE LAMA
// ============================================
function cleanupOldFiles($uploadDir, $maxAgeDays = 30) {
    if (!is_dir($uploadDir)) {
        return;
    }
    
    $files = glob($uploadDir . "movie_*");
    $now = time();
    $maxAge = $maxAgeDays * 24 * 60 * 60;
    
    foreach ($files as $file) {
        if (is_file($file)) {
            // Hapus file yang lebih tua dari $maxAgeDays
            if ($now - filemtime($file) > $maxAge) {
                @unlink($file);
            }
        }
    }
}

// Eksekusi cleanup secara berkala (10% chance setiap request)
if (rand(1, 10) === 1) {
    cleanupOldFiles('uploads/', 30);
}

?>