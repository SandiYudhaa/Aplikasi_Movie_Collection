<?php
/**
 * FILE: config.php
 * DESKRIPSI: File konfigurasi utama untuk koneksi database dan fungsi API
 * VERSI: 6.0 - Security Enhanced for serv00.net
 * PENULIS: Sandi Yudha - Movie Collection App
 * LAST UPDATE: 2024
 */

// ============================================
// KONFIGURASI ERROR REPORTING (SERV00.NET)
// ============================================
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(E_ALL); // Tetap log semua error
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/php_errors.log');

// ============================================
// KONFIGURASI KEAMANAN
// ============================================
define('JWT_SECRET', 'movie_app_secret_key_' . md5(__DIR__)); // Secret key unik
define('JWT_ALGORITHM', 'HS256');
define('MAX_FILE_SIZE', 3 * 1024 * 1024); // 3MB
define('ALLOWED_IMAGE_TYPES', ['jpg', 'jpeg', 'png', 'gif', 'webp']);

// ============================================
// KONFIGURASI DATABASE 
// ============================================
$host = "localhost";
$username = "pencari2_sandi";
$password = "@Sandi210803";
$database = "pencari2_sandi";

// ============================================
// SET HEADERS UNTUK FLUTTER (FIXED)
// ============================================
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

// Handle OPTIONS request untuk Flutter web
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ============================================
// FUNGSI KONEKSI DATABASE (STABIL)
// ============================================
function connectDatabase() {
    global $host, $username, $password, $database;
    
    try {
        // Koneksi ke MySQL dengan error reporting
        $conn = new mysqli($host, $username, $password, $database);
        
        // Cek koneksi
        if ($conn->connect_error) {
            error_log("Database Connection Failed: " . $conn->connect_error);
            return false;
        }
        
        // Set charset
        $conn->set_charset("utf8mb4");
        
        return $conn;
        
    } catch (Exception $e) {
        error_log("Database Exception: " . $e->getMessage());
        return false;
    }
}

// ============================================
// INISIALISASI KONEKSI GLOBAL
// ============================================
$connection = connectDatabase();

if (!$connection) {
    // Response error yang ramah untuk Flutter
    echo json_encode([
        "success" => false,
        "message" => "Database connection error. Please contact administrator.",
        "timestamp" => date('Y-m-d H:i:s'),
        "error_code" => "DB_CONNECTION_FAILED"
    ]);
    exit();
}

// ============================================
// FUNGSI HELPER UNTUK RESPONSE (SIMPLE)
// ============================================

/**
 * Kirim response sukses
 */
function sendSuccess($message, $data = []) {
    $response = [
        "success" => true,
        "message" => $message,
        "timestamp" => date('Y-m-d H:i:s')
    ];
    
    if (!empty($data)) {
        $response["data"] = $data;
    }
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit();
}

/**
 * Kirim response error
 */
function sendError($message, $code = 400, $additionalData = []) {
    http_response_code($code);
    
    $response = [
        "success" => false,
        "message" => $message,
        "timestamp" => date('Y-m-d H:i:s'),
        "code" => $code
    ];
    
    if (!empty($additionalData)) {
        $response["details"] = $additionalData;
    }
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit();
}

/**
 * Validasi input JSON dari Flutter
 */
function getJsonInput() {
    $input = file_get_contents("php://input");
    
    if (empty($input)) {
        sendError("Request body cannot be empty", 400);
    }
    
    $data = json_decode($input, true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        sendError("Invalid JSON format: " . json_last_error_msg(), 400);
    }
    
    return $data;
}

/**
 * Validasi field yang wajib diisi
 */
function validateRequired($data, $fields) {
    $missing = [];
    
    foreach ($fields as $field) {
        if (!isset($data[$field]) || (is_string($data[$field]) && trim($data[$field]) === '')) {
            $missing[] = $field;
        }
    }
    
    if (!empty($missing)) {
        sendError("Missing required fields: " . implode(', ', $missing), 400, [
            "missing_fields" => $missing
        ]);
    }
}

/**
 * Generate JWT token yang lebih aman
 */
function generateToken($userData) {
    $header = json_encode(['typ' => 'JWT', 'alg' => JWT_ALGORITHM]);
    $payload = json_encode([
        'user_id' => $userData['id'],
        'username' => $userData['username'],
        'email' => $userData['email'],
        'iat' => time(),
        'exp' => time() + (7 * 24 * 60 * 60) // 7 hari
    ]);
    
    $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
    $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
    
    $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, JWT_SECRET, true);
    $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    
    return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
}

/**
 * Verify JWT token
 */
function verifyToken($token) {
    if (empty($token)) {
        return false;
    }
    
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        return false;
    }
    
    list($base64UrlHeader, $base64UrlPayload, $base64UrlSignature) = $parts;
    
    $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, JWT_SECRET, true);
    $base64UrlSignatureToVerify = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
    
    if ($base64UrlSignature !== $base64UrlSignatureToVerify) {
        return false;
    }
    
    $payload = json_decode(base64_decode(str_replace(['-', '_'], ['+', '/'], $base64UrlPayload)), true);
    
    if (isset($payload['exp']) && $payload['exp'] < time()) {
        return false;
    }
    
    return $payload;
}

/**
 * Clean input untuk mencegah SQL injection
 */
