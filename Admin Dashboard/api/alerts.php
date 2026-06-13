<?php
/**
 * Alerts API - Fetches active SOS alerts from MongoDB Atlas with dummy fallback
 */
header('Content-Type: application/json');
header('Cache-Control: no-cache, no-store, must-revalidate');
require_once __DIR__ . '/../config.php';

try {
    $severity = isset($_GET['severity']) ? strtolower(trim($_GET['severity'])) : 'all';

    // --- Try MongoDB Atlas first ---
    $alerts = getAlertsFromMongo();
    $source = 'mongodb';

    // --- Fallback to dummy data if MongoDB is unavailable ---
    if (empty($alerts)) {
        $requests = getDummyRequests();
        $alerts = array_values(array_filter(
            $requests,
            fn($r) => in_array($r['status'] ?? '', ['pending', 'accepted', 'in_progress'])
        ));
        $source = 'dummy';
    }

    // Summary counts (computed before severity filter)
    $counts = [
        'critical' => count(array_filter($alerts, fn($a) => ($a['severity'] ?? '') === 'critical')),
        'high'     => count(array_filter($alerts, fn($a) => ($a['severity'] ?? '') === 'high')),
        'medium'   => count(array_filter($alerts, fn($a) => ($a['severity'] ?? '') === 'medium')),
        'low'      => count(array_filter($alerts, fn($a) => ($a['severity'] ?? '') === 'low')),
        'total'    => count($alerts),
    ];

    // Filter by severity if requested
    $filtered = $alerts;
    if ($severity !== 'all' && in_array($severity, ['critical', 'high', 'medium', 'low'])) {
        $filtered = array_values(array_filter(
            $alerts,
            fn($a) => strtolower($a['severity'] ?? '') === $severity
        ));
    }

    // Sort by newest first, severity as tiebreaker
    $order = ['critical' => 0, 'high' => 1, 'medium' => 2, 'low' => 3];
    usort($filtered, function($a, $b) use ($order) {
        $timeA = strtotime($a['created_at'] ?? '2000-01-01');
        $timeB = strtotime($b['created_at'] ?? '2000-01-01');
        if ($timeA !== $timeB) return $timeB - $timeA; // newest first
        return ($order[strtolower($a['severity'] ?? 'low')] ?? 3) -
               ($order[strtolower($b['severity'] ?? 'low')] ?? 3);
    });

    echo json_encode([
        'success'   => true,
        'source'    => $source,
        'counts'    => $counts,
        'alerts'    => $filtered,
        'fetched_at' => gmdate('Y-m-d\TH:i:s\Z'),
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error'   => 'Failed to fetch alerts.',
    ]);
}
