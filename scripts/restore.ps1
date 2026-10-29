# Re-enables every Amazon app that 1-debloat.ps1 disables.
# Usage: .\scripts\restore.ps1 [-Tv 10.0.0.18]
param([string]$Tv)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\config.ps1"
if (-not $Tv) { $Tv = $DefaultTv }
$s = Connect-Tv $Tv

$disabled = (adb -s $s shell pm list packages -d) -replace '^package:', ''
foreach ($p in $DebloatGroups.Values | ForEach-Object { $_ }) {
  if ($disabled -contains $p) { adb -s $s shell pm enable $p | Out-Null; '{0,-40} re-enabled' -f $p }
}
Write-Host 'Done. Restart the TV to see Amazon apps again.' -ForegroundColor Green
