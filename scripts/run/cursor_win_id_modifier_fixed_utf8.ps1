# PowerShell Script for Cursor ID Modification - Fixed UTF-8 Version
# Author: Enhanced by AI Assistant
# Purpose: Reset Cursor trial and modify machine ID
# Date: 2025-01-07

# Set output encoding to UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Color definitions
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

# Configuration file paths
$STORAGE_FILE = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
$BACKUP_DIR = "$env:APPDATA\Cursor\User\globalStorage\backups"

# Function to check administrator privileges
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to generate random string
function Generate-RandomString {
    param([int]$Length)
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $result = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $result += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $result
}

# Function to stop all Cursor processes
function Stop-AllCursorProcesses {
    param(
        [int]$MaxRetries = 3,
        [int]$WaitSeconds = 5
    )

    Write-Host "$BLUE[Process Check]$NC Checking and closing all Cursor related processes..."

    $cursorProcessNames = @(
        "Cursor",
        "cursor",
        "Cursor Helper",
        "Cursor Helper (GPU)",
        "Cursor Helper (Plugin)",
        "Cursor Helper (Renderer)",
        "CursorUpdater"
    )

    for ($retry = 1; $retry -le $MaxRetries; $retry++) {
        Write-Host "$BLUE[Check]$NC Attempt $retry/$MaxRetries process check..."

        $foundProcesses = @()
        foreach ($processName in $cursorProcessNames) {
            $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if ($processes) {
                $foundProcesses += $processes
                Write-Host "$YELLOW[Found]$NC Process: $processName (PID: $($processes.Id -join ', '))"
            }
        }

        if ($foundProcesses.Count -eq 0) {
            Write-Host "$GREEN[Success]$NC All Cursor processes are closed"
            return $true
        }

        Write-Host "$YELLOW[Closing]$NC Closing $($foundProcesses.Count) Cursor processes..."

        # Try graceful shutdown first
        foreach ($process in $foundProcesses) {
            try {
                $process.CloseMainWindow() | Out-Null
                Write-Host "$BLUE  • Graceful close: $($process.ProcessName) (PID: $($process.Id))$NC"
            } catch {
                Write-Host "$YELLOW  • Graceful close failed: $($process.ProcessName)$NC"
            }
        }

        Start-Sleep -Seconds 3

        # Force terminate remaining processes
        foreach ($processName in $cursorProcessNames) {
            $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if ($processes) {
                foreach ($process in $processes) {
                    try {
                        Stop-Process -Id $process.Id -Force
                        Write-Host "$RED  • Force terminate: $($process.ProcessName) (PID: $($process.Id))$NC"
                    } catch {
                        Write-Host "$RED  • Force terminate failed: $($process.ProcessName)$NC"
                    }
                }
            }
        }

        if ($retry -lt $MaxRetries) {
            Write-Host "$YELLOW[Wait]$NC Waiting $WaitSeconds seconds before next check..."
            Start-Sleep -Seconds $WaitSeconds
        }
    }

    Write-Host "$RED[Failed]$NC Still have Cursor processes running after $MaxRetries attempts"
    return $false
}

# Function to remove Cursor trial folders
function Remove-CursorTrialFolders {
    Write-Host ""
    Write-Host "$GREEN[Core Function]$NC Executing Cursor trial Pro folder deletion..."
    Write-Host "$BLUE[Description]$NC This function will delete specified Cursor related folders to reset trial status"
    Write-Host ""

    # Define folders to delete
    $foldersToDelete = @()

    # Windows Administrator user paths
    $adminPaths = @(
        "C:\Users\Administrator\.cursor",
        "C:\Users\Administrator\AppData\Roaming\Cursor"
    )

    # Current user paths
    $currentUserPaths = @(
        "$env:USERPROFILE\.cursor",
        "$env:APPDATA\Cursor"
    )

    # Merge all paths
    $foldersToDelete += $adminPaths
    $foldersToDelete += $currentUserPaths

    Write-Host "$BLUE[Detection]$NC Will check the following folders:"
    foreach ($folder in $foldersToDelete) {
        Write-Host "   📁 $folder"
    }
    Write-Host ""

    $deletedCount = 0
    $skippedCount = 0
    $errorCount = 0

    # Delete specified folders
    foreach ($folder in $foldersToDelete) {
        Write-Host "$BLUE[Check]$NC Checking folder: $folder"

        if (Test-Path $folder) {
            try {
                Write-Host "$YELLOW[Warning]$NC Folder exists, deleting..."
                Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
                Write-Host "$GREEN[Success]$NC Deleted folder: $folder"
                $deletedCount++
            }
            catch {
                Write-Host "$RED[Error]$NC Failed to delete folder: $folder"
                Write-Host "$RED[Details]$NC Error: $($_.Exception.Message)"
                $errorCount++
            }
        } else {
            Write-Host "$YELLOW[Skip]$NC Folder does not exist: $folder"
            $skippedCount++
        }
        Write-Host ""
    }

    # Display operation statistics
    Write-Host "$GREEN[Statistics]$NC Operation completed:"
    Write-Host "   ✅ Successfully deleted: $deletedCount folders"
    Write-Host "   ⏭️  Skipped: $skippedCount folders"
    Write-Host "   ❌ Failed to delete: $errorCount folders"
    Write-Host ""

    if ($deletedCount -gt 0) {
        Write-Host "$GREEN[Complete]$NC Cursor trial Pro folder deletion completed!"

        # Pre-create necessary directory structure to avoid permission issues
        Write-Host "$BLUE[Fix]$NC Pre-creating necessary directory structure to avoid permission issues..."

        $cursorAppData = "$env:APPDATA\Cursor"
        $cursorUserProfile = "$env:USERPROFILE\.cursor"

        # Create main directories
        try {
            if (-not (Test-Path $cursorAppData)) {
                New-Item -ItemType Directory -Path $cursorAppData -Force | Out-Null
            }
            if (-not (Test-Path $cursorUserProfile)) {
                New-Item -ItemType Directory -Path $cursorUserProfile -Force | Out-Null
            }
            Write-Host "$GREEN[Complete]$NC Directory structure pre-creation completed"
        } catch {
            Write-Host "$YELLOW[Warning]$NC Issue occurred during directory pre-creation: $($_.Exception.Message)"
        }
    } else {
        Write-Host "$YELLOW[Note]$NC No folders found to delete, may have been cleaned already"
    }
    Write-Host ""
}

