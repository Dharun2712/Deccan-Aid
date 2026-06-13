<?php
/**
 * Dashboard Page - Smart Ambulance Admin
 * Namakkal Region - Near Namakkal Town Center
 */
require_once __DIR__ . '/../config.php';

// Fetch stats from backend
$stats = adminApiCall('/stats');
$activeRequests = adminApiCall('/requests');
$drivers = adminApiCall('/drivers');
$hospitals = adminApiCall('/hospitals');

// Process stats
$statsData = $stats['stats'] ?? $stats['data'] ?? [];
$totalRequests = $statsData['total_requests'] ?? 0;
$activeRequestsCount = $statsData['active_requests'] ?? 0;
$availableDrivers = $statsData['available_drivers'] ?? 0;
$totalHospitals = $statsData['total_hospitals'] ?? 0;
$totalUsers = $statsData['total_users'] ?? 0;
$criticalRequests = $statsData['critical_requests'] ?? 0;
$avgResponseTime = $statsData['avg_response_time'] ?? '4.2';
$successRate = $statsData['success_rate'] ?? 98.5;

// Get recent requests (limit 5)
$allRequests = $activeRequests['requests'] ?? $activeRequests['data'] ?? [];
$recentRequests = array_slice($allRequests, 0, 5);

// Get driver list
$driverList = $drivers['drivers'] ?? $drivers['data'] ?? [];
$availableDriversList = array_filter($driverList, fn($d) => $d['status'] === 'available');
$busyDriversList = array_filter($driverList, fn($d) => $d['status'] === 'busy');

// Get hospital list
$hospitalList = $hospitals['hospitals'] ?? $hospitals['data'] ?? [];
?>

