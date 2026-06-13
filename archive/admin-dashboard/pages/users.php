<?php
/**
 * Users Page - User Management
 */
require_once __DIR__ . '/../config.php';

$users = adminApiCall('/users');
$userList = $users['users'] ?? $users['data'] ?? [];
?>

<div class="space-y-6">
  <!-- Page Header -->
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-bold text-white">Users</h1>
      <p class="text-slate-400 text-sm mt-1">Manage system users and permissions</p>
    </div>
    <div class="flex items-center gap-3">
      <div class="relative">
        <input type="text" placeholder="Search users..." 
               class="w-64 px-4 py-2 pl-10 bg-slate-800/50 border border-slate-700/50 rounded-lg text-sm text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500/50">
        <svg class="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
        </svg>
      </div>
    </div>
  </div>

  <!-- Stats Row -->
  <div class="grid grid-cols-1 sm:grid-cols-4 gap-4">
    <div class="metric-card">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-indigo-500/20 rounded-xl">
          <svg class="w-6 h-6 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Total Users</p>
          <p class="text-2xl font-bold text-white"><?= count($userList) ?></p>
        </div>
      </div>
    </div>
    <div class="metric-card">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-cyan-500/20 rounded-xl">
          <svg class="w-6 h-6 text-cyan-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Patients</p>
          <p class="text-2xl font-bold text-cyan-400"><?= count(array_filter($userList, fn($u) => ($u['role'] ?? '') === 'user')) ?></p>
        </div>
      </div>
    </div>
    <div class="metric-card">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-emerald-500/20 rounded-xl">
          <svg class="w-6 h-6 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Drivers</p>
          <p class="text-2xl font-bold text-emerald-400"><?= count(array_filter($userList, fn($u) => ($u['role'] ?? '') === 'driver')) ?></p>
        </div>
      </div>
    </div>
    <div class="metric-card">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-purple-500/20 rounded-xl">
          <svg class="w-6 h-6 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-sm">Admins</p>
          <p class="text-2xl font-bold text-purple-400"><?= count(array_filter($userList, fn($u) => ($u['role'] ?? '') === 'admin')) ?></p>
        </div>
      </div>
    </div>
  </div>

  <!-- Filter Tabs -->
  <div class="flex items-center gap-2 border-b border-slate-700/50 pb-3">
    <button class="px-4 py-2 text-sm font-medium bg-indigo-500/20 text-indigo-400 rounded-lg">All Users</button>
    <button class="px-4 py-2 text-sm font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg">Patients</button>
    <button class="px-4 py-2 text-sm font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg">Drivers</button>
    <button class="px-4 py-2 text-sm font-medium text-slate-400 hover:bg-slate-700/50 rounded-lg">Admins</button>
  </div>

  <!-- Users Table -->
  <div class="control-card overflow-hidden">
    <?php if (empty($userList)): ?>
    <div class="empty-state py-12">
      <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
      </svg>
      <h3>No Users Found</h3>
      <p>No users are registered in the system</p>
    </div>
    <?php else: ?>
    <div class="overflow-x-auto">
      <table class="data-table">
        <thead>
          <tr>
            <th>User</th>
            <th>Email</th>
            <th>Phone</th>
            <th>Role</th>
            <th>Status</th>
            <th>Joined</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($userList as $user): ?>
          <tr>
            <td>
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-full bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center text-white font-bold">
                  <?= strtoupper(substr($user['name'] ?? 'U', 0, 1)) ?>
                </div>
                <div>
                  <p class="text-white font-medium"><?= htmlspecialchars($user['name'] ?? 'Unknown') ?></p>
                  <p class="text-slate-400 text-xs">ID: <?= substr($user['_id'] ?? $user['user_id'] ?? 'N/A', -6) ?></p>
                </div>
              </div>
            </td>
            <td class="text-slate-300"><?= htmlspecialchars($user['email'] ?? 'N/A') ?></td>
            <td class="text-slate-400"><?= htmlspecialchars($user['phone'] ?? 'N/A') ?></td>
            <td>
              <?php 
              $role = $user['role'] ?? 'user';
              $roleColors = [
                'admin' => 'purple',
                'driver' => 'emerald', 
                'user' => 'cyan',
                'hospital' => 'amber'
              ];
              $roleColor = $roleColors[$role] ?? 'slate';
              ?>
              <span class="px-2.5 py-1 text-xs font-medium bg-<?= $roleColor ?>-500/20 text-<?= $roleColor ?>-400 rounded-full border border-<?= $roleColor ?>-500/30">
                <?= ucfirst($role) ?>
              </span>
            </td>
            <td>
              <div class="flex items-center gap-2">
                <span class="status-indicator <?= ($user['is_active'] ?? true) ? 'available' : 'offline' ?>"></span>
                <span class="text-sm <?= ($user['is_active'] ?? true) ? 'text-emerald-400' : 'text-slate-500' ?>">
                  <?= ($user['is_active'] ?? true) ? 'Active' : 'Inactive' ?>
                </span>
              </div>
            </td>
            <td class="text-slate-400 text-sm"><?= formatDate($user['created_at'] ?? null) ?></td>
            <td>
              <div class="flex items-center gap-1">
                <button class="p-2 text-slate-400 hover:text-white hover:bg-slate-700/50 rounded-lg transition" title="Edit">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                </button>
                <button class="p-2 text-slate-400 hover:text-red-400 hover:bg-red-500/10 rounded-lg transition" title="Delete">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
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
</div>