# Function to modify machine code configuration
function Modify-MachineCodeConfig {
    Write-Host ""
    Write-Host "$GREEN[Configuration]$NC Modifying machine code configuration..."

    $configPath = "$env:APPDATA\Cursor\User\globalStorage\storage.json"

    # Enhanced configuration file check
    if (-not (Test-Path $configPath)) {
        Write-Host "$RED[Error]$NC Configuration file does not exist: $configPath"
        Write-Host ""
        Write-Host "$YELLOW[Solution]$NC Please try the following steps:"
        Write-Host "$BLUE  1️⃣  Manually start Cursor application$NC"
        Write-Host "$BLUE  2️⃣  Wait for Cursor to fully load (about 30 seconds)$NC"
        Write-Host "$BLUE  3️⃣  Close Cursor application$NC"
        Write-Host "$BLUE  4️⃣  Re-run this script$NC"
        Write-Host ""
        return $false
    }

    try {
        Write-Host "$BLUE[Verification]$NC Checking configuration file format..."
        $originalContent = Get-Content $configPath -Raw -Encoding UTF8 -ErrorAction Stop
        $config = $originalContent | ConvertFrom-Json -ErrorAction Stop
        Write-Host "$GREEN[Verification]$NC Configuration file format is correct"

        # Generate new IDs
        $MAC_MACHINE_ID = [System.Guid]::NewGuid().ToString()
        $UUID = [System.Guid]::NewGuid().ToString()
        $prefixBytes = [System.Text.Encoding]::UTF8.GetBytes("auth0|user_")
        $prefixHex = -join ($prefixBytes | ForEach-Object { '{0:x2}' -f $_ })
        $randomBytes = New-Object byte[] 32
        $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
        $rng.GetBytes($randomBytes)
        $randomPart = [System.BitConverter]::ToString($randomBytes) -replace '-',''
        $rng.Dispose()
        $MACHINE_ID = "${prefixHex}${randomPart}"
        $SQM_ID = "{$([System.Guid]::NewGuid().ToString().ToUpper())}"

        # Backup original file
        $backupDir = "$env:APPDATA\Cursor\User\globalStorage\backups"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force -ErrorAction Stop | Out-Null
        }

        $backupName = "storage.json.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        $backupPath = "$backupDir\$backupName"
        Copy-Item $configPath $backupPath -ErrorAction Stop
        Write-Host "$GREEN[Backup]$NC Configuration backup successful: $backupName"

        # Update configuration values
        $propertiesToUpdate = @{
            'telemetry.machineId' = $MACHINE_ID
            'telemetry.macMachineId' = $MAC_MACHINE_ID
            'telemetry.devDeviceId' = $UUID
            'telemetry.sqmId' = $SQM_ID
        }

        foreach ($property in $propertiesToUpdate.GetEnumerator()) {
            $key = $property.Key
            $value = $property.Value

            if ($config.PSObject.Properties[$key]) {
                $config.$key = $value
                Write-Host "$BLUE  ✓ Updated property: ${key}$NC"
            } else {
                $config | Add-Member -MemberType NoteProperty -Name $key -Value $value -Force
                Write-Host "$BLUE  + Added property: ${key}$NC"
            }
        }

        # Write updated configuration
        $updatedJson = $config | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($configPath, $updatedJson, [System.Text.Encoding]::UTF8)

        Write-Host "$GREEN[Success]$NC Machine code configuration modification completed!"
        Write-Host "$BLUE[Info]$NC New device identifiers have been generated and applied"
        return $true

    } catch {
        Write-Host "$RED[Error]$NC Configuration file modification failed: $($_.Exception.Message)"
        return $false
    }
}

