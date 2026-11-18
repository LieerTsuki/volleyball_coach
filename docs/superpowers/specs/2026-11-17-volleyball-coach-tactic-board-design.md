# Godot 排球教练战术板 3D 设计规格

## 关键帧编排版本

本版本以“先在 2D 球场摆站位，再复用到 3D 回放”为首要流程。应用启动后进入 2D 编排器，教练通过连续关键帧记录站位变化。新增关键帧会复制前一帧的全部球员位置，教练只需要拖动发生变化的球员。关键帧列表、播放进度和当前选中帧始终由同一个战术文档驱动。

2D 编辑器使用自绘 `Control` 处理球场、号码圆点、关键帧路径和触控拖动。3D 回放使用独立的 `Node3D` 场景，读取同一组关键帧并按帧时长插值。切换模式只改变呈现层，不复制或重新录入战术数据。

## 目标

交付一个离线优先的 Godot 4.x 横屏 Android 教练战术板。教练可以新建或复制战术，摆放六名己方球员，编排发球、一传、二传、进攻与掩护，使用统一时间轴回放，并在顶视、斜上方和网侧三种机位之间切换。

## 架构

工程使用 GDScript 和 Godot 原生节点。`scripts/domain` 保存字典型 DTO 和校验，`scripts/application` 负责确定性时间评估和播放时钟，`scripts/presentation` 负责 Node3D 场景、程序化低模球员、相机和 Control UI，`scripts/infrastructure` 负责 `user://tactics` 下的 JSON 存档。

播放和 Seek 都调用 `TacticEvaluator.evaluate_at(tactic, time_ms)`。移动位置由 `FrameInterpolator` 从 `frames[]` 计算，姿态进度、触球锚点和球路弧线由同一时间输入计算。球路保存固定世界坐标或共享触球 ID，不保存屏幕像素或节点引用。

## 数据与存档

`TacticDocument` 包含 schemaVersion、稳定 ID、球场配置、球员、`frames[]`、阶段、姿态、触球和球路。每个关键帧包含 `id`、`durationMs` 和 `positions`，位置使用排球场米制坐标。保存使用临时文件和备份。复制通过 JSON 深拷贝生成新的战术 ID。读取时校验 ID、关键帧时长、球员引用、触球连续性和球路数据。

## 体验

战术库支持新建、打开、复制、重命名、删除和内置示例复制。2D 编辑器显示球场、号码圆点、关键帧缩略图、帧间路径和“下一张”按钮。2D 播放支持播放、暂停、重播和时间轴。3D 回放支持播放、暂停、重播、0.5×、1×、Seek、阶段跳转和三个机位。手机触控需要区分 UI 点击、单指拖拽和双指缩放。

## Android

使用 Godot Export Templates 生成 APK。Android Studio 提供 SDK，项目需要配置 OpenJDK 17、NDK、CMake 和对应 Android 平台。首版使用 GDScript，避免 Godot C# Android 导出的实验性限制。

## 验收

测试 JSON 往返、复制隔离、关键帧继承、移动插值、触球端点、球路弧线、坏数据和 Seek 一致性。Android 验收横屏、安全区域、触控、前后台切换、离线重启和 APK 安装。触球帧球与锚点误差目标不超过 5 cm。
