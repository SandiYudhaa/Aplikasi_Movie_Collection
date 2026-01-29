<?php
/**
 * FILE: delete_movie.php
 * DESKRIPSI: Hapus film - Flutter version
 */

require_once 'config.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendError("Method not allowed", 405);
    }
    
    $data = getJsonInput();
    
    if (!isset($data['movie_id']) || $data['movie_id'] <= 0) {
        sendError("ID film tidak valid");
    }
    
    $movie_id = intval($data['movie_id']);
    $user_id = isset($data['user_id']) ? intval($data['user_id']) : null;
    
    // Ambil data film sebelum dihapus
    $getQuery = "SELECT 
        m.id,
        m.title,
        m.user_id,
        u.username,
        COUNT(r.id) as total_reviews
    FROM movies m
    LEFT JOIN users u ON m.user_id = u.id
    LEFT JOIN reviews r ON m.id = r.movie_id
    WHERE m.id = ?
    GROUP BY m.id";
    
    $stmt = $connection->prepare($getQuery);
    $stmt->bind_param("i", $movie_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        $stmt->close();
        sendError("Film tidak ditemukan", 404);
    }
    
    $movieData = $result->fetch_assoc();
    $stmt->close();
    
    // Cek permission jika user_id diberikan
    if ($user_id !== null && $movieData['user_id'] != $user_id) {
        sendError("Anda tidak memiliki izin menghapus film ini", 403);
    }
    
    // Mulai transaction
    $connection->begin_transaction();
    
    // 1. Hapus review terkait
    $deleteReviews = "DELETE FROM reviews WHERE movie_id = ?";
    $stmt1 = $connection->prepare($deleteReviews);
    $stmt1->bind_param("i", $movie_id);
    $stmt1->execute();
    $deletedReviews = $stmt1->affected_rows;
    $stmt1->close();
    
    // 2. Hapus film
    $deleteMovie = "DELETE FROM movies WHERE id = ?";
    $stmt2 = $connection->prepare($deleteMovie);
    $stmt2->bind_param("i", $movie_id);
    $stmt2->execute();
    $deletedMovie = $stmt2->affected_rows;
    $stmt2->close();
    
    if ($deletedMovie === 0) {
        throw new Exception("Failed to delete movie");
    }
    
    // Commit transaction
    $connection->commit();
    
    sendSuccess("Film berhasil dihapus", [
        "deleted_movie" => [
            "id" => $movieData['id'],
            "title" => $movieData['title'],
            "user_id" => $movieData['user_id'],
            "username" => $movieData['username']
        ],
        "statistics" => [
            "movie_deleted" => true,
            "reviews_deleted" => $deletedReviews,
            "total_items_deleted" => 1 + $deletedReviews
        ],
        "message" => "Film '{$movieData['title']}' telah dihapus dari koleksi"
    ]);
    
} catch (Exception $e) {
    // Rollback jika error
    if ($connection) {
        $connection->rollback();
    }
    error_log("Delete Movie Error: " . $e->getMessage());
    sendError("Gagal menghapus film: " . $e->getMessage(), 500);
}
?>