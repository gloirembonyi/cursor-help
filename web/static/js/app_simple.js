// Cursor Helper Web UI JavaScript Application (Simplified)
class CursorHelperApp {
    constructor() {
        this.init();
        this.addMicroInteractions();
        this.addKeyboardShortcuts();
    }

    init() {
        this.setupEventListeners();
        this.loadInitialData();
        this.startStatusPolling();
        this.addLog('Web interface initialized', 'success');
        this.addWelcomeAnimation();
    }

    // Add professional micro-interactions
    addMicroInteractions() {
        // Add hover effects to cards
        document.addEventListener('mouseover', (e) => {
            if (e.target.closest('.status-card, .action-card, .config-card, .logs-card')) {
                this.addCardHoverEffect(e.target.closest('.status-card, .action-card, .config-card, .logs-card'));
            }
        });

        // Add click ripple effects to buttons
        document.addEventListener('click', (e) => {
            if (e.target.closest('.btn')) {
                this.addRippleEffect(e.target.closest('.btn'), e);
            }
        });

        // Add smooth scroll behavior
        document.documentElement.style.scrollBehavior = 'smooth';
    }

    addCardHoverEffect(card) {
        const rect = card.getBoundingClientRect();
        const x = event.clientX - rect.left;
        const y = event.clientY - rect.top;
        
        card.style.setProperty('--mouse-x', x + 'px');
        card.style.setProperty('--mouse-y', y + 'px');
    }

    addRippleEffect(button, event) {
        const rect = button.getBoundingClientRect();
        const size = Math.max(rect.width, rect.height);
        const x = event.clientX - rect.left - size / 2;
        const y = event.clientY - rect.top - size / 2;
        
        const ripple = document.createElement('span');
        ripple.style.cssText = `
            position: absolute;
            width: ${size}px;
            height: ${size}px;
            left: ${x}px;
            top: ${y}px;
            background: rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            transform: scale(0);
            animation: ripple 0.6s ease-out;
            pointer-events: none;
        `;
        
        button.style.position = 'relative';
        button.style.overflow = 'hidden';
        button.appendChild(ripple);
        
        setTimeout(() => ripple.remove(), 600);
        
        // Add ripple animation CSS if not exists
        if (!document.getElementById('ripple-style')) {
            const style = document.createElement('style');
            style.id = 'ripple-style';
            style.textContent = `
                @keyframes ripple {
                    to {
                        transform: scale(2);
                        opacity: 0;
                    }
                }
            `;
            document.head.appendChild(style);
        }
    }

    addWelcomeAnimation() {
        const cards = document.querySelectorAll('.status-card, .action-card');
        cards.forEach((card, index) => {
            card.style.opacity = '0';
            card.style.transform = 'translateY(30px)';
            
            setTimeout(() => {
                card.style.transition = 'all 0.6s cubic-bezier(0.4, 0, 0.2, 1)';
                card.style.opacity = '1';
                card.style.transform = 'translateY(0)';
            }, index * 150);
        });
    }

