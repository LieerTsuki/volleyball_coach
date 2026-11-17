using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;
using VolleyballCoach.Application;
using VolleyballCoach.Domain;
using VolleyballCoach.Infrastructure;

namespace VolleyballCoach.Presentation
{
    public sealed class VolleyballCoachBootstrap : MonoBehaviour
    {
        private TacticRepository repository;
        private TacticSceneController scene;
        private PlaybackClock clock;
        private CameraRigController cameraRig;
        private TacticEditController editor;
        private TMP_Text titleLabel, timeLabel, phaseLabel, statusLabel;
        private Slider timeline;
        private int selectedPhase;

        private void Start()
        {
            Screen.orientation = ScreenOrientation.LandscapeLeft; Screen.sleepTimeout = SleepTimeout.NeverSleep;
            repository = new TacticRepository(); var tactic = repository.EnsureSample();
            var cameraGo = Camera.main != null ? Camera.main.gameObject : new GameObject("Main Camera"); if (Camera.main == null) cameraGo.AddComponent<Camera>(); var camera = cameraGo.GetComponent<Camera>(); camera.clearFlags = CameraClearFlags.SolidColor; camera.backgroundColor = new Color(0.04f, 0.07f, 0.11f);
            cameraRig = gameObject.AddComponent<CameraRigController>(); cameraRig.Configure(camera);
            clock = gameObject.AddComponent<PlaybackClock>(); scene = gameObject.AddComponent<TacticSceneController>(); scene.Setup(tactic, clock, cameraRig); scene.OnPhaseChanged += OnPhaseChanged;
            editor = gameObject.AddComponent<TacticEditController>(); editor.Load(tactic); var gesture = gameObject.AddComponent<CourtGestureSurface>(); gesture.targetCamera = camera; gesture.editor = editor;
            BuildUi(tactic);
        }

