using TMPro;
using UnityEngine;
using VolleyballCoach.Domain;

namespace VolleyballCoach.Presentation
{
    public sealed class PlayerActor : MonoBehaviour
    {
        public string PlayerId { get; private set; }
        private Transform torso, head, armL, armR, legL, legR, numberLabel;
        private Material bodyMaterial;
        public static PlayerActor Create(PlayerDefinition definition, Transform parent)
        {
            var root = new GameObject("Player_" + definition.id); root.transform.SetParent(parent, false); var actor = root.AddComponent<PlayerActor>(); actor.PlayerId = definition.id; actor.Build(definition); return actor;
        }
        private void Build(PlayerDefinition definition)
        {
            bodyMaterial = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard")) { color = definition.isReceiver ? new Color(0.95f, 0.42f, 0.18f) : new Color(0.2f, 0.64f, 0.95f) };
            torso = Part(PrimitiveType.Capsule, "Torso", new Vector3(0f, 1.1f, 0f), new Vector3(0.42f, 0.7f, 0.28f));
            head = Part(PrimitiveType.Sphere, "Head", new Vector3(0f, 2.02f, 0f), new Vector3(0.28f, 0.28f, 0.28f));
            armL = Part(PrimitiveType.Capsule, "Arm.L", new Vector3(-0.48f, 1.3f, 0f), new Vector3(0.12f, 0.46f, 0.12f));
            armR = Part(PrimitiveType.Capsule, "Arm.R", new Vector3(0.48f, 1.3f, 0f), new Vector3(0.12f, 0.46f, 0.12f));
            legL = Part(PrimitiveType.Capsule, "Leg.L", new Vector3(-0.18f, 0.42f, 0f), new Vector3(0.14f, 0.46f, 0.14f));
            legR = Part(PrimitiveType.Capsule, "Leg.R", new Vector3(0.18f, 0.42f, 0f), new Vector3(0.14f, 0.46f, 0.14f));
            var label = new GameObject("JerseyNumber"); label.transform.SetParent(transform, false); label.transform.localPosition = new Vector3(0f, 1.15f, -0.3f); label.transform.localRotation = Quaternion.Euler(0f, 180f, 0f); var tmp = label.AddComponent<TextMeshPro>(); tmp.text = definition.jerseyNumber; tmp.fontSize = 1.2f; tmp.alignment = TextAlignmentOptions.Center; tmp.color = Color.white; numberLabel = label.transform;
        }
        private Transform Part(PrimitiveType type, string name, Vector3 pos, Vector3 scale) { var go = GameObject.CreatePrimitive(type); go.name = name; go.transform.SetParent(transform, false); go.transform.localPosition = pos; go.transform.localScale = scale; go.GetComponent<Renderer>().material = bodyMaterial; return go.transform; }
        public void Apply(EvaluatedPlayerState state)
        {
            transform.localPosition = state.position; transform.localRotation = Quaternion.Euler(0f, state.yawDeg, 0f);
            var p = state.poseProgress; var wave = Mathf.Sin(p * Mathf.PI); var crouch = state.pose == PoseActionType.Ready || state.pose == PoseActionType.Dig ? 0.18f : 0f;
            torso.localPosition = new Vector3(0f, 1.1f - crouch, 0f); head.localPosition = new Vector3(0f, 2.02f - crouch, 0f);
            armL.localRotation = Quaternion.Euler(state.pose == PoseActionType.Set ? -55f * wave : state.pose == PoseActionType.Spike ? -35f - 80f * wave : state.pose == PoseActionType.Dig ? 60f : 0f, 0f, state.pose == PoseActionType.Dig ? -22f : 0f);
            armR.localRotation = Quaternion.Euler(state.pose == PoseActionType.Set ? -55f * wave : state.pose == PoseActionType.Spike ? -35f - 80f * wave : state.pose == PoseActionType.Dig ? 60f : 0f, 0f, state.pose == PoseActionType.Dig ? 22f : 0f);
            legL.localRotation = Quaternion.Euler(state.pose == PoseActionType.Approach ? Mathf.Sin(p * Mathf.PI * 2f) * 35f : 0f, 0f, 0f); legR.localRotation = Quaternion.Euler(state.pose == PoseActionType.Approach ? -Mathf.Sin(p * Mathf.PI * 2f) * 35f : 0f, 0f, 0f);
            var jump = state.pose == PoseActionType.Spike || state.pose == PoseActionType.JumpCover ? wave * 0.6f : 0f; transform.localPosition = new Vector3(state.position.x, jump, state.position.z);
            numberLabel.forward = Camera.main != null ? Camera.main.transform.forward : Vector3.forward;
        }
    }
}
