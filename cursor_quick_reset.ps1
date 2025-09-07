# Cursor Reset - Quick One-Liner Commands

# Method 1: Run the simple reset script directly
# Copy and paste this into an Administrator PowerShell:

irm https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/simple_cursor_reset.ps1 | iex

# Method 2: If the above doesn't work, use this local approach:
# 1. Save this file as cursor_quick_reset.ps1
# 2. Right-click on PowerShell and "Run as Administrator"  
# 3. Run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# 4. Run: .\cursor_quick_reset.ps1

# Method 3: Alternative one-liner (use this if method 1 fails):
# Invoke-Expression (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/yuaotian/go-cursor-help/refs/heads/master/simple_cursor_reset.ps1")

# QUICK RESET FUNCTION (embedded)
function Quick-CursorReset {
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "❌ Run as Administrator!" -ForegroundColor Red; return
    }
    
    Write-Host "🚀 Quick Cursor Reset..." -ForegroundColor Cyan
    
    # Stop Cursor
    Get-Process | Where-Object {$_.ProcessName -match "Cursor"} | ForEach-Object {$_.Kill()}
    Start-Sleep 2
    
    # Reset Machine GUID
    $newGuid = [System.Guid]::NewGuid().ToString().ToUpper()
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid" -Value $newGuid
    
    # Reset Cursor storage if exists
    $storage = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
    if (Test-Path $storage) {
        $config = Get-Content $storage -Raw | ConvertFrom-Json
        $config."telemetry.machineId" = [System.Guid]::NewGuid().ToString()
        $config."telemetry.devDeviceId" = [System.Guid]::NewGuid().ToString()
        $config | ConvertTo-Json -Depth 10 | Set-Content $storage -Encoding UTF8
    }
    
    Write-Host "✅ Reset complete! Restart computer and open Cursor." -ForegroundColor Green
}

# Run the quick reset
Quick-CursorReset