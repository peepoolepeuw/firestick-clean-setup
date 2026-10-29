# Makes Aerial Views (Apple TV-style aerial videos) the screensaver.
# Fire OS only lists Amazon's screensaver in Settings, so this uses adb.
# Undo: .\scripts\4-set-screensaver.ps1 -Off
param([string]$Tv, [switch]$Off)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\config.ps1"
if (-not $Tv) { $Tv = $DefaultTv }
$s = Connect-Tv $Tv

$value = if ($Off) { 'com.amazon.ftv.screensaver/.app.services.ScreensaverService' } else { $AerialScreensaver }
adb -s $s shell settings put secure screensaver_components $value
'Screensaver: ' + (adb -s $s shell settings get secure screensaver_components)
