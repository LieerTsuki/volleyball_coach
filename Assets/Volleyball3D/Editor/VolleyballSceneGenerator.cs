#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using VolleyballCoach.Presentation;

namespace VolleyballCoach.Editor
{
    public static class VolleyballSceneGenerator
    {
        [MenuItem("Volleyball Coach/生成示例场景")]
        public static void Generate()
        {
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var camera = new GameObject("Main Camera"); camera.tag = "MainCamera"; camera.AddComponent<Camera>();
            var light = new GameObject("Directional Light"); var lamp = light.AddComponent<Light>(); lamp.type = LightType.Directional; light.transform.rotation = Quaternion.Euler(50f, -30f, 0f); lamp.intensity = 1.1f;
            var app = new GameObject("VolleyballCoachApp"); app.AddComponent<VolleyballCoachBootstrap>();
            AssetDatabase.SaveAssets(); EditorSceneManager.SaveScene(scene, "Assets/Volleyball3D/Scenes/VolleyballCoach.unity"); Selection.activeGameObject = app;
        }
    }
}
#endif
