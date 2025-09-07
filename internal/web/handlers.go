package web

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/yuaotian/go-cursor-help/internal/config"
	"github.com/yuaotian/go-cursor-help/internal/lang"
)

// SystemInfo represents system information
type SystemInfo struct {
	OS            string `json:"os"`
	Username      string `json:"username"`
	IsAdmin       bool   `json:"isAdmin"`
	ConfigPath    string `json:"configPath"`
	CursorRunning bool   `json:"cursorRunning"`
	Language      string `json:"language"`
}

// ConfigData represents configuration data
type ConfigData struct {
	TelemetryMacMachineId string `json:"telemetryMacMachineId"`
	TelemetryMachineId    string `json:"telemetryMachineId"`
	TelemetryDevDeviceId  string `json:"telemetryDevDeviceId"`
	TelemetrySqmId        string `json:"telemetrySqmId"`
	LastModified          string `json:"lastModified"`
	Version               string `json:"version"`
}

// ResetRequest represents a reset request
type ResetRequest struct {
	SetReadOnly bool `json:"setReadOnly"`
}

// setupRoutes sets up all the web routes
func (s *Server) setupRoutes() {
	// Serve static files
	s.mux.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("./web/static"))))
	s.mux.HandleFunc("/", s.serveIndex)
	s.mux.HandleFunc("/help", s.serveHelp)
	s.mux.HandleFunc("/favicon.ico", s.serveFavicon)

	// API routes
	s.mux.HandleFunc("/api/system-info", s.getSystemInfo)
	s.mux.HandleFunc("/api/config", s.getConfig)
	s.mux.HandleFunc("/api/reset", s.resetConfig)
	s.mux.HandleFunc("/api/kill-cursor", s.killCursor)
	s.mux.HandleFunc("/api/check-cursor", s.checkCursor)
	s.mux.HandleFunc("/api/generate-ids", s.generateIds)
	s.mux.HandleFunc("/api/elevate", s.requestElevation)
	s.mux.HandleFunc("/api/disable-autoupdate", s.disableAutoUpdate)
	s.mux.HandleFunc("/api/health", s.healthCheck)
}

// serveIndex serves the main HTML page
func (s *Server) serveIndex(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	http.ServeFile(w, r, "./web/templates/index.html")
}

// serveHelp serves the help documentation page
func (s *Server) serveHelp(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, "./web/templates/help.html")
}

// serveFavicon serves the favicon
func (s *Server) serveFavicon(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, "./web/static/favicon.ico")
}

// getSystemInfo returns system information
func (s *Server) getSystemInfo(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		s.writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	isAdmin, _ := s.checkAdminPrivileges()

	// Get current language safely
	langString := "en"
	if currentLang := lang.GetCurrentLanguage(); currentLang != "" {
		langString = string(currentLang)
	}

	info := SystemInfo{
		OS:            runtime.GOOS,
		Username:      getCurrentUser(),
		IsAdmin:       isAdmin,
		ConfigPath:    s.getConfigPath(),
		CursorRunning: s.processManager.IsCursorRunning(),
		Language:      langString,
	}

	s.writeJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    info,
	})
}

// getConfig returns the current configuration
func (s *Server) getConfig(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		s.writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	config, err := s.configManager.ReadConfig()
	if err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to read configuration: "+err.Error())
		return
	}

	if config == nil {
		s.writeJSON(w, http.StatusOK, map[string]interface{}{
			"success": true,
			"data":    nil,
			"message": "No configuration file found",
		})
		return
	}

	configData := ConfigData{
		TelemetryMacMachineId: config.TelemetryMacMachineId,
		TelemetryMachineId:    config.TelemetryMachineId,
		TelemetryDevDeviceId:  config.TelemetryDevDeviceId,
		TelemetrySqmId:        config.TelemetrySqmId,
		LastModified:          config.LastModified,
		Version:               config.Version,
	}

	s.writeJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"data":    configData,
	})
}

