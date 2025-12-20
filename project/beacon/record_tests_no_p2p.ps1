# Recording script for running tests without P2P related tests
# Run this script to record the emulator while running integration/unit tests (excluding P2P)

param(
    [ValidateSet('unit', 'integration', 'both')]
    [string]$TestType = 'both',
    
    [int]$RecordingDuration = 180  # Recording duration in seconds (3 minutes)
)

# Set Android SDK path
$androidHome = "D:\Android_SDK"

if (-not (Test-Path "$androidHome\platform-tools\adb.exe")) {
    Write-Host "[ERROR] ADB not found at: $androidHome\platform-tools\adb.exe"
    Write-Host "[HELP] Please update the script with your Android SDK path"
    exit 1
}

$adbPath = "$androidHome\platform-tools\adb.exe"

# Setup
$videoDir = "$PSScriptRoot\recordings"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$videoName = "beacon_tests_no_p2p_$timestamp.mp4"
$videoPath = Join-Path $videoDir $videoName

# Create recordings directory if it doesn't exist
if (-not (Test-Path $videoDir)) {
    New-Item -ItemType Directory -Path $videoDir | Out-Null
}

Write-Host "========================================================"
Write-Host "[VIDEO] BEACON TESTS RECORDING - NO P2P TESTING"
Write-Host "========================================================"
Write-Host ""
Write-Host "[TEST] Test Type: $TestType"
Write-Host "[TIME] Recording Duration: $RecordingDuration seconds"
Write-Host "[FILE] Video Location: $videoPath"
Write-Host ""

# Check if emulator/device is connected
$devices = & $adbPath devices | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
if (-not $devices) {
    Write-Host "[ERROR] No Android emulator/device found!"
    exit 1
}

Write-Host "[OK] Device found"
Write-Host ""

# Clean up previous recordings
& $adbPath shell rm -f /sdcard/$videoName 2>$null

# Start screen recording on emulator in background
Write-Host "[REC] Starting screen recording..."
$recordingCommand = "$adbPath shell screenrecord --time-limit $RecordingDuration --size 1280x720 --bit-rate 8000000 /sdcard/$videoName"
$recordingProcess = Start-Process -NoNewWindow -PassThru powershell -ArgumentList "-NoProfile", "-Command", "& $recordingCommand"

Start-Sleep -Seconds 2

# Run tests (excluding P2P related)
Write-Host "[RUN] Running tests (excluding P2P)..."
Write-Host "────────────────────────────────────────────────────────"
Write-Host ""

# Run tests based on type
switch ($TestType) {
    'unit' {
        Write-Host "Running unit tests..."
        flutter test test/unit/ --reporter=expanded 2>&1
    }
    'integration' {
        Write-Host "Running integration tests..."
        flutter test test/integration/ --reporter=expanded 2>&1
    }
    'both' {
        Write-Host "Launching app for recording..."
        flutter run --no-fast-start 2>&1
    }
}

Write-Host ""
Write-Host "────────────────────────────────────────────────────────"
Write-Host "[WAIT] Waiting for screen recording to finalize..."

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
    Write-Host "[WARN] Video file not found (tests may have completed quickly)"
}

# Clean up emulator storage
Write-Host "[CLEANUP] Cleaning up emulator storage..."
& $adbPath shell rm -f /sdcard/$videoName 2>$null

Write-Host ""
Write-Host "========================================================"
Write-Host "[DONE] Recording complete!"
Write-Host "========================================================"
Write-Host ""
Write-Host "[TIPS] Usage Examples:"
Write-Host "  • Record app demo:          .\record_app_no_p2p.ps1"
Write-Host "  • Record app with 5 min:    .\record_app_no_p2p.ps1 -RecordingDuration 300"
Write-Host "  • Record unit tests:        .\record_tests_no_p2p.ps1 -TestType unit"
Write-Host "  • Record integration tests: .\record_tests_no_p2p.ps1 -TestType integration"
Write-Host "  • Record all tests:         .\record_tests_no_p2p.ps1 -TestType both -RecordingDuration 300"
Write-Host ""
