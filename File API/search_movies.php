<?php
/**
 * FILE: search_movies.php
 * DESKRIPSI: Pencarian film dengan berbagai kriteria
 */

require_once 'config.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        sendError("Method not allowed", 405);
    }
    
    // Ambil parameter pencarian
    $query = isset($_GET['q']) ? cleanInput($_GET['q']) : '';
    $genre = isset($_GET['genre']) ? cleanInput($_GET['genre']) : '';
    $year = isset($_GET['year']) ? cleanInput($_GET['year']) : '';
    $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
    
    if (empty($query) && empty($genre) && empty($year)) {
        sendError("Harap masukkan kata kunci pencarian", 400);
    }
    
    // Validasi pagination
    if ($page < 1) $page = 1;
    if ($limit < 1 || $limit > 50) $limit = 10;
    $offset = ($page - 1) * $limit;
    
    // Bangun query pencarian
    $whereConditions = [];
    $params = [];
    $paramTypes = "";
    
    if (!empty($query)) {
        $whereConditions[] = "(m.title LIKE ? OR m.director LIKE ? OR m.description LIKE ?)";
        $searchTerm = "%" . $query . "%";
        $params[] = $searchTerm;
        $params[] = $searchTerm;
        $params[] = $searchTerm;
        $paramTypes .= "sss";
    }
    
    if (!empty($genre)) {
        $whereConditions[] = "m.genre LIKE ?";
        $params[] = "%" . $genre . "%";
        $paramTypes .= "s";
    }
    
    if (!empty($year)) {
        $whereConditions[] = "m.year = ?";
        $params[] = $year;
        $paramTypes .= "s";
    }
    
    // Query count
    $countQuery = "SELECT COUNT(*) as total FROM movies m";
    if (!empty($whereConditions)) {
        $countQuery .= " WHERE " . implode(" AND ", $whereConditions);
    }
    
    $countStmt = $connection->prepare($countQuery);
    if (!empty($params)) {
        $countStmt->bind_param($paramTypes, ...$params);
    }
    $countStmt->execute();
    $countResult = $countStmt->get_result();
    $totalData = $countResult->fetch_assoc()['total'];
    $countStmt->close();
    
    // Query utama
    $mainQuery = "SELECT 
        m.id,
        m.title,
        m.year,
        m.genre,
        m.director,
        m.duration,
        m.poster_url,
        m.watch_status,
        m.is_favorite,
        u.username as user_username,
        COALESCE(AVG(r.rating), 0) as average_rating
    FROM movies m
    LEFT JOIN users u ON m.user_id = u.id
    LEFT JOIN reviews r ON m.id = r.movie_id";
    
    if (!empty($whereConditions)) {
        $mainQuery .= " WHERE " . implode(" AND ", $whereConditions);
    }
    
    $mainQuery .= " GROUP BY m.id ORDER BY m.created_at DESC LIMIT ? OFFSET ?";
    
    // Tambah parameter pagination
    $params[] = $limit;
    $params[] = $offset;
    $paramTypes .= "ii";
    
    $stmt = $connection->prepare($mainQuery);
    $stmt->bind_param($paramTypes, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $movies = [];
    while ($row = $result->fetch_assoc()) {
        $row['average_rating'] = round((float)$row['average_rating'], 1);
        $row['is_favorite'] = (bool)$row['is_favorite'];
        $movies[] = $row;
    }
    
    $stmt->close();
    
    // Hitung pagination
    $totalPages = ceil($totalData / $limit);
    
    sendSuccess("Hasil pencarian ditemukan", [
        "search_results" => $movies,
        "search_metadata" => [
            "query" => $query,
            "genre" => $genre,
            "year" => $year,
            "total_results" => (int)$totalData
        ],
        "pagination" => [
            "current_page" => $page,
            "total_pages" => $totalPages,
            "results_per_page" => $limit,
            "has_more_results" => $page < $totalPages
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Search Movies Error: " . $e->getMessage());
    sendError("Error searching movies: " . $e->getMessage(), 500);
}
?>