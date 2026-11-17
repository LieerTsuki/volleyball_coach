using System;
using UnityEngine;
using VolleyballCoach.Domain;

namespace VolleyballCoach.Application
{
    public static class SampleTacticFactory
    {
        public static TacticDocument Create()
        {
            var now = DateTime.UtcNow.ToString("o");
            var t = new TacticDocument { id = "sample-three-receiver-fast-middle", title = "三人接发 · 副攻快球掩护 · 四号位进攻", notes = "内置可播放示例", createdAt = now, updatedAt = now };
            t.players.AddRange(new[]
            {
                new PlayerDefinition { id = "p1", jerseyNumber = "1", role = PlayerRole.Setter, isReceiver = false },
                new PlayerDefinition { id = "p2", jerseyNumber = "2", role = PlayerRole.OutsideHitter, isReceiver = true },
                new PlayerDefinition { id = "p3", jerseyNumber = "3", role = PlayerRole.MiddleBlocker, isReceiver = false },
                new PlayerDefinition { id = "p4", jerseyNumber = "4", role = PlayerRole.OutsideHitter, isReceiver = true },
                new PlayerDefinition { id = "p5", jerseyNumber = "5", role = PlayerRole.Opposite, isReceiver = false },
                new PlayerDefinition { id = "p6", jerseyNumber = "6", role = PlayerRole.Libero, isReceiver = true }
            });
            t.initialFormation.AddRange(new[]
            {
                Slot("p1", 2.8f, -2.6f, 180f), Slot("p2", -3.2f, -5.6f, 160f), Slot("p3", -1.1f, -2.0f, 180f),
                Slot("p4", 0.1f, -5.7f, 180f), Slot("p5", 3.0f, -5.4f, 200f), Slot("p6", -2.1f, -7.2f, 170f)
            });
            t.phases.AddRange(new[] { new TacticPhase { id = "phase-receive", label = "发球与一传", startMs = 0 }, new TacticPhase { id = "phase-set", label = "二传组织", startMs = 1700 }, new TacticPhase { id = "phase-attack", label = "进攻", startMs = 2800 } });
            t.moveTracks.AddRange(new[]
            {
                Move("m-p1", "p1", 700, 1700, new Vector3(1.4f, 0f, -1.2f)), Move("m-p2", "p2", 700, 1700, new Vector3(-2.4f, 0f, -4.2f)),
                Move("m-p6", "p6", 700, 1700, new Vector3(-1.1f, 0f, -5.4f)), Move("m-p3", "p3", 1600, 2700, new Vector3(-0.4f, 0f, -0.5f), new Vector3(-0.8f, 0f, 0.8f)),
                Move("m-p4", "p4", 2700, 3500, new Vector3(-1.8f, 0f, -2.2f), new Vector3(-2.6f, 0f, 0.5f)), Move("m-p2-attack", "p2", 2700, 3500, new Vector3(-2.2f, 0f, -1.0f), new Vector3(-2.4f, 0f, 0.7f))
            });
            t.poseActions.AddRange(new[]
            {
                Pose("pose-ready-2", "p2", PoseActionType.Ready, 0, 700), Pose("pose-dig-2", "p2", PoseActionType.Dig, 1300, 1900),
                Pose("pose-set-1", "p1", PoseActionType.Set, 2050, 2650), Pose("pose-cover-3", "p3", PoseActionType.JumpCover, 2200, 3100),
                Pose("pose-approach-2", "p2", PoseActionType.Approach, 2700, 3150), Pose("pose-spike-2", "p2", PoseActionType.Spike, 3150, 3650)
            });
            t.contactEvents.AddRange(new[]
            {
                new ContactEvent { id = "c-pass", playerId = "p2", actionId = "pose-dig-2", timeMs = 1700, anchorType = ContactAnchorType.Forearms },
                new ContactEvent { id = "c-set", playerId = "p1", actionId = "pose-set-1", timeMs = 2500, anchorType = ContactAnchorType.OverheadHands },
                new ContactEvent { id = "c-spike", playerId = "p2", actionId = "pose-spike-2", timeMs = 3350, anchorType = ContactAnchorType.HittingHand }
            });
            t.ballActions.AddRange(new[]
            {
                new BallAction { id = "ball-serve", type = BallActionType.Serve, startMs = 700, endMs = 1700, from = BallEndpoint.World(new Vector3(4.7f, 2.3f, 9.6f)), to = BallEndpoint.Contact("c-pass"), arcHeightM = 2.2f },
                new BallAction { id = "ball-pass", type = BallActionType.Pass, startMs = 1700, endMs = 2500, from = BallEndpoint.Contact("c-pass"), to = BallEndpoint.Contact("c-set"), arcHeightM = 1.3f },
                new BallAction { id = "ball-set", type = BallActionType.Set, startMs = 2500, endMs = 3350, from = BallEndpoint.Contact("c-set"), to = BallEndpoint.Contact("c-spike"), arcHeightM = 2.7f },
                new BallAction { id = "ball-spike", type = BallActionType.Spike, startMs = 3350, endMs = 3800, from = BallEndpoint.Contact("c-spike"), to = BallEndpoint.World(new Vector3(2.8f, 0.15f, 4.5f)), arcHeightM = 0.3f }
            });
            return t;
        }

        private static FormationSlot Slot(string id, float x, float z, float yaw) => new FormationSlot { playerId = id, x = x, z = z, yawDeg = yaw };
        private static MoveSegment Move(string id, string player, int start, int end, params Vector3[] points) => new MoveSegment { id = id, playerId = player, startMs = start, endMs = end, waypoints = new System.Collections.Generic.List<Vector3>(points) };
        private static PoseAction Pose(string id, string player, PoseActionType type, int start, int end) => new PoseAction { id = id, playerId = player, type = type, startMs = start, endMs = end };
    }
}
