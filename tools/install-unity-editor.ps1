param(
  [string]$UnityCli = 'D:\Unity\CLI\bin\unity.exe',
  [string]$EditorVersion = '6000.0.23f1',
  [string]$EditorInstallPath = 'D:\Unity\Hub\Editor'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $UnityCli)) { throw "找不到 Unity CLI：$UnityCli" }
New-Item -ItemType Directory -Force $EditorInstallPath | Out-Null
New-Item -ItemType Directory -Force 'D:\Unity\Temp' | Out-Null
$env:TEMP = 'D:\Unity\Temp'
$env:TMP = 'D:\Unity\Temp'
$env:UNITY_CLI_HOME = 'D:\Unity\CLI'
& $UnityCli --no-banner --non-interactive install-path --set $EditorInstallPath
& $UnityCli --no-banner --non-interactive install $EditorVersion --module android --child-modules --accept-eula --resume --no-elevate
if ($LASTEXITCODE -ne 0) { throw "Unity Editor 安装失败，退出码 $LASTEXITCODE。可重新运行本脚本从 D 盘断点恢复。" }
Write-Host "Unity Editor 已安装到 $EditorInstallPath"
