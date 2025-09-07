# Enhanced Cursor Trial Reset Tool
# Fixed BOM issue, improved error handling, and comprehensive reset functionality
# Author: Enhanced by AI Assistant
# Date: 2025-01-07
# Purpose: Complete Cursor trial reset with machine ID modification

# Set output encoding to UTF-8 (without BOM)
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ANSI Color codes for better display
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$CYAN = "`e[36m"
$WHITE = "`e[37m"
$BOLD = "`e[1m"
$NC = "`e[0m"  # No Color / Reset

# Configuration paths
$CURSOR_APPDATA = "$env:APPDATA\Cursor"
$CURSOR_LOCAL = "$env:LOCALAPPDATA\cursor"
$CURSOR_PROFILE = "$env:USERPROFILE\.cursor"
$STORAGE_FILE = "$CURSOR_APPDATA\User\globalStorage\storage.json"
$BACKUP_DIR = "$CURSOR_APPDATA\User\globalStorage\backups"

# Global variables for tracking
$script:OperationSuccess = $true
$script:SuccessfulOperations = @()
$script:FailedOperations = @()

# Function to check administrator privileges
function Test-AdminPrivileges {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

# Enhanced logging functions
function Write-SuccessMessage { 
    param($Message, $Details = "")
    Write-Host "${GREEN}[SUCCESS]${NC} $Message" 
    if ($Details) { Write-Host "          $Details" -ForegroundColor DarkGreen }
    $script:SuccessfulOperations += $Message
}

function Write-ErrorMessage { 
    param($Message, $Details = "")
    Write-Host "${RED}[ERROR]${NC} $Message" 
    if ($Details) { Write-Host "        $Details" -ForegroundColor DarkRed }
    $script:FailedOperations += $Message
    $script:OperationSuccess = $false
}

function Write-WarningMessage { 
    param($Message, $Details = "")
    Write-Host "${YELLOW}[WARNING]${NC} $Message" 
    if ($Details) { Write-Host "          $Details" -ForegroundColor DarkYellow }
}

function Write-InfoMessage { 
    param($Message, $Details = "")
    Write-Host "${BLUE}[INFO]${NC} $Message" 
    if ($Details) { Write-Host "       $Details" -ForegroundColor DarkBlue }
}

function Write-StepMessage { 
    param($Step, $Total, $Message)
    Write-Host "${CYAN}[STEP $Step/$Total]${NC} $Message" 
}

# Function to generate cryptographically strong random strings
function New-SecureRandomString {
    param([int]$Length = 32)
    
    $bytes = New-Object byte[] $Length
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    try {
        $rng.GetBytes($bytes)
        return [System.BitConverter]::ToString($bytes) -replace '-', '' | Select-Object -First $Length
    }
    finally {
        $rng.Dispose()
    }
}

# Function to generate new machine identifiers
function New-MachineIdentifiers {
    return @{
        MachineGuid = [System.Guid]::NewGuid().ToString().ToUpper()
        DeviceId = [System.Guid]::NewGuid().ToString()
        MacMachineId = New-SecureRandomString -Length 64
        SqmId = "{$([System.Guid]::NewGuid().ToString().ToUpper())}"
        AuthMachineId = "auth0|user_$(New-SecureRandomString -Length 32)"
    }
}

# Enhanced process management
function Stop-AllCursorProcesses {
    Write-InfoMessage "Stopping all Cursor processes..."
    
    $cursorProcessNames = @(
        "Cursor", "cursor", "Cursor Helper", "Cursor Helper (GPU)", 
        "Cursor Helper (Plugin)", "Cursor Helper (Renderer)", "CursorUpdater"
    )
    
    $processesFound = $false
    $processesToStop = @()
    
    # Find all Cursor processes
    foreach ($processName in $cursorProcessNames) {
        $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if ($processes) {
            $processesToStop += $processes
            $processesFound = $true
            Write-InfoMessage "Found $($processes.Count) process(es): $processName"
        }
    }
    
    if (-not $processesFound) {
        Write-SuccessMessage "No Cursor processes found running"
        return $true
    }
    
    # Graceful shutdown attempt
    Write-InfoMessage "Attempting graceful shutdown..."
    foreach ($process in $processesToStop) {
        try {
            $process.CloseMainWindow() | Out-Null
            Write-InfoMessage "Sent close signal to: $($process.ProcessName) (PID: $($process.Id))"
        }
        catch {
            Write-WarningMessage "Could not send close signal to: $($process.ProcessName)"
        }
    }
    
    # Wait for graceful shutdown
    Start-Sleep -Seconds 5
    
    # Force kill remaining processes
    $remainingProcesses = @()
    foreach ($processName in $cursorProcessNames) {
        $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if ($processes) {
            $remainingProcesses += $processes
        }
    }
    
    if ($remainingProcesses.Count -gt 0) {
        Write-InfoMessage "Force stopping $($remainingProcesses.Count) remaining processes..."
        foreach ($process in $remainingProcesses) {
            try {
                Stop-Process -Id $process.Id -Force -ErrorAction Stop
                Write-InfoMessage "Force stopped: $($process.ProcessName) (PID: $($process.Id))"
            }
            catch {
                Write-WarningMessage "Could not force stop: $($process.ProcessName)"
            }
        }
    }
    
    # Final verification
    Start-Sleep -Seconds 2
    $finalCheck = @()
    foreach ($processName in $cursorProcessNames) {
        $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if ($processes) {
            $finalCheck += $processes
        }
    }
    
    if ($finalCheck.Count -eq 0) {
        Write-SuccessMessage "All Cursor processes stopped successfully"
        return $true
    } else {
        Write-WarningMessage "$($finalCheck.Count) Cursor processes still running"
        return $false
    }
}

# Function to reset Windows Machine GUID
function Reset-WindowsMachineGuid {
    Write-InfoMessage "Resetting Windows Machine GUID..."
    
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
    $valueName = "MachineGuid"
    
    try {
        # Verify registry path exists
        if (-not (Test-Path $registryPath)) {
            Write-ErrorMessage "Registry path does not exist: $registryPath"
            return $false
        }
        
        # Backup current value
        $currentGuid = $null
        try {
            $currentGuid = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop
        }
        catch {
            Write-WarningMessage "MachineGuid not found in registry, will create new one"
        }
        
        if ($currentGuid) {
            # Create backup directory
            if (-not (Test-Path $BACKUP_DIR)) {
                New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
            }
            
            $backupFile = "$BACKUP_DIR\MachineGuid_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
            "Original MachineGuid: $($currentGuid.MachineGuid)" | Out-File -FilePath $backupFile -Encoding UTF8
            Write-SuccessMessage "Registry backup created" $backupFile
        }
        
        # Generate and set new GUID
        $newGuid = [System.Guid]::NewGuid().ToString().ToUpper()
        Set-ItemProperty -Path $registryPath -Name $valueName -Value $newGuid -Force -ErrorAction Stop
        
        # Verify the change
        $verifyGuid = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop
        if ($verifyGuid.MachineGuid -eq $newGuid) {
            Write-SuccessMessage "Windows Machine GUID updated successfully" "New GUID: $newGuid"
            return $true
        } else {
            Write-ErrorMessage "Failed to verify GUID update in registry"
            return $false
        }
    }
    catch {
        Write-ErrorMessage "Failed to modify Windows registry" $_.Exception.Message
        return $false
    }
}

# Function to completely remove Cursor data folders
function Remove-CursorDataFolders {
    Write-InfoMessage "Removing Cursor data folders..."
    
    $foldersToDelete = @(
        $CURSOR_APPDATA,
        $CURSOR_LOCAL, 
        $CURSOR_PROFILE,
        "C:\Users\Administrator\.cursor",
        "C:\Users\Administrator\AppData\Roaming\Cursor"
    )
    
    $deletedCount = 0
    $totalFolders = $foldersToDelete.Count
    
    foreach ($folder in $foldersToDelete) {
        if (Test-Path $folder) {
            try {
                Write-InfoMessage "Deleting folder: $folder"
                Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
                Write-SuccessMessage "Deleted: $(Split-Path $folder -Leaf)"
                $deletedCount++
            }
            catch {
                Write-ErrorMessage "Failed to delete: $folder" $_.Exception.Message
            }
        } else {
            Write-InfoMessage "Folder not found (skipping): $folder"
        }
    }
    
    Write-InfoMessage "Folder deletion summary: $deletedCount/$totalFolders folders deleted"
    
    # Recreate essential directory structure
    try {
        if (-not (Test-Path $CURSOR_APPDATA)) {
            New-Item -ItemType Directory -Path $CURSOR_APPDATA -Force | Out-Null
        }
        if (-not (Test-Path $CURSOR_PROFILE)) {
            New-Item -ItemType Directory -Path $CURSOR_PROFILE -Force | Out-Null
        }
        Write-SuccessMessage "Essential directories recreated"
        return $true
    }
    catch {
        Write-WarningMessage "Could not recreate essential directories" $_.Exception.Message
        return $false
    }
}

# Function to generate and wait for new Cursor configuration
function Initialize-CursorConfiguration {
    Write-InfoMessage "Initializing new Cursor configuration..."
    
    # Try to find Cursor executable
    $cursorPaths = @(
        "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
        "$env:PROGRAMFILES\Cursor\Cursor.exe", 
        "$env:PROGRAMFILES(X86)\Cursor\Cursor.exe"
    )
    
    $cursorExecutable = $null
    foreach ($path in $cursorPaths) {
        if (Test-Path $path) {
            $cursorExecutable = $path
            Write-InfoMessage "Found Cursor executable: $path"
            break
        }
    }
    
    if (-not $cursorExecutable) {
        Write-WarningMessage "Cursor executable not found. Please ensure Cursor is installed."
        return $false
    }
    
    try {
        Write-InfoMessage "Starting Cursor to generate initial configuration..."
        $process = Start-Process -FilePath $cursorExecutable -PassThru -WindowStyle Hidden
        
        # Wait for configuration file generation
        $configWaitTime = 0
        $maxWaitTime = 45
        
        while (-not (Test-Path $STORAGE_FILE) -and $configWaitTime -lt $maxWaitTime) {
            Start-Sleep -Seconds 1
            $configWaitTime++
            if ($configWaitTime % 10 -eq 0) {
                Write-InfoMessage "Waiting for configuration generation... ($configWaitTime/$maxWaitTime seconds)"
            }
        }
        
        # Stop the process
        if ($process -and -not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit(5000)
        }
        
        # Ensure all processes are stopped
        Stop-AllCursorProcesses | Out-Null
        
        if (Test-Path $STORAGE_FILE) {
            Write-SuccessMessage "Configuration file generated successfully"
            return $true
        } else {
            Write-ErrorMessage "Configuration file was not generated within timeout"
            return $false
        }
    }
    catch {
        Write-ErrorMessage "Failed to initialize Cursor configuration" $_.Exception.Message
        return $false
    }
}

# Function to modify Cursor configuration with new identifiers
function Update-CursorConfiguration {
    Write-InfoMessage "Updating Cursor configuration with new identifiers..."
    
    if (-not (Test-Path $STORAGE_FILE)) {
        Write-ErrorMessage "Cursor configuration file not found: $STORAGE_FILE"
        return $false
    }
    
    try {
        # Create backup
        if (-not (Test-Path $BACKUP_DIR)) {
            New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
        }
        
        $backupFile = "$BACKUP_DIR\storage_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        Copy-Item $STORAGE_FILE $backupFile -Force
        Write-SuccessMessage "Configuration backup created" $backupFile
        
        # Read and parse configuration
        $configContent = Get-Content $STORAGE_FILE -Raw -Encoding UTF8 | ConvertFrom-Json
        
        # Generate new identifiers
        $newIds = New-MachineIdentifiers
        
        # Update telemetry identifiers
        $updates = @{
            "telemetry.machineId" = $newIds.AuthMachineId
            "telemetry.macMachineId" = $newIds.MacMachineId
            "telemetry.devDeviceId" = $newIds.DeviceId
            "telemetry.sqmId" = $newIds.SqmId
        }
        
        foreach ($key in $updates.Keys) {
            if ($configContent.PSObject.Properties.Name -contains $key) {
                $configContent.$key = $updates[$key]
                Write-InfoMessage "Updated: $key"
            } else {
                $configContent | Add-Member -MemberType NoteProperty -Name $key -Value $updates[$key] -Force
                Write-InfoMessage "Added: $key"
            }
        }
        
        # Save updated configuration
        $updatedJson = $configContent | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($STORAGE_FILE, $updatedJson, [System.Text.Encoding]::UTF8)
        
        Write-SuccessMessage "Cursor configuration updated successfully"
        Write-InfoMessage "New Machine ID: $($newIds.AuthMachineId.Substring(0,20))..."
        Write-InfoMessage "New Device ID: $($newIds.DeviceId)"
        
        return $true
    }
    catch {
        Write-ErrorMessage "Failed to update Cursor configuration" $_.Exception.Message
        return $false
    }
}

# Function to display final results
function Show-CompletionSummary {
    Write-Host ""
    Write-Host "${GREEN}${BOLD}" + "=" * 70 + "${NC}"
    Write-Host "${GREEN}${BOLD}              🎉 CURSOR RESET COMPLETED! 🎉              ${NC}"
    Write-Host "${GREEN}${BOLD}" + "=" * 70 + "${NC}"
    Write-Host ""
    
    if ($script:SuccessfulOperations.Count -gt 0) {
        Write-Host "${GREEN}✅ Successful Operations:${NC}"
        foreach ($operation in $script:SuccessfulOperations) {
            Write-Host "   ✓ $operation" -ForegroundColor DarkGreen
        }
        Write-Host ""
    }
    
    if ($script:FailedOperations.Count -gt 0) {
        Write-Host "${RED}❌ Failed Operations:${NC}"
        foreach ($operation in $script:FailedOperations) {
            Write-Host "   ✗ $operation" -ForegroundColor DarkRed
        }
        Write-Host ""
    }
    
    Write-Host "${YELLOW}📋 Next Steps:${NC}"
    Write-Host "   1. ${CYAN}Restart your computer${NC} (recommended for complete reset)"
    Write-Host "   2. ${CYAN}Start Cursor application${NC}"
    Write-Host "   3. ${CYAN}Check if trial period has been reset${NC}"
    Write-Host ""
    
    if ($script:OperationSuccess) {
        Write-Host "${GREEN}🎊 Reset completed successfully! Enjoy your renewed trial period!${NC}"
    } else {
        Write-Host "${YELLOW}⚠️  Reset completed with some warnings. Manual intervention may be needed.${NC}"
    }
    Write-Host ""
}

# Main execution function
function Start-CursorReset {
    Clear-Host
    
    # Display header
    Write-Host @"
${CYAN}
   ╔══════════════════════════════════════════════════════════════╗
   ║                                                              ║
   ║    ${WHITE}${BOLD}Enhanced Cursor Trial Reset Tool - v2.0${NC}${CYAN}                  ║
   ║                                                              ║
   ║    ${YELLOW}📚 Educational and Study Purposes Only${NC}${CYAN}                     ║
   ║    ${WHITE}🔧 Fixed BOM Issues & Enhanced Error Handling${NC}${CYAN}               ║
   ║                                                              ║
   ╚══════════════════════════════════════════════════════════════╝
${NC}
"@
    
    Write-Host ""
    Write-InfoMessage "Starting comprehensive Cursor trial reset..."
    Write-Host ""
    
    # Confirmation
    Write-Host "${YELLOW}⚠️  This will completely reset Cursor trial data and configuration.${NC}"
    $confirmation = Read-Host "Do you want to continue? (y/N)"
    
    if ($confirmation -notmatch '^[Yy]') {
        Write-InfoMessage "Operation cancelled by user"
        return
    }
    
    Write-Host ""
    
    # Execute reset steps
    Write-StepMessage 1 5 "Stopping Cursor processes"
    Stop-AllCursorProcesses | Out-Null
    
    Write-StepMessage 2 5 "Resetting Windows Machine GUID"
    Reset-WindowsMachineGuid | Out-Null
    
    Write-StepMessage 3 5 "Removing Cursor data folders"
    Remove-CursorDataFolders | Out-Null
    
    Write-StepMessage 4 5 "Initializing new Cursor configuration"
    if (Initialize-CursorConfiguration) {
        Write-StepMessage 5 5 "Updating Cursor configuration with new identifiers"
        Update-CursorConfiguration | Out-Null
    } else {
        Write-WarningMessage "Skipping configuration update due to initialization failure"
        Write-InfoMessage "Manual configuration may be needed on next Cursor startup"
    }
    
    # Display results
    Show-CompletionSummary
}

# Script entry point
if (-not (Test-AdminPrivileges)) {
    Write-Host ""
    Write-Host "${RED}${BOLD}[ERROR] Administrator privileges required!${NC}" 
    Write-Host ""
    Write-Host "${YELLOW}Please run this script as administrator:${NC}"
    Write-Host "${BLUE}  1. Right-click on PowerShell${NC}"
    Write-Host "${BLUE}  2. Select 'Run as administrator'${NC}"
    Write-Host "${BLUE}  3. Navigate to script location and run it${NC}"
    Write-Host ""
    Write-Host "${CYAN}Alternative: Right-click on the script file and select 'Run with PowerShell'${NC}"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Execute main function
Start-CursorReset

Write-Host "${GREEN}Script execution completed.${NC}"
Read-Host "Press Enter to exit"
