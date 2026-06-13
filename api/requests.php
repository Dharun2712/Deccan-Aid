<?php
/**
 * Requests API - Returns SOS request data
 */
header('Content-Type: application/json');
require_once __DIR__ . '/../config.php';

try {
    $status = isset($_GET['status']) ? $_GET['status'] : null;
    
    if ($status === 'active') {
        $result = apiCall('/sos/active');
    } else {
        $result = adminApiCall('/requests');
    }
    
    $requests = $result['data'] ?? [];
    
    // Filter by status if specified
    if ($status && $status !== 'all' && $status !== 'active') {
        $requests = array_filter($requests, function($r) use ($status) {
            return strtolower($r['status'] ?? '') === strtolower($status);
        });
        $requests = array_values($requests);
    }
    
    echo json_encode([
        'success' => true,
        'requests' => $requests
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
