<?php
/**
 * Analytics Page - Reports & Statistics
 */
require_once __DIR__ . '/../config.php';

$stats = adminApiCall('/stats');
$statsData = $stats['stats'] ?? $stats['data'] ?? [];
?>

<div class="space-y-6">
  <!-- Page Header -->
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-bold text-white">Analytics</h1>
      <p class="text-slate-400 text-sm mt-1">System performance and statistics</p>
    </div>
    <div class="flex items-center gap-3">
      <select class="px-4 py-2 bg-slate-800/50 border border-slate-700/50 rounded-lg text-sm text-white focus:outline-none focus:border-indigo-500/50">
        <option>Last 7 days</option>
        <option>Last 30 days</option>
        <option>Last 90 days</option>
        <option>This year</option>
      </select>
      <button class="btn-primary">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
        </svg>
        Export
      </button>
    </div>
  </div>

  <!-- Key Metrics -->
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
    <div class="metric-card">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-slate-400 text-sm font-medium">Total Requests</p>
          <p class="text-3xl font-bold text-white mt-2"><?= number_format($statsData['total_requests'] ?? 0) ?></p>
          <p class="text-xs text-emerald-400 mt-2 flex items-center gap-1">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z" clip-rule="evenodd"/></svg>
            +12% from last week
          </p>
        </div>
        <div class="p-3 bg-gradient-to-br from-indigo-500/20 to-purple-500/20 rounded-xl">
          <svg class="w-6 h-6 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
          </svg>
        </div>
      </div>
    </div>

    <div class="metric-card">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-slate-400 text-sm font-medium">Avg Response Time</p>
          <p class="text-3xl font-bold text-white mt-2"><?= $statsData['avg_response_time'] ?? '4.2' ?> <span class="text-lg text-slate-400">min</span></p>
          <p class="text-xs text-emerald-400 mt-2 flex items-center gap-1">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M14.707 10.293a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 111.414-1.414L9 12.586V5a1 1 0 012 0v7.586l2.293-2.293a1 1 0 011.414 0z" clip-rule="evenodd"/></svg>
            -8% faster
          </p>
        </div>
        <div class="p-3 bg-gradient-to-br from-emerald-500/20 to-teal-500/20 rounded-xl">
          <svg class="w-6 h-6 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
      </div>
    </div>

    <div class="metric-card">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-slate-400 text-sm font-medium">Success Rate</p>
          <p class="text-3xl font-bold text-white mt-2">98.5<span class="text-lg text-slate-400">%</span></p>
          <p class="text-xs text-emerald-400 mt-2 flex items-center gap-1">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z" clip-rule="evenodd"/></svg>
            +2.3% improvement
          </p>
        </div>
        <div class="p-3 bg-gradient-to-br from-cyan-500/20 to-blue-500/20 rounded-xl">
          <svg class="w-6 h-6 text-cyan-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
      </div>
    </div>

    <div class="metric-card">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-slate-400 text-sm font-medium">Active Fleet</p>
          <p class="text-3xl font-bold text-white mt-2"><?= $statsData['available_drivers'] ?? 0 ?> <span class="text-lg text-slate-400">units</span></p>
          <p class="text-xs text-amber-400 mt-2 flex items-center gap-1">
            <span class="status-indicator busy inline-block"></span>
            <?= ($statsData['available_drivers'] ?? 0) ?> available now
          </p>
        </div>
        <div class="p-3 bg-gradient-to-br from-amber-500/20 to-orange-500/20 rounded-xl">
          <svg class="w-6 h-6 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
          </svg>
        </div>
      </div>
    </div>
  </div>

  <!-- Charts Row -->
  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Requests Over Time -->
    <div class="control-card">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h3 class="text-lg font-semibold text-white">Requests Over Time</h3>
          <p class="text-sm text-slate-400">Daily request volume</p>
        </div>
      </div>
      <div class="chart-container">
        <canvas id="requestsTimeChart"></canvas>
      </div>
    </div>

    <!-- Response Time Distribution -->
    <div class="control-card">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h3 class="text-lg font-semibold text-white">Response Time Distribution</h3>
          <p class="text-sm text-slate-400">Time to first response</p>
        </div>
      </div>
      <div class="chart-container">
        <canvas id="responseTimeChart"></canvas>
      </div>
    </div>
  </div>

  <!-- More Charts -->
  <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <!-- Severity Breakdown -->
    <div class="control-card">
      <div class="mb-6">
        <h3 class="text-lg font-semibold text-white">Severity Breakdown</h3>
        <p class="text-sm text-slate-400">Request severity distribution</p>
      </div>
      <div class="chart-container" style="height: 250px;">
        <canvas id="severityBreakdownChart"></canvas>
      </div>
    </div>

    <!-- Peak Hours -->
    <div class="control-card">
      <div class="mb-6">
        <h3 class="text-lg font-semibold text-white">Peak Hours</h3>
        <p class="text-sm text-slate-400">Busiest times of day</p>
      </div>
      <div class="chart-container" style="height: 250px;">
        <canvas id="peakHoursChart"></canvas>
      </div>
    </div>

    <!-- Driver Performance -->
    <div class="control-card">
      <div class="mb-6">
        <h3 class="text-lg font-semibold text-white">Top Performers</h3>
        <p class="text-sm text-slate-400">Drivers by completed requests</p>
      </div>
      <div class="space-y-4">
        <div class="flex items-center gap-4">
          <div class="w-8 h-8 rounded-full bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center text-white text-xs font-bold">R</div>
          <div class="flex-1">
            <div class="flex justify-between text-sm mb-1">
              <span class="text-white">Ravi Kumar</span>
              <span class="text-slate-400">45 trips</span>
            </div>
            <div class="h-2 bg-slate-700 rounded-full overflow-hidden">
              <div class="h-full bg-indigo-500 rounded-full" style="width: 90%"></div>
            </div>
          </div>
        </div>
        <div class="flex items-center gap-4">
          <div class="w-8 h-8 rounded-full bg-gradient-to-br from-emerald-500 to-teal-500 flex items-center justify-center text-white text-xs font-bold">S</div>
          <div class="flex-1">
            <div class="flex justify-between text-sm mb-1">
              <span class="text-white">Suresh M</span>
              <span class="text-slate-400">38 trips</span>
            </div>
            <div class="h-2 bg-slate-700 rounded-full overflow-hidden">
              <div class="h-full bg-emerald-500 rounded-full" style="width: 76%"></div>
            </div>
          </div>
        </div>
        <div class="flex items-center gap-4">
          <div class="w-8 h-8 rounded-full bg-gradient-to-br from-cyan-500 to-blue-500 flex items-center justify-center text-white text-xs font-bold">V</div>
          <div class="flex-1">
            <div class="flex justify-between text-sm mb-1">
              <span class="text-white">Vijay P</span>
              <span class="text-slate-400">32 trips</span>
            </div>
            <div class="h-2 bg-slate-700 rounded-full overflow-hidden">
              <div class="h-full bg-cyan-500 rounded-full" style="width: 64%"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
  // Requests Over Time Chart
  const requestsTimeCtx = document.getElementById('requestsTimeChart');
  if (requestsTimeCtx) {
    new Chart(requestsTimeCtx, {
      type: 'line',
      data: {
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        datasets: [{
          label: 'Requests',
          data: [28, 35, 22, 45, 38, 52, 30],
          borderColor: '#6366f1',
          backgroundColor: 'rgba(99, 102, 241, 0.1)',
          fill: true,
          tension: 0.4
        }, {
          label: 'Completed',
          data: [26, 33, 20, 42, 36, 48, 28],
          borderColor: '#10b981',
          backgroundColor: 'rgba(16, 185, 129, 0.1)',
          fill: true,
          tension: 0.4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { labels: { color: '#94a3b8' } } },
        scales: {
          x: { grid: { color: 'rgba(148, 163, 184, 0.1)' }, ticks: { color: '#64748b' } },
          y: { grid: { color: 'rgba(148, 163, 184, 0.1)' }, ticks: { color: '#64748b' } }
        }
      }
    });
  }
  
  // Response Time Chart
  const responseTimeCtx = document.getElementById('responseTimeChart');
  if (responseTimeCtx) {
    new Chart(responseTimeCtx, {
      type: 'bar',
      data: {
        labels: ['< 2min', '2-5min', '5-10min', '10-15min', '> 15min'],
        datasets: [{
          data: [45, 80, 35, 15, 5],
          backgroundColor: ['#10b981', '#06b6d4', '#6366f1', '#f59e0b', '#ef4444'],
          borderRadius: 8
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { display: false }, ticks: { color: '#64748b' } },
          y: { grid: { color: 'rgba(148, 163, 184, 0.1)' }, ticks: { color: '#64748b' } }
        }
      }
    });
  }
  
  // Severity Breakdown
  const severityCtx = document.getElementById('severityBreakdownChart');
  if (severityCtx) {
    new Chart(severityCtx, {
      type: 'doughnut',
      data: {
        labels: ['Critical', 'High', 'Medium', 'Low'],
        datasets: [{
          data: [12, 28, 45, 15],
          backgroundColor: ['#ef4444', '#f59e0b', '#06b6d4', '#10b981'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: '65%',
        plugins: { legend: { position: 'bottom', labels: { color: '#94a3b8', padding: 15 } } }
      }
    });
  }
  
  // Peak Hours
  const peakCtx = document.getElementById('peakHoursChart');
  if (peakCtx) {
    new Chart(peakCtx, {
      type: 'bar',
      data: {
        labels: ['6AM', '9AM', '12PM', '3PM', '6PM', '9PM', '12AM'],
        datasets: [{
          data: [8, 25, 18, 12, 30, 22, 10],
          backgroundColor: 'rgba(99, 102, 241, 0.5)',
          borderColor: '#6366f1',
          borderWidth: 1,
          borderRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { display: false }, ticks: { color: '#64748b' } },
          y: { grid: { color: 'rgba(148, 163, 184, 0.1)' }, ticks: { color: '#64748b' } }
        }
      }
    });
  }
});
</script>