<div x-data="dashboard()" x-init="init()" class="space-y-6">
  <!-- Page Header with Region Info -->
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-bold text-white">Dashboard</h1>
      <p class="text-slate-400 text-sm mt-1">
        <svg class="w-4 h-4 inline-block mr-1 text-red-400" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd"/>
        </svg>
        Namakkal District • Near Namakkal Town Center
      </p>
    </div>
    <div class="flex items-center gap-3">
      <span class="text-xs text-slate-500">Last updated: <span id="lastUpdate"><?= date('H:i:s') ?></span></span>
      <button onclick="location.reload()" class="btn-secondary">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
        Refresh
      </button>
    </div>
  </div>

  <!-- Critical Alert Banner -->
  <?php if ($criticalRequests > 0): ?>
  <div class="bg-gradient-to-r from-red-500/20 to-orange-500/20 border border-red-500/50 rounded-xl p-4 flex items-center gap-4 animate-pulse">
    <div class="p-2 bg-red-500/30 rounded-lg">
      <svg class="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
      </svg>
    </div>
    <div class="flex-1">
      <h4 class="text-red-400 font-semibold"><?= $criticalRequests ?> Critical Emergency Alert<?= $criticalRequests > 1 ? 's' : '' ?>!</h4>
      <p class="text-red-300/70 text-sm">Immediate attention required in Namakkal region</p>
    </div>
    <a href="?page=requests" class="btn-primary bg-red-500 hover:bg-red-600">View Now</a>
  </div>
  <?php endif; ?>

  <!-- Stats Cards - Row 1 -->
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
    <!-- Total Requests -->
    <div class="metric-card">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-slate-400 text-sm font-medium">Total Requests</p>
          <p class="text-3xl font-bold text-white mt-2"><?= number_format($totalRequests) ?></p>
          <p class="text-xs text-emerald-400 mt-2 flex items-center gap-1">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z" clip-rule="evenodd"/></svg>
            All time
          </p>
        </div>
        <div class="p-3 bg-gradient-to-br from-indigo-500/20 to-purple-500/20 rounded-xl">
          <svg class="w-6 h-6 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
          </svg>
        </div>
      </div>
    </div>

    <!-- Active Requests -->
    <div class="metric-card">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-slate-400 text-sm font-medium">Active Requests</p>
          <p class="text-3xl font-bold text-white mt-2"><?= number_format($activeRequestsCount) ?></p>
          <p class="text-xs text-amber-400 mt-2 flex items-center gap-1">
            <span class="status-indicator pending inline-block mr-1"></span>
            In progress
          </p>
        </div>
        <div class="p-3 bg-gradient-to-br from-amber-500/20 to-orange-500/20 rounded-xl">
          <svg class="w-6 h-6 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
      </div>
    </div>

    <!-- Available Drivers -->
    <div class="metric-card">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-slate-400 text-sm font-medium">Available Drivers</p>
          <p class="text-3xl font-bold text-white mt-2"><?= number_format($availableDrivers) ?></p>
          <p class="text-xs text-emerald-400 mt-2 flex items-center gap-1">
            <span class="status-indicator available inline-block mr-1"></span>
            Ready
          </p>
        </div>
        <div class="p-3 bg-gradient-to-br from-emerald-500/20 to-teal-500/20 rounded-xl">
          <svg class="w-6 h-6 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
          </svg>
        </div>
      </div>
    </div>

    <!-- Hospitals -->
    <div class="metric-card">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-slate-400 text-sm font-medium">Total Hospitals</p>
          <p class="text-3xl font-bold text-white mt-2"><?= number_format($totalHospitals) ?></p>
          <p class="text-xs text-cyan-400 mt-2 flex items-center gap-1">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/></svg>
            Connected
          </p>
        </div>
        <div class="p-3 bg-gradient-to-br from-cyan-500/20 to-blue-500/20 rounded-xl">
          <svg class="w-6 h-6 text-cyan-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
          </svg>
        </div>
      </div>
    </div>
  </div>

  <!-- Stats Cards - Row 2 -->
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
    <!-- Total Users -->
    <div class="metric-card">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-slate-400 text-sm font-medium">Registered Users</p>
          <p class="text-3xl font-bold text-white mt-2"><?= number_format($totalUsers) ?></p>
          <p class="text-xs text-purple-400 mt-2 flex items-center gap-1">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path d="M13 6a3 3 0 11-6 0 3 3 0 016 0zM18 8a2 2 0 11-4 0 2 2 0 014 0zM14 15a4 4 0 00-8 0v3h8v-3zM6 8a2 2 0 11-4 0 2 2 0 014 0zM16 18v-3a5.972 5.972 0 00-.75-2.906A3.005 3.005 0 0119 15v3h-3zM4.75 12.094A5.973 5.973 0 004 15v3H1v-3a3 3 0 013.75-2.906z"/></svg>
            Namakkal Region
          </p>
        </div>
        <div class="p-3 bg-gradient-to-br from-purple-500/20 to-pink-500/20 rounded-xl">
          <svg class="w-6 h-6 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
          </svg>
        </div>
      </div>
    </div>

    <!-- Response Time -->
    <div class="metric-card">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-slate-400 text-sm font-medium">Avg Response Time</p>
          <p class="text-3xl font-bold text-white mt-2"><?= $avgResponseTime ?> <span class="text-lg text-slate-400">min</span></p>
          <p class="text-xs text-emerald-400 mt-2 flex items-center gap-1">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M14.707 10.293a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 111.414-1.414L9 12.586V5a1 1 0 012 0v7.586l2.293-2.293a1 1 0 011.414 0z" clip-rule="evenodd"/></svg>
            -8% faster
          </p>
        </div>
        <div class="p-3 bg-gradient-to-br from-teal-500/20 to-cyan-500/20 rounded-xl">
          <svg class="w-6 h-6 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
        </div>
      </div>
    </div>

    <!-- Success Rate -->
    <div class="metric-card">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-slate-400 text-sm font-medium">Success Rate</p>
          <p class="text-3xl font-bold text-white mt-2"><?= $successRate ?><span class="text-lg text-slate-400">%</span></p>
          <p class="text-xs text-emerald-400 mt-2 flex items-center gap-1">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z" clip-rule="evenodd"/></svg>
            +2.3% this week
          </p>
        </div>
        <div class="p-3 bg-gradient-to-br from-green-500/20 to-emerald-500/20 rounded-xl">
          <svg class="w-6 h-6 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
      </div>
    </div>

    <!-- Critical Cases -->
    <div class="metric-card">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-slate-400 text-sm font-medium">Critical Cases</p>
          <p class="text-3xl font-bold text-white mt-2"><?= number_format($criticalRequests) ?></p>
          <p class="text-xs text-red-400 mt-2 flex items-center gap-1">
            <span class="status-indicator critical inline-block mr-1"></span>
            Needs attention
          </p>
        </div>
        <div class="p-3 bg-gradient-to-br from-red-500/20 to-rose-500/20 rounded-xl">
          <svg class="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
      </div>
    </div>
  </div>

  <!-- Charts Row -->
  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Requests Chart -->
    <div class="control-card">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h3 class="text-lg font-semibold text-white">Request Trends</h3>
          <p class="text-sm text-slate-400">Weekly overview - Namakkal Region</p>
        </div>
        <div class="flex gap-2">
          <button class="px-3 py-1.5 text-xs font-medium bg-indigo-500/20 text-indigo-400 rounded-lg">Week</button>
          <button class="px-3 py-1.5 text-xs font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg">Month</button>
        </div>
      </div>
      <div class="chart-container">
        <canvas id="requestsChart"></canvas>
      </div>
    </div>

    <!-- Severity Distribution -->
    <div class="control-card">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h3 class="text-lg font-semibold text-white">Severity Distribution</h3>
          <p class="text-sm text-slate-400">Request breakdown by priority</p>
        </div>
      </div>
      <div class="chart-container">
        <canvas id="severityChart"></canvas>
      </div>
    </div>
  </div>

  <!-- Live Ambulance Tracking & Active Drivers -->
  <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <!-- Live Map with Leaflet -->
    <div class="lg:col-span-2 control-card p-0 overflow-hidden">
      <div class="flex items-center justify-between p-4 border-b border-slate-700/50">
        <div>
          <h3 class="text-lg font-semibold text-white">Live Ambulance Tracking</h3>
          <p class="text-sm text-slate-400">Interactive map - Namakkal District</p>
        </div>
        <div class="flex items-center gap-3">
          <span class="flex items-center gap-2 px-3 py-1.5 bg-emerald-500/20 text-emerald-400 rounded-lg text-xs font-medium">
            <span class="status-indicator available"></span>
            <?= count($availableDriversList) ?> Active
          </span>
          <a href="?page=tracking" class="text-sm text-indigo-400 hover:text-indigo-300">Full Map →</a>
        </div>
      </div>
      
      <!-- Leaflet Map Container -->
      <div id="dashboardMap" style="height: 320px; width: 100%; z-index: 1;"></div>
      
      <div class="p-3 bg-slate-800/30 border-t border-slate-700/50 flex items-center justify-between text-xs">
        <div class="flex gap-4">
          <div class="flex items-center gap-2 text-slate-400">
            <span class="w-3 h-3 rounded-full bg-red-500"></span>
            Accidents
          </div>
          <div class="flex items-center gap-2 text-slate-400">
            <span class="w-3 h-3 rounded-full bg-cyan-500"></span>
            Ambulances
          </div>
          <div class="flex items-center gap-2 text-slate-400">
            <span class="w-3 h-3 rounded-full bg-emerald-500"></span>
            Hospitals
          </div>
        </div>
        <span class="text-slate-500">Centered: Namakkal Town Center</span>
      </div>
    </div>

    <!-- Active Drivers Panel -->
    <div class="control-card">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h3 class="text-lg font-semibold text-white">Active Drivers</h3>
          <p class="text-sm text-slate-400">Real-time status</p>
        </div>
        <a href="?page=ambulances" class="text-sm text-indigo-400 hover:text-indigo-300">View All</a>
      </div>
      
      <div class="space-y-3 max-h-72 overflow-y-auto custom-scrollbar">
        <?php foreach (array_slice($driverList, 0, 6) as $driver): ?>
        <div class="flex items-center gap-3 p-3 bg-slate-800/50 rounded-lg border border-slate-700/30">
          <div class="w-10 h-10 rounded-full bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center text-white font-bold text-sm">
            <?= strtoupper(substr($driver['name'], 0, 1)) ?>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-white text-sm font-medium truncate"><?= htmlspecialchars($driver['name']) ?></p>
            <p class="text-slate-400 text-xs truncate"><?= htmlspecialchars($driver['area'] ?? 'Namakkal') ?></p>
          </div>
          <span class="status-badge <?= $driver['status'] ?> text-xs">
            <?= ucfirst($driver['status']) ?>
          </span>
        </div>
        <?php endforeach; ?>
      </div>
    </div>
  </div>

  <!-- Active Requests & System Status -->
  <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <!-- Active Requests List -->
    <div class="lg:col-span-2 control-card">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h3 class="text-lg font-semibold text-white">Active Requests</h3>
          <p class="text-sm text-slate-400">Real-time SOS monitoring - Namakkal Region</p>
        </div>
        <a href="?page=requests" class="text-sm text-indigo-400 hover:text-indigo-300 flex items-center gap-1">
          View All
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </a>
      </div>
      
      <?php if (empty($recentRequests)): ?>
      <div class="empty-state py-8">
        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
        </svg>
        <h3>No Active Requests</h3>
        <p>All SOS requests have been handled</p>
      </div>
      <?php else: ?>
      <div class="overflow-x-auto">
        <table class="data-table">
          <thead>
            <tr>
              <th>Request ID</th>
              <th>User</th>
              <th>Location</th>
              <th>Severity</th>
              <th>Status</th>
              <th>Time</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <?php foreach ($recentRequests as $request): ?>
            <tr>
              <td class="font-mono text-xs text-slate-300">#<?= substr($request['request_id'] ?? $request['_id'] ?? 'N/A', -6) ?></td>
              <td>
                <div class="flex items-center gap-2">
                  <div class="w-8 h-8 rounded-full bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center text-white text-xs font-bold">
                    <?= strtoupper(substr($request['user_name'] ?? 'U', 0, 1)) ?>
                  </div>
                  <span class="text-white text-sm"><?= htmlspecialchars($request['user_name'] ?? 'Unknown') ?></span>
                </div>
              </td>
              <td class="text-slate-400 text-xs max-w-32 truncate"><?= htmlspecialchars($request['location']['name'] ?? $request['pickup_location'] ?? 'Namakkal') ?></td>
              <td>
                <span class="status-badge <?= strtolower($request['severity'] ?? 'medium') ?>">
                  <?= ucfirst($request['severity'] ?? 'Medium') ?>
                </span>
              </td>
              <td>
                <span class="status-badge <?= strtolower(str_replace(' ', '-', $request['status'] ?? 'pending')) ?>">
                  <?= ucfirst($request['status'] ?? 'Pending') ?>
                </span>
              </td>
              <td class="text-slate-400 text-sm"><?= timeAgo($request['created_at'] ?? null) ?></td>
              <td>
                <button class="text-slate-400 hover:text-white p-1">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                </button>
              </td>
            </tr>
            <?php endforeach; ?>
          </tbody>
        </table>
      </div>
      <?php endif; ?>
    </div>

    <!-- System Status -->
    <div class="control-card">
      <div class="mb-6">
        <h3 class="text-lg font-semibold text-white">System Status</h3>
        <p class="text-sm text-slate-400">Service health check</p>
      </div>
      
      <div class="space-y-4">
        <div class="flex items-center justify-between p-3 bg-slate-800/50 rounded-lg">
          <div class="flex items-center gap-3">
            <div class="status-indicator available"></div>
            <span class="text-sm text-white">Backend API</span>
          </div>
          <span class="text-xs text-emerald-400">Online</span>
        </div>
        
        <div class="flex items-center justify-between p-3 bg-slate-800/50 rounded-lg">
          <div class="flex items-center gap-3">
            <div class="status-indicator available"></div>
            <span class="text-sm text-white">Database</span>
          </div>
          <span class="text-xs text-emerald-400">Connected</span>
        </div>
        
        <div class="flex items-center justify-between p-3 bg-slate-800/50 rounded-lg">
          <div class="flex items-center gap-3">
            <div class="status-indicator available"></div>
            <span class="text-sm text-white">WebSocket</span>
          </div>
          <span class="text-xs text-emerald-400">Active</span>
        </div>
        
        <div class="flex items-center justify-between p-3 bg-slate-800/50 rounded-lg">
          <div class="flex items-center gap-3">
            <div class="status-indicator available"></div>
            <span class="text-sm text-white">Severity Model</span>
          </div>
          <span class="text-xs text-emerald-400">Loaded</span>
        </div>
      </div>

      <div class="mt-6 pt-6 border-t border-slate-700/50">
        <h4 class="text-sm font-medium text-white mb-4">Quick Actions</h4>
        <div class="grid grid-cols-2 gap-3">
          <a href="?page=requests" class="flex flex-col items-center gap-2 p-3 bg-slate-800/50 rounded-lg hover:bg-slate-700/50 transition group">
            <svg class="w-5 h-5 text-indigo-400 group-hover:text-indigo-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
            </svg>
            <span class="text-xs text-slate-400 group-hover:text-white">View SOS</span>
          </a>
          <a href="?page=ambulances" class="flex flex-col items-center gap-2 p-3 bg-slate-800/50 rounded-lg hover:bg-slate-700/50 transition group">
            <svg class="w-5 h-5 text-emerald-400 group-hover:text-emerald-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
            <span class="text-xs text-slate-400 group-hover:text-white">Drivers</span>
          </a>
          <a href="?page=hospitals" class="flex flex-col items-center gap-2 p-3 bg-slate-800/50 rounded-lg hover:bg-slate-700/50 transition group">
            <svg class="w-5 h-5 text-cyan-400 group-hover:text-cyan-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
            <span class="text-xs text-slate-400 group-hover:text-white">Hospitals</span>
          </a>
          <a href="?page=analytics" class="flex flex-col items-center gap-2 p-3 bg-slate-800/50 rounded-lg hover:bg-slate-700/50 transition group">
            <svg class="w-5 h-5 text-purple-400 group-hover:text-purple-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
            <span class="text-xs text-slate-400 group-hover:text-white">Analytics</span>
          </a>
        </div>
      </div>
    </div>
  </div>

  <!-- Hospitals & Top Performers -->
  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Nearby Hospitals -->
    <div class="control-card">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h3 class="text-lg font-semibold text-white">Nearby Hospitals</h3>
          <p class="text-sm text-slate-400">Namakkal Region Network</p>
        </div>
        <a href="?page=hospitals" class="text-sm text-indigo-400 hover:text-indigo-300">View All</a>
      </div>
      
      <div class="space-y-3">
        <?php foreach (array_slice($hospitalList, 0, 4) as $hospital): 
          $capacity = $hospital['capacity'] ?? ['total' => 100, 'occupied' => 0];
          $occupiedPct = ($capacity['total'] > 0) ? round(($capacity['occupied'] / $capacity['total']) * 100) : 0;
        ?>
        <div class="flex items-center gap-4 p-3 bg-slate-800/50 rounded-lg border border-slate-700/30">
          <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-cyan-500 to-blue-600 flex items-center justify-center flex-shrink-0">
            <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-white text-sm font-medium truncate"><?= htmlspecialchars($hospital['name']) ?></p>
            <div class="flex items-center gap-3 mt-1">
              <span class="text-slate-400 text-xs"><?= $occupiedPct ?>% occupied</span>
              <span class="text-slate-500 text-xs"><?= $hospital['distance'] ?? 'N/A' ?></span>
            </div>
          </div>
          <span class="status-badge <?= $hospital['status'] === 'available' ? 'available' : 'busy' ?> text-xs">
            <?= ucfirst($hospital['status']) ?>
          </span>
        </div>
        <?php endforeach; ?>
      </div>
    </div>

    <!-- Top Performers -->
    <div class="control-card">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h3 class="text-lg font-semibold text-white">Top Performers</h3>
          <p class="text-sm text-slate-400">This month's best drivers</p>
        </div>
      </div>
      
      <div class="space-y-4">
        <?php 
        $topDrivers = $driverList;
        usort($topDrivers, fn($a, $b) => ($b['trips_completed'] ?? 0) - ($a['trips_completed'] ?? 0));
        $maxTrips = $topDrivers[0]['trips_completed'] ?? 1;
        $colors = ['indigo', 'emerald', 'cyan', 'purple', 'amber'];
        foreach (array_slice($topDrivers, 0, 5) as $idx => $driver): 
          $pct = round(($driver['trips_completed'] ?? 0) / $maxTrips * 100);
          $color = $colors[$idx];
        ?>
        <div class="flex items-center gap-4">
          <div class="w-8 h-8 rounded-full bg-gradient-to-br from-<?= $color ?>-500 to-<?= $color ?>-600 flex items-center justify-center text-white text-xs font-bold">
            <?= strtoupper(substr($driver['name'], 0, 1)) ?>
          </div>
          <div class="flex-1">
            <div class="flex justify-between text-sm mb-1">
              <span class="text-white"><?= htmlspecialchars($driver['name']) ?></span>
              <span class="text-slate-400"><?= $driver['trips_completed'] ?? 0 ?> trips</span>
            </div>
            <div class="h-2 bg-slate-700 rounded-full overflow-hidden">
              <div class="h-full bg-gradient-to-r from-<?= $color ?>-500 to-<?= $color ?>-400 rounded-full" style="width: <?= $pct ?>%"></div>
            </div>
          </div>
        </div>
        <?php endforeach; ?>
      </div>
    </div>
  </div>

  <!-- Recent Activity -->
  <div class="control-card">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h3 class="text-lg font-semibold text-white">Recent Activity</h3>
        <p class="text-sm text-slate-400">Latest system events - Namakkal Region</p>
      </div>
    </div>
    
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      <div class="activity-item">
        <div class="p-2 bg-emerald-500/20 rounded-lg flex-shrink-0">
          <svg class="w-5 h-5 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-white text-sm font-medium">Request Completed</p>
          <p class="text-slate-400 text-xs truncate">Dharun Prasad delivered to Government Medical College Hospital, Namakkal</p>
          <p class="text-slate-500 text-xs mt-1">2 min ago</p>
        </div>
      </div>
      <div class="activity-item">
        <div class="p-2 bg-amber-500/20 rounded-lg flex-shrink-0">
          <svg class="w-5 h-5 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"/>
          </svg>
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-white text-sm font-medium">Driver Dispatched</p>
          <p class="text-slate-400 text-xs truncate">Aswanth Vijay en route to Tiruchengode</p>
          <p class="text-slate-500 text-xs mt-1">5 min ago</p>
        </div>
      </div>
      <div class="activity-item">
        <div class="p-2 bg-red-500/20 rounded-lg flex-shrink-0">
          <svg class="w-5 h-5 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
          </svg>
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-white text-sm font-medium">Critical Alert</p>
          <p class="text-slate-400 text-xs truncate">Emergency near Namakkal Bus Stand</p>
          <p class="text-slate-500 text-xs mt-1">8 min ago</p>
        </div>
      </div>
      <div class="activity-item">
        <div class="p-2 bg-indigo-500/20 rounded-lg flex-shrink-0">
          <svg class="w-5 h-5 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"/>
          </svg>
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-white text-sm font-medium">New User</p>
          <p class="text-slate-400 text-xs truncate">Kishore Balaji registered</p>
          <p class="text-slate-500 text-xs mt-1">15 min ago</p>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
  const requestsCtx = document.getElementById('requestsChart');
  if (requestsCtx) {
    new Chart(requestsCtx, {
      type: 'line',
      data: {
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        datasets: [{
          label: 'Requests',
          data: [18, 25, 14, 22, 28, 24, 16],
          borderColor: '#6366f1',
          backgroundColor: 'rgba(99, 102, 241, 0.1)',
          fill: true,
          tension: 0.4,
          pointBackgroundColor: '#6366f1',
          pointBorderColor: '#0f172a',
          pointBorderWidth: 2,
          pointRadius: 4
        }, {
          label: 'Completed',
          data: [16, 23, 12, 20, 26, 22, 14],
          borderColor: '#10b981',
          backgroundColor: 'rgba(16, 185, 129, 0.1)',
          fill: true,
          tension: 0.4,
          pointBackgroundColor: '#10b981',
          pointBorderColor: '#0f172a',
          pointBorderWidth: 2,
          pointRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: true, position: 'top', align: 'end', labels: { color: '#94a3b8', usePointStyle: true } }
        },
        scales: {
          x: { grid: { color: 'rgba(148, 163, 184, 0.1)' }, ticks: { color: '#64748b' } },
          y: { grid: { color: 'rgba(148, 163, 184, 0.1)' }, ticks: { color: '#64748b' }, beginAtZero: true }
        }
      }
    });
  }
  
  const severityCtx = document.getElementById('severityChart');
  if (severityCtx) {
    new Chart(severityCtx, {
      type: 'doughnut',
      data: {
        labels: ['Critical', 'High', 'Medium', 'Low'],
        datasets: [{
          data: [12, 28, 42, 18],
          backgroundColor: ['#ef4444', '#f59e0b', '#06b6d4', '#10b981'],
          borderWidth: 0,
          hoverOffset: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: '65%',
        plugins: {
          legend: { position: 'bottom', labels: { color: '#94a3b8', padding: 20, usePointStyle: true, pointStyle: 'circle' } }
        }
      }
    });
  }

  // Initialize Dashboard Leaflet Map
  initDashboardMap();
});

