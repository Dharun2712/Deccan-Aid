<?php
/**
 * Stats API - Returns dashboard statistics
 */
header('Content-Type: application/json');
require_once __DIR__ . '/../config.php';

try {
    $stats = adminApiCall('/stats');
    $activeRequests = apiCall('/sos/active');
    
    echo json_encode([
        'success' => true,
        'stats' => [
            'totalRequests' => $stats['data']['total_requests'] ?? 0,
            'activeRequests' => $stats['data']['active_requests'] ?? 0,
            'availableDrivers' => $stats['data']['available_drivers'] ?? 0,
            'totalHospitals' => $stats['data']['total_hospitals'] ?? 0
        ],
        'recentRequests' => array_slice($activeRequests['data'] ?? [], 0, 5)
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
