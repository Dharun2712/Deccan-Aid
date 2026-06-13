<?php
/**
 * Requests Page - SOS Request Management
 * Live data via AJAX from api/requests.php (MongoDB patient_requests only)
 */
require_once __DIR__ . '/../config.php';
?>

<style>
  @keyframes reqSlideIn {
    from {
      opacity: 0;
      transform: translateY(-20px);
    }

    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  @keyframes reqBadgePulse {
    0% {
      box-shadow: 0 0 0 0 rgba(251, 146, 60, 0.5);
    }

    70% {
      box-shadow: 0 0 0 6px rgba(251, 146, 60, 0);
    }

    100% {
      box-shadow: 0 0 0 0 rgba(251, 146, 60, 0);
    }
  }
</style>

<div class="space-y-6">
  <!-- Page Header -->
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-bold text-white">SOS Requests</h1>
      <p class="text-slate-400 text-sm mt-1">
        Monitor and manage emergency requests - Live
        <span id="reqSourceBadge"
          class="ml-2 px-2 py-0.5 text-xs rounded-full bg-slate-700 text-slate-400">loading...</span>
        <span id="reqLastFetched" class="ml-2 text-xs text-slate-500"></span>
      </p>
    </div>
    <div class="flex items-center gap-3">
      <button id="reqDeleteAllBtn" onclick="deleteAllRequests()" class="btn-primary bg-red-600 hover:bg-red-700 focus:ring-red-500 text-white">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6M9 7V4a1 1 0 011-1h4a1 1 0 011 1v3M4 7h16" />
        </svg>
        Delete All
      </button>
      <button onclick="loadRequests('all')" class="btn-primary">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
        Refresh
      </button>
    </div>
  </div>

  <!-- Stats Row -->
  <div class="grid grid-cols-1 sm:grid-cols-4 gap-4">
    <div class="metric-card">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-indigo-500/20 rounded-xl">
          <svg class="w-6 h-6 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Total</p>
          <p class="text-2xl font-bold text-white" id="reqCountTotal">0</p>
        </div>
      </div>
    </div>
    <div class="metric-card">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-amber-500/20 rounded-xl">
          <svg class="w-6 h-6 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">High</p>
          <p class="text-2xl font-bold text-amber-400" id="reqCountHigh">0</p>
        </div>
      </div>
    </div>
    <div class="metric-card">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-red-500/20 rounded-xl">
          <svg class="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Critical</p>
          <p class="text-2xl font-bold text-red-400" id="reqCountCritical">0</p>
        </div>
      </div>
    </div>
    <div class="metric-card">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-emerald-500/20 rounded-xl">
          <svg class="w-6 h-6 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Medium</p>
          <p class="text-2xl font-bold text-emerald-400" id="reqCountMedium">0</p>
        </div>
      </div>
    </div>
  </div>

  <!-- Filter Tabs -->
  <div class="flex items-center gap-2 border-b border-slate-700/50 pb-3">
    <button onclick="loadRequests('all')"
      class="req-filter-btn active px-4 py-2 text-sm font-medium bg-indigo-500/20 text-indigo-400 rounded-lg"
      data-filter="all">All Requests</button>
    <button onclick="loadRequests('critical')"
      class="req-filter-btn px-4 py-2 text-sm font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg"
      data-filter="critical">Critical</button>
    <button onclick="loadRequests('high')"
      class="req-filter-btn px-4 py-2 text-sm font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg"
      data-filter="high">High</button>
    <button onclick="loadRequests('medium')"
      class="req-filter-btn px-4 py-2 text-sm font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg"
      data-filter="medium">Medium</button>
    <button onclick="loadRequests('low')"
      class="req-filter-btn px-4 py-2 text-sm font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg"
      data-filter="low">Low</button>
  </div>

  <!-- Requests Table (AJAX) -->
  <div class="control-card overflow-hidden">
    <div id="reqTableContainer">
      <div class="flex items-center justify-center py-12">
        <svg class="animate-spin w-8 h-8 text-indigo-400" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"></path>
        </svg>
        <span class="ml-3 text-slate-400">Loading requests from MongoDB...</span>
      </div>
    </div>
  </div>
</div>

<script>
  // ============================================================
  // SOS Requests AJAX (MongoDB patient_requests)
  // Incremental: only prepends NEW entries on poll
  // ============================================================
  const reqSevColors = { critical: 'red', high: 'amber', medium: 'cyan', low: 'emerald' };
  let reqKnownIds = new Set();
  let reqCurrentFilter = 'all';
  let reqInitialDone = false;
  const reqDeleteBtnDefaultHtml = `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6M9 7V4a1 1 0 011-1h4a1 1 0 011 1v3M4 7h16" /></svg>Delete All`;

  function setDeleteBtnBusy(isBusy) {
    const btn = document.getElementById('reqDeleteAllBtn');
    if (!btn) return;
    btn.disabled = isBusy;
    btn.classList.toggle('opacity-60', isBusy);
    btn.classList.toggle('cursor-not-allowed', isBusy);
    btn.innerHTML = isBusy
      ? `<svg class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"></path></svg>Deleting...`
      : reqDeleteBtnDefaultHtml;
  }

  async function deleteAllRequests() {
    const approved = confirm('This will permanently delete all SOS requests from MongoDB. Continue?');
    if (!approved) return;

    const confirmation = prompt('Type DELETE to confirm clearing all SOS requests:');
    if (confirmation !== 'DELETE') {
      alert('Delete cancelled. Confirmation text did not match.');
      return;
    }

    setDeleteBtnBusy(true);
    try {
      const response = await fetch('api/requests.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'delete_all', confirm: 'DELETE_ALL' })
      });

      const data = await response.json().catch(() => ({ success: false, error: 'Invalid server response' }));
      if (!response.ok || !data.success) {
        throw new Error(data.error || 'Failed to delete SOS requests');
      }

      reqKnownIds.clear();
      reqInitialDone = false;
      loadRequests(reqCurrentFilter);

      const deletedCount = Number(data.deleted_count || 0);
      alert(`Deleted ${deletedCount} SOS request${deletedCount === 1 ? '' : 's'} successfully.`);
    } catch (err) {
      alert(`Delete failed: ${err.message || err}`);
    } finally {
      setDeleteBtnBusy(false);
    }
  }

  function reqToIST(dateStr) {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    if (isNaN(d)) return '';
    return d.toLocaleString('en-IN', { timeZone: 'Asia/Kolkata', day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit', hour12: true });
  }
  function reqTimeAgo(dateStr) {
    if (!dateStr) return 'Just now';
    const diff = Math.floor((Date.now() - new Date(dateStr).getTime()) / 1000);
    if (diff < 0) return reqToIST(dateStr);
    if (diff < 60) return diff + 's ago';
    if (diff < 3600) return Math.floor(diff / 60) + 'm ago';
    if (diff < 86400) return Math.floor(diff / 3600) + 'h ago';
    return Math.floor(diff / 86400) + 'd ago';
  }
  function reqEsc(s) { return s ? String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;') : ''; }

  function normalizeReqSeverity(raw) {
    const key = String(raw || '').toLowerCase();
    if (key === 'critical' || key === 'severe') return 'critical';
    if (key === 'high') return 'high';
    if (key === 'low' || key === 'minor') return 'low';
    return 'medium';
  }

  function formatReqType(request) {
    if (request.emergency_type) return String(request.emergency_type);
    if (!request.condition) return 'Emergency';
    return String(request.condition)
      .replace(/_/g, ' ')
      .replace(/\b\w/g, ch => ch.toUpperCase());
  }

  function resolveReqLocationName(request) {
    return 'Reva University';
  }

  const revaMapDestination = {
    lat: 13.1165,
    lng: 77.6341,
  };

  function reqToNumber(value) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }

  function extractReqCoordinates(request) {
    let lat = reqToNumber(request.latitude ?? request.lat ?? (request.location && request.location.lat));
    let lng = reqToNumber(request.longitude ?? request.lng ?? (request.location && request.location.lng));

    const coordinates = request.location && Array.isArray(request.location.coordinates)
      ? request.location.coordinates
      : null;

    if ((lat === null || lng === null) && coordinates && coordinates.length >= 2) {
      lng = reqToNumber(coordinates[0]);
      lat = reqToNumber(coordinates[1]);
    }

    if (lat === null || lng === null) return null;
    return { lat, lng };
  }

  function getRevaDirectionsUrl(request) {
    const destination = `${revaMapDestination.lat},${revaMapDestination.lng}`;
    const origin = extractReqCoordinates(request);

    let mapsUrl = `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(destination)}&travelmode=driving`;
    if (origin) {
      mapsUrl += `&origin=${encodeURIComponent(`${origin.lat},${origin.lng}`)}`;
    }

    return mapsUrl;
  }

  function renderReqRow(a) {
    const sev = normalizeReqSeverity(a.severity || a.preliminary_severity || a.injury_level);
    const color = reqSevColors[sev] || 'cyan';
    const statusSlug = (a.status || 'pending').toLowerCase().replace(/ /g, '-');
    const id = a._id || a.request_id || a.id || '';
    const shortId = id.slice(-8);
    const userName = a.user_name || a.name || 'Unknown';
    const initial = userName.charAt(0).toUpperCase();
    const emergencyType = formatReqType(a);
    const loc = resolveReqLocationName(a);
    const createdAt = a.created_at || a.timestamp || '';
    const directionsUrl = getRevaDirectionsUrl(a);

    return `<tr class="req-row hover:bg-slate-800/50 transition" data-req-id="${reqEsc(id)}">
    <td class="truncate"><span class="font-mono text-xs text-indigo-400">#${reqEsc(shortId)}</span></td>
    <td class="truncate">
      <div class="flex items-center gap-2 min-w-0">
        <div class="w-7 h-7 flex-shrink-0 rounded-full bg-gradient-to-br from-${color}-500 to-${color}-600 flex items-center justify-center text-white text-xs font-bold">${initial}</div>
        <span class="text-white text-sm truncate">${reqEsc(userName)}</span>
      </div>
    </td>
    <td class="text-slate-400 text-xs truncate" title="${reqEsc(emergencyType)}">${reqEsc(emergencyType)}</td>
    <td class="whitespace-nowrap"><span class="status-badge ${sev} text-xs"><span class="status-indicator ${sev} inline-block"></span> ${sev.charAt(0).toUpperCase() + sev.slice(1)}</span></td>
    <td class="whitespace-nowrap"><span class="status-badge ${statusSlug} text-xs">${reqEsc(a.status || 'Pending')}</span></td>
    <td class="text-slate-400 text-xs truncate">${reqEsc(loc)}</td>
    <td class="whitespace-nowrap">
      <div class="text-right">
        <p class="text-${color}-400 text-xs font-medium req-timeago" data-ts="${reqEsc(createdAt)}">${reqTimeAgo(createdAt)}</p>
        <p class="text-slate-500 text-[10px]">${reqToIST(createdAt)}</p>
      </div>
    </td>
    <td>
      <div class="flex items-center gap-1">
        <button class="p-2 text-slate-400 hover:text-white hover:bg-slate-700/50 rounded-lg transition" title="View Details">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
        </button>
        <a href="${reqEsc(directionsUrl)}" target="_blank" rel="noopener noreferrer" class="p-2 inline-flex text-slate-400 hover:text-white hover:bg-slate-700/50 rounded-lg transition" title="Directions to REVA University">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/></svg>
        </a>
      </div>
    </td>
  </tr>`;
  }

  function reqRefreshTimeAgos() {
    document.querySelectorAll('.req-timeago').forEach(el => {
      const ts = el.dataset.ts;
      if (ts) el.textContent = reqTimeAgo(ts);
    });
  }

  function loadRequests(severity) {
    if (severity !== undefined) {
      reqCurrentFilter = severity;
      reqKnownIds.clear();
      reqInitialDone = false;
    }

    document.querySelectorAll('.req-filter-btn').forEach(btn => {
      const isActive = btn.dataset.filter === reqCurrentFilter;
      btn.className = isActive
        ? 'req-filter-btn active px-4 py-2 text-sm font-medium bg-indigo-500/20 text-indigo-400 rounded-lg'
        : 'req-filter-btn px-4 py-2 text-sm font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg';
    });

    const container = document.getElementById('reqTableContainer');

    if (!reqInitialDone) {
      container.innerHTML = `<div class="flex items-center justify-center py-12">
      <svg class="animate-spin w-6 h-6 text-indigo-400" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"></path></svg>
      <span class="ml-3 text-slate-400 text-sm">Fetching from MongoDB...</span>
    </div>`;
    }

    fetch(`api/requests.php?severity=${encodeURIComponent(reqCurrentFilter)}`)
      .then(r => r.json())
      .then(data => {
        if (!data.success) throw new Error('API error');
        const reqItems = Array.isArray(data.requests) ? data.requests : [];

        // Badge
        const badge = document.getElementById('reqSourceBadge');
        if (data.source === 'mongodb') {
          badge.textContent = 'Google Cloud Functions';
          badge.className = 'ml-2 px-2 py-0.5 text-xs rounded-full bg-orange-500/20 text-orange-400';
        } else {
          badge.textContent = 'Unavailable';
          badge.className = 'ml-2 px-2 py-0.5 text-xs rounded-full bg-slate-600/40 text-slate-400';
        }
        badge.style.animation = 'none';
        badge.offsetHeight;
        badge.style.animation = 'reqBadgePulse 0.8s ease-out';

        // Counts
        document.getElementById('reqCountTotal').textContent = data.counts.total;
        document.getElementById('reqCountCritical').textContent = data.counts.critical;
        document.getElementById('reqCountHigh').textContent = data.counts.high;
        document.getElementById('reqCountMedium').textContent = data.counts.medium;
        document.getElementById('reqLastFetched').textContent = '• updated ' + reqTimeAgo(data.fetched_at);

        if (!reqInitialDone) {
          // First load — full table
          if (reqItems.length === 0) {
            container.innerHTML = `<div class="empty-state py-12">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
            <h3>No SOS Requests</h3><p>No active emergency requests found</p>
          </div>`;
          } else {
            container.innerHTML = `<div class="overflow-x-auto"><table class="data-table w-full table-fixed">
          <colgroup><col style="width:7%"><col style="width:18%"><col style="width:21%"><col style="width:10%"><col style="width:10%"><col style="width:14%"><col style="width:12%"><col style="width:8%"></colgroup>
          <thead><tr>
            <th>ID</th><th>User</th><th>Type</th><th>Severity</th><th>Status</th><th>Location</th><th>Time</th><th>Actions</th>
          </tr></thead><tbody id="reqTbody">${reqItems.map(renderReqRow).join('')}</tbody></table></div>`;
          }
          reqItems.forEach(a => reqKnownIds.add(a._id || a.request_id || a.id));
          reqInitialDone = true;
        } else {
          // Incremental — only prepend new rows
          const newAlerts = reqItems.filter(a => {
            const aid = a._id || a.request_id || a.id;
            return aid && !reqKnownIds.has(aid);
          });
          if (newAlerts.length > 0) {
            let tbody = document.getElementById('reqTbody');
            if (!tbody) {
              container.innerHTML = `<div class="overflow-x-auto"><table class="data-table w-full table-fixed">
              <colgroup><col style="width:7%"><col style="width:18%"><col style="width:21%"><col style="width:10%"><col style="width:10%"><col style="width:14%"><col style="width:12%"><col style="width:8%"></colgroup>
              <thead><tr>
              <th>ID</th><th>User</th><th>Type</th><th>Severity</th><th>Status</th><th>Location</th><th>Time</th><th>Actions</th>
            </tr></thead><tbody id="reqTbody"></tbody></table></div>`;
              tbody = document.getElementById('reqTbody');
            }
            newAlerts.forEach(a => {
              const temp = document.createElement('tbody');
              temp.innerHTML = renderReqRow(a);
              const row = temp.firstElementChild;
              row.style.animation = 'reqSlideIn 0.5s ease-out';
              row.style.borderLeft = '3px solid #facc15';
              tbody.prepend(row);
              reqKnownIds.add(a._id || a.request_id || a.id);
              setTimeout(() => { row.style.borderLeft = ''; }, 3000);
            });
          }
          reqRefreshTimeAgos();
        }
      })
      .catch(() => {
        if (!reqInitialDone) {
          container.innerHTML = `<div class="empty-state py-12">
          <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
          <h3>Failed to Load Requests</h3><p>Could not reach the API. <button onclick="loadRequests('all')" class="text-indigo-400 underline">Retry</button></p>
        </div>`;
        }
      });
  }

  // Immediate load + 5s polling
  loadRequests('all');
  setInterval(() => loadRequests(), 5000);
</script>