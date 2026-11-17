param(
  [string]$Godot = 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe',
  [string]$ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Godot)) { throw "找不到 Godot：$Godot" }
$godotTemp = 'D:\GodotTemp'
$gradleHome = 'D:\GodotGradle'
New-Item -ItemType Directory -Force $godotTemp, $gradleHome | Out-Null
$env:TEMP = $godotTemp
$env:TMP = $godotTemp
$env:GRADLE_USER_HOME = $gradleHome
New-Item -ItemType Directory -Force (Join-Path $ProjectPath 'Builds') | Out-Null
& $Godot --headless --path $ProjectPath --editor --export-debug Android (Join-Path $ProjectPath 'Builds\VolleyballCoach.apk')
if ($LASTEXITCODE -ne 0) { throw "Godot Android 构建失败，退出码 $LASTEXITCODE。" }
Write-Host "APK: $(Join-Path $ProjectPath 'Builds\VolleyballCoach.apk')"
