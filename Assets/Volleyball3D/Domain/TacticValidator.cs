using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace VolleyballCoach.Domain
{
    public sealed class ValidationIssue
    {
        public string code, message;
        public ValidationIssue(string code, string message) { this.code = code; this.message = message; }
    }

    public static class TacticValidator
    {
        public static List<ValidationIssue> Validate(TacticDocument tactic, bool requirePlayable)
        {
            var issues = new List<ValidationIssue>();
            if (tactic == null) { issues.Add(new ValidationIssue("null", "战术数据为空。")); return issues; }
            if (tactic.schemaVersion != 1) issues.Add(new ValidationIssue("schema", "战术版本不是当前支持的版本。"));
            if (string.IsNullOrWhiteSpace(tactic.id)) issues.Add(new ValidationIssue("id", "战术缺少稳定 ID。"));
            CheckUnique(tactic.players.Select(p => p.id), "球员 ID", issues);
            CheckUnique(tactic.moveTracks.Select(p => p.id), "跑位 ID", issues);
            CheckUnique(tactic.poseActions.Select(p => p.id), "动作 ID", issues);
            CheckUnique(tactic.contactEvents.Select(p => p.id), "触球 ID", issues);
            CheckUnique(tactic.ballActions.Select(p => p.id), "球路 ID", issues);
            var playerIds = new HashSet<string>(tactic.players.Select(p => p.id));
            foreach (var slot in tactic.initialFormation)
                if (!playerIds.Contains(slot.playerId)) issues.Add(new ValidationIssue("formation.ref", $"站位引用了不存在的球员 {slot.playerId}。"));
            foreach (var move in tactic.moveTracks)
            {
                if (!playerIds.Contains(move.playerId)) issues.Add(new ValidationIssue("move.ref", $"跑位 {move.id} 引用了不存在的球员。"));
                if (move.startMs < 0 || move.endMs <= move.startMs) issues.Add(new ValidationIssue("move.time", $"球员 {move.playerId} 的跑位时间无效。"));
                if (move.waypoints == null || move.waypoints.Count == 0) issues.Add(new ValidationIssue("move.path", $"球员 {move.playerId} 的跑位缺少目标点。"));
                if (move.waypoints != null && move.waypoints.Any(p => float.IsNaN(p.x) || float.IsNaN(p.y) || float.IsNaN(p.z))) issues.Add(new ValidationIssue("move.coord", $"跑位 {move.id} 含有无效坐标。"));
            }
            foreach (var pose in tactic.poseActions)
            {
                if (!playerIds.Contains(pose.playerId)) issues.Add(new ValidationIssue("pose.ref", $"动作 {pose.id} 引用了不存在的球员。"));
                if (pose.startMs < 0 || pose.endMs <= pose.startMs) issues.Add(new ValidationIssue("pose.time", $"球员 {pose.playerId} 的动作时间无效。"));
            }
            foreach (var contact in tactic.contactEvents)
                if (!playerIds.Contains(contact.playerId)) issues.Add(new ValidationIssue("contact.ref", $"触球 {contact.id} 引用了不存在的球员。"));
            foreach (var ball in tactic.ballActions)
            {
                if (ball.startMs < 0 || ball.endMs <= ball.startMs) issues.Add(new ValidationIssue("ball.time", $"球路 {ball.id} 的时间无效。"));
                if (ball.from == null || ball.to == null) issues.Add(new ValidationIssue("ball.endpoint", $"球路 {ball.id} 缺少起点或终点。"));
                if (ball.from != null && ball.to != null && !ball.from.isContact && !ball.to.isContact)
                {
                    var a = ball.from.worldPoint; var b = ball.to.worldPoint;
                    if ((a.z < 0f && b.z > 0f) || (a.z > 0f && b.z < 0f))
                    {
                        var u = Mathf.Clamp01(-a.z / Mathf.Max(0.0001f, b.z - a.z));
                        var y = Mathf.Lerp(a.y, b.y, u) + 4f * Mathf.Max(0f, ball.arcHeightM) * u * (1f - u);
                        if (y < tactic.courtConfig.netHeightM + 0.12f) issues.Add(new ValidationIssue("ball.net", $"球路 {ball.id} 过网高度不足，请提高弧线或调整触球时机。"));
                    }
                }
            }
            foreach (var pair in tactic.ballActions.SelectMany((a, i) => tactic.ballActions.Skip(i + 1).Select(b => new { a, b })))
                if (pair.a.startMs < pair.b.endMs && pair.b.startMs < pair.a.endMs)
                    issues.Add(new ValidationIssue("ball.overlap", $"球路 {pair.a.id} 与 {pair.b.id} 的飞行时间重叠。"));
            foreach (var group in tactic.moveTracks.GroupBy(m => m.playerId))
                foreach (var pair in group.SelectMany((a, i) => group.Skip(i + 1).Select(b => new { a, b })))
                    if (pair.a.startMs < pair.b.endMs && pair.b.startMs < pair.a.endMs)
                        issues.Add(new ValidationIssue("move.overlap", $"球员 {group.Key} 的跑位时间重叠。"));
            if (requirePlayable)
            {
                if (tactic.contactEvents.Count == 0) issues.Add(new ValidationIssue("playable.contacts", "可回放战术至少需要一个触球事件。"));
                if (tactic.ballActions.Count == 0) issues.Add(new ValidationIssue("playable.ball", "可回放战术至少需要一段球路。"));
                foreach (var contact in tactic.contactEvents)
                {
                    var pose = tactic.poseActions.FirstOrDefault(p => p.id == contact.actionId);
                    if (pose == null || contact.timeMs < pose.startMs || contact.timeMs > pose.endMs) issues.Add(new ValidationIssue("contact.pose", $"触球 {contact.id} 不在对应动作片段内。"));
                }
            }
            return issues;
        }

        private static void CheckUnique(IEnumerable<string> ids, string label, List<ValidationIssue> issues)
        {
            var seen = new HashSet<string>();
            foreach (var id in ids) if (string.IsNullOrWhiteSpace(id) || !seen.Add(id)) issues.Add(new ValidationIssue("duplicate", $"{label}存在空值或重复。"));
        }
    }
}
