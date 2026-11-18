# 排球战术板 3D

Godot 4.x 离线排球教练战术板。项目使用竖屏 GDScript、Control、Node3D、Camera3D 和 JSON 存档，先在按真实 9m × 18m 比例缩小的 2D 球场中摆位，再用同一份数据驱动 3D 回放。

## 当前实现

- Godot 项目入口为 `scenes/main.tscn`。
- `scripts/domain` 保存战术数据模型和校验。
- `scripts/application` 提供关键帧插值、确定性回放计算和统一播放时钟。
- `scripts/infrastructure` 使用 `user://tactics` 保存战术，并提供内置示例和复制。
- `scripts/presentation/tactic_editor_2d.gd` 提供 2D 球场、号码圆点、关键帧、拖动和 2D 播放。
- `scripts/presentation/vertical_court_layout.gd` 固定 9m × 18m 球场比例和屏幕坐标换算。
- `scripts/presentation/vertical_court_board.gd` 提供竖屏球场绘制和球员拖动，工具栏由原生 Button 控件承载。
- `scripts/presentation/tactic_replay_3d.gd` 提供游戏化球馆、双方球员、球、动作和三种机位。
- `scripts/main.gd` 在 2D 编排和 3D 回放之间切换，并保存同一个战术文档。
- `export_presets.cfg` 已配置 Android arm64 导出目标。

## 在 Godot 中运行

1. 安装 Godot 4.x，打开本目录。
2. 导入 `project.godot`。
3. 点击运行。内置示例会写入 `user://tactics`。
4. 在竖屏 2D 界面拖动球员圆点，使用底部大按钮，点击「下一张」创建后续关键帧，再点击「进入 3D」查看回放。

## Android APK

Android Studio 已提供 SDK，Godot 还需要配置 OpenJDK 17、Android SDK、NDK 和 CMake。Godot 官方 Android 导出文档列出了需要安装的组件。

```powershell
cd D:\codex_work\coach
.\tools\build-godot-android.ps1 -Godot 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
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
