# Disables Amazon tracking, ads, promos and unused extras. Reversible with restore.ps1.
# Usage: .\scripts\1-debloat.ps1 [-Tv 10.0.0.18] [-WhatIf]
param([string]$Tv, [switch]$WhatIf)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\config.ps1"
if (-not $Tv) { $Tv = $DefaultTv }
$s = Connect-Tv $Tv

$installed = (adb -s $s shell pm list packages) -replace '^package:', ''
$disabled = (adb -s $s shell pm list packages -d) -replace '^package:', ''

foreach ($group in $DebloatGroups.Keys) {
  Write-Host "`n== $group" -ForegroundColor Cyan
  foreach ($p in $DebloatGroups[$group]) {
    if ($installed -notcontains $p) { '{0,-40} not on this model' -f $p; continue }
    if ($disabled -contains $p) { '{0,-40} already disabled' -f $p; continue }
    if ($WhatIf) { '{0,-40} would disable' -f $p; continue }
    $r = (adb -s $s shell "pm disable-user --user 0 $p 2>&1" | Out-String).Trim()
    if ($r -match 'disabled-user') { '{0,-40} disabled' -f $p }
    elseif ($r -match 'protected') { '{0,-40} protected by Amazon (skipped)' -f $p }
    else { '{0,-40} FAILED: {1}' -f $p, ($r -split "`n")[0] }
  }
}
Write-Host "`nLeft alone on purpose: $ProtectedNote" -ForegroundColor DarkGray
