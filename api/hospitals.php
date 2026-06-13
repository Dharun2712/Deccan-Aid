<?php
/**
 * Hospitals API - Returns hospital data
 */
header('Content-Type: application/json');
require_once __DIR__ . '/../config.php';

try {
    $result = adminApiCall('/hospitals');
    
    echo json_encode([
        'success' => true,
        'hospitals' => $result['data'] ?? []
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
