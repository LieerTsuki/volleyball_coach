# 排球战术板 3D

Godot 4.x 离线排球教练战术板。项目使用 GDScript、Node3D、Camera3D、Control 和 JSON 存档，支持六名球员、跑位、姿态、触球、球路和三种回放机位。

## 当前实现

- Godot 项目入口为 `scenes/main.tscn`。
- `scripts/domain` 保存战术数据模型和校验。
- `scripts/application` 提供确定性回放计算和统一播放时钟。
- `scripts/infrastructure` 使用 `user://tactics` 保存战术，并提供内置示例和复制。
- `scripts/presentation` 生成球场、球网、球员、球和相机。
- `scripts/main.gd` 创建中文 HUD，支持播放、暂停、重播、Seek、阶段显示、保存和三种机位。
- `export_presets.cfg` 已配置 Android arm64 导出目标。

## 在 Godot 中运行

1. 安装 Godot 4.x，打开本目录。
2. 导入 `project.godot`。
3. 点击运行。内置示例会写入 `user://tactics`。
4. 使用 HUD 按钮播放示例、拖动时间轴和切换机位。

## Android APK

Android Studio 已提供 SDK，Godot 还需要配置 OpenJDK 17、Android SDK、NDK 和 CMake。Godot 官方 Android 导出文档列出了需要安装的组件。

```powershell
cd D:\codex_work\coach
.\tools\build-godot-android.ps1 -Godot 'D:\Godot\godot.exe'
.\tools\install-android-apk.ps1 -ApkPath 'D:\codex_work\coach\Builds\VolleyballCoach.apk'
```

APK 输出到 `Builds/VolleyballCoach.apk`。Android 手机需要打开开发者模式和 USB 调试。

## 测试重点

- JSON 序列化往返和复制隔离
- 移动段插值和阶段导航
- 共享触球端点和球路弧线
- 三种机位保持同一播放时间
- Android 横屏、安全区域、前后台切换和离线重启

## 设计与 Prompt

- 当前 Prompt：[volleyball-godot-app-prompt.md](D:/codex_work/coach/volleyball-godot-app-prompt.md)
- Unity 历史 Prompt：[volleyball-unity-legacy-prompt.md](D:/codex_work/coach/volleyball-unity-legacy-prompt.md)
- 设计规格：[Godot 迁移设计](D:/codex_work/coach/docs/superpowers/specs/2026-11-17-volleyball-coach-tactic-board-design.md)

## 目录

```text
project.godot
scenes/main.tscn
scripts/domain/
scripts/application/
scripts/infrastructure/
scripts/presentation/
tools/build-godot-android.ps1
tools/install-android-apk.ps1
```