        private void BuildUi(TacticDocument tactic)
        {
            var canvasGo = new GameObject("CoachHUD"); var canvas = canvasGo.AddComponent<Canvas>(); canvas.renderMode = RenderMode.ScreenSpaceOverlay; canvasGo.AddComponent<CanvasScaler>().uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize; canvasGo.GetComponent<CanvasScaler>().referenceResolution = new Vector2(1920f, 1080f); canvasGo.AddComponent<GraphicRaycaster>();
            titleLabel = Text(canvasGo.transform, tactic.title, new Vector2(40, -32), new Vector2(720, 60), 30, TextAlignmentOptions.Left);
            timeLabel = Text(canvasGo.transform, "00:00.0", new Vector2(-180, -30), new Vector2(160, 60), 28, TextAlignmentOptions.Center); timeLabel.GetComponent<RectTransform>().anchorMin = new Vector2(1, 1); timeLabel.GetComponent<RectTransform>().anchorMax = new Vector2(1, 1);
            phaseLabel = Text(canvasGo.transform, "发球与一传", new Vector2(40, 36), new Vector2(360, 48), 24, TextAlignmentOptions.Left); phaseLabel.GetComponent<RectTransform>().anchorMin = new Vector2(0, 0); phaseLabel.GetComponent<RectTransform>().anchorMax = new Vector2(0, 0);
            statusLabel = Text(canvasGo.transform, "示例已加载 · 可切换机位查看起跳与过网", new Vector2(40, 86), new Vector2(760, 42), 18, TextAlignmentOptions.Left); statusLabel.GetComponent<RectTransform>().anchorMin = new Vector2(0, 0); statusLabel.GetComponent<RectTransform>().anchorMax = new Vector2(0, 0);
            timeline = Slider(canvasGo.transform, new Vector2(0, 88), new Vector2(920, 30)); timeline.onValueChanged.AddListener(v => { if (Mathf.Abs(v - clock.TimeMs) > 2) clock.Seek(Mathf.RoundToInt(v)); });
            Button(canvasGo.transform, "播放 / 暂停", new Vector2(-560, 42), () => clock.Toggle()); Button(canvasGo.transform, "重播", new Vector2(-420, 42), () => clock.Replay()); Button(canvasGo.transform, "0.5×", new Vector2(-280, 42), () => clock.SetSpeed(0.5f)); Button(canvasGo.transform, "1×", new Vector2(-180, 42), () => clock.SetSpeed(1f));
            Button(canvasGo.transform, "顶视", new Vector2(420, 42), () => scene.SetCamera(CameraPreset.Top)); Button(canvasGo.transform, "斜上方", new Vector2(540, 42), () => scene.SetCamera(CameraPreset.Oblique)); Button(canvasGo.transform, "网侧", new Vector2(680, 42), () => scene.SetCamera(CameraPreset.NetSide));
            Button(canvasGo.transform, "保存", new Vector2(810, 42), () => { repository.Save(scene.Tactic); statusLabel.text = "已保存 · 可退出后重新打开"; });
            Button(canvasGo.transform, "撤销", new Vector2(950, 42), () => { if (editor.Undo()) { scene.ApplyAt(clock.TimeMs); statusLabel.text = "已撤销一次编辑"; } });
            Button(canvasGo.transform, "重做", new Vector2(1090, 42), () => { if (editor.Redo()) { scene.ApplyAt(clock.TimeMs); statusLabel.text = "已重做一次编辑"; } });
            var phaseX = 40f; foreach (var phase in tactic.phases) { var captured = selectedPhase; Button(canvasGo.transform, phase.label, new Vector2(phaseX, 140), () => { selectedPhase = captured; clock.Seek(phase.startMs); }); phaseX += 190f; }
            clock.Changed += OnClockChanged; OnClockChanged(0);
        }
        private void OnClockChanged(int timeMs) { if (timeline != null) timeline.SetValueWithoutNotify(timeMs); if (timeLabel != null) timeLabel.text = $"{timeMs / 1000:00}:{timeMs % 1000:000}"; }
        private void OnPhaseChanged(int index) { if (scene == null || scene.Tactic == null || index < 0 || index >= scene.Tactic.phases.Count) return; if (phaseLabel != null) phaseLabel.text = "当前阶段 · " + scene.Tactic.phases[index].label; }
        private static TMP_Text Text(Transform parent, string text, Vector2 pos, Vector2 size, float fontSize, TextAlignmentOptions alignment) { var go = new GameObject("Text"); go.transform.SetParent(parent, false); var rect = go.AddComponent<RectTransform>(); rect.anchorMin = new Vector2(0, 1); rect.anchorMax = new Vector2(0, 1); rect.anchoredPosition = pos; rect.sizeDelta = size; var label = go.AddComponent<TextMeshProUGUI>(); label.text = text; label.fontSize = fontSize; label.color = Color.white; label.alignment = alignment; return label; }
        private static Button Button(Transform parent, string label, Vector2 pos, UnityEngine.Events.UnityAction action) { var go = new GameObject("Button_" + label); go.transform.SetParent(parent, false); var rect = go.AddComponent<RectTransform>(); rect.anchorMin = new Vector2(0.5f, 0); rect.anchorMax = new Vector2(0.5f, 0); rect.anchoredPosition = pos; rect.sizeDelta = new Vector2(130, 44); var image = go.AddComponent<Image>(); image.color = new Color(0.06f, 0.12f, 0.2f, 0.92f); var button = go.AddComponent<Button>(); button.targetGraphic = image; button.onClick.AddListener(action); var text = Text(go.transform, label, Vector2.zero, new Vector2(130, 44), 17, TextAlignmentOptions.Center); text.GetComponent<RectTransform>().anchorMin = Vector2.zero; text.GetComponent<RectTransform>().anchorMax = Vector2.one; text.GetComponent<RectTransform>().anchoredPosition = Vector2.zero; return button; }
        private static Slider Slider(Transform parent, Vector2 pos, Vector2 size) { var go = new GameObject("Timeline"); go.transform.SetParent(parent, false); var rect = go.AddComponent<RectTransform>(); rect.anchorMin = new Vector2(0.5f, 0); rect.anchorMax = new Vector2(0.5f, 0); rect.anchoredPosition = pos; rect.sizeDelta = size; var slider = go.AddComponent<Slider>(); slider.minValue = 0; slider.maxValue = 4000; slider.value = 0; return slider; }
    }
}
