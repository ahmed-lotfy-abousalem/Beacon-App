# Recording script for Beacon app without P2P testing
# Run this script to record the emulator while running the Flutter app

param(
    [int]$RecordingDuration = 120  # Recording duration in seconds (2 minutes)
)

# Setup
$videoDir = "$PSScriptRoot\recordings"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$videoName = "beacon_no_p2p_$timestamp.mp4"
$videoPath = Join-Path $videoDir $videoName

# Set Android SDK path
$androidHome = "D:\Android_SDK"

if (-not (Test-Path "$androidHome\platform-tools\adb.exe")) {
    Write-Host "[ERROR] ADB not found at: $androidHome\platform-tools\adb.exe"
    Write-Host "[HELP] Please update the script with your Android SDK path"
    exit 1
}

$adbPath = "$androidHome\platform-tools\adb.exe"

# Create recordings directory if it doesn't exist
if (-not (Test-Path $videoDir)) {
    New-Item -ItemType Directory -Path $videoDir | Out-Null
    Write-Host "[INFO] Created recordings directory: $videoDir"
}

Write-Host "========================================================"
Write-Host "[VIDEO] BEACON APP RECORDING - NO P2P TESTING"
Write-Host "========================================================"
Write-Host ""
Write-Host "[TIME] Recording Duration: $RecordingDuration seconds"
Write-Host "[FILE] Video Location: $videoPath"
Write-Host ""

# Check if emulator/device is connected
$devices = & $adbPath devices | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
if (-not $devices) {
    Write-Host "[ERROR] No Android emulator/device found!"
    Write-Host "[HINT] Please start an Android emulator or connect a device"
    exit 1
}

Write-Host "[OK] Device found"
Write-Host ""

# Clear previous recordings if they exist
Write-Host "[PREP] Cleaning up emulator storage..."
& $adbPath shell rm -f /sdcard/$videoName 2>$null

# Start screen recording on emulator in background
Write-Host "[REC] Starting screen recording..."
$recordingCommand = "$adbPath shell screenrecord --time-limit $RecordingDuration --size 1280x720 --bit-rate 8000000 /sdcard/$videoName"
$recordingProcess = Start-Process -NoNewWindow -PassThru powershell -ArgumentList "-NoProfile", "-Command", "& $recordingCommand"

Start-Sleep -Seconds 2

# Launch Flutter app (without P2P initialization)
Write-Host "[RUN] Launching Beacon app..."
Write-Host "────────────────────────────────────────────────────────"
Write-Host ""

# Start the app in background
$appProcess = Start-Process -NoNewWindow -PassThru powershell -ArgumentList "-NoProfile", "-Command", "flutter run --no-fast-start"

# Wait for app to fully load
Write-Host "[LOAD] Waiting for app to load..."
Start-Sleep -Seconds 8

# Perform automated interactions
Write-Host "[AUTO] Starting automated app interactions..."
Start-Sleep -Seconds 2

# Example interaction patterns - customize these based on your app's UI
# Tap on screen center (adjust coordinates as needed for your app)
Write-Host "[TAP] Tapping on screen..."
& $adbPath shell input tap 640 1280
Start-Sleep -Seconds 1.5

# Swipe up to navigate/scroll
Write-Host "[SWIPE] Swiping up..."
& $adbPath shell input swipe 640 1600 640 800 500
Start-Sleep -Seconds 1.5

# Tap on different area
& $adbPath shell input tap 400 800
Start-Sleep -Seconds 1.5

# Swipe down to go back or navigate
Write-Host "[SWIPE] Swiping down..."
& $adbPath shell input swipe 640 800 640 1600 500
Start-Sleep -Seconds 1.5

# Tap on another element
& $adbPath shell input tap 800 800
Start-Sleep -Seconds 2

Write-Host "[AUTO] Automated interactions complete"

# Let app continue running until recording finishes
Write-Host "[WAIT] Waiting for screen recording to finalize (may take a few seconds)..."

# Wait for the recording process to complete
$recordingProcess | Wait-Process -Timeout 300
Start-Sleep -Seconds 2

# Pull video from emulator to PC
Write-Host "[PULL] Pulling video from emulator..."
$pullAttempts = 0
$maxAttempts = 3
while ($pullAttempts -lt $maxAttempts) {
    & $adbPath pull "/sdcard/$videoName" "$videoPath" 2>$null
    if (Test-Path $videoPath) {
        break
    }
    $pullAttempts++
    Start-Sleep -Seconds 2
}

if (Test-Path $videoPath) {
    $fileSize = (Get-Item $videoPath).Length / 1MB
    Write-Host "[OK] Video successfully saved!"
    Write-Host "[SIZE] File size: $([math]::Round($fileSize, 2)) MB"
    Write-Host "[PATH] Location: $videoPath"
} else {
    Write-Host "[ERROR] Failed to save video"
    exit 1
}

# Clean up emulator storage
Write-Host "[CLEANUP] Cleaning up emulator storage..."
& $adbPath shell rm -f /sdcard/$videoName

Write-Host ""
Write-Host "========================================================"
Write-Host "[DONE] Recording complete!"
Write-Host "========================================================"
Write-Host ""
Write-Host "[TIPS] Usage Examples:"
Write-Host "  - Default 2 min:    .\record_app_no_p2p.ps1"
Write-Host "  - Custom duration:  .\record_app_no_p2p.ps1 -RecordingDuration 300"
Write-Host ""

