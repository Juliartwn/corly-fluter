# Script untuk memindahkan Flutter SDK secara otomatis
# JALANKAN SEBAGAI ADMINISTRATOR!

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  Flutter SDK Migration Script" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$oldPath = "C:\Users\Juli Artawan\flutter"
$newPath = "C:\flutter"
$oldBinPath = "$oldPath\bin"
$newBinPath = "$newPath\bin"

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "✗ ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Step 1: Checking old Flutter SDK..." -ForegroundColor Yellow
if (Test-Path $oldPath) {
    Write-Host "   ✓ Found: $oldPath" -ForegroundColor Green
    $size = (Get-ChildItem -Path $oldPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "   Size: $([math]::Round($size, 2)) GB" -ForegroundColor Cyan
} else {
    Write-Host "   ✗ Old Flutter SDK not found at: $oldPath" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "Step 2: Checking destination..." -ForegroundColor Yellow
if (Test-Path $newPath) {
    Write-Host "   ⚠ WARNING: $newPath already exists!" -ForegroundColor Yellow
    $response = Read-Host "   Do you want to overwrite? (yes/no)"
    if ($response -ne "yes") {
        Write-Host "   Cancelled by user." -ForegroundColor Red
        pause
        exit 0
    }
} else {
    Write-Host "   ✓ Destination is clear" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 3: Copying Flutter SDK..." -ForegroundColor Yellow
Write-Host "   This may take several minutes..." -ForegroundColor Cyan
try {
    # Create destination directory
    New-Item -ItemType Directory -Path $newPath -Force | Out-Null
    
    # Copy with progress
    robocopy $oldPath $newPath /E /MT:8 /R:2 /W:5 /NFL /NDL /NP
    
    Write-Host "   ✓ Copy completed!" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Error during copy: $_" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "Step 4: Updating Environment Variables..." -ForegroundColor Yellow

# Get current PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

# Remove old Flutter path
$updatedPath = $currentPath -replace [regex]::Escape("$oldBinPath;"), ""
$updatedPath = $updatedPath -replace [regex]::Escape("$oldBinPath"), ""

# Add new Flutter path (at the beginning for priority)
if ($updatedPath -notlike "*$newBinPath*") {
    $updatedPath = "$newBinPath;$updatedPath"
}

# Set updated PATH
[Environment]::SetEnvironmentVariable("Path", $updatedPath, "User")
Write-Host "   ✓ Environment variable updated!" -ForegroundColor Green

Write-Host ""
Write-Host "Step 5: Verification..." -ForegroundColor Yellow
Write-Host "   Please close this terminal and open a NEW terminal, then run:" -ForegroundColor Cyan
Write-Host "   flutter --version" -ForegroundColor White
Write-Host "   flutter doctor" -ForegroundColor White
Write-Host ""
Write-Host "   Or run the verification script:" -ForegroundColor Cyan
Write-Host "   .\verify_flutter.ps1" -ForegroundColor White

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  Migration Complete!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT:" -ForegroundColor Yellow
Write-Host "1. RESTART VS Code completely" -ForegroundColor White
Write-Host "2. Open a new terminal and verify with: flutter --version" -ForegroundColor White
Write-Host "3. You can safely delete the old folder after verification:" -ForegroundColor White
Write-Host "   Remove-Item '$oldPath' -Recurse -Force" -ForegroundColor Gray
Write-Host ""

pause
