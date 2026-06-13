<?php
/**
 * Alerts Page - Emergency Alerts & Notifications
 * Chennai Region - Saveetha University
 * Data loaded via AJAX from AWS-DynamoDB (api/alerts.php)
 */
require_once __DIR__ . '/../config.php';
?>

<style>
@keyframes alertSlideIn {
  from { opacity: 0; transform: translateY(-20px); }
  to   { opacity: 1; transform: translateY(0); }
}
@keyframes badgePulse {
  0%   { box-shadow: 0 0 0 0 rgba(251,146,60,0.5); }
  70%  { box-shadow: 0 0 0 6px rgba(251,146,60,0); }
  100% { box-shadow: 0 0 0 0 rgba(251,146,60,0); }
}
</style>

<div class="space-y-6">
  <!-- All Active Alerts (top of page) -->
  <div class="control-card">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h3 class="text-lg font-semibold text-white">All Active Alerts</h3>
        <p class="text-sm text-slate-400">Sorted by newest - Chennai Region
          <span id="dataSourceBadge" class="ml-2 px-2 py-0.5 text-xs rounded-full bg-slate-700 text-slate-400">loading...</span>
          <span id="lastFetched" class="ml-2 text-xs text-slate-500"></span>
        </p>
      </div>
      <div class="flex gap-2" id="filterButtons">
        <button onclick="loadAlerts('all')"      class="filter-btn active px-3 py-1.5 text-xs font-medium bg-indigo-500/20 text-indigo-400 rounded-lg" data-filter="all">All</button>
        <button onclick="loadAlerts('critical')" class="filter-btn px-3 py-1.5 text-xs font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg" data-filter="critical">Critical</button>
        <button onclick="loadAlerts('high')"     class="filter-btn px-3 py-1.5 text-xs font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg" data-filter="high">High</button>
        <button onclick="loadAlerts('medium')"   class="filter-btn px-3 py-1.5 text-xs font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg" data-filter="medium">Medium</button>
      </div>
    </div>
    <div id="alertsListContainer">
      <div class="flex items-center justify-center py-12">
        <svg class="animate-spin w-8 h-8 text-indigo-400" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"></path>
        </svg>
        <span class="ml-3 text-slate-400">Loading alerts from AWS-DynamoDB...</span>
      </div>
    </div>
  </div>

  <!-- Page Header -->
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-bold text-white">Alerts & Notifications</h1>
      <p class="text-slate-400 text-sm mt-1">
        Real-time emergency alerts - Chennai Region
      </p>
    </div>
    <div class="flex items-center gap-3">
      <button onclick="loadAlerts('all')" class="btn-secondary">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
        Refresh
      </button>
      <button class="btn-primary">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
        </svg>
        Configure Alerts
      </button>
    </div>
  </div>

  <!-- Alert Summary -->
  <div class="grid grid-cols-1 sm:grid-cols-4 gap-4">
    <div class="metric-card border-l-4 border-red-500">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-red-500/20 rounded-xl animate-pulse">
          <svg class="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Critical</p>
          <p class="text-2xl font-bold text-red-400" id="countCritical">—</p>
        </div>
      </div>
    </div>
    <div class="metric-card border-l-4 border-amber-500">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-amber-500/20 rounded-xl">
          <svg class="w-6 h-6 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">High Priority</p>
          <p class="text-2xl font-bold text-amber-400" id="countHigh">—</p>
        </div>
      </div>
    </div>
    <div class="metric-card border-l-4 border-cyan-500">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-cyan-500/20 rounded-xl">
          <svg class="w-6 h-6 text-cyan-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Active Alerts</p>
          <p class="text-2xl font-bold text-cyan-400" id="countTotal">—</p>
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
          <p class="text-slate-400 text-sm">Resolved Today</p>
          <p class="text-2xl font-bold text-emerald-400" id="countResolved">—</p>
        </div>
      </div>
    </div>
  </div>

  <!-- Critical Alerts Section (rendered by JS) -->
  <div id="criticalAlertsSection" class="hidden bg-gradient-to-r from-red-500/10 to-orange-500/10 border border-red-500/30 rounded-xl p-6">
    <div class="flex items-center gap-3 mb-4">
      <div class="p-2 bg-red-500/30 rounded-lg animate-pulse">
        <svg class="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
        </svg>
      </div>
      <div>
        <h3 class="text-lg font-semibold text-red-400">Critical Emergencies - Immediate Action Required</h3>
        <p class="text-red-300/70 text-sm">These alerts require immediate attention</p>
      </div>
    </div>
    <div id="criticalAlertsList" class="space-y-3"></div>
  </div>

  <!-- Alert Configuration -->
  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Notification Preferences -->
    <div class="control-card">
      <h3 class="text-lg font-semibold text-white mb-6">Notification Preferences</h3>
      
      <div class="space-y-4">
        <div class="flex items-center justify-between p-4 bg-slate-800/30 rounded-lg">
          <div>
            <p class="text-white font-medium">Critical Alert Sound</p>
            <p class="text-sm text-slate-400">Play sound for critical emergencies</p>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input type="checkbox" checked class="sr-only peer">
            <div class="w-11 h-6 bg-slate-700 rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-red-500"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between p-4 bg-slate-800/30 rounded-lg">
          <div>
            <p class="text-white font-medium">Desktop Notifications</p>
            <p class="text-sm text-slate-400">Show browser notifications</p>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input type="checkbox" checked class="sr-only peer">
            <div class="w-11 h-6 bg-slate-700 rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-500"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between p-4 bg-slate-800/30 rounded-lg">
          <div>
            <p class="text-white font-medium">Email Alerts</p>
            <p class="text-sm text-slate-400">Send email for high priority</p>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input type="checkbox" class="sr-only peer">
            <div class="w-11 h-6 bg-slate-700 rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-500"></div>
          </label>
        </div>
        
        <div class="flex items-center justify-between p-4 bg-slate-800/30 rounded-lg">
          <div>
            <p class="text-white font-medium">SMS Notifications</p>
            <p class="text-sm text-slate-400">Text messages for critical alerts</p>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input type="checkbox" checked class="sr-only peer">
            <div class="w-11 h-6 bg-slate-700 rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-500"></div>
          </label>
        </div>
      </div>
    </div>

    <!-- Alert Rules -->
    <div class="control-card">
      <h3 class="text-lg font-semibold text-white mb-6">Alert Rules - Chennai Region</h3>
      
      <div class="space-y-4">
        <div class="p-4 bg-red-500/10 border border-red-500/30 rounded-lg">
          <div class="flex items-center gap-3 mb-2">
            <span class="status-indicator critical"></span>
            <span class="text-red-400 font-medium">Critical Priority</span>
          </div>
          <p class="text-slate-400 text-sm">Cardiac arrest, severe trauma, unconscious patients near Saveetha University area</p>
        </div>
        
        <div class="p-4 bg-amber-500/10 border border-amber-500/30 rounded-lg">
          <div class="flex items-center gap-3 mb-2">
            <span class="status-indicator busy"></span>
            <span class="text-amber-400 font-medium">High Priority</span>
          </div>
          <p class="text-slate-400 text-sm">Accidents, breathing difficulties, chest pain in Chennai region</p>
        </div>
        
        <div class="p-4 bg-cyan-500/10 border border-cyan-500/30 rounded-lg">
          <div class="flex items-center gap-3 mb-2">
            <span class="w-2.5 h-2.5 rounded-full bg-cyan-400"></span>
            <span class="text-cyan-400 font-medium">Medium Priority</span>
          </div>
          <p class="text-slate-400 text-sm">Fever emergencies, minor injuries, general transport</p>
        </div>
        
        <div class="p-4 bg-emerald-500/10 border border-emerald-500/30 rounded-lg">
          <div class="flex items-center gap-3 mb-2">
            <span class="w-2.5 h-2.5 rounded-full bg-emerald-400"></span>
            <span class="text-emerald-400 font-medium">Low Priority</span>
          </div>
          <p class="text-slate-400 text-sm">Scheduled transfers, non-emergency transport</p>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
