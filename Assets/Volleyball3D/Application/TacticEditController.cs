using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using VolleyballCoach.Domain;

namespace VolleyballCoach.Application
{
    public sealed class TacticEditController : MonoBehaviour
    {
        public TacticDocument Draft { get; private set; }
        private readonly Stack<string> undo = new Stack<string>();
        private readonly Stack<string> redo = new Stack<string>();
        private string draggingPlayerId;
        private Vector3 dragStart;
        public void Load(TacticDocument tactic) { Draft = tactic; undo.Clear(); redo.Clear(); }
        public void BeginDrag(string playerId) { if (Draft == null) return; draggingPlayerId = playerId; dragStart = Initial(playerId); undo.Push(JsonUtility.ToJson(Draft)); redo.Clear(); }
        public void UpdateDrag(Vector3 groundPoint)
        {
            if (Draft == null || string.IsNullOrWhiteSpace(draggingPlayerId)) return;
            var slot = Draft.initialFormation.FirstOrDefault(s => s.playerId == draggingPlayerId); if (slot == null) return; slot.x = groundPoint.x; slot.z = groundPoint.z;
        }
        public void EndDrag() { draggingPlayerId = null; }
        public bool Undo()
        {
            if (Draft == null || undo.Count == 0) return false; redo.Push(JsonUtility.ToJson(Draft)); Restore(JsonUtility.FromJson<TacticDocument>(undo.Pop())); return true;
        }
        public bool Redo()
        {
            if (Draft == null || redo.Count == 0) return false; undo.Push(JsonUtility.ToJson(Draft)); Restore(JsonUtility.FromJson<TacticDocument>(redo.Pop())); return true;
        }
        public void AddMove(string playerId, Vector3 target, int startMs, int durationMs)
        {
            if (Draft == null) return; undo.Push(JsonUtility.ToJson(Draft)); redo.Clear(); Draft.moveTracks.Add(new MoveSegment { id = System.Guid.NewGuid().ToString("N"), playerId = playerId, startMs = Mathf.Max(0, startMs), endMs = Mathf.Max(startMs + 1, startMs + durationMs), waypoints = new List<Vector3> { target }, facingMode = MoveFacingMode.FaceTarget });
        }
        public void AddPose(string playerId, PoseActionType type, int startMs, int endMs)
        {
            if (Draft == null) return; undo.Push(JsonUtility.ToJson(Draft)); redo.Clear(); Draft.poseActions.Add(new PoseAction { id = System.Guid.NewGuid().ToString("N"), playerId = playerId, type = type, startMs = startMs, endMs = endMs });
        }
        private Vector3 Initial(string playerId) { var slot = Draft.initialFormation.FirstOrDefault(s => s.playerId == playerId); return slot == null ? Vector3.zero : new Vector3(slot.x, 0f, slot.z); }
        private void Restore(TacticDocument source)
        {
            Draft.schemaVersion = source.schemaVersion; Draft.title = source.title; Draft.notes = source.notes; Draft.createdAt = source.createdAt; Draft.updatedAt = source.updatedAt;
            Draft.courtConfig = source.courtConfig; Draft.players = source.players; Draft.initialFormation = source.initialFormation; Draft.phases = source.phases; Draft.moveTracks = source.moveTracks; Draft.poseActions = source.poseActions; Draft.contactEvents = source.contactEvents; Draft.ballActions = source.ballActions;
        }
    }
}
