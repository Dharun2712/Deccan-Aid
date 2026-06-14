<?php
/**
 * Drivers API - Returns driver/ambulance data
 */
header('Content-Type: application/json');
require_once __DIR__ . '/../config.php';

try {
    $status = isset($_GET['status']) ? $_GET['status'] : null;
    
    $endpoint = '/drivers';
    if ($status) {
        $endpoint .= '?status=' . urlencode($status);
    }
    
    $result = adminApiCall($endpoint);
    
    echo json_encode([
        'success' => true,
        'drivers' => $result['data'] ?? []
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