// resetConfig resets the Cursor configuration
func (s *Server) resetConfig(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req ResetRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		s.writeError(w, http.StatusBadRequest, "Invalid request format")
		return
	}

	// Check admin privileges
	isAdmin, err := s.checkAdminPrivileges()
	if err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to check privileges: "+err.Error())
		return
	}

	if !isAdmin {
		// Return specific error for privilege elevation
		s.writeJSON(w, http.StatusForbidden, map[string]interface{}{
			"success":          false,
			"error":            "Administrator privileges required",
			"needsElevation":   true,
			"elevationMessage": s.getElevationMessage(),
		})
		return
	}

	// Step 1: Close Cursor processes if running
	if s.processManager.IsCursorRunning() {
		if err := s.processManager.KillCursorProcesses(); err != nil {
			s.writeError(w, http.StatusInternalServerError, "Failed to close Cursor processes: "+err.Error())
			return
		}
		// Wait a moment for processes to fully terminate
		time.Sleep(2 * time.Second)
	}

	// Step 2: Modify Windows registry (if on Windows)
	if runtime.GOOS == "windows" {
		if err := s.modifyWindowsRegistry(); err != nil {
			s.writeError(w, http.StatusInternalServerError, "Failed to modify registry: "+err.Error())
			return
		}
	}

	// Step 3: Read existing config
	oldConfig, err := s.configManager.ReadConfig()
	if err != nil {
		s.logger.Warn("Failed to read existing config:", err)
		oldConfig = nil
	}

	// Step 4: Generate new configuration
	newConfig := &config.StorageConfig{}

	if machineID, err := s.generator.GenerateMachineID(); err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to generate machine ID: "+err.Error())
		return
	} else {
		newConfig.TelemetryMachineId = machineID
	}

	if macMachineID, err := s.generator.GenerateMacMachineID(); err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to generate MAC machine ID: "+err.Error())
		return
	} else {
		newConfig.TelemetryMacMachineId = macMachineID
	}

	if deviceID, err := s.generator.GenerateDeviceID(); err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to generate device ID: "+err.Error())
		return
	} else {
		newConfig.TelemetryDevDeviceId = deviceID
	}

	// Preserve existing SQM ID if available
	if oldConfig != nil && oldConfig.TelemetrySqmId != "" {
		newConfig.TelemetrySqmId = oldConfig.TelemetrySqmId
	} else if sqmID, err := s.generator.GenerateSQMID(); err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to generate SQM ID: "+err.Error())
		return
	} else {
		newConfig.TelemetrySqmId = sqmID
	}

	// Step 5: Save configuration
	if err := s.configManager.SaveConfig(newConfig, req.SetReadOnly); err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to save configuration: "+err.Error())
		return
	}

	// Step 6: Log success
	s.logger.Info("Configuration reset completed successfully")

	s.writeJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "Configuration reset successfully. Please restart Cursor for changes to take effect.",
		"data": ConfigData{
			TelemetryMacMachineId: newConfig.TelemetryMacMachineId,
			TelemetryMachineId:    newConfig.TelemetryMachineId,
			TelemetryDevDeviceId:  newConfig.TelemetryDevDeviceId,
			TelemetrySqmId:        newConfig.TelemetrySqmId,
			LastModified:          time.Now().UTC().Format(time.RFC3339),
		},
		"registryModified": runtime.GOOS == "windows",
	})
}

// getElevationMessage returns platform-specific elevation instructions
func (s *Server) getElevationMessage() string {
	switch runtime.GOOS {
	case "windows":
		return "Please restart the application as Administrator. Right-click on the executable and select 'Run as administrator'."
	case "darwin", "linux":
		return "Please restart the application with sudo privileges: sudo ./cursor-web-ui"
	default:
		return "Administrator privileges are required for this operation."
	}
}

// killCursor terminates all Cursor processes
func (s *Server) killCursor(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	// Check admin privileges
	isAdmin, err := s.checkAdminPrivileges()
	if err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to check privileges: "+err.Error())
		return
	}

	if !isAdmin {
		s.writeError(w, http.StatusForbidden, "Administrator privileges required")
		return
	}

	if err := s.processManager.KillCursorProcesses(); err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to close Cursor: "+err.Error())
		return
	}

	// Double-check if processes are still running
	if s.processManager.IsCursorRunning() {
		s.writeError(w, http.StatusInternalServerError, "Failed to close Cursor completely")
		return
	}

	s.writeJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "All Cursor processes closed successfully",
	})
}