function cleanInput($input) {
    global $connection;
    
    if (is_array($input)) {
        return array_map('cleanInput', $input);
    }
    
    if (is_string($input)) {
        // Hapus whitespace
        $input = trim($input);
        
        // Hilangkan tag HTML/PHP
        $input = strip_tags($input);
        
        // Convert special chars
        $input = htmlspecialchars($input, ENT_QUOTES | ENT_HTML5, 'UTF-8');
        
        // Escape untuk SQL
        if (isset($connection)) {
            $input = mysqli_real_escape_string($connection, $input);
        }
        
        return $input;
    }
    
    return $input;
}

/**
 * Sanitize input untuk file upload dan data khusus
 */
function sanitizeInput($input, $type = 'string') {
    switch ($type) {
        case 'email':
            $input = filter_var(trim($input), FILTER_SANITIZE_EMAIL);
            return filter_var($input, FILTER_VALIDATE_EMAIL) ? $input : '';
            
        case 'int':
            return filter_var($input, FILTER_SANITIZE_NUMBER_INT);
            
        case 'float':
            return filter_var($input, FILTER_SANITIZE_NUMBER_FLOAT, FILTER_FLAG_ALLOW_FRACTION);
            
        case 'url':
            $input = filter_var(trim($input), FILTER_SANITIZE_URL);
            return filter_var($input, FILTER_VALIDATE_URL) ? $input : '';
            
        case 'filename':
            // Hanya izinkan karakter aman untuk nama file
            $input = preg_replace('/[^a-zA-Z0-9\-\._]/', '', basename($input));
            return substr($input, 0, 255);
            
        case 'string':
        default:
            return cleanInput($input);
    }
}

/**
 * Cek apakah user sudah login (token valid)
 */
function checkAuth() {
    $headers = getallheaders();
    
    if (!isset($headers['Authorization'])) {
        sendError("Unauthorized: No token provided", 401);
    }
    
    $authHeader = $headers['Authorization'];
    
    // Format: "Bearer {token}"
    if (preg_match('/Bearer\s+(.+)$/i', $authHeader, $matches)) {
        $token = $matches[1];
        $payload = verifyToken($token);
        
        if (!$payload) {
            sendError("Invalid or expired token", 401);
        }
        
        return $payload; // Return user data dari token
    }
    
    sendError("Invalid authorization header", 401);
}

/**
 * Upload file dengan validasi keamanan
 */
function uploadFile($fileInput, $allowedTypes = null, $maxSize = null) {
    if (!isset($_FILES[$fileInput]) || $_FILES[$fileInput]['error'] !== UPLOAD_ERR_OK) {
        return ['error' => 'No file uploaded or upload error'];
    }
    
    $file = $_FILES[$fileInput];
    $maxSize = $maxSize ?: MAX_FILE_SIZE;
    $allowedTypes = $allowedTypes ?: ALLOWED_IMAGE_TYPES;
    
    // Validasi ukuran
    if ($file['size'] > $maxSize) {
        return ['error' => "File size exceeds maximum limit of " . ($maxSize / 1024 / 1024) . "MB"];
    }
    
    // Validasi ekstensi file
    $fileExtension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    if (!in_array($fileExtension, $allowedTypes)) {
        return ['error' => "File type not allowed. Allowed types: " . implode(', ', $allowedTypes)];
    }
    
    // Validasi MIME type
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);
    
    $allowedMimes = [
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp'
    ];
    
    if (!isset($allowedMimes[$fileExtension]) || $allowedMimes[$fileExtension] !== $mimeType) {
        return ['error' => 'Invalid file type detected'];
    }
    
    // Generate nama file yang unik
    $fileName = uniqid('file_', true) . '_' . time() . '.' . $fileExtension;
    
    return [
        'success' => true,
        'tmp_path' => $file['tmp_name'],
        'name' => $fileName,
        'original_name' => $file['name'],
        'size' => $file['size'],
        'type' => $mimeType,
        'extension' => $fileExtension
    ];
}

/**
 * Log aktivitas ke database
 */
function logActivity($userId, $action, $details = '') {
    global $connection;
    
    try {
        $query = "INSERT INTO activity_logs (user_id, action, details, created_at) 
                  VALUES (?, ?, ?, NOW())";
        
        $stmt = $connection->prepare($query);
        $stmt->bind_param("iss", $userId, $action, $details);
        $stmt->execute();
        $stmt->close();
        
        return true;
    } catch (Exception $e) {
        error_log("Activity log failed: " . $e->getMessage());
        return false;
    }
}

// ============================================
// ALIAS FUNCTIONS untuk kompatibilitas dengan kode lama
// ============================================
function sendSuccessResponse($message, $data = []) {
    sendSuccess($message, $data);
}

function sendErrorResponse($message, $code = 400, $additionalData = []) {
    sendError($message, $code, $additionalData);
}

function validateJsonRequest() {
    return getJsonInput();
}

function validateRequiredFields($data, $fields) {
    validateRequired($data, $fields);
}

// ============================================
// REGISTER SHUTDOWN FUNCTION
// ============================================
register_shutdown_function(function() {
    global $connection;
    if ($connection) {
        $connection->close();
    }
});

// ============================================
// TIMEZONE
// ============================================
date_default_timezone_set('Asia/Jakarta');

// ============================================
// FUNGSI DEPRECATED (untuk kompatibilitas)
// ============================================
/**
 * @deprecated Gunakan generateToken() yang baru
 */
function generateSimpleToken($userData) {
    return generateToken($userData);
}

/**
 * @deprecated Gunakan cleanInput() yang baru
 */
function simpleCleanInput($input) {
    return cleanInput($input);
}

?>