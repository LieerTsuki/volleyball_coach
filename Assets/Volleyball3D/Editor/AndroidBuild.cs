#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace VolleyballCoach.Editor
{
    public static class AndroidBuild
    {
        public static void BuildApk()
        {
            var output = "Builds/VolleyballCoach.apk";
            var options = new BuildPlayerOptions
            {
                scenes = new[] { "Assets/Volleyball3D/Scenes/VolleyballCoach.unity" },
                locationPathName = output,
                target = BuildTarget.Android,
                options = BuildOptions.None
            };
            var report = BuildPipeline.BuildPlayer(options);
            if (report.summary.result != BuildResult.Succeeded) throw new BuildFailedException($"Android APK 构建失败：{report.summary.result}");
            Debug.Log($"Android APK 已生成：{output}，大小 {report.summary.totalSize / (1024f * 1024f):F1} MB");
        }
    }
}
#endif
