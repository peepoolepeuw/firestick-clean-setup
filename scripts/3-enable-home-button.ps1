# Lets Projectivy take over the Home and Back buttons by turning on its accessibility service.
# Fire OS hides third-party accessibility services from its menu, so this is the only way.
# This gives Projectivy control over remote button presses - run it yourself, knowingly.
# Undo: .\scripts\3-enable-home-button.ps1 -Off
param([string]$Tv, [switch]$Off)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\config.ps1"
if (-not $Tv) { $Tv = $DefaultTv }
$s = Connect-Tv $Tv

if ($Off) {
  adb -s $s shell settings put secure enabled_accessibility_services null
  adb -s $s shell settings put secure accessibility_enabled 0
  Write-Host 'Home button returned to Amazon.' -ForegroundColor Green
  return
}
adb -s $s shell settings put secure enabled_accessibility_services $ProjectivyService
adb -s $s shell settings put secure accessibility_enabled 1
'Enabled services: ' + (adb -s $s shell settings get secure enabled_accessibility_services)
Write-Host 'Press Home on the remote - it should open Projectivy.' -ForegroundColor Green
