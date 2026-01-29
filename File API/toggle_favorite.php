<?php
/**
 * FILE: toggle_favorite.php
 * DESKRIPSI: Toggle favorite status - Flutter version
 */

require_once 'config.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendError("Method not allowed", 405);
    }
    
    $data = getJsonInput();
    
    // Validasi input
    if (!isset($data['movie_id']) || !isset($data['is_favorite'])) {
        sendError("movie_id dan is_favorite harus diisi");
    }
    
    $movie_id = intval($data['movie_id']);
    $is_favorite = intval($data['is_favorite']);
    
    if ($movie_id <= 0) {
        sendError("Movie ID tidak valid");
    }
    
    if ($is_favorite !== 0 && $is_favorite !== 1) {
        sendError("is_favorite harus 0 atau 1");
    }
    
    // Cek apakah film ada
    $checkQuery = "SELECT id, title, is_favorite FROM movies WHERE id = ?";
    $stmt = $connection->prepare($checkQuery);
    $stmt->bind_param("i", $movie_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        $stmt->close();
        sendError("Film tidak ditemukan", 404);
    }
    
    $movie = $result->fetch_assoc();
    $stmt->close();
    
    // Cek jika status sudah sama
    if ($movie['is_favorite'] == $is_favorite) {
        $statusText = $is_favorite == 1 ? "sudah favorit" : "sudah bukan favorit";
        sendSuccess("Film '{$movie['title']}' $statusText", [
            "movie_id" => $movie_id,
            "current_status" => (bool)$is_favorite,
            "changed" => false
        ]);
    }
    
    // Update status
    $updateQuery = "UPDATE movies SET is_favorite = ?, updated_at = NOW() WHERE id = ?";
    $stmt = $connection->prepare($updateQuery);
    $stmt->bind_param("ii", $is_favorite, $movie_id);
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to update favorite status: " . $stmt->error);
    }
    
    $stmt->close();
    
    // Ambil data terbaru
    $getQuery = "SELECT 
        m.*,
        u.username as user_username
    FROM movies m
    LEFT JOIN users u ON m.user_id = u.id
    WHERE m.id = ?";
    
    $stmt = $connection->prepare($getQuery);
    $stmt->bind_param("i", $movie_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $updatedMovie = $result->fetch_assoc();
    $stmt->close();
    
    // Format boolean untuk Flutter
    $updatedMovie['is_favorite'] = (bool)$updatedMovie['is_favorite'];
    
    $action = $is_favorite == 1 ? "ditambahkan ke" : "dihapus dari";
    
    sendSuccess("Film '{$movie['title']}' berhasil $action favorit", [
        "movie" => $updatedMovie,
        "previous_status" => (bool)$movie['is_favorite'],
        "new_status" => (bool)$is_favorite,
        "changed" => true
    ]);
    
} catch (Exception $e) {
    error_log("Toggle Favorite Error: " . $e->getMessage());
    sendError("Gagal mengubah status favorit: " . $e->getMessage(), 500);
}
?>