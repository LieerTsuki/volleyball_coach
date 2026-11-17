using System.Collections.Generic;
using TMPro;
using UnityEngine;
using VolleyballCoach.Domain;

namespace VolleyballCoach.Presentation
{
    public static class CourtSceneBuilder
    {
        public static Transform Build(Transform parent, CourtConfig config)
        {
            var root = new GameObject("Court").transform; root.SetParent(parent, false);
            var floor = Cube("CourtFloor", new Vector3(0f, -0.08f, 0f), new Vector3(config.widthM, 0.16f, config.lengthM), new Color(0.12f, 0.34f, 0.43f)); floor.SetParent(root, false);
            Line(root, "CenterLine", new Vector3(0f, 0.02f, 0f), new Vector3(config.widthM, 0.025f, 0.06f), Color.white);
            Line(root, "AttackLineHome", new Vector3(0f, 0.03f, -config.attackLineOffsetM), new Vector3(config.widthM, 0.025f, 0.045f), Color.white);
            Line(root, "AttackLineAway", new Vector3(0f, 0.03f, config.attackLineOffsetM), new Vector3(config.widthM, 0.025f, 0.045f), Color.white);
            Line(root, "BackLineHome", new Vector3(0f, 0.03f, -config.lengthM * 0.5f), new Vector3(config.widthM, 0.025f, 0.045f), Color.white);
            Line(root, "BackLineAway", new Vector3(0f, 0.03f, config.lengthM * 0.5f), new Vector3(config.widthM, 0.025f, 0.045f), Color.white);
            Line(root, "SideLineL", new Vector3(-config.widthM * 0.5f, 0.03f, 0f), new Vector3(0.045f, 0.025f, config.lengthM), Color.white);
            Line(root, "SideLineR", new Vector3(config.widthM * 0.5f, 0.03f, 0f), new Vector3(0.045f, 0.025f, config.lengthM), Color.white);
            var net = Cube("Net", new Vector3(0f, config.netHeightM * 0.5f, 0f), new Vector3(config.widthM, config.netHeightM, 0.06f), new Color(0.08f, 0.09f, 0.12f)); net.SetParent(root, false);
            AddLabel(root, "己方 · 负 Z", new Vector3(-5.2f, 0.1f, -7.8f), 0.42f);
            AddLabel(root, "对方 · 正 Z", new Vector3(-5.2f, 0.1f, 7.8f), 0.42f);
            for (var i = 1; i <= 6; i++) AddLabel(root, i.ToString(), new Vector3(-4.2f + (i - 1) * 1.65f, 0.05f, -0.7f), 0.3f);
            return root;
        }

        private static Transform Cube(string name, Vector3 position, Vector3 scale, Color color)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Cube); go.name = name; go.transform.position = position; go.transform.localScale = scale; go.GetComponent<Renderer>().material = Material(color); return go.transform;
        }
        private static void Line(Transform parent, string name, Vector3 position, Vector3 scale, Color color) { var line = Cube(name, position, scale, color); line.SetParent(parent, false); }
        private static Material Material(Color color) { var shader = Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard"); var mat = new Material(shader) { color = color }; return mat; }
        private static void AddLabel(Transform parent, string text, Vector3 pos, float size)
        {
            var go = new GameObject("Label_" + text); go.transform.SetParent(parent, false); go.transform.localPosition = pos; var label = go.AddComponent<TextMeshPro>(); label.text = text; label.fontSize = size; label.color = Color.white; label.alignment = TextAlignmentOptions.Center; label.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
        }
    }
}
