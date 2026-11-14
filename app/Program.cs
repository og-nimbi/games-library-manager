using System;
using System.Collections.Generic;
using System.IO;
using System.Web.Script.Serialization;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace GamesLibraryManager
{
    public class MainForm : Form
    {
        private WebView2 wv;
        private string startUrl;

        public MainForm(string url)
        {
            Text = "Games Library";
            Width = 1280;
            Height = 800;
            StartPosition = FormStartPosition.CenterScreen;
            try
            {
                string iconPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "games.ico");
                if (File.Exists(iconPath)) Icon = new System.Drawing.Icon(iconPath);
            }
            catch { }
            wv = new WebView2 { Dock = DockStyle.Fill };
            Controls.Add(wv);
            startUrl = url;
            Load += MainForm_Load;
        }

        private async void MainForm_Load(object sender, EventArgs e)
        {
            try
            {
                await wv.EnsureCoreWebView2Async();
                wv.CoreWebView2.WebMessageReceived += (ss, ee) =>
                {
                    string msg = ee.TryGetWebMessageAsString();
                    if (msg != null && msg.Contains("\"launch\""))
                    {
                        int q1 = msg.LastIndexOf("\"");
                        int q2 = msg.LastIndexOf("\"", q1 - 1);
                        if (q1 > q2 && q2 >= 0)
                        {
                            string path = msg.Substring(q2 + 1, q1 - q2 - 1).Replace("\\\\", "\\");
                            try { System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(path) { UseShellExecute = true }); } catch { }
                        }
                    }
                    else if (msg != null && msg.Contains("\"setSecret\""))
                    {
                        string name = "", value = "";
                        int ni = msg.IndexOf("\"name\"");
                        int vi = msg.IndexOf("\"value\"");
                        if (ni >= 0) { int q1 = msg.IndexOf("\"", ni + 6); int q2 = msg.IndexOf("\"", q1 + 1); if (q1 >= 0 && q2 > q1) name = msg.Substring(q1 + 1, q2 - q1 - 1); }
                        if (vi >= 0) { int q1 = msg.IndexOf("\"", vi + 7); int q2 = msg.IndexOf("\"", q1 + 1); if (q1 >= 0 && q2 > q1) value = msg.Substring(q1 + 1, q2 - q1 - 1); }
                        if (!string.IsNullOrWhiteSpace(name)) Secrets.SetSecret(name, value);
                    }
                    else if (msg != null && msg.Contains("\"setConfig\""))
                    {
                        try
                        {
                            var ser = new System.Web.Script.Serialization.JavaScriptSerializer();
                            var obj = ser.Deserialize<System.Collections.Generic.Dictionary<string, object>>(msg);
                            if (obj != null && obj.ContainsKey("config"))
                            {
                                var patch = obj["config"] as System.Collections.Generic.Dictionary<string, object>;
                                Config.ApplyPatch(patch);
                                Config.SaveUserSettings();
                            }
                        }
                        catch { }
                    }
                    else if (msg != null && msg.Contains("\"resetCache\""))
                    {
                        string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                        string libDir = Path.Combine(Config.LibraryRoot ?? @"D:\Games", "_library");
                        System.Threading.Tasks.Task.Run(() =>
                        {
                            Program.ResetAndRebuildCache(baseDir);
                            try
                            {
                                this.BeginInvoke((Action)(() =>
                                {
                                    try
                                    {
                                        if (wv != null && wv.CoreWebView2 != null)
                                            wv.CoreWebView2.Navigate("file:///" + Path.Combine(libDir, "index.html").Replace("\\", "/"));
                                    }
                                    catch { }
                                }));
                            }
                            catch { }
                        });
                    }
                };
                wv.Source = new Uri(startUrl);
            }
            catch (Exception ex)
            {
                System.IO.File.WriteAllText(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "crash.txt"), ex.ToString());
                MessageBox.Show("WebView2 init failed: " + ex.Message, "Games Library");
            }
        }
    }

    internal static class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            try { System.Net.ServicePointManager.SecurityProtocol = (System.Net.SecurityProtocolType)3072; }
            catch { }
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            bool forceRescan = HasFlag(args, "--rescan") || HasFlag(args, "-rescan") || HasFlag(args, "/rescan");
            string configPath = Path.Combine(baseDir, "config", "settings.json");
            if (args.Length > 0 && !string.IsNullOrWhiteSpace(args[0]) && args[0].EndsWith(".json", StringComparison.OrdinalIgnoreCase))
                configPath = args[0];
            Config.Load(configPath);
            // User settings saved from the settings page override the bundled defaults.
            Config.Load(Config.UserSettingsPath);

            string libraryRoot = Config.LibraryRoot;
            if (string.IsNullOrWhiteSpace(libraryRoot)) libraryRoot = @"D:\Games";

            string libDir = Path.Combine(libraryRoot, "_library");
            Directory.CreateDirectory(libDir);

            string cachePath = Path.Combine(libDir, "library-cache.json");
            List<GameEntry> allGames = null;
            Dictionary<string, string> launchers = null;
            string generatedAt = null;

            if (!forceRescan && LoadLibraryCache(cachePath, out allGames, out launchers, out generatedAt))
            {
                // Fast path: reuse cached scan/enrichment results so the UI can open immediately.
                WriteUi(libDir, baseDir, allGames, launchers, generatedAt);
            }
            else
            {
                // Slow path: scan providers, enrich, generate shortcuts/artwork, and cache results.
                generatedAt = DateTime.Now.ToString("yyyy-MM-dd HH:mm");
                allGames = ScanAndBuild(libraryRoot);
                launchers = ResolveLaunchers();
                SaveLibraryCache(cachePath, allGames, launchers, generatedAt);
                WriteUi(libDir, baseDir, allGames, launchers, generatedAt);
            }

            string indexPath = Path.Combine(libDir, "index.html");
            string indexUrl = "file:///" + indexPath.Replace("\\", "/");
            Application.Run(new MainForm(indexUrl));
        }

        private static bool HasFlag(string[] args, string flag)
        {
            if (args == null) return false;
            foreach (var a in args)
            {
                if (string.Equals(a, flag, StringComparison.OrdinalIgnoreCase)) return true;
            }
            return false;
        }

        private static List<GameEntry> ScanAndBuild(string libraryRoot)
        {
            // Scan Steam
            var steamGames = SteamProvider.Scan();
            Console.WriteLine("Steam: " + steamGames.Count + " games");

            // Scan itch.io
            var itchGames = ItchProvider.Scan();
            if (itchGames != null) Console.WriteLine("itch.io: " + itchGames.Count + " games");

            // Scan Epic
            var epicGames = EpicProvider.Scan();
            if (epicGames != null) Console.WriteLine("Epic: " + epicGames.Count + " games");

            // Combine
            var allGames = new List<GameEntry>();
            allGames.AddRange(steamGames);
            if (itchGames != null) allGames.AddRange(itchGames);
            if (epicGames != null) allGames.AddRange(epicGames);

            foreach (var game in allGames)
            {
                if (Config.CreateLibraryFolders)
                {
                    string providerDir = Path.Combine(libraryRoot, game.Provider.Replace(" ", ""));
                    Directory.CreateDirectory(providerDir);

                    string safeName = Titles.Normalize(game.Name);
                    if (string.IsNullOrWhiteSpace(safeName)) safeName = game.Name;
                    foreach (char c in Path.GetInvalidFileNameChars()) safeName = safeName.Replace(c, '_');
                    string shortcutPath;
                    if (Shortcuts.IsUrlTarget(game.Target))
                    {
                        shortcutPath = Path.Combine(providerDir, safeName + ".url");
                        Shortcuts.CreateUrlShortcut(shortcutPath, game.Target, game.IconPath);
                    }
                    else
                    {
                        shortcutPath = Path.Combine(providerDir, safeName + ".lnk");
                        Shortcuts.CreateLnkShortcut(shortcutPath, game.Target, game.Arguments, game.WorkingDirectory, game.IconPath, game.Name);
                    }
                    game.ShortcutPath = shortcutPath;
                }

                // Resolve artwork for Steam games
                if (game.ProviderKey == "steam")
                {
                    string cover = Artwork.ResolveSteamCover(game.Id, libraryRoot);
                    if (!string.IsNullOrWhiteSpace(cover)) game.CoverPath = cover;
                    string hero = Artwork.ResolveSteamHero(game.Id, libraryRoot);
                    if (!string.IsNullOrWhiteSpace(hero)) game.HeroPath = hero;

                    var meta = Metadata.GetSteamMetadata(game.Id);
                    if (!string.IsNullOrWhiteSpace(meta.Developer)) game.Developer = meta.Developer;
                    if (!string.IsNullOrWhiteSpace(meta.Publisher)) game.Publisher = meta.Publisher;
                    if (!string.IsNullOrWhiteSpace(meta.Year)) game.Year = meta.Year;
                    if (!string.IsNullOrWhiteSpace(meta.Genres)) game.Genres = meta.Genres;
                    if (!string.IsNullOrWhiteSpace(meta.HeroUrl) && string.IsNullOrWhiteSpace(game.HeroPath))
                    {
                        string heroRel = Artwork.ResolveFromUrl(meta.HeroUrl, game.Id + "_hero", libraryRoot);
                        if (!string.IsNullOrWhiteSpace(heroRel)) game.HeroPath = heroRel;
                    }
                }

                // Resolve artwork for itch games
                if (game.ProviderKey == "itch")
                {
                    string cover = Artwork.ResolveItchCover(game.CoverUrl, game.Id, libraryRoot);
                    if (!string.IsNullOrWhiteSpace(cover)) game.CoverPath = cover;
                    if (!string.IsNullOrWhiteSpace(game.CoverPath)) game.HeroPath = game.CoverPath;
                }

                // Generic enrichment: IGDB + SteamGridDB fill any gaps for every
                // storefront, never overriding data the provider already supplied.
                Metadata.Enrich(game, libraryRoot);
            }

            return allGames;
        }

        private static Dictionary<string, string> ResolveLaunchers()
        {
            // A configured launcher path wins over auto-detection, but only when
            // the file still exists; otherwise fall back to discovery.
            var launchers = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            string steamLauncher = ResolveLauncher("steam", SteamProvider.GetSteamInstallPath());
            if (!string.IsNullOrWhiteSpace(steamLauncher)) launchers["Steam"] = steamLauncher;
            string itchLauncher = ResolveLauncher("itch", ItchProvider.GetItchLauncherPath());
            if (!string.IsNullOrWhiteSpace(itchLauncher)) launchers["itch.io"] = itchLauncher;
            string epicLauncher = ResolveLauncher("epic", EpicProvider.GetEpicLauncherPath());
            if (!string.IsNullOrWhiteSpace(epicLauncher)) launchers["Epic Games"] = epicLauncher;
            return launchers;
        }

        private static void WriteUi(string libDir, string baseDir, List<GameEntry> games, Dictionary<string, string> launchers, string generatedAt)
        {
            Directory.CreateDirectory(libDir);
            string indexPath = Path.Combine(libDir, "index.html");
            string html = HtmlGenerator.GenerateIndex(games ?? new List<GameEntry>(), generatedAt ?? DateTime.Now.ToString("yyyy-MM-dd HH:mm"), launchers);
            File.WriteAllText(indexPath, html);

            // Generate settings.html from current config.
            string settingsPath = Path.Combine(libDir, "settings.html");
            string settingsHtml = HtmlGenerator.GenerateSettings();
            File.WriteAllText(settingsPath, settingsHtml);

            // Copy host exe + DLLs + icon + settings.js to _library
            foreach (var name in new[] { "GamesLibraryViewer.exe", "WebView2Loader.dll", "Microsoft.Web.WebView2.Core.dll", "Microsoft.Web.WebView2.WinForms.dll", "games.ico" })
            {
                string src = Path.Combine(baseDir, name);
                if (name == "games.ico") src = Path.Combine(baseDir, "..", "assets", "games.ico");
                string dst = Path.Combine(libDir, name);
                if (src != dst && File.Exists(src)) File.Copy(src, dst, true);
            }
            string settingsJsSrc = Path.Combine(baseDir, "settings.js");
            if (!File.Exists(settingsJsSrc)) settingsJsSrc = Path.Combine(baseDir, "..", "web", "js", "settings.js");
            string settingsJsDst = Path.Combine(libDir, "settings.js");
            if (File.Exists(settingsJsSrc) && !string.Equals(settingsJsSrc, settingsJsDst, StringComparison.OrdinalIgnoreCase))
                File.Copy(settingsJsSrc, settingsJsDst, true);
        }

        private static string ResolveLauncher(string key, string detected)
        {
            foreach (var candidate in GetLauncherKeys(key))
            {
                string configured = Config.GetLauncherPath(candidate);
                if (string.IsNullOrWhiteSpace(configured)) continue;
                string expanded = Discovery.ExpandPath(configured);
                if (!string.IsNullOrWhiteSpace(expanded) && File.Exists(expanded)) return expanded;
            }
            return detected;
        }

        private static string[] GetLauncherKeys(string key)
        {
            if (string.IsNullOrWhiteSpace(key)) return new string[0];
            var lower = key.ToLowerInvariant();
            if (lower == "steam") return new[] { "steam", "Steam" };
            if (lower == "itch") return new[] { "itch", "itch.io", "Itch", "itchio" };
            if (lower == "epic") return new[] { "epic", "Epic Games", "epicgames" };
            return new[] { key };
        }

        internal static bool LoadLibraryCache(string cachePath, out List<GameEntry> games, out Dictionary<string, string> launchers, out string generatedAt)
        {
            games = null; launchers = null; generatedAt = null;
            try
            {
                if (string.IsNullOrWhiteSpace(cachePath) || !File.Exists(cachePath)) return false;
                var ser = new JavaScriptSerializer();
                ser.MaxJsonLength = int.MaxValue;
                var root = ser.Deserialize<Dictionary<string, object>>(File.ReadAllText(cachePath));
                if (root == null) return false;
                if (root.ContainsKey("generatedAt") && root["generatedAt"] != null) generatedAt = root["generatedAt"].ToString();
                launchers = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                if (root.ContainsKey("launchers") && root["launchers"] is Dictionary<string, object>)
                {
                    var ld = (Dictionary<string, object>)root["launchers"];
                    foreach (var kv in ld) { if (kv.Value != null) launchers[kv.Key] = kv.Value.ToString(); }
                }
                games = new List<GameEntry>();
                if (root.ContainsKey("games") && root["games"] is System.Collections.ArrayList)
                {
                    foreach (var item in (System.Collections.ArrayList)root["games"])
                    {
                        var d = item as Dictionary<string, object>;
                        if (d == null) continue;
                        games.Add(GameFromDict(d));
                    }
                }
                return games != null;
            }
            catch { return false; }
        }

        internal static void SaveLibraryCache(string cachePath, List<GameEntry> games, Dictionary<string, string> launchers, string generatedAt)
        {
            try
            {
                var root = new Dictionary<string, object>();
                root["generatedAt"] = generatedAt ?? "";
                var l = new Dictionary<string, object>();
                if (launchers != null) { foreach (var kv in launchers) l[kv.Key] = kv.Value; }
                root["launchers"] = l;
                var list = new List<object>();
                if (games != null) { foreach (var g in games) list.Add(GameToDict(g)); }
                root["games"] = list;
                var ser = new JavaScriptSerializer();
                ser.MaxJsonLength = int.MaxValue;
                string dir = Path.GetDirectoryName(cachePath);
                if (!string.IsNullOrWhiteSpace(dir) && !Directory.Exists(dir)) Directory.CreateDirectory(dir);
                File.WriteAllText(cachePath, ser.Serialize(root));
            }
            catch { }
        }

        private static Dictionary<string, object> GameToDict(GameEntry g)
        {
            var d = new Dictionary<string, object>();
            if (g == null) return d;
            d["Name"] = g.Name ?? ""; d["Provider"] = g.Provider ?? ""; d["ProviderKey"] = g.ProviderKey ?? "";
            d["Kind"] = g.Kind ?? ""; d["Target"] = g.Target ?? ""; d["Arguments"] = g.Arguments ?? "";
            d["WorkingDirectory"] = g.WorkingDirectory ?? ""; d["IconPath"] = g.IconPath ?? ""; d["InstallDir"] = g.InstallDir ?? "";
            d["Id"] = g.Id ?? ""; d["Source"] = g.Source ?? ""; d["CoverPath"] = g.CoverPath ?? ""; d["CoverUrl"] = g.CoverUrl ?? "";
            d["HeroPath"] = g.HeroPath ?? ""; d["Developer"] = g.Developer ?? ""; d["Publisher"] = g.Publisher ?? "";
            d["Year"] = g.Year ?? ""; d["Genres"] = g.Genres ?? ""; d["Rating"] = g.Rating ?? ""; d["ShortcutPath"] = g.ShortcutPath ?? "";
            return d;
        }

        private static GameEntry GameFromDict(Dictionary<string, object> d)
        {
            var g = new GameEntry();
            Func<string, string> S = k => (d.ContainsKey(k) && d[k] != null) ? d[k].ToString() : "";
            g.Name = S("Name"); g.Provider = S("Provider"); g.ProviderKey = S("ProviderKey"); g.Kind = S("Kind");
            g.Target = S("Target"); g.Arguments = S("Arguments"); g.WorkingDirectory = S("WorkingDirectory");
            g.IconPath = S("IconPath"); g.InstallDir = S("InstallDir"); g.Id = S("Id"); g.Source = S("Source");
            g.CoverPath = S("CoverPath"); g.CoverUrl = S("CoverUrl"); g.HeroPath = S("HeroPath");
            g.Developer = S("Developer"); g.Publisher = S("Publisher"); g.Year = S("Year"); g.Genres = S("Genres");
            g.Rating = S("Rating"); g.ShortcutPath = S("ShortcutPath");
            if (string.IsNullOrEmpty(g.Kind)) g.Kind = "StoreGame";
            return g;
        }

        internal static void ResetAndRebuildCache(string baseDir)
        {
            try
            {
                string libraryRoot = Config.LibraryRoot;
                if (string.IsNullOrWhiteSpace(libraryRoot)) libraryRoot = @"D:\Games";
                string libDir = Path.Combine(libraryRoot, "_library");
                string cachePath = Path.Combine(libDir, "library-cache.json");
                try { if (File.Exists(cachePath)) File.Delete(cachePath); } catch { }
                string generatedAt = DateTime.Now.ToString("yyyy-MM-dd HH:mm");
                var games = ScanAndBuild(libraryRoot);
                var launchers = ResolveLaunchers();
                SaveLibraryCache(cachePath, games, launchers, generatedAt);
                WriteUi(libDir, baseDir, games, launchers, generatedAt);
            }
            catch { }
        }
    }
}