<?php
/**
 * Dispatch Management - Ambulance Assignment & Coordination
 * Erode Region - Kongu Engineering College Area
 */
require_once __DIR__ . '/../config.php';

$drivers = getDummyDrivers();
$requests = getDummyRequests();
$hospitals = getDummyHospitals();

$pendingRequests = array_filter($requests, fn($r) => $r['status'] === 'pending');
$activeDispatches = array_filter($requests, fn($r) => in_array($r['status'], ['accepted', 'in_progress']));
$availableDrivers = array_filter($drivers, fn($d) => $d['status'] === 'available');
?>

<div class="space-y-6">
  <!-- Page Header -->
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-bold text-white">Dispatch Center</h1>
      <p class="text-slate-400 text-sm mt-1">Real-time ambulance dispatch & coordination - Erode Region</p>
    </div>
    <div class="flex items-center gap-3">
      <div class="flex items-center gap-2 px-3 py-2 rounded-lg bg-emerald-500/10 border border-emerald-500/30">
        <div class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></div>
        <span class="text-sm font-medium text-emerald-400">Live Mode</span>
      </div>
      <button onclick="location.reload()" class="btn-secondary">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
        Refresh
      </button>
    </div>
  </div>

  <!-- Dispatch Stats -->
  <div class="grid grid-cols-1 sm:grid-cols-5 gap-4">
    <div class="metric-card border-l-4 border-red-500">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-red-500/20 rounded-xl animate-pulse">
          <svg class="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-xs uppercase tracking-wide">Pending</p>
          <p class="text-2xl font-bold text-red-400"><?= count($pendingRequests) ?></p>
        </div>
      </div>
    </div>
    <div class="metric-card border-l-4 border-amber-500">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-amber-500/20 rounded-xl">
          <svg class="w-6 h-6 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-xs uppercase tracking-wide">In Progress</p>
          <p class="text-2xl font-bold text-amber-400"><?= count($activeDispatches) ?></p>
        </div>
      </div>
    </div>
    <div class="metric-card border-l-4 border-emerald-500">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-emerald-500/20 rounded-xl">
          <svg class="w-6 h-6 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-xs uppercase tracking-wide">Available</p>
          <p class="text-2xl font-bold text-emerald-400"><?= count($availableDrivers) ?></p>
        </div>
      </div>
    </div>
    <div class="metric-card border-l-4 border-cyan-500">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-cyan-500/20 rounded-xl">
          <svg class="w-6 h-6 text-cyan-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-xs uppercase tracking-wide">Hospitals</p>
          <p class="text-2xl font-bold text-cyan-400"><?= count($hospitals) ?></p>
        </div>
      </div>
    </div>
    <div class="metric-card border-l-4 border-indigo-500">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-indigo-500/20 rounded-xl">
          <svg class="w-6 h-6 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-xs uppercase tracking-wide">Avg Response</p>
          <p class="text-2xl font-bold text-indigo-400">4.2<span class="text-sm">min</span></p>
        </div>
      </div>
    </div>
  </div>

  <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
    <!-- Pending Requests Queue -->
    <div class="control-card xl:col-span-2">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h3 class="text-lg font-semibold text-white">Dispatch Queue</h3>
          <p class="text-sm text-slate-400">Pending requests awaiting assignment</p>
        </div>
        <span class="px-3 py-1.5 bg-red-500/20 text-red-400 rounded-lg text-sm font-medium">
          <?= count($pendingRequests) ?> Pending
        </span>
      </div>
      
      <?php if (empty($pendingRequests)): ?>
      <div class="empty-state py-12">
        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <h3>Queue Empty</h3>
        <p>All requests have been dispatched</p>
      </div>
      <?php else: ?>
      <div class="space-y-4">
        <?php foreach (array_slice($pendingRequests, 0, 6) as $request): 
          $severityColors = ['critical' => 'red', 'high' => 'amber', 'medium' => 'cyan', 'low' => 'emerald'];
          $color = $severityColors[$request['severity'] ?? 'medium'] ?? 'cyan';
        ?>
        <div class="p-4 bg-slate-800/50 border border-<?= $color ?>-500/30 rounded-xl hover:border-<?= $color ?>-500/50 transition group">
          <div class="flex items-start gap-4">
            <div class="status-indicator <?= $request['severity'] ?? 'medium' ?>"></div>
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-2">
                <span class="text-white font-medium"><?= htmlspecialchars($request['user_name'] ?? 'Unknown') ?></span>
                <span class="status-badge <?= $request['severity'] ?? 'medium' ?> text-xs"><?= ucfirst($request['severity'] ?? 'Medium') ?></span>
              </div>
              <p class="text-slate-400 text-sm mb-1">
                <span class="text-<?= $color ?>-400"><?= htmlspecialchars($request['emergency_type'] ?? 'Emergency') ?></span>
              </p>
              <div class="flex items-center gap-2 text-slate-500 text-xs">
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                </svg>
                <?= htmlspecialchars($request['location']['name'] ?? $request['pickup_location'] ?? 'Erode') ?>
              </div>
            </div>
            <div class="text-right">
              <p class="text-<?= $color ?>-400 text-sm font-medium"><?= timeAgo($request['created_at'] ?? null) ?></p>
              <p class="text-slate-500 text-xs"><?= $request['user_phone'] ?? '' ?></p>
            </div>
          </div>
          
          <div class="mt-4 pt-4 border-t border-slate-700/50">
            <div class="text-xs text-slate-500 mb-2">
              Recommended: <span class="text-slate-300"><?= $hospitals[array_rand($hospitals)]['name'] ?? 'Nearest Hospital' ?></span>
            </div>
            <div class="flex items-center gap-2">
              <select class="flex-1 min-w-0 text-xs bg-slate-700/50 border border-slate-600/50 rounded-lg px-2 py-1.5 text-slate-300 focus:border-indigo-500/50 focus:outline-none">
                <option>Select Driver</option>
                <?php foreach (array_slice($availableDrivers, 0, 5) as $driver): ?>
                <option value="<?= $driver['_id'] ?>"><?= $driver['name'] ?> - <?= $driver['vehicle_number'] ?></option>
                <?php endforeach; ?>
              </select>
              <button class="flex-shrink-0 btn-primary text-sm py-1.5">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
                Dispatch
              </button>
            </div>
          </div>
        </div>
        <?php endforeach; ?>
      </div>
      <?php endif; ?>
    </div>

    <!-- Available Drivers -->
    <div class="control-card">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h3 class="text-lg font-semibold text-white">Available Drivers</h3>
          <p class="text-sm text-slate-400">Ready for dispatch</p>
        </div>
        <span class="px-3 py-1.5 bg-emerald-500/20 text-emerald-400 rounded-lg text-sm font-medium">
          <?= count($availableDrivers) ?> Online
        </span>
      </div>
      
      <div class="space-y-3">
        <?php foreach (array_slice($availableDrivers, 0, 8) as $driver): ?>
        <div class="flex items-center gap-3 p-3 bg-slate-800/30 rounded-lg hover:bg-slate-800/50 transition cursor-pointer group">
          <div class="relative">
            <div class="w-10 h-10 rounded-full bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center text-white font-bold text-sm">
              <?= strtoupper(substr($driver['name'], 0, 1)) ?>
            </div>
            <div class="absolute -bottom-1 -right-1 w-3.5 h-3.5 bg-emerald-400 rounded-full border-2 border-slate-800"></div>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-white text-sm font-medium truncate"><?= htmlspecialchars($driver['name']) ?></p>
            <p class="text-slate-500 text-xs"><?= htmlspecialchars($driver['vehicle_number'] ?? '') ?></p>
          </div>
          <div class="text-right">
            <p class="text-emerald-400 text-xs font-medium">Available</p>
            <p class="text-slate-500 text-xs"><?= rand(1, 5) ?> km away</p>
          </div>
          <button class="opacity-0 group-hover:opacity-100 transition p-2 text-indigo-400 hover:bg-indigo-500/20 rounded-lg">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          </button>
        </div>
        <?php endforeach; ?>
      </div>
      
      <div class="mt-4 pt-4 border-t border-slate-700/50">
        <a href="?page=ambulances" class="text-indigo-400 hover:text-indigo-300 text-sm flex items-center gap-2">
          View all drivers
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
          </svg>
        </a>
      </div>
    </div>
  </div>

  <!-- Active Dispatches -->
  <div class="control-card">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h3 class="text-lg font-semibold text-white">Active Dispatches</h3>
        <p class="text-sm text-slate-400">Currently in progress</p>
      </div>
      <div class="flex gap-2">
        <button class="px-3 py-1.5 text-xs font-medium bg-indigo-500/20 text-indigo-400 rounded-lg">All</button>
        <button class="px-3 py-1.5 text-xs font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg">En Route</button>
        <button class="px-3 py-1.5 text-xs font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg">At Scene</button>
        <button class="px-3 py-1.5 text-xs font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg">To Hospital</button>
      </div>
    </div>

    <?php if (empty($activeDispatches)): ?>
    <div class="empty-state py-12">
      <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M13 10V3L4 14h7v7l9-11h-7z" />
      </svg>
      <h3>No Active Dispatches</h3>
      <p>All ambulances are on standby</p>
    </div>
    <?php else: ?>
    <div class="overflow-x-auto">
      <table class="w-full">
        <thead>
          <tr class="text-left border-b border-slate-800/50">
            <th class="px-4 py-3 text-xs font-semibold text-slate-400 uppercase tracking-wide">Request</th>
            <th class="px-4 py-3 text-xs font-semibold text-slate-400 uppercase tracking-wide">Driver</th>
            <th class="px-4 py-3 text-xs font-semibold text-slate-400 uppercase tracking-wide">Status</th>
            <th class="px-4 py-3 text-xs font-semibold text-slate-400 uppercase tracking-wide">Location</th>
            <th class="px-4 py-3 text-xs font-semibold text-slate-400 uppercase tracking-wide">Hospital</th>
            <th class="px-4 py-3 text-xs font-semibold text-slate-400 uppercase tracking-wide">ETA</th>
            <th class="px-4 py-3 text-xs font-semibold text-slate-400 uppercase tracking-wide">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-800/50">
          <?php foreach (array_slice($activeDispatches, 0, 8) as $dispatch): 
            $driver = array_filter($drivers, fn($d) => ($d['id'] ?? '') === ($dispatch['driver_id'] ?? ''));
            $driver = reset($driver) ?: null;
            $hospital = $hospitals[array_rand($hospitals)] ?? null;
            $statusClass = $dispatch['status'] === 'in_progress' ? 'in-progress' : 'accepted';
          ?>
          <tr class="hover:bg-slate-800/30 transition">
            <td class="px-4 py-4">
              <div class="flex items-center gap-3">
                <div class="status-indicator <?= $dispatch['severity'] ?? 'medium' ?>"></div>
                <div>
                  <p class="text-white font-medium"><?= htmlspecialchars($dispatch['user_name'] ?? 'Unknown') ?></p>
                  <p class="text-slate-500 text-xs"><?= htmlspecialchars($dispatch['emergency_type'] ?? 'Emergency') ?></p>
                </div>
              </div>
            </td>
            <td class="px-4 py-4">
              <div class="flex items-center gap-2">
                <div class="w-8 h-8 rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-white text-xs font-bold">
                  <?= $driver ? strtoupper(substr($driver['name'], 0, 1)) : '?' ?>
                </div>
                <div>
                  <p class="text-white text-sm"><?= htmlspecialchars($dispatch['driver_name'] ?? $driver['name'] ?? 'Assigning...') ?></p>
                  <p class="text-slate-500 text-xs"><?= $driver['vehicle_number'] ?? '' ?></p>
                </div>
              </div>
            </td>
            <td class="px-4 py-4">
              <span class="status-badge <?= $statusClass ?>"><?= ucfirst(str_replace('_', ' ', $dispatch['status'] ?? 'Pending')) ?></span>
            </td>
            <td class="px-4 py-4">
              <p class="text-slate-300 text-sm truncate max-w-[150px]"><?= htmlspecialchars($dispatch['location']['name'] ?? 'Erode') ?></p>
            </td>
            <td class="px-4 py-4">
              <p class="text-slate-300 text-sm"><?= htmlspecialchars($hospital['name'] ?? 'TBD') ?></p>
            </td>
            <td class="px-4 py-4">
              <span class="text-amber-400 font-medium"><?= rand(2, 15) ?> min</span>
            </td>
            <td class="px-4 py-4">
              <div class="flex items-center gap-2">
                <button class="p-2 text-slate-400 hover:text-white hover:bg-slate-700/50 rounded-lg transition" title="Track">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                  </svg>
                </button>
                <button class="p-2 text-slate-400 hover:text-white hover:bg-slate-700/50 rounded-lg transition" title="Call Driver">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                  </svg>
                </button>
                <button class="p-2 text-emerald-400 hover:bg-emerald-500/20 rounded-lg transition" title="Mark Complete">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                </button>
              </div>
            </td>
          </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
    <?php endif; ?>
  </div>

  <!-- Nearby Hospitals Quick Reference -->
  <div class="control-card">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h3 class="text-lg font-semibold text-white">Erode Region Hospitals</h3>
        <p class="text-sm text-slate-400">Quick reference for dispatch routing</p>
      </div>
      <a href="?page=hospitals" class="text-indigo-400 hover:text-indigo-300 text-sm">View All →</a>
    </div>
    
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      <?php foreach (array_slice($hospitals, 0, 8) as $hospital): 
        $bedsAvailable = rand(5, 25);
        $bedsTotal = rand(50, 150);
        $occupancy = round((($bedsTotal - $bedsAvailable) / $bedsTotal) * 100);
      ?>
      <div class="p-4 bg-slate-800/30 rounded-xl border border-slate-700/50 hover:border-indigo-500/50 transition">
        <div class="flex items-start gap-3 mb-3">
          <div class="p-2 bg-cyan-500/20 rounded-lg">
            <svg class="w-5 h-5 text-cyan-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-white text-sm font-medium truncate"><?= htmlspecialchars($hospital['name']) ?></p>
            <p class="text-slate-500 text-xs"><?= rand(1, 8) ?> km • <?= $hospital['type'] ?? 'General' ?></p>
          </div>
        </div>
        <div class="flex items-center justify-between text-xs">
          <span class="text-slate-400">Beds: <span class="text-emerald-400"><?= $bedsAvailable ?></span>/<?= $bedsTotal ?></span>
          <span class="<?= $occupancy > 80 ? 'text-red-400' : ($occupancy > 60 ? 'text-amber-400' : 'text-emerald-400') ?>"><?= $occupancy ?>% full</span>
        </div>
      </div>
      <?php endforeach; ?>
    </div>
  </div>
</div>
