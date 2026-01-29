<?php
/**
 * FILE: get_reviews.php
 * DESKRIPSI: Mendapatkan review film - Flutter version
 */

require_once 'config.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        sendError("Method not allowed", 405);
    }
    
    // Validasi parameter
    if (!isset($_GET['movie_id']) || $_GET['movie_id'] <= 0) {
        sendError("Parameter movie_id diperlukan");
    }
    
    $movie_id = intval($_GET['movie_id']);
    $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
    $sort = isset($_GET['sort']) ? cleanInput($_GET['sort']) : 'newest'; // newest, oldest, highest, lowest
    
    // Validasi pagination
    if ($page < 1) $page = 1;
    if ($limit < 1 || $limit > 50) $limit = 10;
    $offset = ($page - 1) * $limit;
    
    // Cek apakah film ada
    $checkQuery = "SELECT id, title FROM movies WHERE id = ?";
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
    
    // Tentukan sorting
    $orderBy = "r.created_at DESC";
    switch ($sort) {
        case 'oldest':
            $orderBy = "r.created_at ASC";
            break;
        case 'highest':
            $orderBy = "r.rating DESC, r.created_at DESC";
            break;
        case 'lowest':
            $orderBy = "r.rating ASC, r.created_at DESC";
            break;
        default:
            $orderBy = "r.created_at DESC";
    }
    
    // Ambil review dengan pagination
    $query = "SELECT 
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
    WHERE r.movie_id = ?
    ORDER BY $orderBy
    LIMIT ? OFFSET ?";
    
    $stmt = $connection->prepare($query);
    $stmt->bind_param("iii", $movie_id, $limit, $offset);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $reviews = [];
    $ratingDistribution = [1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0];
    $totalRating = 0;
    
    while ($row = $result->fetch_assoc()) {
        $reviews[] = $row;
        $totalRating += $row['rating'];
        $ratingDistribution[$row['rating']]++;
    }
    
    $stmt->close();
    
    // Hitung total review
    $countQuery = "SELECT COUNT(*) as total FROM reviews WHERE movie_id = ?";
    $stmt = $connection->prepare($countQuery);
    $stmt->bind_param("i", $movie_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $totalData = $result->fetch_assoc()['total'];
    $stmt->close();
    
    // Hitung statistik
    $averageRating = $totalData > 0 ? round($totalRating / $totalData, 1) : 0;
    $totalPages = ceil($totalData / $limit);
    
    sendSuccess("Berhasil mengambil review", [
        "movie" => [
            "id" => $movie_id,
            "title" => $movie['title']
        ],
        "reviews" => $reviews,
        "statistics" => [
            "average_rating" => $averageRating,
            "total_reviews" => (int)$totalData,
            "rating_distribution" => $ratingDistribution
        ],
        "pagination" => [
            "current_page" => $page,
            "total_pages" => $totalPages,
            "total_items" => (int)$totalData,
            "items_per_page" => $limit,
            "has_next_page" => $page < $totalPages,
            "has_prev_page" => $page > 1,
            "sort_by" => $sort
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Get Reviews Error: " . $e->getMessage());
    sendError("Error fetching reviews: " . $e->getMessage(), 500);
}
?>