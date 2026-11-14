using System;
using System.Collections.Generic;
using System.IO;
using System.Web.Script.Serialization;

namespace GamesLibraryManager
{
    public static class Config
    {
        public static string LibraryRoot = @"D:\Games";
        public static bool CreateFolderIcons = true;
        public static bool CreateHtmlIndex = true;
        public static bool RemoveStaleShortcuts = true;
        public static bool CreateWindowsLibrary = true;
        // When false, no game folders or shortcuts are written to the library root.
        public static bool CreateLibraryFolders = true;
        public static Dictionary<string, bool> Providers = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);
        public static string[] ShortcutFolders = Array.Empty<string>();
        public static int StandaloneDepth = 4;
        public static int RomDepth = 5;
        public static bool DeepDriveScan = false;
        public static string[] StandaloneSearchRoots = { "%ProgramFiles%", "%ProgramFiles(x86)%", "%LOCALAPPDATA%\\Programs" };
        public static string[] RomRoots = Array.Empty<string>();
        public static string[] EmulatorRoots = Array.Empty<string>();
        public static string[] ExtraGameRoots = Array.Empty<string>();
        // Optional manual launcher executables keyed by provider (steam, itch, epic).
        // These are used before auto-detection so users can recover a missing launcher.
        public static Dictionary<string, string> LauncherPaths = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        public static void Load(string configPath)
        {
            if (string.IsNullOrWhiteSpace(configPath) || !File.Exists(configPath)) return;
            try
            {
                string json = File.ReadAllText(configPath);
                var ser = new JavaScriptSerializer();
                var root = ser.Deserialize<Dictionary<string, object>>(json);
                if (root == null) return;

                if (root.ContainsKey("libraryRoot")) LibraryRoot = root["libraryRoot"] == null ? null : root["libraryRoot"].ToString();
                if (root.ContainsKey("createFolderIcons")) CreateFolderIcons = Convert.ToBoolean(root["createFolderIcons"]);
                if (root.ContainsKey("createHtmlIndex")) CreateHtmlIndex = Convert.ToBoolean(root["createHtmlIndex"]);
                if (root.ContainsKey("removeStaleShortcuts")) RemoveStaleShortcuts = Convert.ToBoolean(root["removeStaleShortcuts"]);
                if (root.ContainsKey("createWindowsLibrary")) CreateWindowsLibrary = Convert.ToBoolean(root["createWindowsLibrary"]);
                if (root.ContainsKey("createLibraryFolders")) CreateLibraryFolders = Convert.ToBoolean(root["createLibraryFolders"]);

                if (root.ContainsKey("library") && root["library"] is Dictionary<string, object>) { var library = (Dictionary<string, object>)root["library"];
                    if (library.ContainsKey("createFolders")) CreateLibraryFolders = Convert.ToBoolean(library["createFolders"]);
                }

                if (root.ContainsKey("providers") && root["providers"] is Dictionary<string, object>) { var prov = (Dictionary<string, object>)root["providers"];
                    // providers block
                    foreach (var kv in prov)
                    {
                        Providers[kv.Key] = Convert.ToBoolean(kv.Value);
                    }
                }

                if (root.ContainsKey("launchers") && root["launchers"] is Dictionary<string, object>) { var launchers = (Dictionary<string, object>)root["launchers"];
                    ApplyLauncherPatch(launchers);
                }

                if (root.ContainsKey("scan") && root["scan"] is Dictionary<string, object>) { var scan = (Dictionary<string, object>)root["scan"];
                    // scan block
                    if (scan.ContainsKey("standaloneDepth")) StandaloneDepth = Convert.ToInt32(scan["standaloneDepth"]);
                    if (scan.ContainsKey("deepDriveScan")) DeepDriveScan = Convert.ToBoolean(scan["deepDriveScan"]);
                    if (scan.ContainsKey("romDepth")) RomDepth = Convert.ToInt32(scan["romDepth"]);
                    if (scan.ContainsKey("shortcutFolders")) ShortcutFolders = ToStringArray(scan["shortcutFolders"]);
                    if (scan.ContainsKey("standaloneSearchRoots")) StandaloneSearchRoots = ToStringArray(scan["standaloneSearchRoots"]);
                    if (scan.ContainsKey("romRoots")) RomRoots = ToStringArray(scan["romRoots"]);
                    if (scan.ContainsKey("emulatorRoots")) EmulatorRoots = ToStringArray(scan["emulatorRoots"]);
                    if (scan.ContainsKey("extraGameRoots")) ExtraGameRoots = ToStringArray(scan["extraGameRoots"]);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("Config load error: " + ex.Message);
            }
        }

        private static string[] ToStringArray(object obj)
        {
            if (obj is System.Collections.ArrayList) { var list = (System.Collections.ArrayList)obj;
                var arr = new string[list.Count];
                for (int i = 0; i < list.Count; i++) arr[i] = list[i] == null ? null : list[i].ToString();
                return arr;
            }
            if (obj is object[])
            {
                var arr2 = (object[])obj;
                var arr = new string[arr2.Length];
                for (int i = 0; i < arr2.Length; i++) arr[i] = arr2[i] == null ? null : arr2[i].ToString();
                return arr;
            }
            return Array.Empty<string>();
        }

        public static bool IsProviderEnabled(string key)
        {
            bool val;
            if (Providers.TryGetValue(key, out val)) return val;
            return true;
        }

        private static void ApplyLauncherPatch(Dictionary<string, object> launchers)
        {
            if (launchers == null) return;
            // The settings UI sends the complete launcher set, so replace it to
            // allow removed rows to disappear.
            LauncherPaths = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (var kv in launchers)
            {
                string key = kv.Key == null ? "" : kv.Key.ToString().Trim();
                string value = kv.Value == null ? "" : kv.Value.ToString().Trim();
                if (key.Length == 0 || value.Length == 0) continue;
                LauncherPaths[key] = value;
            }
        }

        public static string GetLauncherPath(string key)
        {
            if (string.IsNullOrWhiteSpace(key)) return null;
            string value;
            return LauncherPaths.TryGetValue(key, out value) ? value : null;
        }

        // User settings saved from the in-app settings page persist here so they
        // survive rebuilds of the generated _library folder.
        public static string UserSettingsPath
        {
            get
            {
                string dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "GamesLibraryManager");
                return Path.Combine(dir, "settings.json");
            }
        }

