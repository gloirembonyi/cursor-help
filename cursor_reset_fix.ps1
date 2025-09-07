# Cursor Helper - ID Reset Tool (Clean Version)
# Fixed encoding and administrator privilege issues

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[ERROR] Administrator privileges required!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Right-click on PowerShell and select 'Run as Administrator'" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "   Cursor Helper - Reset Tool" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Color functions
function Write-Success { param($msg) Write-Host "[SUCCESS] $msg" -ForegroundColor Green }
function Write-Error { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Warning { param($msg) Write-Host "[WARNING] $msg" -ForegroundColor Yellow }
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }

# Stop Cursor processes
function Stop-CursorProcesses {
    Write-Info "Stopping Cursor processes..."
    
    $processes = Get-Process | Where-Object { $_.ProcessName -like "*Cursor*" }
    
    if ($processes.Count -eq 0) {
        Write-Success "No Cursor processes found running"
        return $true
    }
    
    foreach ($process in $processes) {
        try {
            Write-Info "Stopping process: $($process.ProcessName) (PID: $($process.Id))"
            $process.Kill()
            Start-Sleep -Milliseconds 500
        }
        catch {
            Write-Warning "Could not stop process $($process.ProcessName): $($_.Exception.Message)"
        }
    }
    
    # Wait and verify
    Start-Sleep -Seconds 2
    $remainingProcesses = Get-Process | Where-Object { $_.ProcessName -like "*Cursor*" }
    
    if ($remainingProcesses.Count -eq 0) {
        Write-Success "All Cursor processes stopped successfully"
        return $true
    } else {
        Write-Warning "$($remainingProcesses.Count) Cursor processes still running"
        return $false
    }
}

# Generate new machine GUID
function New-MachineGuid {
    return [System.Guid]::NewGuid().ToString().ToUpper()
}

# Backup and modify Windows registry
function Reset-WindowsRegistry {
    Write-Info "Resetting Windows Machine GUID..."
    
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
    $valueName = "MachineGuid"
    
    try {
        # Backup current value
        $currentGuid = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop
        $backupFile = "$env:TEMP\cursor_machine_guid_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        
        "Original MachineGuid: $($currentGuid.MachineGuid)" | Out-File -FilePath $backupFile
        Write-Success "Backup created: $backupFile"
        
        # Generate new GUID
        $newGuid = New-MachineGuid
        
        # Update registry
        Set-ItemProperty -Path $registryPath -Name $valueName -Value $newGuid -Force
        
        # Verify change
        $updatedGuid = Get-ItemProperty -Path $registryPath -Name $valueName
        if ($updatedGuid.MachineGuid -eq $newGuid) {
            Write-Success "Windows Machine GUID updated successfully"
            Write-Info "New GUID: $newGuid"
            return $true
        } else {
            Write-Error "Failed to verify GUID update"
            return $false
        }
    }
    catch {
        Write-Error "Failed to modify registry: $($_.Exception.Message)"
        return $false
    }
}

# Reset Cursor configuration
function Reset-CursorConfig {
    Write-Info "Resetting Cursor configuration..."
    
    $storageFile = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
    
    if (-not (Test-Path $storageFile)) {
        Write-Warning "Cursor storage file not found: $storageFile"
        Write-Info "This might be normal if Cursor hasn't been run yet"
        return $true
    }
    
    try {
        # Backup original file
        $backupFile = "$env:APPDATA\Cursor\User\globalStorage\storage_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        Copy-Item $storageFile $backupFile -Force
        Write-Success "Configuration backup created: $backupFile"
        
        # Read and parse JSON
        $jsonContent = Get-Content $storageFile -Raw | ConvertFrom-Json
        
        # Generate new identifiers
        $newMachineId = New-MachineGuid
        $newDeviceId = New-MachineGuid
        $newSqmId = "{$(New-MachineGuid)}"
        $newMacMachineId = -join ((1..32) | ForEach-Object { '{0:x}' -f (Get-Random -Max 16) })
        
        # Update identifiers
        if ($jsonContent.PSObject.Properties.Name -contains "telemetry.machineId") {
            $jsonContent."telemetry.machineId" = $newMachineId
        }
        if ($jsonContent.PSObject.Properties.Name -contains "telemetry.devDeviceId") {
            $jsonContent."telemetry.devDeviceId" = $newDeviceId
        }
        if ($jsonContent.PSObject.Properties.Name -contains "telemetry.sqmId") {
            $jsonContent."telemetry.sqmId" = $newSqmId
        }
        if ($jsonContent.PSObject.Properties.Name -contains "telemetry.macMachineId") {
            $jsonContent."telemetry.macMachineId" = $newMacMachineId
        }
        
        # Save updated configuration
        $jsonContent | ConvertTo-Json -Depth 10 | Set-Content $storageFile -Encoding UTF8
        
        Write-Success "Cursor configuration updated successfully"
        Write-Info "New Machine ID: $newMachineId"
        Write-Info "New Device ID: $newDeviceId"
        
        return $true
    }
    catch {
        Write-Error "Failed to update Cursor configuration: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
function Main {
    Write-Host "Starting Cursor trial reset process..." -ForegroundColor Green
    Write-Host ""
    
    # Step 1: Stop Cursor processes
    if (-not (Stop-CursorProcesses)) {
        Write-Error "Failed to stop all Cursor processes. Please close Cursor manually and try again."
        Read-Host "Press Enter to exit"
        return
    }
    
    # Step 2: Reset Windows registry
    if (-not (Reset-WindowsRegistry)) {
        Write-Error "Failed to reset Windows registry. The reset may be incomplete."
    }
    
    # Step 3: Reset Cursor configuration
    if (-not (Reset-CursorConfig)) {
        Write-Error "Failed to reset Cursor configuration. The reset may be incomplete."
    }
    
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "   Reset Process Completed!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host ""
    Write-Success "Cursor trial has been reset successfully!"
    Write-Info "You can now restart Cursor and enjoy your renewed trial period."
    Write-Warning "Important: Restart your computer for all changes to take effect."
    Write-Host ""
}

# Execute main function
Main

Read-Host "Press Enter to exit"