// checkCursor checks if Cursor is running
func (s *Server) checkCursor(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		s.writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	isRunning := s.processManager.IsCursorRunning()
	s.writeJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"data": map[string]interface{}{
			"running": isRunning,
		},
	})
}

// generateIds generates new IDs without saving
func (s *Server) generateIds(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	newConfig := &config.StorageConfig{}

	if machineID, err := s.generator.GenerateMachineID(); err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to generate machine ID: "+err.Error())
		return
	} else {
		newConfig.TelemetryMachineId = machineID
	}

	if macMachineID, err := s.generator.GenerateMacMachineID(); err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to generate MAC machine ID: "+err.Error())
		return
	} else {
		newConfig.TelemetryMacMachineId = macMachineID
	}

	if deviceID, err := s.generator.GenerateDeviceID(); err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to generate device ID: "+err.Error())
		return
	} else {
		newConfig.TelemetryDevDeviceId = deviceID
	}

	if sqmID, err := s.generator.GenerateSQMID(); err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to generate SQM ID: "+err.Error())
		return
	} else {
		newConfig.TelemetrySqmId = sqmID
	}

	s.writeJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"data": ConfigData{
			TelemetryMacMachineId: newConfig.TelemetryMacMachineId,
			TelemetryMachineId:    newConfig.TelemetryMachineId,
			TelemetryDevDeviceId:  newConfig.TelemetryDevDeviceId,
			TelemetrySqmId:        newConfig.TelemetrySqmId,
		},
	})
}

// healthCheck returns the health status of the service
func (s *Server) healthCheck(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		s.writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	s.writeJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"status":  "healthy",
		"time":    time.Now().UTC().Format(time.RFC3339),
	})
}

// checkAdminPrivileges checks if the current user has admin privileges
func (s *Server) checkAdminPrivileges() (bool, error) {
	switch runtime.GOOS {
	case "windows":
		// Check if running as administrator
		cmd := exec.Command("net", "session")
		return cmd.Run() == nil, nil
	case "darwin", "linux":
		// Check if running as root
		return os.Geteuid() == 0, nil
	default:
		return false, fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}
}

// elevatePrivileges attempts to restart the application with elevated privileges
func (s *Server) elevatePrivileges() error {
	switch runtime.GOOS {
	case "windows":
		// For Windows, we need to restart with elevated privileges
		exe, err := os.Executable()
		if err != nil {
			return fmt.Errorf("failed to get executable path: %w", err)
		}

		// Use PowerShell Start-Process with -Verb RunAs to elevate
		cmd := exec.Command("powershell", "-Command",
			fmt.Sprintf("Start-Process '%s' -Verb RunAs -ArgumentList '--port 8080'", exe))
		return cmd.Run()

	case "darwin", "linux":
		// For Unix systems, suggest using sudo
		return fmt.Errorf("please restart the application with sudo: sudo %s", os.Args[0])

	default:
		return fmt.Errorf("privilege elevation not supported on %s", runtime.GOOS)
	}
}

// requestElevation handles privilege elevation requests
func (s *Server) requestElevation(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	// Check if already running with admin privileges
	isAdmin, err := s.checkAdminPrivileges()
	if err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to check privileges: "+err.Error())
		return
	}

	if isAdmin {
		s.writeJSON(w, http.StatusOK, map[string]interface{}{
			"success": true,
			"message": "Already running with administrator privileges",
			"isAdmin": true,
		})
		return
	}

	// Attempt to elevate privileges
	if err := s.elevatePrivileges(); err != nil {
		s.writeError(w, http.StatusInternalServerError, "Failed to elevate privileges: "+err.Error())
		return
	}

	s.writeJSON(w, http.StatusOK, map[string]interface{}{
		"success":      true,
		"message":      "Privilege elevation initiated. Please approve the UAC prompt and refresh the page.",
		"needsRestart": true,
	})
}

