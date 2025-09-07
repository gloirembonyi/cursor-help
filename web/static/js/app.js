// Cursor Helper Web UI JavaScript Application
class CursorHelperApp {
    constructor() {
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.loadInitialData();
        this.startStatusPolling();
    }

    // Event Listeners
    setupEventListeners() {
        // Main action buttons
        document.getElementById('reset-btn').addEventListener('click', () => this.resetConfig());
        document.getElementById('kill-cursor-btn').addEventListener('click', () => this.killCursor());
        
        // Config section buttons
        document.getElementById('refresh-config-btn').addEventListener('click', () => this.loadConfig());
        document.getElementById('generate-preview-btn').addEventListener('click', () => this.showPreviewModal());
        document.getElementById('toggle-config-btn').addEventListener('click', () => this.toggleConfigDetails());
        
        // Log actions
        document.getElementById('clear-logs-btn').addEventListener('click', () => this.clearLogs());
        
        // Modal buttons
        document.getElementById('success-ok-btn').addEventListener('click', () => this.hideSuccessModal());
        document.getElementById('error-ok-btn').addEventListener('click', () => this.hideErrorModal());
        document.getElementById('preview-close-btn').addEventListener('click', () => this.hidePreviewModal());
        document.getElementById('preview-regenerate-btn').addEventListener('click', () => this.regeneratePreview());
        
        // Copy buttons
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('copy-btn') || e.target.parentElement.classList.contains('copy-btn')) {
                const button = e.target.classList.contains('copy-btn') ? e.target : e.target.parentElement;
                const targetId = button.getAttribute('data-copy');
                this.copyToClipboard(targetId);
            }
        });
        
        // Modal overlay clicks
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('modal')) {
                if (e.target.id === 'success-modal') this.hideSuccessModal();
                if (e.target.id === 'error-modal') this.hideErrorModal();
                if (e.target.id === 'preview-modal') this.hidePreviewModal();
            }
        });

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.hideAllModals();
            }
        });
    }

    // Data Loading
    async loadInitialData() {
        this.addLog('Loading system information...', 'info');
        await Promise.all([
            this.loadSystemInfo(),
            this.loadConfig(),
            this.checkCursorStatus()
        ]);
        this.addLog('Initial data loaded successfully', 'success');
    }

    async loadSystemInfo() {
        try {
            const response = await fetch('/api/system-info');
            const data = await response.json();
            
            if (data.success) {
                this.updateSystemInfo(data.data);
            } else {
                throw new Error(data.error || 'Failed to load system info');
            }
        } catch (error) {
            console.error('Error loading system info:', error);
            this.addLog('Failed to load system information', 'error');
        }
    }

    async loadConfig() {
        try {
            const response = await fetch('/api/config');
            const data = await response.json();
            
            if (data.success) {
                this.updateConfigDisplay(data.data);
            } else {
                throw new Error(data.error || 'Failed to load config');
            }
        } catch (error) {
            console.error('Error loading config:', error);
            this.addLog('Failed to load configuration', 'error');
        }
    }

    async checkCursorStatus() {
        try {
            const response = await fetch('/api/check-cursor');
            const data = await response.json();
            
            if (data.success) {
                this.updateCursorStatus(data.data.running);
            } else {
                throw new Error(data.error || 'Failed to check Cursor status');
            }
        } catch (error) {
            console.error('Error checking Cursor status:', error);
            this.addLog('Failed to check Cursor status', 'error');
        }
    }

    // UI Updates
    updateSystemInfo(info) {
        document.getElementById('os-info').textContent = info.os.charAt(0).toUpperCase() + info.os.slice(1);
        document.getElementById('user-info').textContent = info.username;
        document.getElementById('config-path').textContent = info.configPath;
        
        const adminIcon = document.getElementById('admin-icon');
        const adminStatus = document.getElementById('admin-status');
        
        if (info.isAdmin) {
            adminIcon.className = 'fas fa-shield-alt';
            adminIcon.style.color = '#10b981';
            adminStatus.textContent = 'Administrator';
            adminStatus.style.color = '#10b981';
        } else {
            adminIcon.className = 'fas fa-shield-alt';
            adminIcon.style.color = '#ef4444';
            adminStatus.textContent = 'Standard User';
            adminStatus.style.color = '#ef4444';
        }
    }

    updateConfigDisplay(config) {
        if (!config) {
            this.setConfigValue('machine-id', 'No configuration found');
            this.setConfigValue('mac-machine-id', 'No configuration found');
            this.setConfigValue('device-id', 'No configuration found');
            this.setConfigValue('sqm-id', 'No configuration found');
            this.setConfigValue('last-modified', 'No configuration found');
            return;
        }

        this.setConfigValue('machine-id', config.telemetryMachineId || 'Not set');
        this.setConfigValue('mac-machine-id', config.telemetryMacMachineId || 'Not set');
        this.setConfigValue('device-id', config.telemetryDevDeviceId || 'Not set');
        this.setConfigValue('sqm-id', config.telemetrySqmId || 'Not set');
        this.setConfigValue('last-modified', config.lastModified ? new Date(config.lastModified).toLocaleString() : 'Not set');
    }

    setConfigValue(id, value) {
        const element = document.getElementById(id);
        if (element) {
            element.textContent = value;
        }
    }

    updateCursorStatus(isRunning) {
        const indicator = document.getElementById('cursor-indicator');
        const statusText = document.getElementById('cursor-status-text');
        const killButton = document.getElementById('kill-cursor-btn');
        const statusDot = indicator.querySelector('.status-dot');
        
        if (isRunning) {
            statusDot.className = 'status-dot running';
            statusText.textContent = 'Running';
            statusText.style.color = '#ef4444';
            killButton.disabled = false;
        } else {
            statusDot.className = 'status-dot stopped';
            statusText.textContent = 'Not Running';
            statusText.style.color = '#10b981';
            killButton.disabled = true;
        }
    }

    // Actions
    async resetConfig() {
        const readOnly = document.getElementById('readonly-option').checked;
        
        // Check if Cursor is running
        await this.checkCursorStatus();
        const isRunning = document.getElementById('cursor-status-text').textContent === 'Running';
        
        if (isRunning && !confirm('Cursor is currently running. It will be automatically closed before resetting the configuration. Continue?')) {
            return;
        }

        this.showLoading('Resetting Cursor configuration...');
        
        try {
            const response = await fetch('/api/reset', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    setReadOnly: readOnly
                })
            });
            
            const data = await response.json();
            
            if (data.success) {
                this.hideLoading();
                this.showSuccessModal('Configuration reset successfully!');
                this.loadConfig();
                this.checkCursorStatus();
            } else {
                throw new Error(data.error || 'Reset failed');
            }
        } catch (error) {
            this.hideLoading();
            this.showErrorModal('Failed to reset configuration: ' + error.message);
            this.addLog('Reset failed: ' + error.message, 'error');
        }
    }

    async killCursor() {
        this.showLoading('Closing Cursor processes...');
        
        try {
            const response = await fetch('/api/kill-cursor', {
                method: 'POST'
            });
            
            const data = await response.json();
            
            if (data.success) {
                this.hideLoading();
                this.addLog('Cursor processes closed successfully', 'success');
                this.checkCursorStatus();
            } else {
                throw new Error(data.error || 'Failed to close Cursor');
            }
        } catch (error) {
            this.hideLoading();
            this.showErrorModal('Failed to close Cursor: ' + error.message);
            this.addLog('Failed to close Cursor: ' + error.message, 'error');
        }
    }

    async showPreviewModal() {
        this.showLoading('Generating preview identifiers...');
        
        try {
            const response = await fetch('/api/generate-ids', {
                method: 'POST'
            });
            
            const data = await response.json();
            
            if (data.success) {
                this.hideLoading();
                this.displayPreview(data.data);
                document.getElementById('preview-modal').classList.add('show');
            } else {
                throw new Error(data.error || 'Failed to generate preview');
            }
        } catch (error) {
            this.hideLoading();
            this.showErrorModal('Failed to generate preview: ' + error.message);
        }
    }

    displayPreview(config) {
        const grid = document.getElementById('preview-grid');
        grid.innerHTML = `
            <div class="preview-item">
                <label>Machine ID:</label>
                <span>${config.telemetryMachineId}</span>
            </div>
            <div class="preview-item">
                <label>MAC Machine ID:</label>
                <span>${config.telemetryMacMachineId}</span>
            </div>
            <div class="preview-item">
                <label>Device ID:</label>
                <span>${config.telemetryDevDeviceId}</span>
            </div>
            <div class="preview-item">
                <label>SQM ID:</label>
                <span>${config.telemetrySqmId}</span>
            </div>
        `;
    }

    async regeneratePreview() {
        await this.showPreviewModal();
    }

    // UI Controls
    toggleConfigDetails() {
        const details = document.getElementById('config-details');
        const button = document.getElementById('toggle-config-btn');
        const icon = button.querySelector('i');
        
        if (details.style.display === 'none') {
            details.style.display = 'block';
            button.innerHTML = '<i class="fas fa-chevron-up"></i> Hide Details';
        } else {
            details.style.display = 'none';
            button.innerHTML = '<i class="fas fa-chevron-down"></i> Show Details';
        }
    }

    // Modal Management
    showSuccessModal(message) {
        document.getElementById('success-message').textContent = message;
        document.getElementById('success-modal').classList.add('show');
    }

    hideSuccessModal() {
        document.getElementById('success-modal').classList.remove('show');
    }

    showErrorModal(message) {
        document.getElementById('error-message').textContent = message;
        document.getElementById('error-modal').classList.add('show');
    }

    hideErrorModal() {
        document.getElementById('error-modal').classList.remove('show');
    }

    hidePreviewModal() {
        document.getElementById('preview-modal').classList.remove('show');
    }

    hideAllModals() {
        this.hideSuccessModal();
        this.hideErrorModal();
        this.hidePreviewModal();
    }

    // Loading Overlay
    showLoading(message = 'Processing...') {
        document.getElementById('loading-message').textContent = message;
        document.getElementById('loading-overlay').classList.add('show');
    }

    hideLoading() {
        document.getElementById('loading-overlay').classList.remove('show');
    }

    // Logging
    addLog(message, type = 'info') {
        const container = document.getElementById('logs-container');
        const entry = document.createElement('div');
        entry.className = `log-entry ${type}`;
        
        const time = new Date().toLocaleTimeString();
        entry.innerHTML = `
            <span class="log-time">[${time}]</span>
            <span class="log-message">${message}</span>
        `;
        
        container.appendChild(entry);
        container.scrollTop = container.scrollHeight;
        
        // Keep only last 100 log entries
        while (container.children.length > 100) {
            container.removeChild(container.firstChild);
        }
    }

    clearLogs() {
        const container = document.getElementById('logs-container');
        container.innerHTML = '<div class="log-entry info"><span class="log-time">[Cleared]</span><span class="log-message">Log cleared by user</span></div>';
    }

    // Utility Functions
    async copyToClipboard(elementId) {
        const element = document.getElementById(elementId);
        if (!element) return;
        
        try {
            await navigator.clipboard.writeText(element.textContent);
            this.addLog(`Copied ${elementId.replace('-', ' ')} to clipboard`, 'success');
            
            // Visual feedback
            const button = document.querySelector(`[data-copy="${elementId}"]`);
            const originalIcon = button.innerHTML;
            button.innerHTML = '<i class="fas fa-check"></i>';
            setTimeout(() => {
                button.innerHTML = originalIcon;
            }, 1000);
        } catch (error) {
            this.addLog('Failed to copy to clipboard', 'error');
        }
    }

    // Status Polling
    startStatusPolling() {
        // Poll Cursor status every 10 seconds
        setInterval(() => {
            this.checkCursorStatus();
        }, 10000);
    }

    // Health Check
    async checkHealth() {
        try {
            const response = await fetch('/api/health');
            const data = await response.json();
            return data.success;
        } catch (error) {
            return false;
        }
    }
}

// Initialize the application when the page loads
document.addEventListener('DOMContentLoaded', () => {
    window.cursorApp = new CursorHelperApp();
});

// Export for debugging
window.CursorHelperApp = CursorHelperApp;