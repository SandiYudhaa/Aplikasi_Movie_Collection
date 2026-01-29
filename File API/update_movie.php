<?php
/**
 * FILE: update_movie.php
 * DESKRIPSI: Update film - Flutter version
 */

require_once 'config.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendError("Method not allowed", 405);
    }
    
    $data = getJsonInput();
    
    // Validasi ID film
    if (!isset($data['id']) || $data['id'] <= 0) {
        sendError("ID film tidak valid");
    }
    
    $movie_id = intval($data['id']);
    
    // Cek apakah film ada
    $checkQuery = "SELECT id, title FROM movies WHERE id = ?";
    $checkStmt = $connection->prepare($checkQuery);
    $checkStmt->bind_param("i", $movie_id);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();
    
    if ($checkResult->num_rows === 0) {
        $checkStmt->close();
        sendError("Film tidak ditemukan", 404);
    }
    
    $existingMovie = $checkResult->fetch_assoc();
    $checkStmt->close();
    
    // Prepare update fields
    $updateFields = [];
    $updateValues = [];
    $paramTypes = "";
    
    $fields = [
        'title' => 's',
        'year' => 's',
        'genre' => 's',
        'director' => 's',
        'duration' => 's',
        'poster_url' => 's',
        'description' => 's',
        'watch_status' => 's',
        'is_favorite' => 'i'
    ];
    
    foreach ($fields as $field => $type) {
        if (isset($data[$field])) {
            $updateFields[] = "$field = ?";
            
            if ($field === 'is_favorite') {
                $updateValues[] = intval($data[$field]);
            } else {
                $updateValues[] = cleanInput($data[$field]);
            }
            
            $paramTypes .= $type;
        }
    }
    
    // Validasi jika ada field yang diupdate
    if (empty($updateFields)) {
        sendError("Tidak ada data yang diupdate");
    }
    
    // Validasi watch_status jika diupdate
    if (isset($data['watch_status'])) {
        $validStatuses = ['plan_to_watch', 'watching', 'watched'];
        if (!in_array($data['watch_status'], $validStatuses)) {
            sendError("watch_status tidak valid. Pilih: plan_to_watch, watching, atau watched");
        }
    }
    
    // Validasi is_favorite jika diupdate
    if (isset($data['is_favorite']) && $data['is_favorite'] !== 0 && $data['is_favorite'] !== 1) {
        sendError("is_favorite harus 0 atau 1");
    }
    
    // Tambahkan updated_at
    $updateFields[] = "updated_at = NOW()";
    
    // Bangun dan eksekusi query
    $updateQuery = "UPDATE movies SET " . implode(", ", $updateFields) . " WHERE id = ?";
    $updateValues[] = $movie_id;
    $paramTypes .= "i";
    
    $stmt = $connection->prepare($updateQuery);
    $stmt->bind_param($paramTypes, ...$updateValues);
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to update movie: " . $stmt->error);
    }
    
    $affectedRows = $stmt->affected_rows;
    $stmt->close();
    
    // Jika ada perubahan, ambil data terbaru
    if ($affectedRows > 0) {
        $getQuery = "SELECT 
            m.*,
            u.username as user_username,
            u.full_name as user_full_name
        FROM movies m
        LEFT JOIN users u ON m.user_id = u.id
        WHERE m.id = ?";
        
        $getStmt = $connection->prepare($getQuery);
        $getStmt->bind_param("i", $movie_id);
        $getStmt->execute();
        $result = $getStmt->get_result();
        $updatedMovie = $result->fetch_assoc();
        $getStmt->close();
        
        // Format boolean untuk Flutter
        $updatedMovie['is_favorite'] = (bool)$updatedMovie['is_favorite'];
        
        sendSuccess("Film berhasil diupdate", [
            "movie" => $updatedMovie,
            "changes_made" => count($updateFields) - 1 // minus updated_at
        ]);
    } else {
        sendSuccess("Tidak ada perubahan data", [
            "movie_id" => $movie_id
        ]);
    }
    
} catch (Exception $e) {
    error_log("Update Movie Error: " . $e->getMessage());
    sendError("Gagal mengupdate film: " . $e->getMessage(), 500);
}
?>