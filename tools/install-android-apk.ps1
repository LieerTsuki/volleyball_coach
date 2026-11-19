param(
  [string]$ApkPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'Builds\VolleyballCoach.apk'),
  [string]$AdbPath = (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'),
  [string]$Serial = $env:ANDROID_SERIAL
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $ApkPath -PathType Leaf)) { throw "找不到 APK：$ApkPath。先运行 tools/build-godot-android.ps1。" }
if (-not (Test-Path $AdbPath)) { throw "找不到 adb：$AdbPath。请确认 Android SDK platform-tools 已安装。" }
& $AdbPath start-server | Out-Null
$devices = @(& $AdbPath devices | ForEach-Object { if ($_ -match '^([^\s]+)\s+device$') { $Matches[1] } })
if ($Serial) {
  if ($Serial -notin $devices) { throw "设备未连接或未授权：$Serial" }
} else {
  if ($devices.Count -eq 0) { throw '没有检测到已授权的 Android 设备或模拟器。' }
  if ($devices.Count -gt 1) { throw "检测到多个设备，请用 -Serial 指定：$($devices -join ', ')" }
  $Serial = $devices[0]
}
& $AdbPath -s $Serial install -r $ApkPath
if ($LASTEXITCODE -ne 0) { throw "adb 安装失败，退出码 $LASTEXITCODE。" }
Write-Host "已安装到 $Serial：$ApkPath"
