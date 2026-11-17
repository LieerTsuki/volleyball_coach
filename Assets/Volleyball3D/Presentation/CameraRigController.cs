using UnityEngine;
using VolleyballCoach.Domain;

namespace VolleyballCoach.Presentation
{
    public sealed class CameraRigController : MonoBehaviour
    {
        [SerializeField] private Camera targetCamera;
        public CameraPreset Preset { get; private set; } = CameraPreset.Top;
        public void Configure(Camera camera) { targetCamera = camera; SetPreset(CameraPreset.Top); }
        public void SetPreset(CameraPreset preset)
        {
            Preset = preset; if (targetCamera == null) return; targetCamera.orthographic = preset == CameraPreset.Top;
            if (preset == CameraPreset.Top) { targetCamera.transform.position = new Vector3(0f, 22f, -0.1f); targetCamera.transform.rotation = Quaternion.Euler(90f, 0f, 0f); targetCamera.orthographicSize = 11f; }
            else if (preset == CameraPreset.Oblique) { targetCamera.transform.position = new Vector3(12f, 15f, -15f); targetCamera.transform.rotation = Quaternion.Euler(45f, 38f, 0f); targetCamera.fieldOfView = 42f; }
            else { targetCamera.transform.position = new Vector3(-12f, 5f, -2f); targetCamera.transform.rotation = Quaternion.Euler(76f, -90f, 0f); targetCamera.fieldOfView = 46f; }
        }
    }
}
