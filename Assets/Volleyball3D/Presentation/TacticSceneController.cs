using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using VolleyballCoach.Application;
using VolleyballCoach.Domain;

namespace VolleyballCoach.Presentation
{
    public sealed class TacticSceneController : MonoBehaviour
    {
        public TacticDocument Tactic { get; private set; }
        public PlaybackClock Clock { get; private set; }
        private readonly Dictionary<string, PlayerActor> actors = new Dictionary<string, PlayerActor>();
        private readonly List<LineRenderer> moveLines = new List<LineRenderer>();
        private Transform courtRoot, actorsRoot, ball;
        private CameraRigController cameraRig;
        public System.Action<int> OnPhaseChanged;

        public void Setup(TacticDocument tactic, PlaybackClock clock, CameraRigController rig)
        {
            Tactic = tactic; Clock = clock; cameraRig = rig; Clock.Configure(4000); Clock.Changed += ApplyAt;
            courtRoot = CourtSceneBuilder.Build(transform, tactic.courtConfig); actorsRoot = new GameObject("Players").transform; actorsRoot.SetParent(transform, false);
            foreach (var player in tactic.players) actors[player.id] = PlayerActor.Create(player, actorsRoot);
            var ballGo = GameObject.CreatePrimitive(PrimitiveType.Sphere); ballGo.name = "Volleyball"; ballGo.transform.localScale = Vector3.one * 0.24f; ballGo.GetComponent<Renderer>().material = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard")) { color = new Color(0.98f, 0.88f, 0.4f) }; ball = ballGo.transform; ball.SetParent(transform, false);
            BuildMoveGuides(); ApplyAt(0);
        }
        public void ApplyAt(int timeMs)
        {
            if (Tactic == null) return;
            var state = TacticEvaluator.EvaluateAt(Tactic, timeMs);
            foreach (var player in state.players) if (actors.TryGetValue(player.playerId, out var actor)) actor.Apply(player);
            ball.gameObject.SetActive(state.ball.active); if (state.ball.active) ball.localPosition = state.ball.position;
            OnPhaseChanged?.Invoke(state.currentPhaseIndex);
        }
        public void SetCamera(CameraPreset preset) => cameraRig.SetPreset(preset);
        public void ShowMoveGuides(bool visible) { foreach (var line in moveLines) line.enabled = visible; }
        private void BuildMoveGuides()
        {
            foreach (var move in Tactic.moveTracks)
            {
                var go = new GameObject("MoveGuide_" + move.id); go.transform.SetParent(transform, false); var line = go.AddComponent<LineRenderer>(); line.positionCount = (move.waypoints?.Count ?? 0) + 1; line.widthMultiplier = 0.045f; line.material = new Material(Shader.Find("Sprites/Default")) { color = Color.yellow }; line.startColor = Color.yellow; line.endColor = Color.yellow; var start = Tactic.initialFormation.FirstOrDefault(s => s.playerId == move.playerId); line.SetPosition(0, start == null ? Vector3.zero : new Vector3(start.x, 0.12f, start.z)); for (var i = 0; i < (move.waypoints?.Count ?? 0); i++) line.SetPosition(i + 1, move.waypoints[i] + Vector3.up * 0.12f); moveLines.Add(line);
            }
        }
    }
}
