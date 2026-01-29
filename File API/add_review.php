<?php
/**
 * FILE: add_review.php
 * DESKRIPSI: Tambah review - Flutter version
 */

require_once 'config.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendError("Method not allowed", 405);
    }
    
    $data = getJsonInput();
    validateRequired($data, ['user_id', 'movie_id', 'rating', 'comment']);
    
    $user_id = intval($data['user_id']);
    $movie_id = intval($data['movie_id']);
    $rating = intval($data['rating']);
    $comment = cleanInput($data['comment']);
    
    // Validasi data
    if ($user_id <= 0 || $movie_id <= 0) {
        sendError("User ID atau Movie ID tidak valid");
    }
    
    if ($rating < 1 || $rating > 5) {
        sendError("Rating harus antara 1-5");
    }
    
    if (strlen($comment) < 3) {
        sendError("Komentar minimal 3 karakter");
    }
    
    // Cek apakah user dan movie ada
    $checkUser = "SELECT id FROM users WHERE id = ?";
    $stmt = $connection->prepare($checkUser);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    
    if ($stmt->get_result()->num_rows === 0) {
        $stmt->close();
        sendError("User tidak ditemukan", 404);
    }
    $stmt->close();
    
    // Cek movie
    $checkMovie = "SELECT id, title FROM movies WHERE id = ?";
    $stmt = $connection->prepare($checkMovie);
    $stmt->bind_param("i", $movie_id);
    $stmt->execute();
    $movieResult = $stmt->get_result();
    
    if ($movieResult->num_rows === 0) {
        $stmt->close();
        sendError("Film tidak ditemukan", 404);
    }
    
    $movie = $movieResult->fetch_assoc();
    $stmt->close();
    
    // Cek apakah user sudah mereview film ini
    $checkReview = "SELECT id FROM reviews WHERE user_id = ? AND movie_id = ?";
    $stmt = $connection->prepare($checkReview);
    $stmt->bind_param("ii", $user_id, $movie_id);
    $stmt->execute();
    
    if ($stmt->get_result()->num_rows > 0) {
        $stmt->close();
        sendError("Anda sudah memberikan review untuk film ini", 400);
    }
    $stmt->close();
    
    // Tambahkan review
    $insertQuery = "INSERT INTO reviews (user_id, movie_id, rating, comment) VALUES (?, ?, ?, ?)";
    $stmt = $connection->prepare($insertQuery);
    $stmt->bind_param("iiis", $user_id, $movie_id, $rating, $comment);
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to insert review: " . $stmt->error);
    }
    
    $review_id = $stmt->insert_id;
    $stmt->close();
    
    // Ambil data review lengkap
    $getReview = "SELECT 
        r.id,
        r.user_id,
        r.movie_id,
        r.rating,
        r.comment,
        r.created_at,
        u.username,
        u.full_name,
        u.email
    FROM reviews r
    JOIN users u ON r.user_id = u.id
    WHERE r.id = ?";
    
    $stmt = $connection->prepare($getReview);
    $stmt->bind_param("i", $review_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $review = $result->fetch_assoc();
    $stmt->close();
    
    // Hitung statistik baru
    $statsQuery = "SELECT 
        AVG(rating) as avg_rating,
        COUNT(*) as total_reviews
    FROM reviews 
    WHERE movie_id = ?";
    
    $stmt = $connection->prepare($statsQuery);
    $stmt->bind_param("i", $movie_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $stats = $result->fetch_assoc();
    $stmt->close();
    
    $stats['avg_rating'] = round((float)$stats['avg_rating'], 1);
    
    sendSuccess("Review berhasil ditambahkan", [
        "review" => $review,
        "movie" => [
            "id" => $movie_id,
            "title" => $movie['title'],
            "new_rating_stats" => $stats
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Add Review Error: " . $e->getMessage());
    sendError("Gagal menambahkan review: " . $e->getMessage(), 500);
}
?>