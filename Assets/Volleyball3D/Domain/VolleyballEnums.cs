using System;

namespace VolleyballCoach.Domain
{
    public enum PlayerRole { OutsideHitter, MiddleBlocker, Setter, Opposite, Libero }
    public enum MoveFacingMode { KeepHeading, FacePath, FaceTarget }
    public enum PoseActionType { Ready, Shuffle, Dig, Set, Approach, JumpCover, Spike, Land }
    public enum BallActionType { Serve, Pass, Set, Spike }
    public enum ContactAnchorType { Forearms, OverheadHands, HittingHand, WorldPoint }
    public enum CameraPreset { Top, Oblique, NetSide }
}