// modifyWindowsRegistry modifies the Windows MachineGuid registry key
func (s *Server) modifyWindowsRegistry() error {
	if runtime.GOOS != "windows" {
		return nil // Not applicable for non-Windows systems
	}

	// Check admin privileges first
	isAdmin, err := s.checkAdminPrivileges()
	if err != nil {
		return fmt.Errorf("failed to check admin privileges: %w", err)
	}
	if !isAdmin {
		return fmt.Errorf("administrator privileges required for registry modification")
	}

	// Backup current MachineGuid
	backupCmd := exec.Command("reg", "query",
		"HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Cryptography",
		"/v", "MachineGuid")
	backupOutput, err := backupCmd.Output()
	if err != nil {
		return fmt.Errorf("failed to read current MachineGuid: %w", err)
	}

	// Extract current GUID value
	lines := strings.Split(string(backupOutput), "\n")
	var currentGuid string
	for _, line := range lines {
		if strings.Contains(line, "MachineGuid") && strings.Contains(line, "REG_SZ") {
			parts := strings.Fields(line)
			if len(parts) >= 3 {
				currentGuid = parts[len(parts)-1]
				break
			}
		}
	}

	if currentGuid == "" {
		return fmt.Errorf("failed to extract current MachineGuid")
	}

	// Create backup directory
	backupDir := filepath.Join(os.Getenv("APPDATA"), "Cursor", "User", "globalStorage", "backups")
	if err := os.MkdirAll(backupDir, 0755); err != nil {
		return fmt.Errorf("failed to create backup directory: %w", err)
	}

	// Save backup
	backupFile := filepath.Join(backupDir, fmt.Sprintf("MachineGuid.backup_%s",
		time.Now().Format("20060102_150405")))
	if err := os.WriteFile(backupFile, []byte(currentGuid), 0644); err != nil {
		return fmt.Errorf("failed to save backup: %w", err)
	}

	// Generate new GUID
	newGuid, err := s.generator.GenerateDeviceID()
	if err != nil {
		return fmt.Errorf("failed to generate new GUID: %w", err)
	}

	// Remove hyphens and convert to uppercase for registry format
	newGuid = strings.ToUpper(strings.ReplaceAll(newGuid, "-", ""))

	// Modify registry
	modifyCmd := exec.Command("reg", "add",
		"HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Cryptography",
		"/v", "MachineGuid", "/t", "REG_SZ", "/d", newGuid, "/f")
	if err := modifyCmd.Run(); err != nil {
		return fmt.Errorf("failed to modify registry: %w", err)
	}

	s.logger.Infof("Successfully modified MachineGuid from %s to %s", currentGuid, newGuid)
	s.logger.Infof("Backup saved to: %s", backupFile)

	return nil
}

// getConfigPath returns the configuration file path
func (s *Server) getConfigPath() string {
	switch runtime.GOOS {
	case "windows":
		return fmt.Sprintf("%s\\Cursor\\User\\globalStorage\\storage.json", os.Getenv("APPDATA"))
	case "darwin":
		return fmt.Sprintf("/Users/%s/Library/Application Support/Cursor/User/globalStorage/storage.json", getCurrentUser())
	case "linux":
		return fmt.Sprintf("/home/%s/.config/Cursor/User/globalStorage/storage.json", getCurrentUser())
	default:
		return "Unknown"
	}
}

// getCurrentUser gets the current username
func getCurrentUser() string {
	if username := os.Getenv("SUDO_USER"); username != "" {
		return username
	}

	user, err := user.Current()
	if err != nil {
		return "unknown"
	}
	return user.Username
}

// writeJSON writes JSON response
func (s *Server) writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

// writeError writes error JSON response
func (s *Server) writeError(w http.ResponseWriter, status int, message string) {
	s.writeJSON(w, status, map[string]interface{}{
		"success": false,
		"error":   message,
	})
}

