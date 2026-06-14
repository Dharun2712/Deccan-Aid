<#
.SYNOPSIS
    Automates the Flutter quickstart process for Deccan-Aid.
.DESCRIPTION
    This script checks for the Flutter executable, runs pub get to install
    dependencies, checking connected devices, and launching the app.
#>

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "    Deccan-Aid Flutter Quickstart         " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if flutter is installed and in PATH
$flutterPath = Get-Command "flutter" -ErrorAction SilentlyContinue
if ($null -eq $flutterPath) {
    Write-Host "ERROR: Flutter is not installed or not added to your PATH environment variable." -ForegroundColor Red
    Write-Host "Please install Flutter and try again." -ForegroundColor Yellow
    exit 1
}

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Move up one level since the script is inside /documents/
$projectRootDir = (Get-Item $projectRoot).Parent.FullName

Set-Location -Path $projectRootDir
Write-Host "Changed directory to project root: $projectRootDir" -ForegroundColor Green

Write-Host "`n[1/3] Getting Flutter packages..." -ForegroundColor Yellow
flutter pub get

Write-Host "`n[2/3] Checking connected devices..." -ForegroundColor Yellow
flutter devices

Write-Host "`n[3/3] Launching application..." -ForegroundColor Yellow
Write-Host "If multiple devices are connected, the launch might ask you to select one, or you can kill the script and run: flutter run -d <device_id>" -ForegroundColor Magenta

flutter run
