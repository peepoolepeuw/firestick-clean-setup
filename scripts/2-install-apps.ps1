# Installs SmartTube, Projectivy Launcher and Aerial Views from their official GitHub releases.
# Each APK is verified against GitHub's published SHA-256 digest; a mismatch aborts that app.
# Usage: .\scripts\2-install-apps.ps1 [-Tv 10.0.0.18] [-WhatIf]
param([string]$Tv, [switch]$WhatIf)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\config.ps1"
if (-not $Tv) { $Tv = $DefaultTv }
$s = Connect-Tv $Tv

$abis = (adb -s $s shell getprop ro.product.cpu.abilist).Trim() -split ','
$abi = if ($abis -contains 'arm64-v8a') { 'arm64-v8a' } else { 'armeabi-v7a' }
Write-Host "TV CPU: $abi"
$headers = @{ 'User-Agent' = 'firestick-setup' }
$ProgressPreference = 'SilentlyContinue'

foreach ($app in $Apps) {
  Write-Host "`n== $($app.Name)" -ForegroundColor Cyan
  $releases = Invoke-RestMethod "https://api.github.com/repos/$($app.Repo)/releases?per_page=10" -Headers $headers
  $release = $releases | Where-Object { -not $_.prerelease -and -not $_.draft } | Select-Object -First 1
  $pattern = $app.Asset -replace '\{abi\}', $abi
  $asset = $release.assets | Where-Object { $_.name -like $pattern } | Select-Object -First 1
  if (-not $asset) { Write-Warning "No asset matching $pattern in $($app.Repo) $($release.tag_name)"; continue }
  if (-not $asset.digest) { Write-Warning "GitHub published no checksum for $($asset.name); skipping"; continue }
  "Release $($release.tag_name): $($asset.name) ($([math]::Round($asset.size / 1MB, 1)) MB)"
  if ($WhatIf) { 'would download, verify and install'; continue }

  # Short temp path: adb can't read the long paths some sandboxes use.
  $dir = Join-Path $env:TEMP ("fs-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
  New-Item -ItemType Directory $dir | Out-Null
  try {
    $apk = Join-Path $dir 'app.apk'
    Invoke-WebRequest $asset.browser_download_url -OutFile $apk -UseBasicParsing
    $hash = 'sha256:' + (Get-FileHash $apk -Algorithm SHA256).Hash.ToLower()
    if ($hash -ne $asset.digest) { Write-Warning "Checksum mismatch for $($asset.name) - NOT installing"; continue }
    'Checksum OK'
    adb -s $s install -r $apk
  } finally { Remove-Item -Recurse -Force $dir }
}
