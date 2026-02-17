# Script untuk verifikasi Flutter SDK setelah dipindah
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  Flutter SDK Verification Script" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Checking Flutter location..." -ForegroundColor Yellow
$flutterPath = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if ($flutterPath) {
    Write-Host "   ✓ Flutter found at: $flutterPath" -ForegroundColor Green
    
    # Check if path contains spaces
    if ($flutterPath -match '\s') {
        Write-Host "   ✗ WARNING: Path contains spaces!" -ForegroundColor Red
    } else {
        Write-Host "   ✓ Path looks good (no spaces)" -ForegroundColor Green
    }
} else {
    Write-Host "   ✗ Flutter not found in PATH!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "2. Checking Flutter version..." -ForegroundColor Yellow
flutter --version

Write-Host ""
Write-Host "3. Running Flutter doctor..." -ForegroundColor Yellow
flutter doctor -v

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  Verification Complete!" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
