# Shared settings for every script. Dot-sourced: . "$PSScriptRoot\..\config.ps1"

# Default Fire TV address. Override per run with -Tv 10.0.0.x
$DefaultTv = '10.0.0.18'

# Amazon packages to disable (pm disable-user --user 0).
# Disabling sticks across reboots; uninstalling does NOT - Fire OS quietly reinstalls removed system apps.
# Every entry is reversible with scripts\restore.ps1. Packages missing on a given model are skipped.
$DebloatGroups = [ordered]@{
  'Tracking & ads' = @(
    'com.amazon.device.telemetry.emitter', 'com.amazon.wirelessmetrics.service', 'com.amazon.perfcollection',
    'com.amazon.dp.logger', 'com.amazon.hybridadidservice', 'com.amazon.tv.acr', 'com.amazon.sneakpeek',
    'com.amazon.media.recommendations')
  'Nags & tutorials' = @(
    'com.amazon.tv.easyupgrade', 'com.amazon.tv.releasenotes', 'com.amazon.tv.earlyaccess',
    'com.amazon.storm.lightning.tutorial', 'com.amazon.tmm.tutorial')
  'Shopping' = @('com.amazon.shoptv.client', 'com.amazon.shoptv.firetv.client')
  'Amazon extras' = @(
    'com.amazon.bueller.photos', 'com.amazon.bueller.music', 'com.amazon.minitv.android.app',
    'com.amazon.gamehub', 'com.amazon.firebat', 'com.amazon.spiderpork', 'com.amazon.tahoe',
    'com.amazon.cloud9', 'com.amazon.tv.ftvambient', 'com.amazon.smarthomemapviewapp')
  'Live TV & Matter' = @('com.amazon.tv.livetv', 'com.amazon.tv.matter', 'com.amazon.tv.mattercohost')
}

# Never touch these: home screen, settings, appstore, Alexa/voice remote, Bluetooth, push messaging.
$ProtectedNote = 'com.amazon.tv.launcher, com.amazon.tv.settings.v2, com.amazon.venezia, Alexa/AVS, Bluetooth, com.amazon.device.messaging'

# Apps installed from their official GitHub releases. Each download is checked against
# the SHA-256 digest GitHub publishes for the release asset before it is installed.
$Apps = @(
  @{ Name = 'SmartTube';          Package = 'org.smarttube.stable';      Repo = 'yuliskov/SmartTube';     Asset = 'SmartTube_stable_*_{abi}.apk'; Stable = $true }
  @{ Name = 'Projectivy Launcher'; Package = 'com.spocky.projengmenu';   Repo = 'spocky/miproja1';        Asset = 'ProjectivyLauncher-*.apk' }
  @{ Name = 'Aerial Views';       Package = 'com.neilturner.aerialviews'; Repo = 'theothernt/AerialViews'; Asset = 'aerial-views-*.apk' }
)

$ProjectivyService = 'com.spocky.projengmenu/com.spocky.projengmenu.services.ProjectivyAccessibilityService'
$AerialScreensaver = 'com.neilturner.aerialviews/.ui.screensaver.DreamActivity'

function Connect-Tv([string]$Tv) {
  $serial = if ($Tv -match ':') { $Tv } else { "$Tv`:5555" }
  $out = adb connect $serial 2>&1 | Out-String
  if ($out -notmatch 'connected') { throw "Could not reach $serial. Is ADB debugging on and the IP right?`n$out" }
  $state = (adb -s $serial get-state 2>&1 | Out-String).Trim()
  if ($state -ne 'device') { throw "TV at $serial is '$state'. Accept the 'Allow USB debugging?' prompt on the TV, then rerun." }
  $model = (adb -s $serial shell getprop ro.product.model).Trim()
  $os = (adb -s $serial shell getprop ro.build.version.release).Trim()
  Write-Host "Connected to $serial ($model, Android $os)" -ForegroundColor Green
  return $serial
}
