# 排球战术板 3D

Unity 6 LTS 的离线排球教练战术板样片。工程把战术站位、跑位、姿态、触球和球路保存为带 `schemaVersion` 的 JSON，并用统一 `PlaybackClock` 计算播放与 Seek 的同一帧状态。

## 当前交付

- 可打开的 Unity 6 LTS 工程骨架，URP、Input System、uGUI/TextMeshPro 和 Unity Test Framework 已锁定在 `Packages/`。
- `Assets/Volleyball3D/Domain`：战术 DTO、共享触球端点、两级校验。
- `Assets/Volleyball3D/Application`：确定性 `TacticEvaluator`、统一时钟、示例战术、JSON 仓库、编辑草稿与撤销/重做。
- `Assets/Volleyball3D/Presentation`：球场线、球网、球、六名程序化低模骨骼角色、跑位箭头、顶视/斜上方/网侧机位和中文回放 HUD。
- `Assets/Volleyball3D/Editor/VolleyballSceneGenerator.cs`：菜单 `Volleyball Coach/生成示例场景`，用于在 Editor 中生成并保存场景。
- `Assets/Volleyball3D/Tests`：EditMode 和 PlayMode 测试样例。

## 在 Unity 中运行

1. 使用 Unity Hub 安装 Unity `6000.0.23f1`（Unity 6 LTS）和 Android Build Support。
2. 打开本目录，等待 Package Manager 完成 `Packages/manifest.json` 的解析。
3. 打开 `Assets/Volleyball3D/Scenes/VolleyballCoach.unity`。若场景需要重建，执行菜单 `Volleyball Coach/生成示例场景`。
4. 点击 Play。首次运行会在 `Application.persistentDataPath/tactics` 写入内置示例。
5. 用底部按钮播放、暂停、重播、切换 0.5×/1×，拖动时间轴；右侧按钮切换顶视、斜上方和网侧。

## 测试

在 Unity Test Runner 中分别运行 `VolleyballCoach.Tests` 的 EditMode 和 PlayMode 测试。重点检查：示例可播放、移动段可插值、共享触球在 Seek 时保持一致、非法时间/重复 ID 会被指出、复制不会改变原战术。

## Android 验收清单

本工作区没有安装 Unity Editor，也没有连接 Android 真机，因此以下结果尚未执行：

- Unity Editor 导入和 URP 场景运行
- Android APK 构建
- 真机触控、安全区域、前后台切换和飞行模式恢复
- 中端 Android 稳定 30 FPS Profiler 记录

在具备 Unity/Android 环境后，先运行测试，再在 Player Settings 中选择 Android、横屏，并按 prompt 的触球帧误差目标（≤5 cm）记录验收日志。

## 构建和安装 APK

本机已检测到 Android Studio（`D:\Android_studio\bin\studio64.exe`）和 Android SDK/ADB（`C:\Users\LENOVO\AppData\Local\Android\Sdk`）。Android Studio 可打开 Unity 导出的 Gradle 工程；实际 APK 仍需 Unity 6 Editor 先执行场景和资源构建。

Unity Hub 本身是 Windows AppX 包，系统可能继续将 Hub 外壳放在 C 盘；请在 Unity Hub 的 **Preferences → Installs** 中把 Editor 安装位置明确设置为 `D:\Unity\Hub`，并把项目和构建缓存保留在 D 盘。仓库脚本默认查找 `D:\Unity\Hub\Editor\6000.0.23f1\Editor\Unity.exe`。

安装 Unity `6000.0.23f1` 后，在 PowerShell 中运行：

```powershell
.\tools\build-android.ps1 -UnityEditor 'C:\path\to\Unity.exe'
.\tools\install-android-apk.ps1
```

如果尚未安装 Editor，先运行 `.\tools\install-unity-editor.ps1`。该脚本把临时目录、Hub 下载缓存、Editor 安装目录和 Android 模块都固定在 D 盘，并支持中断后继续下载。

也可以在 Unity Editor 中使用 `Volleyball Coach/生成示例场景`，再从 Build Settings 选择 Android 构建。构建日志保存到 `Builds/android-build.log`，APK 输出到 `Builds/VolleyballCoach.apk`。

## 资产与许可

首版角色、动作和材质均由代码生成，没有运行时联网或外部模型依赖。若后续替换为外部 Humanoid/动画，需要在 `Assets/Volleyball3D/Content/ASSET_LICENSES.md` 记录来源、版本和许可。

## 目录

```text
Assets/Volleyball3D/
  Domain/          数据模型和校验
  Application/     回放、编辑和示例数据
  Infrastructure/  JSON 存档
  Presentation/    3D 场景、相机、角色、UI
  Editor/          场景生成菜单
  Tests/           EditMode/PlayMode 测试
docs/superpowers/specs/  已确认设计规格
```
