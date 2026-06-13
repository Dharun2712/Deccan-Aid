<?php
/**
 * Hospitals Page - Hospital Management
 */
require_once __DIR__ . '/../config.php';

$hospitals = adminApiCall('/hospitals');
$hospitalList = $hospitals['hospitals'] ?? $hospitals['data'] ?? [];
?>

<div class="space-y-6">
  <!-- Page Header -->
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-bold text-white">Hospitals</h1>
      <p class="text-slate-400 text-sm mt-1">View and manage hospital network</p>
    </div>
    <div class="flex items-center gap-3">
      <div class="relative">
        <input type="text" placeholder="Search hospitals..." 
               class="w-64 px-4 py-2 pl-10 bg-slate-800/50 border border-slate-700/50 rounded-lg text-sm text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500/50">
        <svg class="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
        </svg>
      </div>
    </div>
  </div>

  <!-- Stats Row -->
  <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
    <div class="metric-card">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-cyan-500/20 rounded-xl">
          <svg class="w-6 h-6 text-cyan-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Total Hospitals</p>
          <p class="text-2xl font-bold text-white"><?= count($hospitalList) ?></p>
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
          <p class="text-slate-400 text-sm">Available</p>
          <p class="text-2xl font-bold text-white"><?= count(array_filter($hospitalList, fn($h) => ($h['status'] ?? '') === 'available')) ?></p>
        </div>
      </div>
    </div>
    <div class="metric-card">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-purple-500/20 rounded-xl">
          <svg class="w-6 h-6 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Specialties</p>
          <p class="text-2xl font-bold text-white">12+</p>
        </div>
      </div>
    </div>
  </div>

  <!-- Hospitals Grid -->
  <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
    <?php if (empty($hospitalList)): ?>
    <div class="col-span-full control-card">
      <div class="empty-state py-12">
        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
        </svg>
        <h3>No Hospitals Found</h3>
        <p>No hospitals are registered in the system</p>
      </div>
    </div>
    <?php else: ?>
    <?php foreach ($hospitalList as $hospital): ?>
    <?php 
      $capacity = $hospital['capacity'] ?? ['total' => 100, 'occupied' => 0];
      $occupiedPct = ($capacity['total'] > 0) ? round(($capacity['occupied'] / $capacity['total']) * 100) : 0;
      $capacityColor = $occupiedPct > 80 ? 'red' : ($occupiedPct > 50 ? 'amber' : 'emerald');
    ?>
    <div class="control-card hover:border-cyan-500/30 transition-all">
      <div class="flex items-start justify-between mb-4">
        <div class="flex items-center gap-3">
          <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-cyan-500 to-blue-600 flex items-center justify-center">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          <div>
            <h3 class="text-white font-semibold text-sm"><?= htmlspecialchars($hospital['name'] ?? 'Unknown Hospital') ?></h3>
            <p class="text-slate-400 text-xs"><?= htmlspecialchars($hospital['type'] ?? 'General Hospital') ?></p>
          </div>
        </div>
        <span class="status-badge <?= ($hospital['status'] ?? '') === 'available' ? 'available' : 'offline' ?>">
          <?= ucfirst($hospital['status'] ?? 'N/A') ?>
        </span>
      </div>

      <!-- Capacity Bar -->
      <div class="mb-4">
        <div class="flex items-center justify-between text-xs mb-2">
          <span class="text-slate-400">Bed Capacity</span>
          <span class="text-<?= $capacityColor ?>-400"><?= $occupiedPct ?>% Occupied</span>
        </div>
        <div class="h-2 bg-slate-700 rounded-full overflow-hidden">
          <div class="h-full bg-gradient-to-r from-<?= $capacityColor ?>-500 to-<?= $capacityColor ?>-400 rounded-full transition-all" 
               style="width: <?= $occupiedPct ?>%"></div>
        </div>
        <div class="flex items-center justify-between text-xs mt-1">
          <span class="text-slate-500"><?= $capacity['occupied'] ?? 0 ?> / <?= $capacity['total'] ?? 0 ?> beds</span>
          <span class="text-slate-500"><?= ($capacity['total'] ?? 0) - ($capacity['occupied'] ?? 0) ?> available</span>
        </div>
      </div>

      <div class="space-y-2 mb-4">
        <?php if (!empty($hospital['phone'])): ?>
        <div class="flex items-center gap-2 text-sm">
          <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
          </svg>
          <span class="text-slate-300"><?= htmlspecialchars($hospital['phone']) ?></span>
        </div>
        <?php endif; ?>
        <?php if (!empty($hospital['address'])): ?>
        <div class="flex items-start gap-2 text-sm">
          <svg class="w-4 h-4 text-slate-500 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
          </svg>
          <span class="text-slate-400 text-xs"><?= htmlspecialchars($hospital['address']) ?></span>
        </div>
        <?php endif; ?>
      </div>

      <?php if (!empty($hospital['specialties'])): ?>
      <div class="flex flex-wrap gap-1 mb-4">
        <?php foreach (array_slice($hospital['specialties'], 0, 3) as $specialty): ?>
        <span class="px-2 py-0.5 text-xs bg-slate-700/50 text-slate-300 rounded"><?= htmlspecialchars($specialty) ?></span>
        <?php endforeach; ?>
        <?php if (count($hospital['specialties']) > 3): ?>
        <span class="px-2 py-0.5 text-xs bg-slate-700/50 text-slate-400 rounded">+<?= count($hospital['specialties']) - 3 ?></span>
        <?php endif; ?>
      </div>
      <?php endif; ?>

      <div class="flex items-center gap-2 pt-4 border-t border-slate-700/50">
        <button class="flex-1 btn-secondary text-xs py-2">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
          </svg>
          Details
        </button>
        <button class="flex-1 btn-secondary text-xs py-2">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
          </svg>
          Map
        </button>
      </div>
    </div>
    <?php endforeach; ?>
    <?php endif; ?>
  </div>
</div>
