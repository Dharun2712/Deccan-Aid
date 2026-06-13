<?php
/**
 * Users API - Returns user data
 */
header('Content-Type: application/json');
require_once __DIR__ . '/../config.php';

try {
    $role = isset($_GET['role']) ? $_GET['role'] : null;
    
    $endpoint = '/users';
    if ($role && $role !== 'all') {
        $endpoint .= '?role=' . urlencode($role);
    }
    
    $result = adminApiCall($endpoint);
    
    echo json_encode([
        'success' => true,
        'users' => $result['data'] ?? []
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
