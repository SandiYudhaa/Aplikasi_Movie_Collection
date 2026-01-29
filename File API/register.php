<?php
/**
 * FILE: register.php
 * DESKRIPSI: API Register untuk Flutter Movie Collection - VERSI FIXED
 * ENDPOINT: https://pencarijawabankaisen.my.id/pencari2_sandi_api/register.php
 * METHOD: POST
 */

require_once 'config.php';

try {
    // LOG: Mulai proses register
    error_log("=== REGISTER PROCESS STARTED ===");
    
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
    
    error_log("Received data: " . json_encode($data));
    
    // Validasi field wajib
    validateRequired($data, ['username', 'password', 'email', 'full_name']);
    error_log("Required fields validated");
    
    // Sanitize input (gunakan sanitizeInput() bukan cleanInput())
    $username = sanitizeInput($data['username']);
    $password = $data['password']; // Password tidak di-sanitize untuk hash
    $email = strtolower(sanitizeInput($data['email']));
    $full_name = sanitizeInput($data['full_name']);
    
    error_log("Sanitized - Username: $username, Email: $email, Name: $full_name");
    
    // ============================
    // VALIDASI LENGKAP
    // ============================
    
    // Validasi Username
    if (strlen($username) < 3) {
        error_log("Username too short: $username");
        sendError("Username must be at least 3 characters", 400);
    }
    
    if (strlen($username) > 50) {
        error_log("Username too long: $username");
        sendError("Username maximum 50 characters", 400);
    }
    
    if (!preg_match('/^[a-zA-Z0-9_]+$/', $username)) {
        error_log("Invalid username format: $username");
        sendError("Username can only contain letters, numbers, and underscores", 400);
    }
    
    // Validasi Password
    if (strlen($password) < 6) {
        error_log("Password too short");
        sendError("Password must be at least 6 characters", 400);
    }
    
    if (strlen($password) > 100) {
        error_log("Password too long");
        sendError("Password maximum 100 characters", 400);
    }
    
    // Validasi Email
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        error_log("Invalid email format: $email");
        sendError("Invalid email format", 400);
    }
    
    if (strlen($email) > 100) {
        error_log("Email too long: $email");
        sendError("Email maximum 100 characters", 400);
    }
    
    // Validasi Full Name
    if (strlen($full_name) < 2) {
        error_log("Full name too short: $full_name");
        sendError("Full name must be at least 2 characters", 400);
    }
    
    if (strlen($full_name) > 100) {
        error_log("Full name too long: $full_name");
        sendError("Full name maximum 100 characters", 400);
    }
    
    error_log("All validations passed");
    
    // ============================
    // CEK USERNAME/EMAIL SUDAH ADA
    // ============================
    error_log("Checking duplicate username/email...");
    
    $check_sql = "SELECT id FROM users WHERE username = ? OR email = ? LIMIT 1";
    $check_stmt = $connection->prepare($check_sql);
    
    if (!$check_stmt) {
        error_log("Prepare check statement failed: " . $connection->error);
        sendError("Database error", 500);
    }
    
    $check_stmt->bind_param("ss", $username, $email);
    
    if (!$check_stmt->execute()) {
        error_log("Execute check failed: " . $check_stmt->error);
        $check_stmt->close();
        sendError("Database query error", 500);
    }
    
    $check_result = $check_stmt->get_result();
    
    if ($check_result->num_rows > 0) {
        $check_stmt->close();
        error_log("Duplicate found - Username: $username or Email: $email");
        sendError("Username or email already exists", 409);
    }
    
    $check_stmt->close();
    error_log("No duplicate found");
    
    // ============================
    // HASH PASSWORD
    // ============================
    error_log("Hashing password...");
    $hashed_password = password_hash($password, PASSWORD_DEFAULT);
    
    if (!$hashed_password) {
        error_log("Password hash failed");
        sendError("Registration failed: password processing error", 500);
    }
    
    // ============================
    // INSERT USER BARU
    // ============================
    error_log("Inserting new user to database...");
    
    $insert_sql = "INSERT INTO users (username, password, email, full_name, created_at, updated_at) 
                   VALUES (?, ?, ?, ?, NOW(), NOW())";
    
    $insert_stmt = $connection->prepare($insert_sql);
    
    if (!$insert_stmt) {
        error_log("Prepare insert failed: " . $connection->error);
        sendError("Database error", 500);
    }
    
    $insert_stmt->bind_param("ssss", $username, $hashed_password, $email, $full_name);
    
    if (!$insert_stmt->execute()) {
        error_log("Execute insert failed: " . $insert_stmt->error);
        sendError("Registration failed: " . $insert_stmt->error, 500);
    }
    
    $user_id = $insert_stmt->insert_id;
    $insert_stmt->close();
    
    error_log("User inserted successfully. ID: $user_id");
    
    // ============================
    // AMBIL DATA USER YANG BARU DIBUAT
    // ============================
    error_log("Fetching new user data...");
    
    $user_sql = "SELECT id, username, email, full_name, created_at, updated_at 
                 FROM users WHERE id = ?";
    
    $user_stmt = $connection->prepare($user_sql);
    
    if (!$user_stmt) {
        error_log("Prepare user fetch failed: " . $connection->error);
        sendError("Database error", 500);
    }
    
    $user_stmt->bind_param("i", $user_id);
    
    if (!$user_stmt->execute()) {
        error_log("Execute user fetch failed: " . $user_stmt->error);
        $user_stmt->close();
        sendError("Database query error", 500);
    }
    
    $user_result = $user_stmt->get_result();
    $new_user = $user_result->fetch_assoc();
    $user_stmt->close();
    
    if (!$new_user) {
        error_log("New user not found after insert. ID: $user_id");
        sendError("Registration completed but user data not found", 500);
    }
    
    error_log("New user data fetched: " . json_encode($new_user));
    
    // ============================
    // GENERATE TOKEN
    // ============================
    error_log("Generating token...");
    $token = generateToken($new_user);
    
    // ============================
    // RESPONSE SUKSES
    // ============================
    error_log("Registration successful for user: $username (ID: $user_id)");
    
    sendSuccess("Registration successful", [
        'user' => [
            'id' => (int)$new_user['id'],
            'username' => $new_user['username'],
            'email' => $new_user['email'],
            'full_name' => $new_user['full_name'],
            'created_at' => $new_user['created_at']
        ],
        'token' => $token,
        'token_type' => 'Bearer',
        'expires_in' => 604800, // 7 hari dalam detik
        'expires_at' => date('Y-m-d H:i:s', time() + 604800)
    ]);
    
} catch (Exception $e) {
    error_log("Register Exception: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    sendError("Registration failed. Please try again.", 500);
}
?>