# Function to show success message
function Show-SuccessMessage {
    Write-Host ""
    Write-Host "$GREEN" + "=" * 60 + "$NC"
    Write-Host "$GREEN              🎉 CURSOR RESET COMPLETED! 🎉              $NC"
    Write-Host "$GREEN" + "=" * 60 + "$NC"
    Write-Host ""
    Write-Host "$GREEN✅ [SUCCESS]$NC Cursor trial reset has been completed successfully!"
    Write-Host ""
    Write-Host "$BLUE📋 [Summary]$NC Operations performed:"
    Write-Host "$BLUE  ✓ Cursor processes closed$NC"
    Write-Host "$BLUE  ✓ Trial folders deleted$NC"
    Write-Host "$BLUE  ✓ Machine code configuration modified$NC"
    Write-Host "$BLUE  ✓ New device identifiers generated$NC"
    Write-Host ""
    Write-Host "$YELLOW⚠️  [Important]$NC Next steps:"
    Write-Host "$YELLOW  1. Restart Cursor application$NC"
    Write-Host "$YELLOW  2. The trial period should be reset$NC"
    Write-Host "$YELLOW  3. You can now use Cursor Pro features during trial$NC"
    Write-Host ""
    Write-Host "$GREEN🎊 [Complete]$NC Thank you for using this tool!$NC"
    Write-Host ""
}

# Main execution starts here
Clear-Host

# Check administrator privileges
if (-not (Test-Administrator)) {
    Write-Host ""
    Write-Host "$RED[ERROR]$NC Administrator privileges required!"
    Write-Host ""
    Write-Host "$YELLOW[Solution]$NC Please run this script as administrator:"
    Write-Host "$BLUE  1. Right-click on the script file$NC"
    Write-Host "$BLUE  2. Select 'Run as administrator'$NC"
    Write-Host "$BLUE  3. Or open PowerShell as administrator and run the script$NC"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Display logo and information
Write-Host @"

   ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
  ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
  ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
  ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
  ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
   ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝

"@
Write-Host "$BLUE" + "=" * 60 + "$NC"
Write-Host "$GREEN🚀   Cursor Trial Reset Tool - Fixed Version          $NC"
Write-Host "$YELLOW📱  Educational and Study Purposes Only  $NC"
Write-Host "$BLUE" + "=" * 60 + "$NC"

Write-Host ""
Write-Host "$GREEN[Start]$NC Starting Cursor trial reset process..."
Write-Host ""

# Step 1: Stop all Cursor processes
Write-Host "$BLUE[Step 1/3]$NC Stopping Cursor processes..."
if (-not (Stop-AllCursorProcesses -MaxRetries 3 -WaitSeconds 3)) {
    Write-Host "$YELLOW[Warning]$NC Some Cursor processes may still be running, but continuing..."
}

# Step 2: Remove trial folders
Write-Host "$BLUE[Step 2/3]$NC Removing trial folders..."
Remove-CursorTrialFolders

# Wait a moment before configuration modification
Write-Host "$BLUE[Wait]$NC Waiting 3 seconds before configuration modification..."
Start-Sleep -Seconds 3

# Step 3: Modify machine code configuration
Write-Host "$BLUE[Step 3/3]$NC Modifying machine code configuration..."

# Try to start Cursor briefly to generate config if needed
$configPath = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
if (-not (Test-Path $configPath)) {
    Write-Host "$YELLOW[Notice]$NC Configuration file not found, attempting to generate..."
    
    # Try to find Cursor executable
    $cursorPaths = @(
        "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
        "$env:PROGRAMFILES\Cursor\Cursor.exe",
        "$env:PROGRAMFILES(X86)\Cursor\Cursor.exe"
    )
    
    $cursorPath = $null
    foreach ($path in $cursorPaths) {
        if (Test-Path $path) {
            $cursorPath = $path
            break
        }
    }
    
    if ($cursorPath) {
        Write-Host "$BLUE[Generate]$NC Starting Cursor briefly to generate configuration..."
        try {
            $process = Start-Process -FilePath $cursorPath -PassThru -WindowStyle Hidden
            Start-Sleep -Seconds 15
            
            if ($process -and -not $process.HasExited) {
                $process.Kill()
                $process.WaitForExit(5000)
            }
            
            # Ensure all processes are closed
            Stop-AllCursorProcesses -MaxRetries 2 -WaitSeconds 2 | Out-Null
            
            Start-Sleep -Seconds 3
        } catch {
            Write-Host "$YELLOW[Warning]$NC Could not auto-generate config: $($_.Exception.Message)"
        }
    }
}

# Attempt to modify configuration
if (Modify-MachineCodeConfig) {
    Show-SuccessMessage
} else {
    Write-Host ""
    Write-Host "$RED[Error]$NC Configuration modification failed"
    Write-Host "$YELLOW[Manual Steps]$NC If automatic configuration failed:"
    Write-Host "$BLUE  1. Start Cursor manually$NC"
    Write-Host "$BLUE  2. Let it fully load (30 seconds)$NC"
    Write-Host "$BLUE  3. Close Cursor$NC"
    Write-Host "$BLUE  4. Run this script again$NC"
    Write-Host ""
}

Write-Host "$GREEN[Finished]$NC Script execution completed."
Read-Host "Press Enter to exit"