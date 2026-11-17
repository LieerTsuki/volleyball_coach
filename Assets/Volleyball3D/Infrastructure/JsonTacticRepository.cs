using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEngine;
using VolleyballCoach.Application;
using VolleyballCoach.Domain;

namespace VolleyballCoach.Infrastructure
{
    public sealed class TacticRepository
    {
        private readonly string root;
        public TacticRepository(string directory = null) { root = directory ?? Path.Combine(Application.persistentDataPath, "tactics"); Directory.CreateDirectory(root); }
        public IReadOnlyList<TacticDocument> LoadAll()
        {
            var list = new List<TacticDocument>();
            foreach (var path in Directory.GetFiles(root, "*.json")) if (TryLoad(path, out var tactic, out _)) list.Add(tactic);
            return list.OrderByDescending(t => t.updatedAt).ToList();
        }
        public TacticDocument EnsureSample()
        {
            var sample = SampleTacticFactory.Create();
            var path = Path.Combine(root, sample.id + ".json");
            if (!File.Exists(path)) Save(sample);
            return sample;
        }
        public void Save(TacticDocument tactic)
        {
            if (tactic == null || string.IsNullOrWhiteSpace(tactic.id)) throw new ArgumentException("战术 ID 不能为空。");
            tactic.updatedAt = DateTime.UtcNow.ToString("o");
            var json = JsonUtility.ToJson(tactic, true);
            var path = Path.Combine(root, tactic.id + ".json");
            var temp = path + ".tmp";
            var backup = path + ".bak";
            File.WriteAllText(temp, json);
            if (File.Exists(path)) { File.Copy(path, backup, true); File.Delete(path); }
            File.Move(temp, path);
        }
        public bool TryGet(string id, out TacticDocument tactic, out string error) => TryLoad(Path.Combine(root, id + ".json"), out tactic, out error);
        public void Delete(string id) { var path = Path.Combine(root, id + ".json"); if (File.Exists(path)) File.Delete(path); }
        public TacticDocument Copy(TacticDocument source)
        {
            var copy = JsonUtility.FromJson<TacticDocument>(JsonUtility.ToJson(source));
            var idMap = new Dictionary<string, string>();
            copy.id = Guid.NewGuid().ToString("N"); copy.title = source.title + "（副本）"; copy.createdAt = DateTime.UtcNow.ToString("o"); copy.updatedAt = copy.createdAt;
            foreach (var move in copy.moveTracks) { var old = move.id; move.id = Guid.NewGuid().ToString("N"); idMap[old] = move.id; }
            foreach (var pose in copy.poseActions) { var old = pose.id; pose.id = Guid.NewGuid().ToString("N"); idMap[old] = pose.id; }
            foreach (var contact in copy.contactEvents) { var old = contact.id; contact.id = Guid.NewGuid().ToString("N"); idMap[old] = contact.id; contact.actionId = idMap.TryGetValue(contact.actionId, out var next) ? next : contact.actionId; }
            foreach (var ball in copy.ballActions) { ball.id = Guid.NewGuid().ToString("N"); ball.from = CopyEndpoint(ball.from, idMap); ball.to = CopyEndpoint(ball.to, idMap); }
            Save(copy); return copy;
        }
        private static BallEndpoint CopyEndpoint(BallEndpoint endpoint, Dictionary<string, string> map) { if (endpoint == null || !endpoint.isContact) return endpoint; endpoint.contactId = map.TryGetValue(endpoint.contactId, out var id) ? id : endpoint.contactId; return endpoint; }
        private static bool TryLoad(string path, out TacticDocument tactic, out string error)
        {
            tactic = null; error = null;
            try { if (!File.Exists(path)) { error = "文件不存在。"; return false; } tactic = JsonUtility.FromJson<TacticDocument>(File.ReadAllText(path)); var issues = TacticValidator.Validate(tactic, false); if (issues.Count > 0) { error = issues[0].message; return false; } return true; }
            catch (Exception ex) { error = ex.Message; return false; }
        }
    }
}
