param(
  [string]$DDriveHubData = 'D:\Unity\HubData\UnityHub'
)

$ErrorActionPreference = 'Stop'
$appDataHub = Join-Path $env:APPDATA 'UnityHub'
$downloadsSource = Join-Path $DDriveHubData 'downloads'
$downloadsTarget = Join-Path $appDataHub 'downloads'

if (-not (Test-Path $DDriveHubData)) { throw "找不到 D 盘 Hub 数据目录：$DDriveHubData" }
if (-not (Test-Path $downloadsSource)) { New-Item -ItemType Directory -Force $downloadsSource | Out-Null }

if (Test-Path $appDataHub) {
  $item = Get-Item $appDataHub -Force
  if ($item.LinkType) {
    [System.IO.Directory]::Delete($appDataHub)
  }
}

New-Item -ItemType Directory -Force $appDataHub | Out-Null
Get-ChildItem $DDriveHubData -Force | Where-Object { $_.Name -ne 'downloads' } | Copy-Item -Destination $appDataHub -Recurse -Force
if (Test-Path $downloadsTarget) {
  $downloadsItem = Get-Item $downloadsTarget -Force
  if ($downloadsItem.LinkType) { [System.IO.Directory]::Delete($downloadsTarget) }
  else { throw "C 盘下载目录已存在且不是目录联接，请先备份后再运行。" }
}
New-Item -ItemType Junction -Path $downloadsTarget -Target $downloadsSource | Out-Null
Write-Host "Unity Hub 配置已恢复，下载缓存位于 $downloadsSource"
