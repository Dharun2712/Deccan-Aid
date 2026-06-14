<?php
require_once __DIR__ . '/../config.php';
$currentPage = $_GET['page'] ?? 'dashboard';
?>
<!DOCTYPE html>
<html lang="en" x-data="appShell()" x-init="init()" :class="{ 'dark': theme === 'dark' }">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Smart Ambulance Admin</title>
  <link rel="icon" type="image/svg+xml" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><rect width='100' height='100' rx='20' fill='%236366f1'/><text x='50' y='65' font-size='50' text-anchor='middle' fill='white'>🚑</text></svg>">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <script src="https://cdn.tailwindcss.com"></script>
  <script>
    tailwind.config = {
      darkMode: 'class',
      theme: {
        extend: {
          fontFamily: {
            sans: ['Poppins', 'sans-serif'],
          },
          colors: {
            neon: {
              400: '#00f0ff',
              500: '#00d1ff',
              600: '#00b3ff',
            },
            primary: {
              400: '#818cf8',
              500: '#6366f1',
              600: '#4f46e5',
            }
          },
          boxShadow: {
            neon: '0 0 20px rgba(99, 102, 241, 0.6)',
            'neon-cyan': '0 0 20px rgba(0, 209, 255, 0.6)',
          }
        }
      }
    }
  </script>
  <link href="https://unpkg.com/aos@2.3.1/dist/aos.css" rel="stylesheet">
  <!-- Leaflet.js for Interactive Maps -->
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
  <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
  <link rel="stylesheet" href="assets/css/styles.css" />
