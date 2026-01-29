<?php
/**
 * FILE: get_all_movies.php
 * DESKRIPSI: Mendapatkan semua film dengan pagination
 */

require_once 'config.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        sendError("Method not allowed", 405);
    }
    
    // Pagination parameters
    $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
    $sort_by = isset($_GET['sort_by']) ? cleanInput($_GET['sort_by']) : 'created_at';
    $order = isset($_GET['order']) ? cleanInput($_GET['order']) : 'DESC';
    
    // Validasi
    if ($page < 1) $page = 1;
    if ($limit < 1 || $limit > 50) $limit = 10;
    $offset = ($page - 1) * $limit;
    
    // Validasi sort dan order
    $allowed_sort = ['created_at', 'title', 'year', 'average_rating'];
    $allowed_order = ['ASC', 'DESC'];
    
    if (!in_array($sort_by, $allowed_sort)) {
        $sort_by = 'created_at';
    }
    if (!in_array($order, $allowed_order)) {
        $order = 'DESC';
    }
    
    // Hitung total data
    $countQuery = "SELECT COUNT(*) as total FROM movies";
    $countResult = $connection->query($countQuery);
    $totalData = $countResult->fetch_assoc()['total'];
    
    // Query utama dengan rating
    $query = "SELECT 
        m.*,
        u.username as user_username,
        u.full_name as user_full_name,
        COALESCE(AVG(r.rating), 0) as average_rating,
        COUNT(r.id) as total_reviews
    FROM movies m
    LEFT JOIN users u ON m.user_id = u.id
    LEFT JOIN reviews r ON m.id = r.movie_id
    GROUP BY m.id
    ORDER BY $sort_by $order
    LIMIT ? OFFSET ?";
    
    $stmt = $connection->prepare($query);
    $stmt->bind_param("ii", $limit, $offset);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $movies = [];
    while ($row = $result->fetch_assoc()) {
        $row['is_favorite'] = (bool)$row['is_favorite'];
        $row['average_rating'] = round((float)$row['average_rating'], 1);
        $row['total_reviews'] = (int)$row['total_reviews'];
        $movies[] = $row;
    }
    
    $stmt->close();
    
    // Hitung pagination
    $totalPages = ceil($totalData / $limit);
    
    sendSuccess("Berhasil mengambil data film", [
        "movies" => $movies,
        "pagination" => [
            "current_page" => $page,
            "total_pages" => $totalPages,
            "total_items" => (int)$totalData,
            "items_per_page" => $limit,
            "has_next_page" => $page < $totalPages,
            "has_prev_page" => $page > 1
        ],
        "sorting" => [
            "sort_by" => $sort_by,
            "order" => $order
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Get All Movies Error: " . $e->getMessage());
    sendError("Gagal mengambil data film", 500);
}
?>