# Godot 3D 排球教练战术板开发 Prompt

请在当前仓库实现一款名为「排球战术板 3D」的离线 Android App。使用 Godot 4.x、GDScript、Mobile 或 Compatibility 渲染器和 Android Studio 提供的 Android SDK。项目必须在横屏手机上运行，支持 Windows 编辑器鼠标测试和 Android 触控。

## 目标流程

教练可以新建或复制战术，摆出六名己方球员，编排发球、一传、二传、进攻和掩护跑位，播放 3D 回放，退出后重新打开继续编辑。球场、球网、球员和排球必须处在同一个真实 3D 场景中。俯视用于编辑，斜上方和网侧用于讲解。

## 技术约束

- 使用 Godot 4.x 原生 Node3D 场景，不使用 WebView 或预渲染视频。
- 使用 GDScript 作为首版主语言。Android 上的 Godot C# 导出仍有实验性限制，因此领域逻辑、回放和 UI 统一使用 GDScript。
- 场景使用 `Node3D`、`Camera3D`、`MeshInstance3D`、`AnimationPlayer`/程序化姿态节点和 `Control` UI。
- 数据使用 JSON 和 `FileAccess` 保存到 `user://tactics`，文件名使用稳定战术 ID。保存时使用临时文件和备份。
- Android 导出使用 Godot Export Templates，SDK、NDK、CMake 和 OpenJDK 由 Android Studio 或 sdkmanager 提供。

## 数据模型

`TacticDocument` 需要包含 `schemaVersion`、`id`、`title`、`notes`、`createdAt`、`updatedAt`、`courtConfig`、`players`、`initialFormation`、`phases`、`moveTracks`、`poseActions`、`contactEvents` 和 `ballActions`。时间使用非负整数毫秒，坐标使用米，引用使用稳定 ID。

移动、姿态、触球和球路分开保存。`evaluate_at(tactic, time_ms)` 必须是确定性的纯计算入口，播放和 Seek 都调用它。球路使用共享触球端点和三维弧线，过网高度不足时返回具体中文提示。移动段不得在同一球员上重叠。

## 界面

- 战术库支持新建、打开、复制、重命名、删除和内置示例复制。
- 编辑器主区域显示球场和六名带号码球员，支持站位拖拽、选球员、目标点、阶段条、跑位实线和球路虚线。
- 回放支持播放、暂停、重播、0.5×、1×、时间轴 Seek、阶段跳转和顶视/斜上方/网侧机位切换。
- 触摸拖拽不穿透 UI，双指缩放不提交球员位移。撤销和重做以一次完整拖拽为单位。
- 所有按钮、空状态、校验错误和存档失败提示使用简体中文。

## 内置示例

示例名称为「三人接发 · 副攻快球掩护 · 四号位进攻」，展示接发、二传、主攻起跳扣球和副攻掩护的并行动作。示例和自定义战术必须共用同一套数据模型、校验和回放逻辑。

## 验收

EditMode 或 GDScript 单元测试覆盖 JSON 往返、复制隔离、移动插值、共享触球端点、过网高度和坏数据校验。Android 验收覆盖横屏、安全区域、触控、前后台切换、离线保存和重新打开。暂停在触球帧时，球与触球锚点误差目标不超过 5 cm。

## 非目标

首版不做账号、联网同步、视频导出、AI 自动编排、正式规则判罚、对方六人防守编排和真实动捕资产。