// ============================================================
// Alerts AJAX — fetches from api/alerts.php (AWS-DynamoDB)
// Incremental: only prepends NEW entries, never re-renders all
// ============================================================
const severityColors = {
  critical: 'red',
  high: 'amber',
  medium: 'cyan',
  low: 'emerald'
};

// Track known alert IDs so we only add new ones
let knownAlertIds = new Set();
let currentFilter = 'all';
let initialLoadDone = false;

// Convert UTC date string to IST display (UTC+5:30)
function toIST(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  if (isNaN(d)) return '';
  return d.toLocaleString('en-IN', { timeZone: 'Asia/Kolkata', day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit', hour12: true });
}

function timeAgoJS(dateStr) {
  if (!dateStr) return 'Just now';
  const diff = Math.floor((Date.now() - new Date(dateStr).getTime()) / 1000);
  if (diff < 0)   return toIST(dateStr);
  if (diff < 60)  return diff + 's ago';
  if (diff < 3600) return Math.floor(diff/60) + 'm ago';
  if (diff < 86400) return Math.floor(diff/3600) + 'h ago';
  return Math.floor(diff/86400) + 'd ago';
}

function escHtml(str) {
  if (!str) return '';
  return String(str).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function renderAlertRow(alert) {
  const sev   = (alert.severity || 'medium').toLowerCase();
  const color = severityColors[sev] || 'cyan';
  const initial = (alert.user_name || 'U').charAt(0).toUpperCase();
  const location = alert.location?.name || alert.pickup_location || 'Chennai';
  const statusSlug = (alert.status || 'pending').toLowerCase().replace(/ /g,'-');
  const id = alert._id || alert.id || Math.random().toString(36).slice(2);

  return `
  <div class="alert-row flex items-center gap-4 p-4 bg-slate-800/50 border border-${color}-500/30 rounded-lg hover:bg-slate-800/80 transition" data-alert-id="${escHtml(id)}" data-created="${escHtml(alert.created_at||'')}">
    <div class="status-indicator ${sev}"></div>
    <div class="w-10 h-10 rounded-full bg-gradient-to-br from-${color}-500 to-${color}-600 flex items-center justify-center text-white font-bold text-sm">${initial}</div>
    <div class="flex-1 min-w-0">
      <div class="flex items-center gap-2 flex-wrap">
        <span class="text-white font-medium">${escHtml(alert.user_name || 'Unknown')}</span>
        <span class="status-badge ${sev} text-xs">${sev.charAt(0).toUpperCase()+sev.slice(1)}</span>
        <span class="status-badge ${statusSlug} text-xs">${escHtml(alert.status || 'Pending')}</span>
      </div>
      <p class="text-slate-400 text-sm truncate">${escHtml(location)}</p>
      <p class="text-slate-500 text-xs mt-1">${escHtml(alert.emergency_type||'Emergency')} • ${escHtml(alert.user_phone||'')}</p>
    </div>
    <div class="text-right">
      <p class="text-${color}-400 text-sm font-medium timeago" data-ts="${escHtml(alert.created_at||'')}">${timeAgoJS(alert.created_at)}</p>
      <p class="text-slate-500 text-xs">${toIST(alert.created_at)}</p>
      ${alert.driver_name ? `<p class="text-slate-400 text-xs mt-1">Driver: ${escHtml(alert.driver_name)}</p>` : ''}
    </div>
    <div class="flex gap-2">
      <button class="p-2 text-slate-400 hover:text-white hover:bg-slate-700/50 rounded-lg transition" title="View Details">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
      </button>
      <button class="p-2 text-slate-400 hover:text-white hover:bg-slate-700/50 rounded-lg transition" title="Track Location">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/></svg>
      </button>
    </div>
  </div>`;
}

// Update all "time ago" labels without re-rendering
function refreshTimeAgos() {
  document.querySelectorAll('.timeago').forEach(el => {
    const ts = el.dataset.ts;
    if (ts) el.textContent = timeAgoJS(ts);
  });
}

function loadAlerts(severity) {
  if (severity !== undefined) {
    // Filter changed — reset and do a full load
    currentFilter = severity;
    knownAlertIds.clear();
    initialLoadDone = false;
  }

  // Update filter button active state
  document.querySelectorAll('.filter-btn').forEach(btn => {
    const isActive = btn.dataset.filter === currentFilter;
    btn.className = isActive
      ? 'filter-btn active px-3 py-1.5 text-xs font-medium bg-indigo-500/20 text-indigo-400 rounded-lg'
      : 'filter-btn px-3 py-1.5 text-xs font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg';
  });

  const container = document.getElementById('alertsListContainer');

  // Show spinner only on first load
  if (!initialLoadDone) {
    container.innerHTML = `<div class="flex items-center justify-center py-12">
      <svg class="animate-spin w-6 h-6 text-indigo-400" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"></path></svg>
      <span class="ml-3 text-slate-400 text-sm">Fetching from AWS-DynamoDB...</span>
    </div>`;
  }

  fetch(`api/alerts.php?severity=${encodeURIComponent(currentFilter)}`)
    .then(r => r.json())
    .then(data => {
      if (!data.success) throw new Error('API error');

      // Update source badge
      const badge = document.getElementById('dataSourceBadge');
      if (data.source === 'mongodb') {
        badge.textContent = '⚡ AWS-DynamoDB';
        badge.className = 'ml-2 px-2 py-0.5 text-xs rounded-full bg-orange-500/20 text-orange-400';
      } else {
        badge.textContent = '📦 Demo Data';
        badge.className = 'ml-2 px-2 py-0.5 text-xs rounded-full bg-slate-600/40 text-slate-400';
      }

      // Update counts
      document.getElementById('countCritical').textContent = data.counts.critical;
      document.getElementById('countHigh').textContent     = data.counts.high;
      document.getElementById('countTotal').textContent    = data.counts.total;
      const resolvedEl = document.getElementById('countResolved');
      if (resolvedEl) resolvedEl.textContent = '—';

      // Last fetched time
      document.getElementById('lastFetched').textContent = '• updated ' + timeAgoJS(data.fetched_at);

      // Pulse the badge to show a refresh happened
      badge.style.animation = 'none';
      badge.offsetHeight; // trigger reflow
      badge.style.animation = 'badgePulse 0.8s ease-out';

      // Critical section
      const criticalAlerts = data.alerts.filter(a => a.severity === 'critical');
      const critSection = document.getElementById('criticalAlertsSection');
      const critList    = document.getElementById('criticalAlertsList');
      if (currentFilter === 'all' && criticalAlerts.length > 0) {
        critSection.classList.remove('hidden');
        critList.innerHTML = criticalAlerts.slice(0,5).map(a => `
          <div class="flex items-center gap-4 p-4 bg-red-500/10 border border-red-500/30 rounded-lg">
            <div class="status-indicator critical"></div>
            <div class="flex-1">
              <div class="flex items-center gap-2">
                <span class="text-white font-semibold">${escHtml(a.user_name||'Unknown')}</span>
                <span class="text-red-400 text-xs">• ${escHtml(a.emergency_type||'Emergency')}</span>
              </div>
              <p class="text-slate-400 text-sm">${escHtml(a.location?.name||a.pickup_location||'Chennai')}</p>
            </div>
            <div class="text-right">
              <p class="text-red-400 text-sm font-medium">${timeAgoJS(a.created_at)}</p>
              <p class="text-slate-500 text-xs">${toIST(a.created_at)}</p>
              <p class="text-slate-500 text-xs">${escHtml(a.user_phone||'')}</p>
            </div>
            <a href="?page=requests" class="btn-primary bg-red-500 hover:bg-red-600 text-sm py-2">Respond</a>
          </div>`).join('');
      } else {
        critSection.classList.add('hidden');
      }

      // --- Incremental list update ---
      if (!initialLoadDone) {
        // First load: render all
        if (data.alerts.length === 0) {
          container.innerHTML = `<div class="empty-state py-12">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
            <h3>No Active Alerts</h3><p>All emergencies have been handled</p>
          </div>`;
        } else {
          container.innerHTML = `<div class="space-y-3" id="alertsList">${data.alerts.map(renderAlertRow).join('')}</div>`;
        }
        data.alerts.forEach(a => knownAlertIds.add(a._id || a.id));
        initialLoadDone = true;
      } else {
        // Subsequent polls: only prepend NEW alerts
        const newAlerts = data.alerts.filter(a => {
          const aid = a._id || a.id;
          return aid && !knownAlertIds.has(aid);
        });

        if (newAlerts.length > 0) {
          let list = document.getElementById('alertsList');
          if (!list) {
            // If container was showing "no alerts", replace it
            container.innerHTML = `<div class="space-y-3" id="alertsList"></div>`;
            list = document.getElementById('alertsList');
          }
          // Prepend new alerts at the top with a highlight animation
          newAlerts.forEach(a => {
            const temp = document.createElement('div');
            temp.innerHTML = renderAlertRow(a);
            const row = temp.firstElementChild;
            row.style.animation = 'alertSlideIn 0.5s ease-out';
            row.style.borderColor = '#facc15'; // yellow flash
            list.prepend(row);
            knownAlertIds.add(a._id || a.id);
            // Remove yellow flash after 3s
            setTimeout(() => { row.style.borderColor = ''; }, 3000);
          });
        }

        // Update time-ago labels in place
        refreshTimeAgos();
      }
    })
    .catch(() => {
      if (!initialLoadDone) {
        container.innerHTML = `<div class="empty-state py-12">
          <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
          <h3>Failed to Load Alerts</h3><p>Could not reach the alerts API. <button onclick="loadAlerts('all')" class="text-indigo-400 underline">Retry</button></p>
        </div>`;
      }
    });
}

// Initial load immediately (DOM elements are above this script)
loadAlerts('all');
// Then poll every 5 seconds (incremental)
setInterval(() => loadAlerts(), 5000);
</script>
