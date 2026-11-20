# VolleySketch

Godot 4.x 离线排球教练战术板。项目使用竖屏 GDScript、Control、Node3D、Camera3D 和 JSON 存档，先在按真实 9m × 18m 比例缩小的 2D 球场中摆位，再用同一份数据驱动 3D 回放。

## 当前实现

- Godot 项目入口为 `scenes/main.tscn`。
- `scripts/domain` 保存战术数据模型和校验。
- `scripts/application` 提供关键帧插值、确定性回放计算和统一播放时钟。
- `scripts/infrastructure` 使用 `user://tactics` 保存战术，并提供内置示例和复制。
- `scripts/presentation/tactic_editor_2d.gd` 提供 2D 球场、号码圆点、关键帧、拖动和 2D 播放。
- `scripts/presentation/vertical_court_layout.gd` 固定 9m × 18m 球场比例和屏幕坐标换算。
- `scripts/presentation/vertical_court_board.gd` 提供竖屏球场绘制和球员拖动，工具栏由原生 Button 控件承载。
- 2D 编辑器支持双击球员编辑。球员位置按相邻站位图和每帧时长插值，2D 和 3D 共用同一套米制坐标。
- 每张站位图保存排球位置。未设置自定义动作时，排球按站位图位置或内置示例的预设球路播放。
- 「战术库」可新建、打开和删除自定义战术。战术保存在 `user://tactics`，重启时直接恢复上次打开的战术。主存档缺失或损坏时会尝试读取上一次备份。
- `assets/ui` 保存卡通文件夹、加号、球员、播放、删除和保存图标，应用图标使用无白边的 VolleySketch 排球标识。
- `assets/splash.png` 提供 VolleySketch 启动画面，`scripts/presentation/tactic_replay_3d.gd` 提供木地板球馆、我方球员、跑步步态、时间轴、半速和三种机位。
- `scripts/main.gd` 在 2D 编排和 3D 回放之间切换，并保存同一个战术文档。
- `export_presets.cfg` 已配置 Android ARM64 手机和 x86_64 模拟器导出目标。

## 在 Godot 中运行

1. 安装 Godot 4.x，打开本目录。
2. 导入 `project.godot`。
3. 点击运行。内置示例会写入 `user://tactics`。
4. 在竖屏 2D 界面拖动球员圆点，使用底部卡通按钮，编辑或删除球员，新增或删除站位图，再点击「进入 3D」查看回放。

## 编排一传、二传和扣球

1. 添加球员并准备连续三张站位图。选中第一张，点「球路与动作」，设置「一传」、执行球员和接球队员。
2. 在小球场点选接球位置，然后保存。这会调整接球队员在下一张站位图里的站位。下一张会默认选中刚才的接球队员，可以安排他做二传。
3. 为二传选择攻手和接球位置，在再下一张安排攻手「起跳扣球」，点选对方场区的落点。
4. 点「进入 3D」回放。动作随战术保存，重开后可再次编辑，也可清除单张站位图的动作。改换已经连好的二传或攻手时，相邻传球会更新到新球员。

## Android APK

Android Studio 已提供 SDK，Godot 还需要配置 OpenJDK 17、Android SDK、NDK 和 CMake。Godot 官方 Android 导出文档列出了需要安装的组件。

```powershell
cd D:\codex_work\coach
.\tools\build-godot-android.ps1 -Godot 'D:\Godot\Godot_v4.7.2-stable_win64_console.exe'
.\tools\install-android-apk.ps1 -ApkPath 'D:\codex_work\coach\Builds\VolleyballCoach.apk'
```

APK 输出到 `Builds/VolleyballCoach.apk`，版本为 `0.3.0`，用于本地安装验证。Android 手机需要打开开发者模式和 USB 调试。连接多个设备时，向安装脚本传入 `-Serial`，例如 `-Serial emulator-5554`。

## 测试重点

- JSON 序列化往返和复制隔离
- 移动段插值和阶段导航
- 共享触球端点和球路弧线
- 三种机位保持同一播放时间
- Android 竖屏、安全区域、前后台切换和离线重启

## 设计与 Prompt

- [当前 Godot Prompt](volleyball-godot-app-prompt.md)
- [Unity 历史 Prompt](volleyball-unity-legacy-prompt.md)
- [Godot 迁移设计](docs/superpowers/specs/2026-11-17-volleyball-coach-tactic-board-design.md)

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
