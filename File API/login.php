<?php
/**
 * FILE: login.php
 * DESKRIPSI: API Login untuk Flutter Movie Collection - VERSI FIXED
 * ENDPOINT: https://pencarijawabankaisen.my.id/pencari2_sandi_api/login.php
 * METHOD: POST
 */

require_once 'config.php';

try {
    // LOG: Mulai proses login
    error_log("=== LOGIN PROCESS STARTED ===");
    
    // Cek method request
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        error_log("Method not allowed: " . $_SERVER['REQUEST_METHOD']);
        sendError("Method not allowed. Use POST method.", 405);
    }
    
    // Ambil data JSON dari Flutter
    error_log("Getting JSON input...");
    $data = getJsonInput();
    
    if (empty($data)) {
        error_log("Empty JSON data received");
        sendError("Request data cannot be empty", 400);
    }
    
    // Validasi field wajib
    validateRequired($data, ['username', 'password']);
    error_log("Required fields validated");
    
    // Sanitize input (gunakan sanitizeInput() yang sudah ada)
    $username = sanitizeInput($data['username']);
    $password = $data['password']; // Password tidak di-sanitize untuk verifikasi
    
    error_log("Login attempt for username/email: $username");
    
    // ============================
    // CEK USER DI DATABASE
    // ============================
    $sql = "SELECT id, username, password, email, full_name, created_at 
            FROM users 
            WHERE username = ? OR email = ? 
            LIMIT 1";
    
    $stmt = $connection->prepare($sql);
    
    if (!$stmt) {
        error_log("Prepare statement failed: " . $connection->error);
        sendError("Database error", 500);
    }
    
    $stmt->bind_param("ss", $username, $username);
    
    if (!$stmt->execute()) {
        error_log("Execute failed: " . $stmt->error);
        $stmt->close();
        sendError("Database query error", 500);
    }
    
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        $stmt->close();
        error_log("User not found: $username");
        sendError("Username or password is incorrect", 401);
    }
    
    $user = $result->fetch_assoc();
    $stmt->close();
    
    error_log("User found: " . $user['username'] . " (ID: " . $user['id'] . ")");
    
    // ============================
    // VERIFIKASI PASSWORD
    // ============================
    if (!password_verify($password, $user['password'])) {
        error_log("Password verification failed for user: " . $user['username']);
        sendError("Username or password is incorrect", 401);
    }
    
    error_log("Password verified successfully");
    
    // ============================
    // PREPARE USER DATA RESPONSE
    // ============================
    $user_data = [
        'id' => (int)$user['id'],
        'username' => $user['username'],
        'email' => $user['email'],
        'full_name' => $user['full_name'],
        'created_at' => $user['created_at']
    ];
    
    // ============================
    // GENERATE TOKEN
    // ============================
    error_log("Generating token...");
    $token = generateToken($user_data);
    
    // ============================
    // RESPONSE SUKSES
    // ============================
    error_log("Login successful for user: " . $user['username']);
    
    sendSuccess("Login successful", [
        'user' => $user_data,
        'token' => $token,
        'token_type' => 'Bearer',
        'expires_in' => 604800, // 7 hari dalam detik
        'expires_at' => date('Y-m-d H:i:s', time() + 604800)
    ]);
    
} catch (Exception $e) {
    error_log("Login Exception: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    sendError("Login failed. Please try again.", 500);
}
?>