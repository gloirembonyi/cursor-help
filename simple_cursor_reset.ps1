# ==============================================
#        Cursor Helper - Simple Reset Tool
# ==============================================
# This is a simplified version that focuses on the core functionality

param(
    [switch]$Force,
    [switch]$NoWait
)

# Check administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`n❌ [ERROR] Administrator privileges required!" -ForegroundColor Red
    Write-Host "   Please run PowerShell as Administrator.`n" -ForegroundColor Yellow
    if (-not $NoWait) { Read-Host "Press Enter to exit" }
    exit 1
}

Write-Host "`n🚀 Cursor Helper - Trial Reset Tool" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Function to stop Cursor processes
function Stop-CursorProcesses {
    Write-Host "`n🔄 Stopping Cursor processes..." -ForegroundColor Yellow
    
    $cursorProcesses = Get-Process | Where-Object { $_.ProcessName -match "Cursor" }
    
    if ($cursorProcesses.Count -eq 0) {
        Write-Host "   ✅ No Cursor processes running" -ForegroundColor Green
        return
    }
    
    foreach ($process in $cursorProcesses) {
        try {
            Write-Host "   🔸 Stopping: $($process.ProcessName)" -ForegroundColor Cyan
            $process.Kill()
            Start-Sleep -Milliseconds 300
        }
        catch {
            Write-Host "   ⚠️  Could not stop: $($process.ProcessName)" -ForegroundColor Yellow
        }
    }
    
    Start-Sleep -Seconds 1
    Write-Host "   ✅ Cursor processes stopped" -ForegroundColor Green
}

# Function to reset Windows Machine GUID
function Reset-MachineGuid {
    Write-Host "`n🔑 Resetting Windows Machine GUID..." -ForegroundColor Yellow
    
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
        $oldGuid = (Get-ItemProperty -Path $regPath -Name "MachineGuid").MachineGuid
        $newGuid = [System.Guid]::NewGuid().ToString().ToUpper()
        
        # Backup
        $backupFile = "$env:TEMP\cursor_guid_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        "Original: $oldGuid`nNew: $newGuid`nDate: $(Get-Date)" | Out-File $backupFile
        
        # Update registry
        Set-ItemProperty -Path $regPath -Name "MachineGuid" -Value $newGuid
        
        Write-Host "   ✅ Machine GUID updated successfully" -ForegroundColor Green
        Write-Host "   📁 Backup saved: $backupFile" -ForegroundColor Cyan
        Write-Host "   🆔 New GUID: $newGuid" -ForegroundColor Gray
        
        return $true
    }
    catch {
        Write-Host "   ❌ Failed to update Machine GUID: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to reset Cursor configuration
function Reset-CursorStorage {
    Write-Host "`n📁 Resetting Cursor storage..." -ForegroundColor Yellow
    
    $storagePath = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
    
    if (-not (Test-Path $storagePath)) {
        Write-Host "   ℹ️  Storage file not found (this is normal for new installations)" -ForegroundColor Cyan
        return $true
    }
    
    try {
        # Backup original
        $backupPath = "$env:APPDATA\Cursor\User\globalStorage\storage_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        Copy-Item $storagePath $backupPath
        
        # Read and update JSON
        $config = Get-Content $storagePath -Raw | ConvertFrom-Json
        
        # Generate new IDs
        $newMachineId = [System.Guid]::NewGuid().ToString()
        $newDeviceId = [System.Guid]::NewGuid().ToString()
        $newSqmId = "{$([System.Guid]::NewGuid().ToString())}"
        $newMacId = -join ((1..32) | ForEach-Object { [System.Convert]::ToString((Get-Random -Max 16), 16) })
        
        # Update telemetry IDs
        if ($config.PSObject.Properties.Name -contains "telemetry.machineId") {
            $config."telemetry.machineId" = $newMachineId
        }
        if ($config.PSObject.Properties.Name -contains "telemetry.devDeviceId") {
            $config."telemetry.devDeviceId" = $newDeviceId
        }
        if ($config.PSObject.Properties.Name -contains "telemetry.sqmId") {
            $config."telemetry.sqmId" = $newSqmId
        }
        if ($config.PSObject.Properties.Name -contains "telemetry.macMachineId") {
            $config."telemetry.macMachineId" = $newMacId
        }
        
        # Save updated config
        $config | ConvertTo-Json -Depth 10 | Set-Content $storagePath -Encoding UTF8
        
        Write-Host "   ✅ Cursor storage updated successfully" -ForegroundColor Green
        Write-Host "   📁 Backup saved: $backupPath" -ForegroundColor Cyan
        
        return $true
    }
    catch {
        Write-Host "   ❌ Failed to update storage: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-Host "`n🔍 Checking Cursor installation..." -ForegroundColor Yellow

# Stop processes first
Stop-CursorProcesses

# Reset machine GUID
$guidSuccess = Reset-MachineGuid

# Reset Cursor storage
$storageSuccess = Reset-CursorStorage

# Results
Write-Host "`n" + "="*50 -ForegroundColor Green
if ($guidSuccess -and $storageSuccess) {
    Write-Host "🎉 SUCCESS: Cursor trial reset completed!" -ForegroundColor Green
    Write-Host "`n📝 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Restart your computer (recommended)" -ForegroundColor White
    Write-Host "   2. Start Cursor" -ForegroundColor White
    Write-Host "   3. Sign in with your account" -ForegroundColor White
    Write-Host "   4. Enjoy your renewed trial!" -ForegroundColor White
} else {
    Write-Host "⚠️  PARTIAL SUCCESS: Some operations failed" -ForegroundColor Yellow
    Write-Host "   The reset may still work, try restarting Cursor" -ForegroundColor White
}
Write-Host "="*50 -ForegroundColor Green

if (-not $NoWait) {
    Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
    Read-Host
}