# ==============================================================================
# WhatsGo (WA Web To Go Reborn) - Automated Release Build & Packaging Script
# ==============================================================================

$ErrorActionPreference = "Stop"

$ProjectRoot = "D:\Nuno\WebWhatsAppToGo"
$DistDir = "$ProjectRoot\dist\release"
$AppBuildDir = "$ProjectRoot\build\app\outputs\flutter-apk"

# Set up environment variables
$env:ANDROID_HOME = "D:\Android\Sdk"
$env:ANDROID_SDK_ROOT = "D:\Android\Sdk"
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot"
$env:Path = "D:\flutter\bin;$env:JAVA_HOME\bin;D:\Android\Sdk\cmdline-tools\latest\bin;D:\Android\Sdk\platform-tools;D:\Android\Sdk\build-tools\34.0.0;$env:Path"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   WhatsGo - Memulai Kompilasi Release & Packaging        " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Prepare output directory
if (Test-Path $DistDir) {
    Remove-Item -Recurse -Force $DistDir
}
New-Item -ItemType Directory -Path $DistDir -Force | Out-Null

# 2. Verify dependencies
Write-Host "`n[1/5] Memeriksa dependensi proyek..." -ForegroundColor Yellow
flutter pub get

# 3. Build Universal Release APK
Write-Host "`n[2/5] Membangun Universal Release APK..." -ForegroundColor Yellow
flutter build apk --release -t lib/main.dart --android-skip-build-dependency-validation

if (Test-Path "$AppBuildDir\app-release.apk") {
    Copy-Item "$AppBuildDir\app-release.apk" "$DistDir\whatsgo-v1.0.0-universal.apk" -Force
    Write-Host "   -> whatsgo-v1.0.0-universal.apk tersimpan!" -ForegroundColor Green
} else {
    Write-Error "Gagal menemukan app-release.apk"
}

# 4. Build Split per-ABI Release APKs
Write-Host "`n[3/5] Membangun Split per-ABI Release APKs (arm64-v8a, armeabi-v7a, x86_64)..." -ForegroundColor Yellow
flutter build apk --release -t lib/main.dart --split-per-abi --android-skip-build-dependency-validation

$abiFiles = @(
    @{ Src = "app-arm64-v8a-release.apk"; Dst = "whatsgo-v1.0.0-arm64-v8a.apk" },
    @{ Src = "app-armeabi-v7a-release.apk"; Dst = "whatsgo-v1.0.0-armeabi-v7a.apk" },
    @{ Src = "app-x86_64-release.apk"; Dst = "whatsgo-v1.0.0-x86_64.apk" }
)

foreach ($item in $abiFiles) {
    $srcPath = "$AppBuildDir\$($item.Src)"
    if (Test-Path $srcPath) {
        Copy-Item $srcPath "$DistDir\$($item.Dst)" -Force
        Write-Host "   -> $($item.Dst) tersimpan!" -ForegroundColor Green
    }
}

# 5. Generate SHA-256 Checksums
Write-Host "`n[4/5] Menghitung SHA-256 Checksums..." -ForegroundColor Yellow
$checksumsFile = "$DistDir\checksums.txt"
$hashLines = @()

$distApks = Get-ChildItem -Path $DistDir -Filter "*.apk"
foreach ($apk in $distApks) {
    $hash = (Get-FileHash -Path $apk.FullName -Algorithm SHA256).Hash.ToLower()
    $sizeMB = [math]::Round($apk.Length / 1MB, 2)
    $line = "$hash  $($apk.Name) ($sizeMB MB)"
    $hashLines += $line
    Write-Host "   $line" -ForegroundColor White
}

$hashLines | Out-File -FilePath $checksumsFile -Encoding utf8
Write-Host "   -> Checksums disimpan ke $checksumsFile" -ForegroundColor Green

# 6. Verify Signature with apksigner
Write-Host "`n[5/5] Memverifikasi Signature Keystore..." -ForegroundColor Yellow
$universalApk = "$DistDir\whatsgo-v1.0.0-universal.apk"
if (Test-Path $universalApk) {
    & apksigner.bat verify --verbose $universalApk
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "   PROSES BUILD SELESAI! Artefak siap di:                " -ForegroundColor Green
Write-Host "   $DistDir" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green

