using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

namespace GamesLibraryManager
{
    public class GameEntry
    {
        public string Name;
        public string Provider;
        public string ProviderKey;
        public string Kind = "StoreGame";
        public string Target;
        public string Arguments = "";
        public string WorkingDirectory = "";
        public string IconPath = "";
        public string InstallDir = "";
        public string Id = "";
        public string Source = "";
        public string CoverPath = "";
        public string CoverUrl = "";
        public string HeroPath = "";
        public string Developer = "";
        public string Publisher = "";
        public string Year = "";
        public string Genres = "";
        public string Rating = "";
        public string ShortcutPath = "";
    }

    public static class SteamProvider
    {
        public static string GetSteamInstallPath()
        {
            string[] candidates = {
                Discovery.GetRegistryValue(@"Software\Valve\Steam", "SteamExe"),
                Discovery.GetRegistryValue(@"SOFTWARE\WOW6432Node\Valve\Steam", "InstallPath"),
                Discovery.GetRegistryValue(@"SOFTWARE\Valve\Steam", "InstallPath")
            };
            foreach (var c in candidates)
            {
                if (string.IsNullOrWhiteSpace(c)) continue;
                string expanded = Discovery.ExpandPath(c);
                if (File.Exists(expanded) && Path.GetFileName(expanded).Equals("steam.exe", StringComparison.OrdinalIgnoreCase))
                    return expanded;
                string nested = Path.Combine(expanded, "steam.exe");
                if (File.Exists(nested)) return nested;
            }
            foreach (var drive in DriveInfo.GetDrives())
            {
                if (!drive.IsReady) continue;
                foreach (var rel in new[] { "Steam", "SteamLibrary", "Games\\Steam" })
                {
                    string candidate = Path.Combine(drive.RootDirectory.FullName, rel, "steam.exe");
                    if (File.Exists(candidate)) return candidate;
                }
            }
            return null;
        }

        private static string GetVdfField(string text, string name)
        {
            var match = Regex.Match(text, "\"" + Regex.Escape(name) + "\"\\s+\"([^\"]*)\"");
            if (match.Success) return match.Groups[1].Value.Replace("\\\\", "\\");
            return null;
        }

        public static string[] GetLibraryFolders(string steamExe)
        {
            var folders = new System.Collections.Generic.HashSet<string>(StringComparer.OrdinalIgnoreCase);
            string steamRoot = Path.GetDirectoryName(steamExe);
            folders.Add(Path.GetFullPath(steamRoot));
            string vdf = Path.Combine(steamRoot, "steamapps", "libraryfolders.vdf");
            if (File.Exists(vdf))
            {
                try
                {
                    string text = File.ReadAllText(vdf);
                    foreach (Match m in Regex.Matches(text, "\"path\"\\s+\"([^\"]+)\""))
                    {
                        string path = m.Groups[1].Value.Replace("\\\\", "\\");
                        path = Discovery.ExpandPath(path);
                        if (!string.IsNullOrWhiteSpace(path) && Directory.Exists(path))
                            folders.Add(Path.GetFullPath(path));
                    }
                }
                catch { }
            }
            return new List<string>(folders).ToArray();
        }

        public static List<GameEntry> Scan()
        {
            var games = new List<GameEntry>();
            var seen = new HashSet<string>();
            string steamExe = GetSteamInstallPath();
            if (string.IsNullOrWhiteSpace(steamExe)) return games;

            foreach (string library in GetLibraryFolders(steamExe))
            {
                string appsDir = Path.Combine(library, "steamapps");
                string commonDir = Path.Combine(appsDir, "common");
                if (!Directory.Exists(appsDir)) continue;

                foreach (var manifest in Directory.GetFiles(appsDir, "appmanifest_*.acf"))
                {
                    try
                    {
                        string text = File.ReadAllText(manifest);
                        string appId = GetVdfField(text, "appid");
                        if (string.IsNullOrWhiteSpace(appId)) appId = Path.GetFileNameWithoutExtension(manifest).Replace("appmanifest_", "");
                        if (seen.Contains(appId)) continue;

                        string name = GetVdfField(text, "name");
                        string installDir = GetVdfField(text, "installdir");
                        string stateFlags = GetVdfField(text, "StateFlags");

                        if (!string.IsNullOrWhiteSpace(stateFlags))
                        {
                            int stateNumber = 0;
                            if (int.TryParse(stateFlags, out stateNumber))
                            {
                                if ((stateNumber & 4) == 0) continue;
                            }
                        }

                        if (string.IsNullOrWhiteSpace(name)) continue;
                        if (appId == "228980") continue;
                        if (Regex.IsMatch(name, @"(steamworks common redistributables|steam linux runtime|proton|steamvr|soundtrack|dedicated server|redistributable)", RegexOptions.IgnoreCase)) continue;

                        seen.Add(appId);
                        string gameDir = null;
                        if (!string.IsNullOrWhiteSpace(installDir))
                        {
                            string candidate = Path.Combine(commonDir, installDir);
                            if (Directory.Exists(candidate)) gameDir = candidate;
                        }

                        string exe = null;
                        if (gameDir != null) exe = FindGameExecutable(gameDir, 3, installDir);

                        var entry = new GameEntry
                        {
                            Name = Titles.Normalize(name, "steam-appmanifest", appId, gameDir),
                            Provider = "Steam",
                            ProviderKey = "steam",
                            Kind = "StoreGame",
                            Target = steamExe,
                            Arguments = "steam://rungameid/" + appId,
                            IconPath = exe ?? "",
                            InstallDir = gameDir ?? "",
                            Id = appId,
                            Source = "steam-appmanifest"
                        };
                        games.Add(entry);
                    }
                    catch { }
                }
            }
            return games;
        }

        private static string FindGameExecutable(string directory, int depth, string preferName)
        {
            if (depth <= 0 || !Directory.Exists(directory)) return null;
            try
            {
                foreach (var file in Directory.GetFiles(directory, "*.exe"))
                {
                    string name = Path.GetFileNameWithoutExtension(file);
                    if (name.IndexOf("unins", StringComparison.OrdinalIgnoreCase) >= 0) continue;
                    if (name.IndexOf("crash", StringComparison.OrdinalIgnoreCase) >= 0) continue;
                    if (name.IndexOf("setup", StringComparison.OrdinalIgnoreCase) >= 0) continue;
                    if (name.IndexOf("install", StringComparison.OrdinalIgnoreCase) >= 0) continue;
                    if (preferName != null && name.Equals(preferName, StringComparison.OrdinalIgnoreCase)) return file;
                }
                foreach (var sub in Directory.GetDirectories(directory))
                {
                    string result = FindGameExecutable(sub, depth - 1, preferName);
                    if (result != null) return result;
                }
                foreach (var file in Directory.GetFiles(directory, "*.exe"))
                {
                    string name = Path.GetFileNameWithoutExtension(file);
                    if (name.IndexOf("unins", StringComparison.OrdinalIgnoreCase) >= 0) continue;
                    if (name.IndexOf("crash", StringComparison.OrdinalIgnoreCase) >= 0) continue;
                    if (name.IndexOf("setup", StringComparison.OrdinalIgnoreCase) >= 0) continue;
                    if (name.IndexOf("install", StringComparison.OrdinalIgnoreCase) >= 0) continue;
                    return file;
                }
            }
            catch { }
            return null;
        }
    }
}