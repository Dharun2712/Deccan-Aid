<?php
require_once __DIR__ . '/includes/header.php';

$page = isset($_GET['page']) ? $_GET['page'] : 'dashboard';
$allowed = ['dashboard', 'ambulances', 'hospitals', 'requests', 'users', 'analytics', 'reports', 'alerts', 'dispatch', 'tracking', 'settings'];
if (!in_array($page, $allowed)) {
    $page = 'dashboard';
}

include __DIR__ . "/pages/{$page}.php";

require_once __DIR__ . '/includes/footer.php';
?>
