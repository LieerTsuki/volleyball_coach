using NUnit.Framework;
using UnityEngine;
using VolleyballCoach.Application;

namespace VolleyballCoach.Tests
{
    public class TacticValidatorTests
    {
        [Test] public void DetectsOverlappingMoves()
        {
            var tactic = SampleTacticFactory.Create(); tactic.moveTracks.Add(new VolleyballCoach.Domain.MoveSegment { id = "bad", playerId = "p1", startMs = 900, endMs = 1200, waypoints = new System.Collections.Generic.List<Vector3> { Vector3.zero } });
            Assert.IsTrue(VolleyballCoach.Domain.TacticValidator.Validate(tactic, false).Exists(x => x.code == "move.overlap"));
        }
        [Test] public void DetectsUnsupportedSchema()
        {
            var tactic = SampleTacticFactory.Create(); tactic.schemaVersion = 99;
            Assert.IsTrue(VolleyballCoach.Domain.TacticValidator.Validate(tactic, false).Exists(x => x.code == "schema"));
        }
    }
}
