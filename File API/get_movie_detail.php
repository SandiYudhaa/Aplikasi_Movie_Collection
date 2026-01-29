<?php
/**
 * FILE: get_movie_detail.php
 * DESKRIPSI: Mendapatkan detail lengkap film dengan review
 */

require_once 'config.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        sendError("Method not allowed", 405);
    }
    
    if (!isset($_GET['movie_id']) || $_GET['movie_id'] <= 0) {
        sendError("Parameter movie_id diperlukan");
    }
    
    $movie_id = intval($_GET['movie_id']);
    
    // Ambil detail film lengkap
    $query = "SELECT 
        m.id,
        m.user_id,
        m.title,
        m.year,
        m.genre,
        m.director,
        m.duration,
        m.poster_url,
        m.description,
        m.watch_status,
        m.is_favorite,
        m.created_at,
        m.updated_at,
        u.username as user_username,
        u.full_name as user_full_name,
        u.email as user_email,
        COALESCE(AVG(r.rating), 0) as average_rating,
        COUNT(r.id) as total_reviews,
        COUNT(CASE WHEN r.rating = 5 THEN 1 END) as rating_5,
        COUNT(CASE WHEN r.rating = 4 THEN 1 END) as rating_4,
        COUNT(CASE WHEN r.rating = 3 THEN 1 END) as rating_3,
        COUNT(CASE WHEN r.rating = 2 THEN 1 END) as rating_2,
        COUNT(CASE WHEN r.rating = 1 THEN 1 END) as rating_1
    FROM movies m
    LEFT JOIN users u ON m.user_id = u.id
    LEFT JOIN reviews r ON m.id = r.movie_id
    WHERE m.id = ?
    GROUP BY m.id";
    
    $stmt = $connection->prepare($query);
    $stmt->bind_param("i", $movie_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        $stmt->close();
        sendError("Film tidak ditemukan", 404);
    }
    
    $movie = $result->fetch_assoc();
    $stmt->close();
    
    // Format data
    $movie['average_rating'] = round((float)$movie['average_rating'], 1);
    $movie['is_favorite'] = (bool)$movie['is_favorite'];
    $movie['total_reviews'] = (int)$movie['total_reviews'];
    
    // Rating distribution
    $ratingDistribution = [
        5 => (int)$movie['rating_5'],
        4 => (int)$movie['rating_4'],
        3 => (int)$movie['rating_3'],
        2 => (int)$movie['rating_2'],
        1 => (int)$movie['rating_1']
    ];
    
    // Hapus kolom rating individual
    unset($movie['rating_5'], $movie['rating_4'], $movie['rating_3'], 
          $movie['rating_2'], $movie['rating_1']);
    
    // Ambil 3 review terbaru
    $reviewsQuery = "SELECT 
        r.id,
        r.rating,
        r.comment,
        r.created_at,
        u.username,
        u.full_name
    FROM reviews r
    JOIN users u ON r.user_id = u.id
    WHERE r.movie_id = ?
    ORDER BY r.created_at DESC
    LIMIT 3";
    
    $stmt = $connection->prepare($reviewsQuery);
    $stmt->bind_param("i", $movie_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $recent_reviews = [];
    while ($row = $result->fetch_assoc()) {
        $recent_reviews[] = $row;
    }
    
    $stmt->close();
    
    sendSuccess("Berhasil mengambil detail film", [
        "movie" => $movie,
        "rating_distribution" => $ratingDistribution,
        "recent_reviews" => $recent_reviews
    ]);
    
} catch (Exception $e) {
    error_log("Get Movie Detail Error: " . $e->getMessage());
    sendError("Error fetching movie details", 500);
}
?>