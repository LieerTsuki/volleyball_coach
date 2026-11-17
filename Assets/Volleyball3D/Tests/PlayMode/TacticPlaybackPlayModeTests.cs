using System.Collections;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using VolleyballCoach.Application;

namespace VolleyballCoach.Tests
{
    public class TacticPlaybackPlayModeTests
    {
        [UnityTest]
        public IEnumerator SampleEvaluatesAfterFrame()
        {
            var go = new GameObject("ClockTest"); var clock = go.AddComponent<PlaybackClock>(); clock.Configure(4000); clock.Seek(1700); yield return null; Assert.AreEqual(1700, clock.TimeMs); Object.Destroy(go);
        }
    }
}
