using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

namespace GamesLibraryManager
{
    public static class EpicProvider
    {
        public static string GetEpicLauncherPath()
        {
            foreach (var drive in DriveInfo.GetDrives())
            {
                if (!drive.IsReady) continue;
                foreach (var rel in new[]
                {
                    "Program Files (x86)\\Epic Games\\Launcher\\Portal\\Binaries\\Win64\\EpicGamesLauncher.exe",
                    "Program Files\\Epic Games\\Launcher\\Portal\\Binaries\\Win64\\EpicGamesLauncher.exe",
                    "Epic Games\\Launcher\\Portal\\Binaries\\Win64\\EpicGamesLauncher.exe"
                })
                {
                    string candidate = Path.Combine(drive.RootDirectory.FullName, rel);
                    if (File.Exists(candidate)) return candidate;
                }
            }
            return null;
        }

        public static string GetEpicInstallPath()
        {
            // Check registry
            string regPath = Discovery.GetRegistryValue(@"SOFTWARE\Epic Games\EpicGamesLauncher", "AppDataPath");
            if (!string.IsNullOrWhiteSpace(regPath))
            {
                string manifestDir = Path.Combine(regPath, "Manifests");
                if (Directory.Exists(manifestDir)) return manifestDir;
            }
            // Check common locations
            foreach (var drive in DriveInfo.GetDrives())
            {
                if (!drive.IsReady) continue;
                string candidate = Path.Combine(drive.RootDirectory.FullName, "ProgramData", "Epic", "EpicGamesLauncher", "Data", "Manifests");
                if (Directory.Exists(candidate)) return candidate;
            }
            return null;
        }

        public static List<GameEntry> Scan()
        {
            var games = new List<GameEntry>();
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            string manifestDir = GetEpicInstallPath();
            if (string.IsNullOrWhiteSpace(manifestDir) || !Directory.Exists(manifestDir)) return games;

            foreach (var file in Directory.GetFiles(manifestDir, "*.item"))
            {
                try
                {
                    string json = File.ReadAllText(file);
                    // Simple JSON field extraction
                    string appName = ExtractField(json, "AppName");
                    string displayName = ExtractField(json, "DisplayName");
                    string installLocation = ExtractField(json, "InstallLocation");
                    string launchExe = ExtractField(json, "LaunchExecutable");
                    string appVersion = ExtractField(json, "AppVersion");

                    if (string.IsNullOrWhiteSpace(appName)) continue;
                    if (seen.Contains(appName)) continue;
                    seen.Add(appName);

                    string title = !string.IsNullOrWhiteSpace(displayName) ? displayName : appName;
                    string exe = null;
                    if (!string.IsNullOrWhiteSpace(installLocation) && !string.IsNullOrWhiteSpace(launchExe))
                    {
                        exe = Path.Combine(installLocation, launchExe);
                        if (!File.Exists(exe)) exe = null;
                    }

                    var entry = new GameEntry
                    {
                        Name = Titles.Normalize(title),
                        Provider = "Epic Games",
                        ProviderKey = "epic",
                        Kind = "StoreGame",
                        Target = "com.epicgames.launcher://apps/" + appName + "?action=launch&silent=true",
                        IconPath = exe ?? "",
                        InstallDir = installLocation ?? "",
                        Id = appName,
                        Source = "epic-manifest"
                    };
                    games.Add(entry);
                }
                catch { }
            }

            if (games.Count == 0) return null;
            return games;
        }

        private static string ExtractField(string json, string field)
        {
            var match = System.Text.RegularExpressions.Regex.Match(json, "\"" + field + "\"\\s*:\\s*\"([^\"]*)\"");
            if (match.Success) return match.Groups[1].Value;
            return "";
        }
    }
}