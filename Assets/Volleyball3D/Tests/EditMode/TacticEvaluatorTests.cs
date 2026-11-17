using NUnit.Framework;
using UnityEngine;
using VolleyballCoach.Application;
using VolleyballCoach.Domain;

namespace VolleyballCoach.Tests
{
    public class TacticEvaluatorTests
    {
        [Test] public void SampleHasSixPlayersAndSharedContacts()
        {
            var tactic = SampleTacticFactory.Create();
            Assert.AreEqual(6, tactic.players.Count);
            Assert.AreEqual(3, tactic.contactEvents.Count);
            Assert.IsEmpty(TacticValidator.Validate(tactic, true));
        }

        [Test] public void MovementInterpolatesAndGapKeepsLastTarget()
        {
            var tactic = SampleTacticFactory.Create();
            var first = TacticEvaluator.EvaluatePlayerPosition(tactic, "p1", 700);
            var middle = TacticEvaluator.EvaluatePlayerPosition(tactic, "p1", 1200);
            var end = TacticEvaluator.EvaluatePlayerPosition(tactic, "p1", 1800);
            Assert.Less(Vector3.Distance(first, middle), 2f);
            Assert.AreEqual(1.4f, end.x, 0.01f);
            Assert.AreEqual(-1.2f, end.z, 0.01f);
        }

        [Test] public void SeekAndPlaybackEvaluationMatch()
        {
            var tactic = SampleTacticFactory.Create();
            var a = TacticEvaluator.EvaluateAt(tactic, 2500);
            var b = TacticEvaluator.EvaluateAt(tactic, 2500);
            Assert.AreEqual(a.ball.position, b.ball.position);
            Assert.AreEqual(a.players[0].position, b.players[0].position);
        }

        [Test] public void CopyChangesIdentityWithoutChangingOriginal()
        {
            var tactic = SampleTacticFactory.Create();
            var json = JsonUtility.ToJson(tactic);
            var copy = JsonUtility.FromJson<TacticDocument>(json);
            copy.id = "copy";
            copy.initialFormation[0].x = 99f;
            Assert.AreEqual(2.8f, tactic.initialFormation[0].x, 0.01f);
            Assert.AreNotEqual(tactic.id, copy.id);
        }
    }
}
