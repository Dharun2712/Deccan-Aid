<?php
/**
 * Reports Page - Detailed Reports & Exports
 * Erode Region - Near Kongu Engineering College
 */
require_once __DIR__ . '/../config.php';

$stats = adminApiCall('/stats');
$requests = adminApiCall('/requests');
$drivers = adminApiCall('/drivers');
$users = adminApiCall('/users');

$statsData = $stats['stats'] ?? [];
$requestList = $requests['requests'] ?? [];
$driverList = $drivers['drivers'] ?? [];
$userList = $users['users'] ?? [];

// Calculate report metrics
$completedRequests = array_filter($requestList, fn($r) => $r['status'] === 'completed');
$criticalRequests = array_filter($requestList, fn($r) => $r['severity'] === 'critical');
$todayRequests = array_filter($requestList, fn($r) => date('Y-m-d', strtotime($r['created_at'])) === date('Y-m-d'));
?>

<div class="space-y-6">
  <!-- Page Header -->
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-bold text-white">Reports</h1>
      <p class="text-slate-400 text-sm mt-1">Detailed reports and data exports - Erode Region</p>
    </div>
    <div class="flex items-center gap-3">
      <select class="px-4 py-2 bg-slate-800/50 border border-slate-700/50 rounded-lg text-sm text-white focus:outline-none focus:border-indigo-500/50">
        <option>Last 7 days</option>
        <option>Last 30 days</option>
        <option>Last 90 days</option>
        <option>Custom Range</option>
      </select>
      <button class="btn-primary">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
        </svg>
        Export PDF
      </button>
    </div>
  </div>

  <!-- Report Summary Cards -->
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
    <div class="metric-card">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-indigo-500/20 rounded-xl">
          <svg class="w-6 h-6 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Total Reports</p>
          <p class="text-2xl font-bold text-white"><?= count($requestList) ?></p>
        </div>
      </div>
    </div>
    <div class="metric-card">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-emerald-500/20 rounded-xl">
          <svg class="w-6 h-6 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Completed</p>
          <p class="text-2xl font-bold text-emerald-400"><?= count($completedRequests) ?></p>
        </div>
      </div>
    </div>
    <div class="metric-card">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-amber-500/20 rounded-xl">
          <svg class="w-6 h-6 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Today's Requests</p>
          <p class="text-2xl font-bold text-amber-400"><?= count($todayRequests) ?></p>
        </div>
      </div>
    </div>
    <div class="metric-card">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-red-500/20 rounded-xl">
          <svg class="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Critical Cases</p>
          <p class="text-2xl font-bold text-red-400"><?= count($criticalRequests) ?></p>
        </div>
      </div>
    </div>
  </div>

  <!-- Report Types Grid -->
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
    <!-- Daily Report -->
    <div class="control-card hover:border-indigo-500/30 transition cursor-pointer group">
      <div class="flex items-start gap-4">
        <div class="p-4 bg-gradient-to-br from-indigo-500/20 to-purple-500/20 rounded-xl group-hover:scale-110 transition">
          <svg class="w-8 h-8 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
        </div>
        <div class="flex-1">
          <h3 class="text-white font-semibold">Daily Report</h3>
          <p class="text-slate-400 text-sm mt-1">Summary of today's activities</p>
          <div class="flex items-center gap-2 mt-3">
            <span class="px-2 py-1 bg-indigo-500/20 text-indigo-400 text-xs rounded">PDF</span>
            <span class="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs rounded">Excel</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Weekly Report -->
    <div class="control-card hover:border-emerald-500/30 transition cursor-pointer group">
      <div class="flex items-start gap-4">
        <div class="p-4 bg-gradient-to-br from-emerald-500/20 to-teal-500/20 rounded-xl group-hover:scale-110 transition">
          <svg class="w-8 h-8 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
          </svg>
        </div>
        <div class="flex-1">
          <h3 class="text-white font-semibold">Weekly Report</h3>
          <p class="text-slate-400 text-sm mt-1">7-day performance analysis</p>
          <div class="flex items-center gap-2 mt-3">
            <span class="px-2 py-1 bg-indigo-500/20 text-indigo-400 text-xs rounded">PDF</span>
            <span class="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs rounded">Excel</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Monthly Report -->
    <div class="control-card hover:border-cyan-500/30 transition cursor-pointer group">
      <div class="flex items-start gap-4">
        <div class="p-4 bg-gradient-to-br from-cyan-500/20 to-blue-500/20 rounded-xl group-hover:scale-110 transition">
          <svg class="w-8 h-8 text-cyan-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
        </div>
        <div class="flex-1">
          <h3 class="text-white font-semibold">Monthly Report</h3>
          <p class="text-slate-400 text-sm mt-1">Comprehensive monthly stats</p>
          <div class="flex items-center gap-2 mt-3">
            <span class="px-2 py-1 bg-indigo-500/20 text-indigo-400 text-xs rounded">PDF</span>
            <span class="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs rounded">Excel</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Driver Performance -->
    <div class="control-card hover:border-purple-500/30 transition cursor-pointer group">
      <div class="flex items-start gap-4">
        <div class="p-4 bg-gradient-to-br from-purple-500/20 to-pink-500/20 rounded-xl group-hover:scale-110 transition">
          <svg class="w-8 h-8 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
        </div>
        <div class="flex-1">
          <h3 class="text-white font-semibold">Driver Performance</h3>
          <p class="text-slate-400 text-sm mt-1"><?= count($driverList) ?> drivers analyzed</p>
          <div class="flex items-center gap-2 mt-3">
            <span class="px-2 py-1 bg-indigo-500/20 text-indigo-400 text-xs rounded">PDF</span>
            <span class="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs rounded">Excel</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Hospital Utilization -->
    <div class="control-card hover:border-amber-500/30 transition cursor-pointer group">
      <div class="flex items-start gap-4">
        <div class="p-4 bg-gradient-to-br from-amber-500/20 to-orange-500/20 rounded-xl group-hover:scale-110 transition">
          <svg class="w-8 h-8 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
          </svg>
        </div>
        <div class="flex-1">
          <h3 class="text-white font-semibold">Hospital Utilization</h3>
          <p class="text-slate-400 text-sm mt-1">Bed occupancy & capacity</p>
          <div class="flex items-center gap-2 mt-3">
            <span class="px-2 py-1 bg-indigo-500/20 text-indigo-400 text-xs rounded">PDF</span>
            <span class="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs rounded">Excel</span>
          </div>
        </div>
      </div>
    </div>

    <!-- User Activity -->
    <div class="control-card hover:border-teal-500/30 transition cursor-pointer group">
      <div class="flex items-start gap-4">
        <div class="p-4 bg-gradient-to-br from-teal-500/20 to-cyan-500/20 rounded-xl group-hover:scale-110 transition">
          <svg class="w-8 h-8 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
        </div>
        <div class="flex-1">
          <h3 class="text-white font-semibold">User Activity</h3>
          <p class="text-slate-400 text-sm mt-1"><?= count($userList) ?> registered users</p>
          <div class="flex items-center gap-2 mt-3">
            <span class="px-2 py-1 bg-indigo-500/20 text-indigo-400 text-xs rounded">PDF</span>
            <span class="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs rounded">Excel</span>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Recent Reports Table -->
  <div class="control-card">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h3 class="text-lg font-semibold text-white">Recent Generated Reports</h3>
        <p class="text-sm text-slate-400">Previously exported reports</p>
      </div>
    </div>
    
    <div class="overflow-x-auto">
      <table class="data-table">
        <thead>
          <tr>
            <th>Report Name</th>
            <th>Type</th>
            <th>Date Range</th>
            <th>Generated</th>
            <th>Format</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td class="text-white">Weekly Emergency Report - Erode</td>
            <td><span class="px-2 py-1 bg-indigo-500/20 text-indigo-400 text-xs rounded">Weekly</span></td>
            <td class="text-slate-400">Jan 18 - Jan 24, 2026</td>
            <td class="text-slate-400">Jan 24, 2026</td>
            <td><span class="px-2 py-1 bg-red-500/20 text-red-400 text-xs rounded">PDF</span></td>
            <td>
              <button class="p-2 text-slate-400 hover:text-white hover:bg-slate-700/50 rounded-lg transition">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
              </button>
            </td>
          </tr>
          <tr>
            <td class="text-white">Driver Performance - January</td>
            <td><span class="px-2 py-1 bg-purple-500/20 text-purple-400 text-xs rounded">Monthly</span></td>
            <td class="text-slate-400">Jan 01 - Jan 24, 2026</td>
            <td class="text-slate-400">Jan 23, 2026</td>
            <td><span class="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs rounded">Excel</span></td>
            <td>
              <button class="p-2 text-slate-400 hover:text-white hover:bg-slate-700/50 rounded-lg transition">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
              </button>
            </td>
          </tr>
          <tr>
            <td class="text-white">KEC Area Emergency Stats</td>
            <td><span class="px-2 py-1 bg-cyan-500/20 text-cyan-400 text-xs rounded">Daily</span></td>
            <td class="text-slate-400">Jan 23, 2026</td>
            <td class="text-slate-400">Jan 23, 2026</td>
            <td><span class="px-2 py-1 bg-red-500/20 text-red-400 text-xs rounded">PDF</span></td>
            <td>
              <button class="p-2 text-slate-400 hover:text-white hover:bg-slate-700/50 rounded-lg transition">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</div>
