# Simple Cursor Reset Tool - Local Version
# Fixed for direct execution without BOM issues
# No external downloads required

param([switch]$Force)

# Check admin privileges first
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host ""
    Write-Host "ERROR: Administrator privileges required!" -ForegroundColor Red
    Write-Host ""
    Write-Host "How to run as administrator:" -ForegroundColor Yellow
    Write-Host "1. Right-click on PowerShell" -ForegroundColor Cyan
    Write-Host "2. Select 'Run as administrator'" -ForegroundColor Cyan
    Write-Host "3. Navigate to this script and run it" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Clear screen and show header
Clear-Host
Write-Host "=================================" -ForegroundColor Green
Write-Host "   Cursor Trial Reset Tool" -ForegroundColor Green  
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

# Functions for colored output
function Write-Success($msg) { Write-Host "[SUCCESS] $msg" -ForegroundColor Green }
function Write-Error($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Warning($msg) { Write-Host "[WARNING] $msg" -ForegroundColor Yellow }
function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }

# Step 1: Stop Cursor processes
Write-Info "Step 1: Stopping Cursor processes..."
$cursorProcesses = Get-Process | Where-Object { 
    $_.ProcessName -like "*Cursor*" -or 
    $_.ProcessName -like "*cursor*" 
}

if ($cursorProcesses) {
    foreach ($process in $cursorProcesses) {
        try {
            Write-Info "Stopping: $($process.ProcessName) (PID: $($process.Id))"
            $process.Kill()
            Start-Sleep -Milliseconds 500
        }
        catch {
            Write-Warning "Could not stop: $($process.ProcessName)"
        }
    }
    Write-Success "Cursor processes stopped"
} else {
    Write-Success "No Cursor processes found"
}

# Step 2: Reset Windows Machine GUID
Write-Info "Step 2: Resetting Windows Machine GUID..."
try {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
    $currentGuid = Get-ItemProperty -Path $regPath -Name "MachineGuid" -ErrorAction SilentlyContinue
    
    if ($currentGuid) {
        # Backup current GUID
        $backupFile = "$env:TEMP\cursor_guid_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        "Original GUID: $($currentGuid.MachineGuid)" | Out-File $backupFile
        Write-Info "Backup saved: $backupFile"
    }
    
    # Generate new GUID
    $newGuid = [System.Guid]::NewGuid().ToString().ToUpper()
    Set-ItemProperty -Path $regPath -Name "MachineGuid" -Value $newGuid -Force
    
    Write-Success "Windows Machine GUID updated"
    Write-Info "New GUID: $newGuid"
}
catch {
    Write-Error "Failed to update Windows GUID: $($_.Exception.Message)"
}

# Step 3: Remove Cursor folders
Write-Info "Step 3: Removing Cursor data folders..."
$foldersToRemove = @(
    "$env:APPDATA\Cursor",
    "$env:LOCALAPPDATA\cursor", 
    "$env:USERPROFILE\.cursor"
)

foreach ($folder in $foldersToRemove) {
    if (Test-Path $folder) {
        try {
            Remove-Item $folder -Recurse -Force
            Write-Success "Removed: $folder"
        }
        catch {
            Write-Error "Failed to remove: $folder"
        }
    } else {
        Write-Info "Not found: $folder"
    }
}

# Step 4: Generate new Cursor config (if possible)
Write-Info "Step 4: Preparing new configuration..."

# Try to find Cursor executable
$cursorPaths = @(
    "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
    "$env:PROGRAMFILES\Cursor\Cursor.exe"
)

$cursorExe = $null
foreach ($path in $cursorPaths) {
    if (Test-Path $path) {
        $cursorExe = $path
        break
    }
}

if ($cursorExe) {
    Write-Info "Found Cursor at: $cursorExe"
    Write-Info "Cursor will generate new config on next startup"
} else {
    Write-Warning "Cursor executable not found. Please ensure Cursor is installed."
}

# Final summary
Write-Host ""
Write-Host "=================================" -ForegroundColor Green
Write-Host "        RESET COMPLETED!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

Write-Success "Cursor trial reset completed successfully!"
Write-Host ""
Write-Info "Next steps:"
Write-Host "1. Restart your computer (recommended)" -ForegroundColor Yellow
Write-Host "2. Start Cursor application" -ForegroundColor Yellow  
Write-Host "3. Your trial should be reset" -ForegroundColor Yellow
Write-Host ""

Write-Warning "Important: Some changes require a system restart to take full effect."
Write-Host ""

# Ask if user wants to restart
if (-not $Force) {
    $restart = Read-Host "Do you want to restart your computer now? (y/n)"
    if ($restart -eq 'y' -or $restart -eq 'Y') {
        Write-Info "Restarting computer in 10 seconds..."
        Write-Host "Press Ctrl+C to cancel" -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }
}

Read-Host "Press Enter to exit"