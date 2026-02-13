# Aftman installation script for brainrot-rivals
# Run this in PowerShell from the project directory

$downloadUrl = "https://github.com/LPGhatguy/aftman/releases/download/v0.3.0/aftman-x86_64-pc-windows-msvc.exe"
$outFile = Join-Path $PSScriptRoot "aftman.exe"

Write-Host "Downloading aftman..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $downloadUrl -OutFile $outFile -UseBasicParsing

Write-Host "Installing aftman..." -ForegroundColor Cyan
& $outFile self-install

Write-Host "Done! Close and reopen your terminal for changes to take effect." -ForegroundColor Green
