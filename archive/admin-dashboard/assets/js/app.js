// Alpine.js App Shell
function appShell() {
  return {
    theme: 'dark',
    init() {
      this.theme = 'dark';
    }
  }
}

// Dashboard data functions
function dashboard() {
  return {
    stats: {
      totalRequests: 0,
      activeRequests: 0,
      availableDrivers: 0,
      totalHospitals: 0
    },
    recentRequests: [],
    loading: true,
    charts: {},
    
    async init() {
      await this.loadStats();
      this.initCharts();
      // Auto refresh every 30 seconds
      setInterval(() => this.loadStats(), 30000);
    },
    
    async loadStats() {
      try {
        const response = await fetch('api/stats.php');
        const data = await response.json();
        if (data.success) {
          this.stats = data.stats;
          this.recentRequests = data.recentRequests || [];
        }
      } catch (e) {
        console.log('Stats loading error:', e);
      }
      this.loading = false;
    },
    
    initCharts() {
      // Requests Chart
      const requestsCtx = document.getElementById('requestsChart');
      if (requestsCtx) {
        this.charts.requests = new Chart(requestsCtx, {
          type: 'line',
          data: {
            labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            datasets: [{
              label: 'Requests',
              data: [12, 19, 8, 15, 22, 18, 10],
              borderColor: '#6366f1',
              backgroundColor: 'rgba(99, 102, 241, 0.1)',
              fill: true,
              tension: 0.4,
              pointBackgroundColor: '#6366f1',
              pointBorderColor: '#fff',
              pointBorderWidth: 2
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: { display: false }
            },
            scales: {
              x: {
                grid: { color: 'rgba(148, 163, 184, 0.1)' },
                ticks: { color: '#64748b' }
              },
              y: {
                grid: { color: 'rgba(148, 163, 184, 0.1)' },
                ticks: { color: '#64748b' }
              }
            }
          }
        });
      }
      
      // Severity Chart
      const severityCtx = document.getElementById('severityChart');
      if (severityCtx) {
        this.charts.severity = new Chart(severityCtx, {
          type: 'doughnut',
          data: {
            labels: ['Critical', 'High', 'Medium', 'Low'],
            datasets: [{
              data: [15, 30, 40, 15],
              backgroundColor: ['#ef4444', '#f59e0b', '#06b6d4', '#10b981'],
              borderWidth: 0
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '70%',
            plugins: {
              legend: {
                position: 'bottom',
                labels: { color: '#94a3b8', padding: 15 }
              }
            }
          }
        });
      }
    }
  }
}

// Ambulances page
function ambulancesPage() {
  return {
    drivers: [],
    loading: true,
    filter: 'all',
    searchQuery: '',
    
    async init() {
      await this.loadDrivers();
    },
    
    async loadDrivers() {
      this.loading = true;
      try {
        const response = await fetch('api/drivers.php');
        const data = await response.json();
        if (data.success) {
          this.drivers = data.drivers || [];
        }
      } catch (e) {
        console.log('Error loading drivers:', e);
      }
      this.loading = false;
    },
    
    get filteredDrivers() {
      let result = this.drivers;
      if (this.filter !== 'all') {
        result = result.filter(d => d.status === this.filter);
      }
      if (this.searchQuery) {
        const q = this.searchQuery.toLowerCase();
        result = result.filter(d => 
          d.name.toLowerCase().includes(q) || 
          (d.vehicle_number && d.vehicle_number.toLowerCase().includes(q))
        );
      }
      return result;
    }
  }
}

// Hospitals page
function hospitalsPage() {
  return {
    hospitals: [],
    loading: true,
    
    async init() {
      await this.loadHospitals();
    },
    
    async loadHospitals() {
      this.loading = true;
      try {
        const response = await fetch('api/hospitals.php');
        const data = await response.json();
        if (data.success) {
          this.hospitals = data.hospitals || [];
        }
      } catch (e) {
        console.log('Error loading hospitals:', e);
      }
      this.loading = false;
    },
    
    getOccupancyColor(hospital) {
      const pct = (hospital.capacity.occupied / hospital.capacity.total) * 100;
      if (pct > 80) return 'red';
      if (pct > 50) return 'amber';
      return 'emerald';
    }
  }
}

// Requests page
function requestsPage() {
  return {
    requests: [],
    loading: true,
    filter: 'all',
    
    async init() {
      await this.loadRequests();
    },
    
    async loadRequests() {
      this.loading = true;
      try {
        let url = 'api/requests.php';
        if (this.filter !== 'all') {
          url += '?status=' + this.filter;
        }
        const response = await fetch(url);
        const data = await response.json();
        if (data.success) {
          this.requests = data.requests || [];
        }
      } catch (e) {
        console.log('Error loading requests:', e);
      }
      this.loading = false;
    },
    
    setFilter(filter) {
      this.filter = filter;
      this.loadRequests();
    }
  }
}

// Users page
function usersPage() {
  return {
    users: [],
    loading: true,
    filter: 'all',
    searchQuery: '',
    
    async init() {
      await this.loadUsers();
    },
    
    async loadUsers() {
      this.loading = true;
      try {
        let url = 'api/users.php';
        if (this.filter !== 'all') {
          url += '?role=' + this.filter;
        }
        const response = await fetch(url);
        const data = await response.json();
        if (data.success) {
          this.users = data.users || [];
        }
      } catch (e) {
        console.log('Error loading users:', e);
      }
      this.loading = false;
    },
    
    get filteredUsers() {
      if (!this.searchQuery) return this.users;
      const q = this.searchQuery.toLowerCase();
      return this.users.filter(u => 
        u.name.toLowerCase().includes(q) || 
        (u.email && u.email.toLowerCase().includes(q))
      );
    }
  }
}

// Format date
function formatDate(dateStr) {
  if (!dateStr) return 'N/A';
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric', 
    hour: '2-digit', 
    minute: '2-digit' 
  });
}

// Time ago
function timeAgo(dateStr) {
  if (!dateStr) return 'N/A';
  const date = new Date(dateStr);
  const now = new Date();
  const diff = Math.floor((now - date) / 1000);
  
  if (diff < 60) return 'Just now';
  if (diff < 3600) return Math.floor(diff / 60) + 'm ago';
  if (diff < 86400) return Math.floor(diff / 3600) + 'h ago';
  return Math.floor(diff / 86400) + 'd ago';
}
