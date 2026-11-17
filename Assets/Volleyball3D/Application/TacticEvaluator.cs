using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using VolleyballCoach.Domain;

namespace VolleyballCoach.Application
{
    public static class TacticEvaluator
    {
        public static EvaluatedTacticState EvaluateAt(TacticDocument tactic, int timeMs)
        {
            var result = new EvaluatedTacticState();
            if (tactic == null) return result;
            timeMs = Mathf.Max(0, timeMs);
            foreach (var player in tactic.players)
            {
                var position = EvaluatePlayerPosition(tactic, player.id, timeMs);
                var yaw = EvaluatePlayerYaw(tactic, player.id, timeMs, position);
                var pose = EvaluatePose(tactic, player.id, timeMs);
                result.players.Add(new EvaluatedPlayerState { playerId = player.id, position = position, yawDeg = yaw, pose = pose.type, poseProgress = pose.progress, isMoving = IsMoving(tactic, player.id, timeMs) });
            }
            result.ball = EvaluateBall(tactic, timeMs);
            result.currentPhaseIndex = CurrentPhaseIndex(tactic, timeMs);
            return result;
        }

        public static Vector3 EvaluatePlayerPosition(TacticDocument tactic, string playerId, int timeMs)
        {
            var position = InitialPosition(tactic, playerId);
            var segments = tactic.moveTracks.Where(m => m.playerId == playerId).OrderBy(m => m.startMs);
            foreach (var move in segments)
            {
                if (timeMs < move.startMs) break;
                var from = position;
                var to = move.waypoints != null && move.waypoints.Count > 0 ? move.waypoints[move.waypoints.Count - 1] : from;
                if (timeMs >= move.endMs) { position = to; continue; }
                var duration = Mathf.Max(1, move.endMs - move.startMs);
                var u = Mathf.Clamp01((timeMs - move.startMs) / (float)duration);
                position = SamplePolyline(from, move.waypoints, u);
                break;
            }
            position.y = 0f;
            return position;
        }

        public static Vector3 ResolveContactPoint(TacticDocument tactic, ContactEvent contact, int timeMs)
        {
            var ground = EvaluatePlayerPosition(tactic, contact.playerId, timeMs);
            var pose = EvaluatePose(tactic, contact.playerId, timeMs);
            var height = contact.anchorType == ContactAnchorType.Forearms ? 1.0f : contact.anchorType == ContactAnchorType.OverheadHands ? 2.15f : contact.anchorType == ContactAnchorType.HittingHand ? 2.5f : 0.15f;
            var forward = Quaternion.Euler(0f, EvaluatePlayerYaw(tactic, contact.playerId, timeMs, ground), 0f) * Vector3.forward;
            if (pose.type == PoseActionType.Spike) height += Mathf.Sin(pose.progress * Mathf.PI) * 0.5f;
            return ground + Vector3.up * height + forward * 0.12f;
        }

        private static EvaluatedBallState EvaluateBall(TacticDocument tactic, int timeMs)
        {
            var action = tactic.ballActions.FirstOrDefault(a => timeMs >= a.startMs && timeMs <= a.endMs);
            if (action == null) return new EvaluatedBallState { active = false, position = Vector3.zero };
            var a = ResolveEndpoint(tactic, action.from, action.startMs);
            var b = ResolveEndpoint(tactic, action.to, action.endMs);
            var u = Mathf.Clamp01((timeMs - action.startMs) / (float)Mathf.Max(1, action.endMs - action.startMs));
            var point = Vector3.Lerp(a, b, u) + Vector3.up * (4f * Mathf.Max(0f, action.arcHeightM) * u * (1f - u));
            return new EvaluatedBallState { active = true, position = point, actionType = action.type, actionId = action.id, progress = u };
        }

        private static Vector3 ResolveEndpoint(TacticDocument tactic, BallEndpoint endpoint, int timeMs)
        {
            if (endpoint == null) return Vector3.zero;
            if (!endpoint.isContact) return endpoint.worldPoint;
            var contact = tactic.contactEvents.FirstOrDefault(c => c.id == endpoint.contactId);
            return contact == null ? Vector3.zero : ResolveContactPoint(tactic, contact, contact.timeMs);
        }

        private static Vector3 InitialPosition(TacticDocument tactic, string playerId)
        {
            var slot = tactic.initialFormation.FirstOrDefault(s => s.playerId == playerId);
            return slot == null ? Vector3.zero : new Vector3(slot.x, 0f, slot.z);
        }

        private static bool IsMoving(TacticDocument tactic, string playerId, int timeMs) => tactic.moveTracks.Any(m => m.playerId == playerId && timeMs >= m.startMs && timeMs < m.endMs);

        private static float EvaluatePlayerYaw(TacticDocument tactic, string playerId, int timeMs, Vector3 position)
        {
            var active = tactic.moveTracks.Where(m => m.playerId == playerId && timeMs >= m.startMs && timeMs < m.endMs).OrderByDescending(m => m.startMs).FirstOrDefault();
            if (active == null) return tactic.initialFormation.FirstOrDefault(s => s.playerId == playerId)?.yawDeg ?? 0f;
            var target = active.waypoints != null && active.waypoints.Count > 0 ? active.waypoints[0] : position + Vector3.forward;
            var direction = target - position;
            return direction.sqrMagnitude < 0.0001f ? 0f : Mathf.Atan2(direction.x, direction.z) * Mathf.Rad2Deg;
        }

        private static (PoseActionType type, float progress) EvaluatePose(TacticDocument tactic, string playerId, int timeMs)
        {
            var active = tactic.poseActions.Where(p => p.playerId == playerId && timeMs >= p.startMs && timeMs <= p.endMs).OrderByDescending(p => p.startMs).FirstOrDefault();
            if (active == null) return (PoseActionType.Ready, 0f);
            return (active.type, Mathf.Clamp01((timeMs - active.startMs) / (float)Mathf.Max(1, active.endMs - active.startMs)));
        }

        private static int CurrentPhaseIndex(TacticDocument tactic, int timeMs)
        {
            var index = 0;
            for (var i = 0; i < tactic.phases.Count; i++) if (tactic.phases[i].startMs <= timeMs) index = i;
            return index;
        }

        private static Vector3 SamplePolyline(Vector3 from, List<Vector3> waypoints, float u)
        {
            if (waypoints == null || waypoints.Count == 0) return from;
            var points = new List<Vector3>(waypoints.Count + 1) { from };
            points.AddRange(waypoints);
            var lengths = new float[points.Count - 1];
            var total = 0f;
            for (var i = 0; i < lengths.Length; i++) { lengths[i] = Vector3.Distance(points[i], points[i + 1]); total += lengths[i]; }
            if (total < 0.0001f) return points[points.Count - 1];
            var distance = u * total;
            for (var i = 0; i < lengths.Length; i++)
            {
                if (distance <= lengths[i]) return Vector3.Lerp(points[i], points[i + 1], distance / Mathf.Max(0.0001f, lengths[i]));
                distance -= lengths[i];
            }
            return points[points.Count - 1];
        }
    }
}