// disableAutoUpdate disables Cursor's auto-update feature
func (s *Server) disableAutoUpdate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	// Check admin privileges for Windows registry operations
	if runtime.GOOS == "windows" {
		isAdmin, err := s.checkAdminPrivileges()
		if err != nil {
			s.writeError(w, http.StatusInternalServerError, "Failed to check privileges: "+err.Error())
			return
		}
		if !isAdmin {
			s.writeError(w, http.StatusForbidden, "Administrator privileges required for auto-update disable on Windows")
			return
		}
	}

	var updaterPaths []string
	var operations []string

	switch runtime.GOOS {
	case "windows":
		// Windows: Delete cursor-updater directory and create blocking file
		updaterPath := filepath.Join(os.Getenv("LOCALAPPDATA"), "cursor-updater")
		updaterPaths = append(updaterPaths, updaterPath)

		// Remove directory if it exists
		if _, err := os.Stat(updaterPath); err == nil {
			if err := os.RemoveAll(updaterPath); err != nil {
				s.writeError(w, http.StatusInternalServerError, "Failed to remove updater directory: "+err.Error())
				return
			}
			operations = append(operations, "Removed updater directory: "+updaterPath)
		}

		// Create blocking file
		if file, err := os.Create(updaterPath); err != nil {
			s.writeError(w, http.StatusInternalServerError, "Failed to create blocking file: "+err.Error())
			return
		} else {
			file.Close()
			operations = append(operations, "Created blocking file: "+updaterPath)
		}

	case "darwin":
		// macOS: Multiple paths and operations
		appUpdatePath := "/Applications/Cursor.app/Contents/Resources/app-update.yml"
		updaterPath := filepath.Join(os.Getenv("HOME"), "Library/Application Support/Caches/cursor-updater")

		// Backup and replace app-update.yml
		if _, err := os.Stat(appUpdatePath); err == nil {
			backupPath := appUpdatePath + ".bak"
			if err := os.Rename(appUpdatePath, backupPath); err != nil {
				s.logger.Warn("Failed to backup app-update.yml:", err)
			}

			// Create empty read-only file
			if file, err := os.Create(appUpdatePath); err == nil {
				file.Close()
				os.Chmod(appUpdatePath, 0444)
				operations = append(operations, "Created read-only app-update.yml")
			}
		}

		// Handle cursor-updater directory
		if _, err := os.Stat(updaterPath); err == nil {
			if err := os.RemoveAll(updaterPath); err != nil {
				s.logger.Warn("Failed to remove updater directory:", err)
			} else {
				operations = append(operations, "Removed updater directory")
			}
		}

		// Create blocking file
		if file, err := os.Create(updaterPath); err == nil {
			file.Close()
			operations = append(operations, "Created blocking file")
		}

		updaterPaths = append(updaterPaths, appUpdatePath, updaterPath)

	case "linux":
		// Linux: Remove updater directory and create blocking file
		updaterPath := filepath.Join(os.Getenv("HOME"), ".config/cursor-updater")
		updaterPaths = append(updaterPaths, updaterPath)

		// Remove directory if it exists
		if _, err := os.Stat(updaterPath); err == nil {
			if err := os.RemoveAll(updaterPath); err != nil {
				s.writeError(w, http.StatusInternalServerError, "Failed to remove updater directory: "+err.Error())
				return
			}
			operations = append(operations, "Removed updater directory: "+updaterPath)
		}

		// Create blocking file
		if file, err := os.Create(updaterPath); err != nil {
			s.writeError(w, http.StatusInternalServerError, "Failed to create blocking file: "+err.Error())
			return
		} else {
			file.Close()
			operations = append(operations, "Created blocking file: "+updaterPath)
		}

	default:
		s.writeError(w, http.StatusNotImplemented, "Auto-update disable not supported on this platform")
		return
	}

	s.logger.Info("Auto-update disabled successfully")
	for _, op := range operations {
		s.logger.Info(op)
	}

	s.writeJSON(w, http.StatusOK, map[string]interface{}{
		"success":    true,
		"message":    "Auto-update disabled successfully. You'll need to manually update Cursor in the future.",
		"operations": operations,
		"paths":      updaterPaths,
		"platform":   runtime.GOOS,
	})
}
