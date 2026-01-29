<?php
/**
 * FILE: get_user_movies.php
 * DESKRIPSI: Mendapatkan film berdasarkan user dengan statistik
 */

require_once 'config.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        sendError("Method not allowed", 405);
    }
    
    // Validasi parameter user_id
    if (!isset($_GET['user_id']) || $_GET['user_id'] <= 0) {
        sendError("Parameter user_id diperlukan");
    }
    
    $user_id = intval($_GET['user_id']);
    
    // Cek apakah user ada
    $checkUser = "SELECT id, username, full_name FROM users WHERE id = ?";
    $stmt = $connection->prepare($checkUser);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        $stmt->close();
        sendError("User tidak ditemukan", 404);
    }
    
    $user = $result->fetch_assoc();
    $stmt->close();
    
    // Hitung statistik user
    $statsQuery = "SELECT 
        COUNT(*) as total_movies,
        SUM(CASE WHEN is_favorite = 1 THEN 1 ELSE 0 END) as favorite_movies,
        SUM(CASE WHEN watch_status = 'plan_to_watch' THEN 1 ELSE 0 END) as plan_to_watch,
        SUM(CASE WHEN watch_status = 'watching' THEN 1 ELSE 0 END) as watching,
        SUM(CASE WHEN watch_status = 'watched' THEN 1 ELSE 0 END) as watched
    FROM movies 
    WHERE user_id = ?";
    
    $stmt = $connection->prepare($statsQuery);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $stats = $result->fetch_assoc();
    $stmt->close();
    
    // Konversi ke integer
    foreach ($stats as $key => $value) {
        $stats[$key] = (int)$value;
    }
    
    // Ambil film terbaru user (limit 5)
    $moviesQuery = "SELECT 
        m.id,
        m.title,
        m.year,
        m.genre,
        m.poster_url,
        m.watch_status,
        m.is_favorite,
        m.created_at
    FROM movies m
    WHERE m.user_id = ?
    ORDER BY m.created_at DESC
    LIMIT 5";
    
    $stmt = $connection->prepare($moviesQuery);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $recent_movies = [];
    while ($row = $result->fetch_assoc()) {
        $row['is_favorite'] = (bool)$row['is_favorite'];
        $recent_movies[] = $row;
    }
    
    $stmt->close();
    
    sendSuccess("Berhasil mengambil data user", [
        "user" => $user,
        "statistics" => $stats,
        "recent_movies" => $recent_movies
    ]);
    
} catch (Exception $e) {
    error_log("Get User Movies Error: " . $e->getMessage());
    sendError("Error fetching user movies: " . $e->getMessage(), 500);
}
?>