// Dashboard Map Initialization
function initDashboardMap() {
  const mapContainer = document.getElementById('dashboardMap');
  if (!mapContainer) return;

  // Center coordinates: Namakkal Town Center
  const centerLat = 11.2194;
  const centerLng = 78.1678;

  // Create map
  const dashMap = L.map('dashboardMap', {
    center: [centerLat, centerLng],
    zoom: 13,
    zoomControl: true,
    scrollWheelZoom: true
  });

  // Add dark theme tile layer
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: '© OpenStreetMap © CARTO',
    subdomains: 'abcd',
    maxZoom: 19
  }).addTo(dashMap);

  // Dummy data for map markers
  const accidents = [
    { lat: centerLat + 0.015, lng: centerLng - 0.012, name: 'Arun Kumar', type: 'Road Accident', severity: 'critical' },
    { lat: centerLat - 0.008, lng: centerLng + 0.018, name: 'Sanjeev Rajan', type: 'Heart Attack', severity: 'critical' },
    { lat: centerLat + 0.022, lng: centerLng + 0.008, name: 'Dharun Prasad', type: 'Fall Injury', severity: 'high' },
    { lat: centerLat - 0.018, lng: centerLng - 0.015, name: 'Kishore Balaji', type: 'Breathing Issue', severity: 'medium' },
  ];

  const ambulances = [
    { lat: centerLat + 0.008, lng: centerLng - 0.005, name: 'Aswanth Vijay', vehicle: 'TN 33 AB 1234', status: 'available' },
    { lat: centerLat - 0.012, lng: centerLng + 0.010, name: 'Karthik Selvam', vehicle: 'TN 33 CD 5678', status: 'busy' },
    { lat: centerLat + 0.005, lng: centerLng + 0.020, name: 'Pradeep Kumar', vehicle: 'TN 33 EF 9012', status: 'available' },
    { lat: centerLat - 0.020, lng: centerLng - 0.008, name: 'Vignesh Raja', vehicle: 'TN 33 GH 3456', status: 'busy' },
  ];

  const hospitals = [
    { lat: centerLat + 0.025, lng: centerLng + 0.015, name: 'Maruthi Hospital', beds: 25 },
    { lat: centerLat - 0.015, lng: centerLng - 0.025, name: 'M.M. Hospital', beds: 18 },
    { lat: centerLat - 0.028, lng: centerLng + 0.022, name: 'CM Speciality Hospital (CM Best)', beds: 32 },
  ];

  // Custom marker styles
  const createMarkerHtml = (emoji, bgColor, shadow) => `
    <div style="
      width: 32px; height: 32px;
      background: ${bgColor};
      border: 2px solid white;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 14px;
      box-shadow: 0 0 10px ${shadow};
    ">${emoji}</div>
  `;

  // Add accident markers
  accidents.forEach(a => {
    const icon = L.divIcon({
      className: 'custom-marker',
      html: createMarkerHtml('⚠️', 'linear-gradient(135deg, #ef4444, #dc2626)', 'rgba(239,68,68,0.5)'),
      iconSize: [32, 32],
      iconAnchor: [16, 16]
    });
    L.marker([a.lat, a.lng], { icon })
      .addTo(dashMap)
      .bindPopup(`<div style="color:#f87171;font-weight:600;">🚨 ${a.type}</div><div style="color:#e2e8f0;">${a.name}</div><div style="color:#94a3b8;font-size:11px;">Severity: ${a.severity}</div>`);
  });

  // Add ambulance markers
  ambulances.forEach(a => {
    const bgColor = a.status === 'available' ? 'linear-gradient(135deg, #10b981, #059669)' : 'linear-gradient(135deg, #f59e0b, #d97706)';
    const shadow = a.status === 'available' ? 'rgba(16,185,129,0.5)' : 'rgba(245,158,11,0.5)';
    const icon = L.divIcon({
      className: 'custom-marker',
      html: createMarkerHtml('🚑', bgColor, shadow),
      iconSize: [32, 32],
      iconAnchor: [16, 16]
    });
    L.marker([a.lat, a.lng], { icon })
      .addTo(dashMap)
      .bindPopup(`<div style="color:#22d3ee;font-weight:600;">🚑 ${a.name}</div><div style="color:#e2e8f0;">${a.vehicle}</div><div style="color:#94a3b8;font-size:11px;">Status: ${a.status}</div>`);
  });

  // Add hospital markers
  hospitals.forEach(h => {
    const icon = L.divIcon({
      className: 'custom-marker',
      html: createMarkerHtml('🏥', 'linear-gradient(135deg, #10b981, #059669)', 'rgba(16,185,129,0.5)'),
      iconSize: [32, 32],
      iconAnchor: [16, 16]
    });
    L.marker([h.lat, h.lng], { icon })
      .addTo(dashMap)
      .bindPopup(`<div style="color:#34d399;font-weight:600;">🏥 ${h.name}</div><div style="color:#94a3b8;font-size:11px;">Beds: ${h.beds} available</div>`);
  });

  // Add Namakkal center marker
  const kecIcon = L.divIcon({
    className: 'custom-marker',
    html: `<div style="
      width: 36px; height: 36px;
      background: linear-gradient(135deg, #6366f1, #8b5cf6);
      border: 3px solid white;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 16px;
      box-shadow: 0 0 20px rgba(99,102,241,0.6);
    ">📍</div>`,
    iconSize: [36, 36],
    iconAnchor: [18, 18]
  });
  L.marker([centerLat, centerLng], { icon: kecIcon })
    .addTo(dashMap)
    .bindPopup('<div style="color:#a5b4fc;font-weight:600;">📍 Namakkal Town Center</div><div style="color:#94a3b8;font-size:11px;">11.2194° N, 78.1678° E</div>');

  // Add coverage circle
  L.circle([centerLat, centerLng], {
    color: '#6366f1',
    fillColor: '#6366f1',
    fillOpacity: 0.05,
    radius: 5000,
    weight: 1,
    dashArray: '5, 5'
  }).addTo(dashMap);
}
</script>
