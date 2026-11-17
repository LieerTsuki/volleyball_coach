using UnityEngine;
using UnityEngine.InputSystem;
using VolleyballCoach.Application;

namespace VolleyballCoach.Presentation
{
    public sealed class CourtGestureSurface : MonoBehaviour
    {
        public Camera targetCamera;
        public TacticEditController editor;
        private string selectedPlayer;
        private bool dragging;
        private Vector3 lastPoint;
        private void Update()
        {
            if (targetCamera == null || editor == null || Camera.main == null) return;
            var mouse = Mouse.current;
            if (mouse != null && mouse.leftButton.wasPressedThisFrame && TryGround(mouse.position.ReadValue(), out var point))
            {
                var hit = Physics.Raycast(targetCamera.ScreenPointToRay(mouse.position.ReadValue()), out var rayHit, 100f) ? rayHit.collider.GetComponentInParent<PlayerActor>() : null;
                if (hit != null) { selectedPlayer = hit.PlayerId; editor.BeginDrag(selectedPlayer); dragging = true; lastPoint = point; }
            }
            if (mouse != null && dragging && mouse.leftButton.isPressed && TryGround(mouse.position.ReadValue(), out point)) { lastPoint = point; editor.UpdateDrag(lastPoint); }
            if (mouse != null && dragging && mouse.leftButton.wasReleasedThisFrame) { editor.EndDrag(); dragging = false; }
        }
        private bool TryGround(Vector3 screen, out Vector3 point)
        {
            var ray = targetCamera.ScreenPointToRay(screen); var plane = new Plane(Vector3.up, Vector3.zero); if (plane.Raycast(ray, out var distance)) { point = ray.GetPoint(distance); return true; } point = Vector3.zero; return false;
        }
    }
}
