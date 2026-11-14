using System;
using System.IO;
using Microsoft.Win32;

namespace GamesLibraryManager
{
    public static class Discovery
    {
        public static string GetRegistryValue(string path, string name)
        {
            try
            {
                using (var key = Registry.CurrentUser.OpenSubKey(path))
                {
                    if (key != null) return key.GetValue(name) == null ? null : key.GetValue(name).ToString();
                }
                using (var key2 = Registry.LocalMachine.OpenSubKey(path))
                {
                    if (key2 != null) return key2.GetValue(name) == null ? null : key2.GetValue(name).ToString();
                }
            }
            catch { }
            return null;
        }

        public static string ExpandPath(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return null;
            return Environment.ExpandEnvironmentVariables(value);
        }

        public static string GetSteamInstallPath()
        {
            string[] candidates = {
                GetRegistryValue(@"Software\Valve\Steam", "SteamExe"),
                GetRegistryValue(@"SOFTWARE\WOW6432Node\Valve\Steam", "InstallPath"),
                GetRegistryValue(@"SOFTWARE\Valve\Steam", "InstallPath")
            };
            foreach (var c in candidates)
            {
                if (string.IsNullOrWhiteSpace(c)) continue;
                string expanded = ExpandPath(c);
                if (File.Exists(expanded) && Path.GetFileName(expanded).Equals("steam.exe", StringComparison.OrdinalIgnoreCase))
                    return expanded;
                string nested = Path.Combine(expanded, "steam.exe");
                if (File.Exists(nested)) return nested;
            }
            // Search common locations
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
    }
}
