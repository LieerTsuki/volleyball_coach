param(
  [string]$UnityEditor = $env:UNITY_EDITOR,
  [string]$ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
if (-not $UnityEditor) {
  $candidates = @(
    'C:\Program Files\Unity\Hub\Editor\6000.0.23f1\Editor\Unity.exe',
    'C:\Program Files\Unity Hub\Editor\6000.0.23f1\Editor\Unity.exe',
    'D:\Unity\Hub\Editor\6000.0.23f1\Editor\Unity.exe'
  )
  $UnityEditor = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $UnityEditor -or -not (Test-Path $UnityEditor)) {
  throw '未找到 Unity 6 Editor。请安装 Unity 6000.0.23f1，并设置 UNITY_EDITOR 为 Unity.exe 的完整路径。Android Studio 不能替代 Unity 构建器。'
}

$sdk = $env:ANDROID_SDK_ROOT
if (-not $sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
if (Test-Path $sdk) { $env:ANDROID_HOME = $sdk; $env:ANDROID_SDK_ROOT = $sdk }

& $UnityEditor -batchmode -quit -nographics -projectPath $ProjectPath -executeMethod VolleyballCoach.Editor.AndroidBuild.BuildApk -logFile (Join-Path $ProjectPath 'Builds\android-build.log')
if ($LASTEXITCODE -ne 0) { throw "Unity Android 构建失败，详见 Builds\android-build.log（退出码 $LASTEXITCODE）。" }
Write-Host "APK: $(Join-Path $ProjectPath 'Builds\VolleyballCoach.apk')"