</head>
<body class="bg-slate-950 text-slate-100 min-h-screen overflow-x-hidden">
  <!-- Animated background -->
  <div class="fixed inset-0 -z-10">
    <div class="absolute inset-0 bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950"></div>
    <div class="absolute top-0 left-1/4 w-96 h-96 bg-indigo-500/20 rounded-full blur-[128px] animate-pulse"></div>
    <div class="absolute bottom-0 right-1/4 w-96 h-96 bg-purple-500/20 rounded-full blur-[128px] animate-pulse" style="animation-delay: 1s;"></div>
  </div>

  <!-- Sidebar Navigation -->
  <aside class="fixed left-0 top-0 h-screen w-72 bg-slate-900/40 backdrop-blur-2xl border-r border-slate-800/50 z-50 flex flex-col">
    <div class="p-6 border-b border-slate-800/50">
      <div class="flex items-center gap-3">
        <div class="relative">
          <div class="h-12 w-12 rounded-2xl bg-gradient-to-br from-indigo-500 to-purple-600 shadow-[0_0_30px_rgba(99,102,241,0.6)] flex items-center justify-center">
            <svg class="w-7 h-7 text-white" fill="currentColor" viewBox="0 0 24 24">
              <path d="M8.5 14.5L4 19l1.5 1.5L9 17h12v-2H8.5zM19 3h-4.5l-2.7 2.7L6 3 4.5 4.5l5.8 5.8L3 17.5l1.4 1.4 7.3-7.2L14 14h3l2-2 2 2h1V5l-3 3V3z"/>
            </svg>
          </div>
          <div class="absolute -bottom-1 -right-1 h-4 w-4 bg-emerald-400 rounded-full border-2 border-slate-900 animate-pulse"></div>
        </div>
        <div>
          <div class="text-xs font-semibold tracking-wider text-indigo-400 uppercase">Admin Panel</div>
          <div class="text-sm font-bold text-white">Smart Ambulance</div>
        </div>
      </div>
    </div>
    
    <nav class="flex-1 p-4 space-y-2 overflow-y-auto">
      <a href="?page=dashboard" class="nav-item group <?= $currentPage === 'dashboard' ? 'active' : '' ?>">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 5a1 1 0 011-1h4a1 1 0 011 1v7a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM14 5a1 1 0 011-1h4a1 1 0 011 1v7a1 1 0 01-1 1h-4a1 1 0 01-1-1V5zM4 16a1 1 0 011-1h4a1 1 0 011 1v3a1 1 0 01-1 1H5a1 1 0 01-1-1v-3zM14 16a1 1 0 011-1h4a1 1 0 011 1v3a1 1 0 01-1 1h-4a1 1 0 01-1-1v-3z"></path></svg>
        <span>Dashboard</span>
        <div class="nav-indicator"></div>
      </a>
      <a href="?page=dispatch" class="nav-item group <?= $currentPage === 'dispatch' ? 'active' : '' ?>">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7"></path></svg>
        <span>Dispatch</span>
        <div class="nav-indicator"></div>
      </a>
      <a href="?page=tracking" class="nav-item group <?= $currentPage === 'tracking' ? 'active' : '' ?>">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
        <span>Live Tracking</span>
        <div class="nav-indicator"></div>
      </a>
      <a href="?page=ambulances" class="nav-item group <?= $currentPage === 'ambulances' ? 'active' : '' ?>">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>
        <span>Ambulances</span>
        <div class="nav-indicator"></div>
      </a>
      <a href="?page=hospitals" class="nav-item group <?= $currentPage === 'hospitals' ? 'active' : '' ?>">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path></svg>
        <span>Hospitals</span>
        <div class="nav-indicator"></div>
      </a>
      <a href="?page=requests" class="nav-item group <?= $currentPage === 'requests' ? 'active' : '' ?>">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
        <span>SOS Requests</span>
        <div class="nav-indicator"></div>
      </a>
      <a href="?page=users" class="nav-item group <?= $currentPage === 'users' ? 'active' : '' ?>">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path></svg>
        <span>Users</span>
        <div class="nav-indicator"></div>
      </a>
      <a href="?page=analytics" class="nav-item group <?= $currentPage === 'analytics' ? 'active' : '' ?>">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>
        <span>Analytics</span>
        <div class="nav-indicator"></div>
      </a>
      <a href="?page=reports" class="nav-item group <?= $currentPage === 'reports' ? 'active' : '' ?>">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
        <span>Reports</span>
        <div class="nav-indicator"></div>
      </a>
      <a href="?page=alerts" class="nav-item group <?= $currentPage === 'alerts' ? 'active' : '' ?>">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"></path></svg>
        <span>Alerts</span>
        <?php 
        $requests = adminApiCall('/requests');
        $criticalCount = count(array_filter($requests['requests'] ?? [], fn($r) => $r['severity'] === 'critical' && in_array($r['status'], ['pending', 'accepted'])));
        if ($criticalCount > 0): 
        ?>
        <span class="ml-auto bg-red-500 text-white text-xs font-bold px-2 py-0.5 rounded-full animate-pulse"><?= $criticalCount ?></span>
        <?php endif; ?>
        <div class="nav-indicator"></div>
      </a>
      
      <div class="my-4 border-t border-slate-800/50"></div>
      
      <a href="?page=settings" class="nav-item group <?= $currentPage === 'settings' ? 'active' : '' ?>">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><circle cx="12" cy="12" r="3"></circle></svg>
        <span>Settings</span>
        <div class="nav-indicator"></div>
      </a>
    </nav>
    
    <div class="p-4 border-t border-slate-800/50">
      <div class="flex items-center gap-3 p-3 rounded-xl bg-slate-800/30">
        <div class="h-10 w-10 rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-white font-bold">
          A
        </div>
        <div class="flex-1">
          <div class="text-sm font-medium text-white">Admin</div>
          <div class="text-xs text-slate-400">Super Admin</div>
        </div>
      </div>
    </div>
  </aside>

  <!-- Main Content -->
  <main class="ml-72 min-h-screen p-8">
    <!-- Top Bar -->
    <header class="flex items-center justify-between mb-8" data-aos="fade-down">
      <div class="flex items-center gap-4">
        <div class="relative">
          <input type="text" placeholder="Search..." class="w-80 px-4 py-2.5 pl-10 rounded-xl bg-slate-800/50 border border-slate-700/50 text-slate-200 placeholder-slate-500 focus:outline-none focus:border-indigo-500/50 focus:ring-2 focus:ring-indigo-500/20 transition-all">
          <svg class="w-5 h-5 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
        </div>
      </div>
      <div class="flex items-center gap-4">
        <div class="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-emerald-500/10 border border-emerald-500/30">
          <div class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></div>
          <span class="text-xs font-medium text-emerald-400">System Online</span>
        </div>
        <button onclick="location.reload()" class="p-2.5 rounded-xl bg-slate-800/50 border border-slate-700/50 text-slate-400 hover:text-white hover:border-indigo-500/50 transition-all">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path></svg>
        </button>
        <button class="relative p-2.5 rounded-xl bg-slate-800/50 border border-slate-700/50 text-slate-400 hover:text-white hover:border-indigo-500/50 transition-all">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"></path></svg>
          <span class="absolute -top-1 -right-1 h-4 w-4 bg-red-500 rounded-full text-[10px] font-bold flex items-center justify-center">3</span>
        </button>
      </div>
    </header>
