using System;
using System.Collections.Generic;
using UnityEngine;

namespace VolleyballCoach.Domain
{
    [Serializable] public struct CourtConfig
    {
        public float widthM, lengthM, attackLineOffsetM, netHeightM, freeZoneM;
        public static CourtConfig Default => new CourtConfig { widthM = 9f, lengthM = 18f, attackLineOffsetM = 3f, netHeightM = 2.43f, freeZoneM = 3f };
    }

    [Serializable] public class PlayerDefinition
    {
        public string id, jerseyNumber;
        public PlayerRole role;
        public bool isReceiver;
    }

    [Serializable] public class FormationSlot
    {
        public string playerId;
        public float x, z, yawDeg;
    }

    [Serializable] public class TacticPhase
    {
        public string id, label;
        public int startMs;
    }

    [Serializable] public class MoveSegment
    {
        public string id, playerId;
        public int startMs, endMs;
        public List<Vector3> waypoints = new List<Vector3>();
        public MoveFacingMode facingMode = MoveFacingMode.FacePath;
    }

    [Serializable] public class PoseAction
    {
        public string id, playerId;
        public PoseActionType type;
        public int startMs, endMs;
    }

    [Serializable] public class BallEndpoint
    {
        public bool isContact;
        public string contactId;
        public Vector3 worldPoint;
        public static BallEndpoint World(Vector3 point) => new BallEndpoint { worldPoint = point };
        public static BallEndpoint Contact(string id) => new BallEndpoint { isContact = true, contactId = id };
    }

    [Serializable] public class BallAction
    {
        public string id;
        public BallActionType type;
        public int startMs, endMs;
        public BallEndpoint from, to;
        public float arcHeightM;
    }

    [Serializable] public class ContactEvent
    {
        public string id, playerId, actionId;
        public int timeMs;
        public ContactAnchorType anchorType;
    }

    [Serializable] public class TacticDocument
    {
        public int schemaVersion = 1;
        public string id, title, notes, createdAt, updatedAt;
        public CourtConfig courtConfig = CourtConfig.Default;
        public List<PlayerDefinition> players = new List<PlayerDefinition>();
        public List<FormationSlot> initialFormation = new List<FormationSlot>();
        public List<TacticPhase> phases = new List<TacticPhase>();
        public List<MoveSegment> moveTracks = new List<MoveSegment>();
        public List<PoseAction> poseActions = new List<PoseAction>();
        public List<ContactEvent> contactEvents = new List<ContactEvent>();
        public List<BallAction> ballActions = new List<BallAction>();
    }

    public struct EvaluatedPlayerState
    {
        public string playerId;
        public Vector3 position;
        public float yawDeg;
        public PoseActionType pose;
        public float poseProgress;
        public bool isMoving;
    }

    public struct EvaluatedBallState
    {
        public bool active;
        public Vector3 position;
        public BallActionType actionType;
        public string actionId;
        public float progress;
    }

    public sealed class EvaluatedTacticState
    {
        public readonly List<EvaluatedPlayerState> players = new List<EvaluatedPlayerState>();
        public EvaluatedBallState ball;
        public int currentPhaseIndex;
    }
}
