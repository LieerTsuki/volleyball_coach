using System;
using UnityEngine;

namespace VolleyballCoach.Application
{
    public sealed class PlaybackClock : MonoBehaviour
    {
        [SerializeField] private int durationMs = 4000;
        public int TimeMs { get; private set; }
        public float Speed { get; private set; } = 1f;
        public bool IsPlaying { get; private set; }
        public event Action<int> Changed;

        public void Configure(int duration) { durationMs = Mathf.Max(1, duration); TimeMs = Mathf.Clamp(TimeMs, 0, durationMs); }
        public void Play() => IsPlaying = true;
        public void Pause() => IsPlaying = false;
        public void Toggle() { if (IsPlaying) Pause(); else Play(); }
        public void Replay() { Seek(0); Play(); }
        public void SetSpeed(float speed) { Speed = Mathf.Approximately(speed, 0.5f) ? 0.5f : 1f; }
        public void Seek(int timeMs) { TimeMs = Mathf.Clamp(timeMs, 0, durationMs); Changed?.Invoke(TimeMs); }
        private void Update()
        {
            if (!IsPlaying) return;
            var next = TimeMs + Mathf.RoundToInt(Time.deltaTime * 1000f * Speed);
            if (next >= durationMs) { TimeMs = durationMs; IsPlaying = false; }
            else TimeMs = next;
            Changed?.Invoke(TimeMs);
        }
    }
}
