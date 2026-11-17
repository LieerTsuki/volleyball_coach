param(
  [string]$ApkPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'Builds\VolleyballCoach.apk'),
  [string]$AdbPath = (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe')
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $ApkPath)) { throw "找不到 APK：$ApkPath。先运行 tools/build-android.ps1。" }
if (-not (Test-Path $AdbPath)) { throw "找不到 adb：$AdbPath。请确认 Android SDK platform-tools 已安装。" }
& $AdbPath start-server | Out-Null
$devices = & $AdbPath devices | Select-String "\tdevice$"
if (-not $devices) { throw '没有检测到已授权的 Android 设备或模拟器。请连接设备并允许 USB 调试。' }
& $AdbPath install -r $ApkPath
if ($LASTEXITCODE -ne 0) { throw "adb 安装失败，退出码 $LASTEXITCODE。" }
Write-Host "已安装：$ApkPath"
