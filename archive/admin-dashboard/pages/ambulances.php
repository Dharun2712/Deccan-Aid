<?php
/**
 * Ambulances Page - Driver & Vehicle Management
 */
require_once __DIR__ . '/../config.php';

$drivers = adminApiCall('/drivers');
$driverList = $drivers['drivers'] ?? $drivers['data'] ?? [];
?>

<div x-data="ambulancesPage()" x-init="init()" class="space-y-6">
  <!-- Page Header -->
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-bold text-white">Ambulances & Drivers</h1>
      <p class="text-slate-400 text-sm mt-1">Manage ambulance fleet and driver assignments</p>
    </div>
    <div class="flex items-center gap-3">
      <div class="relative">
        <input type="text" placeholder="Search drivers..." 
               class="w-64 px-4 py-2 pl-10 bg-slate-800/50 border border-slate-700/50 rounded-lg text-sm text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500/50">
        <svg class="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
        </svg>
      </div>
    </div>
  </div>

  <!-- Status Filter -->
  <div class="flex flex-wrap items-center gap-2">
    <button onclick="filterDrivers('all')" class="filter-btn px-4 py-2 text-sm font-medium bg-indigo-500/20 text-indigo-400 rounded-lg border border-indigo-500/30">All</button>
    <button onclick="filterDrivers('available')" class="filter-btn px-4 py-2 text-sm font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg">Available</button>
    <button onclick="filterDrivers('busy')" class="filter-btn px-4 py-2 text-sm font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg">On Mission</button>
    <button onclick="filterDrivers('offline')" class="filter-btn px-4 py-2 text-sm font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg">Offline</button>
    <span class="mx-2 text-slate-600">|</span>
    <button onclick="filterDrivers('BLS')" class="filter-btn px-3 py-2 text-sm font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg">BLS</button>
    <button onclick="filterDrivers('ALS')" class="filter-btn px-3 py-2 text-sm font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg">ALS</button>
    <button onclick="filterDrivers('Mobile ICU')" class="filter-btn px-3 py-2 text-sm font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg">Mobile ICU</button>
  </div>

  <!-- Drivers Grid -->
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
    <?php if (empty($driverList)): ?>
    <div class="col-span-full control-card">
      <div class="empty-state py-12">
        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
        </svg>
        <h3>No Drivers Found</h3>
        <p>No ambulance drivers are registered in the system</p>
      </div>
    </div>
    <?php else: ?>
    <?php foreach ($driverList as $driver): ?>
    <div class="control-card hover:border-indigo-500/30 transition-all" data-status="<?= strtolower($driver['status'] ?? 'offline') ?>" data-category="<?= htmlspecialchars($driver['ambulance_category'] ?? 'BLS') ?>">
      <div class="flex items-start justify-between mb-3">
        <div class="flex items-center gap-3">
          <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-white text-lg font-bold">
            <?= strtoupper(substr($driver['name'] ?? 'D', 0, 1)) ?>
          </div>
          <div>
            <h3 class="text-white font-semibold"><?= htmlspecialchars($driver['name'] ?? 'Unknown') ?></h3>
            <p class="text-slate-400 text-sm"><?= htmlspecialchars($driver['phone'] ?? 'No phone') ?></p>
          </div>
        </div>
        <span class="status-badge <?= strtolower($driver['status'] ?? 'offline') ?>">
          <?= ucfirst($driver['status'] ?? 'Offline') ?>
        </span>
      </div>

      <!-- Ambulance Category Badge -->
      <?php
        $cat = $driver['ambulance_category'] ?? 'BLS';
        $catColors = [
          'BLS'        => 'bg-blue-500/20 text-blue-400 border-blue-500/30',
          'ALS'        => 'bg-amber-500/20 text-amber-400 border-amber-500/30',
          'Mobile ICU' => 'bg-red-500/20 text-red-400 border-red-500/30',
        ];
        $catLabels = [
          'BLS'        => 'Basic Life Support',
          'ALS'        => 'Advanced Life Support',
          'Mobile ICU' => 'Mobile ICU',
        ];
        $catClass = $catColors[$cat] ?? $catColors['BLS'];
        $catLabel = $catLabels[$cat] ?? $cat;
      ?>
      <div class="mb-3">
        <span class="inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-semibold rounded-md border <?= $catClass ?>">
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/>
          </svg>
          <?= $cat ?> &mdash; <?= $catLabel ?>
        </span>
      </div>

      <div class="space-y-2 mb-3">
        <div class="flex items-center justify-between text-sm">
          <span class="text-slate-400">Vehicle</span>
          <span class="text-white font-medium"><?= htmlspecialchars($driver['vehicle_number'] ?? 'N/A') ?></span>
        </div>
        <div class="flex items-center justify-between text-sm">
          <span class="text-slate-400">Vehicle Type</span>
          <span class="text-white"><?= htmlspecialchars($driver['vehicle_type'] ?? 'Ambulance') ?></span>
        </div>
        <?php if (!empty($driver['current_location'])): ?>
        <div class="flex items-center justify-between text-sm">
          <span class="text-slate-400">Location</span>
          <span class="text-cyan-400 text-xs">
            <?= number_format($driver['current_location']['lat'] ?? 0, 4) ?>, <?= number_format($driver['current_location']['lng'] ?? 0, 4) ?>
          </span>
        </div>
        <?php endif; ?>
        <div class="flex items-center justify-between text-sm">
          <span class="text-slate-400">Last Active</span>
          <span class="text-slate-300"><?= timeAgo($driver['last_active'] ?? null) ?></span>
        </div>
      </div>

      <!-- Performance Metrics -->
      <?php
        $arrival = $driver['avg_arrival_min'] ?? 0;
        $speed   = $driver['avg_speed_kmh'] ?? 0;
        $eff     = $driver['efficiency_pct'] ?? 0;
        $trips   = $driver['trips_completed'] ?? 0;
        $rating  = $driver['rating'] ?? 0;

        $effColor = $eff >= 90 ? 'text-emerald-400' : ($eff >= 80 ? 'text-amber-400' : 'text-red-400');
        $effBar   = $eff >= 90 ? 'bg-emerald-500' : ($eff >= 80 ? 'bg-amber-500' : 'bg-red-500');
      ?>
      <div class="bg-slate-800/60 rounded-lg p-3 mb-3 space-y-2.5">
        <div class="flex items-center justify-between text-xs">
          <span class="text-slate-500 uppercase tracking-wide font-semibold">Performance</span>
          <span class="text-yellow-400 font-medium">&#9733; <?= number_format($rating, 1) ?></span>
        </div>
        <div class="grid grid-cols-3 gap-2 text-center">
          <div>
            <div class="text-white text-sm font-bold"><?= number_format($arrival, 1) ?><span class="text-[10px] text-slate-400 ml-0.5">min</span></div>
            <div class="text-slate-500 text-[10px]">Avg Arrival</div>
          </div>
          <div>
            <div class="text-white text-sm font-bold"><?= $speed ?><span class="text-[10px] text-slate-400 ml-0.5">km/h</span></div>
            <div class="text-slate-500 text-[10px]">Avg Speed</div>
          </div>
          <div>
            <div class="text-white text-sm font-bold"><?= $trips ?></div>
            <div class="text-slate-500 text-[10px]">Trips</div>
          </div>
        </div>
        <!-- Efficiency bar -->
        <div>
          <div class="flex items-center justify-between text-xs mb-1">
            <span class="text-slate-400">Efficiency</span>
            <span class="<?= $effColor ?> font-semibold"><?= $eff ?>%</span>
          </div>
          <div class="w-full h-1.5 bg-slate-700 rounded-full overflow-hidden">
            <div class="h-full rounded-full <?= $effBar ?>" style="width:<?= $eff ?>%"></div>
          </div>
        </div>
      </div>

      <div class="flex items-center gap-2 pt-4 border-t border-slate-700/50">
        <button class="flex-1 btn-secondary text-xs py-2">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          Track
        </button>
        <button class="flex-1 btn-secondary text-xs py-2">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
          </svg>
          Contact
        </button>
      </div>
    </div>
    <?php endforeach; ?>
    <?php endif; ?>
  </div>
</div>

<script>
function filterDrivers(filter) {
  const buttons = document.querySelectorAll('.filter-btn');
  buttons.forEach(btn => {
    btn.classList.remove('bg-indigo-500/20', 'text-indigo-400', 'border', 'border-indigo-500/30');
    btn.classList.add('text-slate-400', 'hover:bg-slate-700/50');
  });
  event.target.classList.add('bg-indigo-500/20', 'text-indigo-400', 'border', 'border-indigo-500/30');
  event.target.classList.remove('text-slate-400', 'hover:bg-slate-700/50');

  const cards = document.querySelectorAll('.control-card[data-status]');
  const categories = ['BLS', 'ALS', 'Mobile ICU'];
  const isCategory = categories.includes(filter);

  cards.forEach(card => {
    if (filter === 'all') {
      card.style.display = '';
    } else if (isCategory) {
      card.style.display = card.dataset.category === filter ? '' : 'none';
    } else {
      card.style.display = card.dataset.status === filter ? '' : 'none';
    }
  });
}
</script>