        public static void ApplyPatch(Dictionary<string, object> patch)
        {
            if (patch == null) return;
            if (patch.ContainsKey("createLibraryFolders")) CreateLibraryFolders = Convert.ToBoolean(patch["createLibraryFolders"]);
            if (patch.ContainsKey("createWindowsLibrary")) CreateWindowsLibrary = Convert.ToBoolean(patch["createWindowsLibrary"]);
            if (patch.ContainsKey("libraryRoot") && patch["libraryRoot"] != null) LibraryRoot = patch["libraryRoot"].ToString();
            if (patch.ContainsKey("scan") && patch["scan"] is Dictionary<string, object>)
            {
                var scan = (Dictionary<string, object>)patch["scan"];
                if (scan.ContainsKey("shortcutFolders")) ShortcutFolders = ToStringArray(scan["shortcutFolders"]);
            }
            if (patch.ContainsKey("launchers") && patch["launchers"] is Dictionary<string, object>)
            {
                ApplyLauncherPatch((Dictionary<string, object>)patch["launchers"]);
            }
        }

        public static void SaveUserSettings()
        {
            try
            {
                var root = new Dictionary<string, object>();
                root["libraryRoot"] = LibraryRoot;
                root["createLibraryFolders"] = CreateLibraryFolders;
                root["createWindowsLibrary"] = CreateWindowsLibrary;
                root["createHtmlIndex"] = CreateHtmlIndex;
                var scan = new Dictionary<string, object>();
                scan["shortcutFolders"] = ShortcutFolders;
                root["scan"] = scan;

                var launchers = new Dictionary<string, object>();
                foreach (var kv in LauncherPaths) launchers[kv.Key] = kv.Value;
                root["launchers"] = launchers;

                var ser = new JavaScriptSerializer();
                string json = ser.Serialize(root);
                string path = UserSettingsPath;
                string dir = Path.GetDirectoryName(path);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                File.WriteAllText(path, json);
            }
            catch (Exception ex)
            {
                Console.WriteLine("Config save error: " + ex.Message);
            }
        }
    }
}
