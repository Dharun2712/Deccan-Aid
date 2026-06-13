<?php
/**
 * Settings Page - System Configuration
 */
require_once __DIR__ . '/../config.php';
?>

<div class="space-y-6">
  <!-- Page Header -->
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-bold text-white">Settings</h1>
      <p class="text-slate-400 text-sm mt-1">System configuration and preferences</p>
    </div>
  </div>

  <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <!-- Settings Navigation -->
    <div class="control-card">
      <nav class="space-y-1">
        <a href="#general" class="flex items-center gap-3 px-4 py-3 text-white bg-indigo-500/20 rounded-lg border border-indigo-500/30">
          <svg class="w-5 h-5 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          General
        </a>
        <a href="#api" class="flex items-center gap-3 px-4 py-3 text-slate-300 hover:bg-slate-700/50 rounded-lg transition">
          <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
          </svg>
          API Configuration
        </a>
        <a href="#notifications" class="flex items-center gap-3 px-4 py-3 text-slate-300 hover:bg-slate-700/50 rounded-lg transition">
          <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
          </svg>
          Notifications
        </a>
        <a href="#security" class="flex items-center gap-3 px-4 py-3 text-slate-300 hover:bg-slate-700/50 rounded-lg transition">
          <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
          </svg>
          Security
        </a>
        <a href="#backup" class="flex items-center gap-3 px-4 py-3 text-slate-300 hover:bg-slate-700/50 rounded-lg transition">
          <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4" />
          </svg>
          Backup
        </a>
      </nav>
    </div>

    <!-- Settings Content -->
    <div class="lg:col-span-2 space-y-6">
      <!-- General Settings -->
      <div id="general" class="control-card">
        <h3 class="text-lg font-semibold text-white mb-6">General Settings</h3>
        
        <div class="space-y-6">
          <div>
            <label class="block text-sm font-medium text-slate-300 mb-2">System Name</label>
            <input type="text" value="Smart Ambulance System" 
                   class="w-full px-4 py-2.5 bg-slate-800/50 border border-slate-700/50 rounded-lg text-white focus:outline-none focus:border-indigo-500/50">
          </div>
          
          <div>
            <label class="block text-sm font-medium text-slate-300 mb-2">Admin Email</label>
            <input type="email" value="admin@smartambulance.com" 
                   class="w-full px-4 py-2.5 bg-slate-800/50 border border-slate-700/50 rounded-lg text-white focus:outline-none focus:border-indigo-500/50">
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-300 mb-2">Timezone</label>
            <select class="w-full px-4 py-2.5 bg-slate-800/50 border border-slate-700/50 rounded-lg text-white focus:outline-none focus:border-indigo-500/50">
              <option>Asia/Kolkata (IST)</option>
              <option>UTC</option>
              <option>America/New_York</option>
            </select>
          </div>

          <div class="flex items-center justify-between p-4 bg-slate-800/30 rounded-lg">
            <div>
              <p class="text-white font-medium">Dark Mode</p>
              <p class="text-sm text-slate-400">Enable dark theme for the dashboard</p>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input type="checkbox" checked class="sr-only peer">
              <div class="w-11 h-6 bg-slate-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-500"></div>
            </label>
          </div>
        </div>
      </div>

      <!-- API Configuration -->
      <div id="api" class="control-card">
        <h3 class="text-lg font-semibold text-white mb-6">API Configuration</h3>
        
        <div class="space-y-6">
          <div>
            <label class="block text-sm font-medium text-slate-300 mb-2">Backend API URL</label>
            <div class="flex gap-2">
              <input type="text" value="<?= API_BASE_URL ?>" 
                     class="flex-1 px-4 py-2.5 bg-slate-800/50 border border-slate-700/50 rounded-lg text-white focus:outline-none focus:border-indigo-500/50 font-mono text-sm">
              <button class="btn-secondary">Test</button>
            </div>
          </div>
          
          <div>
            <label class="block text-sm font-medium text-slate-300 mb-2">Admin API URL</label>
            <div class="flex gap-2">
              <input type="text" value="<?= ADMIN_API_URL ?>" 
                     class="flex-1 px-4 py-2.5 bg-slate-800/50 border border-slate-700/50 rounded-lg text-white focus:outline-none focus:border-indigo-500/50 font-mono text-sm">
              <button class="btn-secondary">Test</button>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-300 mb-2">API Status</label>
            <div class="flex items-center gap-3 p-4 bg-emerald-500/10 border border-emerald-500/30 rounded-lg">
              <span class="status-indicator available"></span>
              <span class="text-emerald-400">Connected and healthy</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Notification Settings -->
      <div id="notifications" class="control-card">
        <h3 class="text-lg font-semibold text-white mb-6">Notification Settings</h3>
        
        <div class="space-y-4">
          <div class="flex items-center justify-between p-4 bg-slate-800/30 rounded-lg">
            <div>
              <p class="text-white font-medium">Critical Alerts</p>
              <p class="text-sm text-slate-400">Notify on critical severity SOS requests</p>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input type="checkbox" checked class="sr-only peer">
              <div class="w-11 h-6 bg-slate-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-500"></div>
            </label>
          </div>

          <div class="flex items-center justify-between p-4 bg-slate-800/30 rounded-lg">
            <div>
              <p class="text-white font-medium">Driver Offline Alerts</p>
              <p class="text-sm text-slate-400">Notify when drivers go offline</p>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input type="checkbox" checked class="sr-only peer">
              <div class="w-11 h-6 bg-slate-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-500"></div>
            </label>
          </div>

          <div class="flex items-center justify-between p-4 bg-slate-800/30 rounded-lg">
            <div>
              <p class="text-white font-medium">Daily Reports</p>
              <p class="text-sm text-slate-400">Send daily summary reports</p>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input type="checkbox" class="sr-only peer">
              <div class="w-11 h-6 bg-slate-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-500"></div>
            </label>
          </div>
        </div>
      </div>

      <!-- Save Button -->
      <div class="flex justify-end gap-3">
        <button class="btn-secondary">Cancel</button>
        <button class="btn-primary">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
          Save Changes
        </button>
      </div>
    </div>
  </div>
</div>