    // Enhanced keyboard shortcuts
    addKeyboardShortcuts() {
        document.addEventListener('keydown', (e) => {
            // Ctrl/Cmd + Enter: Reset config
            if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
                e.preventDefault();
                const resetBtn = document.getElementById('reset-btn');
                if (!resetBtn.disabled) {
                    this.addLog('Keyboard shortcut: Reset triggered', 'info');
                    resetBtn.click();
                }
            }
            
            // Ctrl/Cmd + K: Kill Cursor
            if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
                e.preventDefault();
                const killBtn = document.getElementById('kill-cursor-btn');
                if (!killBtn.disabled) {
                    this.addLog('Keyboard shortcut: Kill Cursor triggered', 'info');
                    killBtn.click();
                }
            }
            
            // Ctrl/Cmd + R: Refresh config
            if ((e.ctrlKey || e.metaKey) && e.key === 'r') {
                e.preventDefault();
                this.addLog('Keyboard shortcut: Refresh triggered', 'info');
                this.loadConfig();
            }
            
            // Ctrl/Cmd + L: Clear logs
            if ((e.ctrlKey || e.metaKey) && e.key === 'l') {
                e.preventDefault();
                this.addLog('Keyboard shortcut: Clear logs triggered', 'info');
                this.clearLogs();
            }
        });
    }

    // Event Listeners
    setupEventListeners() {
        // Main action buttons
        document.getElementById('reset-btn').addEventListener('click', () => this.resetConfig());
        document.getElementById('kill-cursor-btn').addEventListener('click', () => this.killCursor());
        document.getElementById('disable-autoupdate-btn').addEventListener('click', () => this.disableAutoUpdate());
        
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
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            const data = await response.json();
            
            if (data.success) {
                this.updateSystemInfo(data.data);
                this.addLog('System information loaded successfully', 'success');
            } else {
                throw new Error(data.error || 'Failed to load system info');
            }
        } catch (error) {
            console.error('Error loading system info:', error);
            this.addLog(`Failed to load system information: ${error.message}`, 'error');
            // Set default values
            this.updateSystemInfo({
                os: 'Unknown',
                username: 'Unknown',
                isAdmin: false,
                configPath: 'Unknown',
                cursorRunning: false,
                language: 'en'
            });
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
            adminIcon.setAttribute('class', 'fas fa-shield-alt');
            adminIcon.style.color = '#10b981';
            adminStatus.textContent = 'Administrator';
            adminStatus.style.color = '#10b981';
        } else {
            adminIcon.setAttribute('class', 'fas fa-shield-alt');
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
            statusDot.setAttribute('class', 'status-dot running');
            statusText.textContent = 'Running';
            statusText.style.color = '#ef4444';
            killButton.disabled = false;
        } else {
            statusDot.setAttribute('class', 'status-dot stopped');
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
        
        if (isRunning && !confirm('Cursor is currently running. It will be automatically closed before resetting. Continue?')) {
            return;
        }

        this.showLoading('Resetting Cursor configuration...');
        this.addLog('Starting configuration reset...', 'info');
        
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
                
                // Create beautiful success message
                let message = '🎉 Configuration reset completed successfully!\n\n';
                
                if (data.registryModified) {
                    message += '🔧 Registry Operations:\n';
                    message += '• Windows MachineGuid updated\n';
                    message += '• Original values backed up\n\n';
                }
                
                message += '🆔 New Identifiers Generated:\n';
                message += `• Machine ID: ${data.data.telemetryMachineId?.substring(0, 8)}...\n`;
                message += `• Device ID: ${data.data.telemetryDevDeviceId?.substring(0, 8)}...\n`;
                message += `• SQM ID: ${data.data.telemetrySqmId?.substring(0, 8)}...\n\n`;
                message += '🔄 Please restart Cursor for changes to take effect.';
                
                this.showSuccessModal(message);
                
                // Enhanced logging
                this.addLog('🎉 Configuration reset completed successfully!', 'success');
                this.addLog(`📝 Generated new Machine ID: ${data.data.telemetryMachineId?.substring(0, 16)}...`, 'info');
                this.addLog(`📝 Generated new Device ID: ${data.data.telemetryDevDeviceId}`, 'info');
                
                if (data.registryModified) {
                    this.addLog('🔧 Windows registry MachineGuid modified and backed up', 'success');
                }
                
                // Trigger celebration effect
                this.triggerSuccessAnimation();
                
                // Reload data
                this.loadConfig();
                this.checkCursorStatus();
            } else if (data.needsElevation) {
                this.hideLoading();
                this.handlePrivilegeElevation(data.elevationMessage);
            } else {
                throw new Error(data.error || 'Reset failed');
            }
        } catch (error) {
            this.hideLoading();
            this.showErrorModal('Failed to reset configuration: ' + error.message);
            this.addLog('Reset failed: ' + error.message, 'error');
        }
    }

    // Handle privilege elevation
    async handlePrivilegeElevation(message) {
        const shouldElevate = confirm(
            'Administrator privileges are required for this operation.\n\n' +
            message + '\n\n' +
            'Would you like to attempt automatic privilege elevation?'
        );
        
        if (shouldElevate) {
            try {
                this.showLoading('Requesting administrator privileges...');
                const response = await fetch('/api/elevate', {
                    method: 'POST'
                });
                
                const data = await response.json();
                
                if (data.success) {
                    this.hideLoading();
                    if (data.needsRestart) {
                        alert('Privilege elevation initiated. Please:\n\n' +
                              '1. Approve the UAC prompt\n' +
                              '2. Wait for the new elevated window to open\n' +
                              '3. Close this window\n' +
                              '4. Use the new elevated window');
                    } else {
                        this.addLog('Privileges elevated successfully', 'success');
                        // Refresh system info to show new admin status
                        this.loadSystemInfo();
                    }
                } else {
                    this.hideLoading();
                    this.showErrorModal('Failed to elevate privileges: ' + data.error);
                }
            } catch (error) {
                this.hideLoading();
                this.showErrorModal('Failed to elevate privileges: ' + error.message);
            }
        } else {
            this.showErrorModal(
                'Administrator privileges are required to reset Cursor configuration.\n\n' +
                'Please restart the application as administrator and try again.'
            );
        }
    }

    async killCursor() {
        this.showLoading('Closing Cursor processes...');
        this.addLog('Attempting to close Cursor processes...', 'info');
        
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

    async disableAutoUpdate() {
        if (!confirm('Are you sure you want to disable Cursor auto-update?\n\nThis will prevent Cursor from automatically updating to potentially unsupported versions. You\'ll need to manually download and install updates in the future.')) {
            return;
        }

        this.showLoading('Disabling auto-update feature...');
        this.addLog('Attempting to disable auto-update...', 'info');
        
        try {
            const response = await fetch('/api/disable-autoupdate', {
                method: 'POST'
            });
            
            const data = await response.json();
            
            if (data.success) {
                this.hideLoading();
                this.showSuccessModal(
                    'Auto-update disabled successfully!\n\n' +
                    'Operations performed:\n' +
                    data.operations.join('\n') +
                    '\n\nYou\'ll need to manually download and install Cursor updates in the future.'
                );
                this.addLog('Auto-update disabled successfully', 'success');
                for (const operation of data.operations) {
                    this.addLog(operation, 'info');
                }
            } else {
                throw new Error(data.error || 'Failed to disable auto-update');
            }
        } catch (error) {
            this.hideLoading();
            this.showErrorModal('Failed to disable auto-update: ' + error.message);
            this.addLog('Failed to disable auto-update: ' + error.message, 'error');
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
        
        // Add description before the grid
        const container = grid.parentElement;
        let description = container.querySelector('.preview-description');
        if (!description) {
            description = document.createElement('div');
            description.className = 'preview-description';
            description.innerHTML = `
                <p style="margin-bottom: 1.5rem; color: #cbd5e1; line-height: 1.6;">
                    <strong>These are the new identifiers that will be generated:</strong><br>
                    Click on any identifier below to copy it to your clipboard.
                </p>
            `;
            container.insertBefore(description, grid);
        }
        
        grid.innerHTML = `
            <div class="preview-item">
                <label>Machine ID</label>
                <span title="Click to copy to clipboard" onclick="navigator.clipboard.writeText('${config.telemetryMachineId}').then(() => this.style.background = 'rgba(16, 185, 129, 0.2)').catch(() => {})">${config.telemetryMachineId}</span>
            </div>
            <div class="preview-item">
                <label>MAC Machine ID</label>
                <span title="Click to copy to clipboard" onclick="navigator.clipboard.writeText('${config.telemetryMacMachineId}').then(() => this.style.background = 'rgba(16, 185, 129, 0.2)').catch(() => {})">${config.telemetryMacMachineId}</span>
            </div>
            <div class="preview-item">
                <label>Device ID</label>
                <span title="Click to copy to clipboard" onclick="navigator.clipboard.writeText('${config.telemetryDevDeviceId}').then(() => this.style.background = 'rgba(16, 185, 129, 0.2)').catch(() => {})">${config.telemetryDevDeviceId}</span>
            </div>
            <div class="preview-item">
                <label>SQM ID</label>
                <span title="Click to copy to clipboard" onclick="navigator.clipboard.writeText('${config.telemetrySqmId}').then(() => this.style.background = 'rgba(16, 185, 129, 0.2)').catch(() => {})">${config.telemetrySqmId}</span>
            </div>
        `;
        
        // Add copy success feedback
        const spans = grid.querySelectorAll('span');
        spans.forEach(span => {
            span.style.cursor = 'pointer';
            span.addEventListener('click', () => {
                const originalBg = span.style.background;
                span.style.background = 'rgba(16, 185, 129, 0.3)';
                span.style.borderColor = 'rgba(16, 185, 129, 0.5)';
                
                setTimeout(() => {
                    span.style.background = originalBg;
                    span.style.borderColor = '';
                }, 1500);
                
                this.addLog(`Copied ${span.previousElementSibling.textContent.toLowerCase()} to clipboard`, 'success');
            });
        });
    }

    async regeneratePreview() {
        await this.showPreviewModal();
    }

    // UI Controls
    toggleConfigDetails() {
        const details = document.getElementById('config-details');
        const button = document.getElementById('toggle-config-btn');
        
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

    // 🎉 Enhanced Success Animation with Huly-inspired effects
    triggerSuccessAnimation() {
        // Create particle explosion effect
        this.createParticleExplosion();
        
        // Add professional success glow to entire interface
        const header = document.querySelector('.header');
        const cards = document.querySelectorAll('.status-card, .action-card, .config-card');
        
        header.style.background = 'linear-gradient(135deg, rgba(16, 185, 129, 0.2), rgba(139, 92, 246, 0.15))';
        header.style.borderBottom = '1px solid rgba(16, 185, 129, 0.4)';
        
        cards.forEach(card => {
            card.style.borderColor = 'rgba(16, 185, 129, 0.4)';
            card.style.boxShadow = '0 8px 32px rgba(16, 185, 129, 0.2), 0 0 0 1px rgba(16, 185, 129, 0.1)';
        });
        
        // Create floating success indicators
        this.createFloatingIndicators();
        
        // Reset styles after animation
        setTimeout(() => {
            header.style.background = '';
            header.style.borderBottom = '';
            cards.forEach(card => {
                card.style.borderColor = '';
                card.style.boxShadow = '';
            });
        }, 4000);
    }
    
    createParticleExplosion() {
        const colors = ['#10b981', '#8b5cf6', '#3b82f6', '#06b6d4', '#f59e0b'];
        const particles = [];
        
        // Create 60 particles for a rich effect
        for (let i = 0; i < 60; i++) {
            setTimeout(() => {
                const particle = document.createElement('div');
                const size = Math.random() * 8 + 4;
                const color = colors[Math.floor(Math.random() * colors.length)];
                const startX = Math.random() * window.innerWidth;
                const startY = window.innerHeight * 0.3; // Start from header area
                
                particle.style.cssText = `
                    position: fixed;
                    width: ${size}px;
                    height: ${size}px;
                    background: ${color};
                    left: ${startX}px;
                    top: ${startY}px;
                    border-radius: 50%;
                    pointer-events: none;
                    z-index: 9999;
                    box-shadow: 0 0 ${size * 2}px ${color};
                    animation: particleExplosion ${2 + Math.random() * 2}s cubic-bezier(0.25, 0.46, 0.45, 0.94) forwards;
                `;
                
                particles.push(particle);
                document.body.appendChild(particle);
                
                // Remove particle after animation
                setTimeout(() => {
                    if (particle.parentNode) {
                        particle.remove();
                    }
                }, 4000);
            }, i * 50); // Stagger particle creation
        }
        
        // Add particle animation CSS if not exists
        if (!document.getElementById('particle-style')) {
            const style = document.createElement('style');
            style.id = 'particle-style';
            style.textContent = `
                @keyframes particleExplosion {
                    0% {
                        transform: translateY(0) rotate(0deg) scale(1);
                        opacity: 1;
                    }
                    50% {
                        transform: translateY(${-200 - Math.random() * 200}px) 
                                  translateX(${-100 + Math.random() * 200}px) 
                                  rotate(${Math.random() * 720}deg) 
                                  scale(${0.5 + Math.random() * 0.5});
                        opacity: 0.8;
                    }
                    100% {
                        transform: translateY(${-400 - Math.random() * 300}px) 
                                  translateX(${-200 + Math.random() * 400}px) 
                                  rotate(${Math.random() * 1080}deg) 
                                  scale(0);
                        opacity: 0;
                    }
                }
            `;
            document.head.appendChild(style);
        }
    }
    
    createFloatingIndicators() {
        const indicators = ['✓', '🎉', '⭐', '🚀', '💫'];
        
        for (let i = 0; i < 8; i++) {
            setTimeout(() => {
                const indicator = document.createElement('div');
                const icon = indicators[Math.floor(Math.random() * indicators.length)];
                const startX = Math.random() * window.innerWidth;
                
                indicator.style.cssText = `
                    position: fixed;
                    font-size: ${20 + Math.random() * 15}px;
                    left: ${startX}px;
                    top: ${window.innerHeight}px;
                    pointer-events: none;
                    z-index: 9998;
                    color: #10b981;
                    text-shadow: 0 0 10px rgba(16, 185, 129, 0.8);
                    animation: floatUp ${3 + Math.random() * 2}s ease-out forwards;
                `;
                
                indicator.textContent = icon;
                document.body.appendChild(indicator);
                
                setTimeout(() => {
                    if (indicator.parentNode) {
                        indicator.remove();
                    }
                }, 5000);
            }, i * 200);
        }
        
        // Add float animation CSS if not exists
        if (!document.getElementById('float-style')) {
            const style = document.createElement('style');
            style.id = 'float-style';
            style.textContent = `
                @keyframes floatUp {
                    0% {
                        transform: translateY(0) rotate(0deg) scale(0);
                        opacity: 0;
                    }
                    20% {
                        transform: translateY(-100px) rotate(${Math.random() * 360}deg) scale(1);
                        opacity: 1;
                    }
                    80% {
                        transform: translateY(-400px) rotate(${Math.random() * 720}deg) scale(1);
                        opacity: 1;
                    }
                    100% {
                        transform: translateY(-500px) rotate(${Math.random() * 1080}deg) scale(0);
                        opacity: 0;
                    }
                }
            `;
            document.head.appendChild(style);
        }
    }
    
    // Enhanced Success Modal with professional formatting
    showEnhancedSuccessModal(message) {
        const modal = document.getElementById('success-modal');
        const messageElement = document.getElementById('success-message');
        
        // Format message with proper styling
        const formattedMessage = message.replace(/\n/g, '<br>').replace(/•/g, '<span style="color: #10b981; font-weight: 600;">•</span>');
        messageElement.innerHTML = formattedMessage;
        
        modal.classList.add('show');
        
        // Add celebration effects
        this.triggerSuccessAnimation();
        
        // Add success sound simulation (visual feedback)
        this.addSuccessVibration();
    }
    
    addSuccessVibration() {
        // Simulate success feedback with subtle page vibration
        if ('vibrate' in navigator) {
            navigator.vibrate([200, 100, 200]);
        }
        
        // Visual success pulse
        document.body.style.animation = 'successPulse 0.6s ease-out';
        
        setTimeout(() => {
            document.body.style.animation = '';
        }, 600);
        
        // Add success pulse animation CSS if not exists
        if (!document.getElementById('success-pulse-style')) {
            const style = document.createElement('style');
            style.id = 'success-pulse-style';
            style.textContent = `
                @keyframes successPulse {
                    0% { transform: scale(1); }
                    50% { transform: scale(1.002); }
                    100% { transform: scale(1); }
                }
            `;
            document.head.appendChild(style);
        }
    }
}

// Initialize the application when the page loads
document.addEventListener('DOMContentLoaded', () => {
    window.cursorApp = new CursorHelperApp();
});

// Export for debugging
window.CursorHelperApp = CursorHelperApp;