using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;


namespace GamesLibraryManager
{
    public static class ItchProvider
    {
        public static string GetItchLauncherPath()
        {
            // Check registry
            string regPath = Discovery.GetRegistryValue(@"Software\itch", "InstallLocation");
            if (!string.IsNullOrWhiteSpace(regPath))
            {
                string exe = FindItchExe(regPath);
                if (!string.IsNullOrWhiteSpace(exe)) return exe;
            }
            // Search common locations. The itch launcher lives in a versioned
            // app-<version> folder next to the apps folder.
            string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            foreach (string root in new[]
            {
                Path.Combine(appData, "itch"),
                Path.Combine(appData, "Programs", "itch"),
                Path.Combine(appData, "Programs", "itch.io")
            })
            {
                string exe = FindItchExe(root);
                if (!string.IsNullOrWhiteSpace(exe)) return exe;
            }
            foreach (var drive in DriveInfo.GetDrives())
            {
                if (!drive.IsReady) continue;
                foreach (var rel in new[] { "itch", "Itch", "itch.io" })
                {
                    string exe = FindItchExe(Path.Combine(drive.RootDirectory.FullName, rel));
                    if (!string.IsNullOrWhiteSpace(exe)) return exe;
                }
            }
            return null;
        }

        private static string FindItchExe(string root)
        {
            if (string.IsNullOrWhiteSpace(root) || !Directory.Exists(root)) return null;
            string direct = Path.Combine(root, "itch.exe");
            if (File.Exists(direct)) return direct;
            string[] dirs = Directory.GetDirectories(root, "app-*");
            Array.Sort(dirs, StringComparer.OrdinalIgnoreCase);
            for (int i = dirs.Length - 1; i >= 0; i--)
            {
                string exe = Path.Combine(dirs[i], "itch.exe");
                if (File.Exists(exe)) return exe;
            }
            return null;
        }

        public static string[] GetItchAppsRoots(string launcherPath)
        {
            var roots = new List<string>();
            if (!string.IsNullOrWhiteSpace(launcherPath))
            {
                string baseDir = Path.GetDirectoryName(launcherPath);
                // itch stores apps in %APPDATA%\itch\apps or similar
                string appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
                string itchApps = Path.Combine(appData, "itch", "apps");
                if (Directory.Exists(itchApps)) roots.Add(itchApps);
            }
            // Also check common locations
            foreach (var drive in DriveInfo.GetDrives())
            {
                if (!drive.IsReady) continue;
                foreach (var rel in new[] { "itch\\apps", "itch.io\\apps" })
                {
                    string candidate = Path.Combine(drive.RootDirectory.FullName, rel);
                    if (Directory.Exists(candidate)) roots.Add(candidate);
                }
            }
            return roots.ToArray();
        }

        public static List<GameEntry> Scan()
        {
            var games = new List<GameEntry>();
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            string launcherPath = GetItchLauncherPath();

            foreach (string appsRoot in GetItchAppsRoots(launcherPath))
            {
                if (!Directory.Exists(appsRoot)) continue;
                foreach (var appDir in Directory.GetDirectories(appsRoot))
                {
                    if (Path.GetFileName(appDir).Equals("downloads", StringComparison.OrdinalIgnoreCase)) continue;
                    if (seen.Contains(Path.GetFileName(appDir).ToLowerInvariant())) continue;

                    string title = null;
                    string gameId = null;
                    string coverUrl = "";
                    string pageUrl = "";
                    string developerName = "";
                    string publishedAt = "";

                    // Read receipt
                    string receiptPath = Path.Combine(appDir, ".itch", "receipt.json.gz");
                    if (!File.Exists(receiptPath)) receiptPath = Path.Combine(appDir, ".itch", "receipt.json");
                    if (!File.Exists(receiptPath)) receiptPath = Path.Combine(appDir, "receipt.json");
                    if (File.Exists(receiptPath))
                    {
                        try
                        {
                            string json = "";
                            if (receiptPath.EndsWith(".gz"))
                            {
                                using (var fs = File.OpenRead(receiptPath))
                                using (var gz = new System.IO.Compression.GZipStream(fs, System.IO.Compression.CompressionMode.Decompress))
                                using (var reader = new System.IO.StreamReader(gz))
                                {
                                    json = reader.ReadToEnd();
                                }
                            }
                            else
                            {
                                json = File.ReadAllText(receiptPath);
                            }
                            title = ExtractJsonField(json, "title");
                            gameId = ExtractJsonField(json, "id");
                            coverUrl = ExtractJsonField(json, "coverUrl");
                            if (string.IsNullOrWhiteSpace(coverUrl)) coverUrl = ExtractJsonField(json, "stillCoverUrl");
                            pageUrl = ExtractJsonField(json, "url");
                            developerName = ExtractJsonField(json, "displayName");
                            publishedAt = ExtractJsonField(json, "publishedAt");
                        }
                        catch { }
                    }

                    if (string.IsNullOrWhiteSpace(title))
                    {
                        title = Path.GetFileName(appDir).Replace("-", " ").Replace("_", " ");
                        // Title case
                        title = System.Globalization.CultureInfo.CurrentCulture.TextInfo.ToTitleCase(title);
                    }

                    // Find executable
                    string exe = FindGameExecutable(appDir, 4);
                    string target = exe;
                    string args = "";
                    string workDir = "";

                    if (string.IsNullOrWhiteSpace(target))
                    {
                        // Try batch launcher
                        string[] batches = Directory.GetFiles(appDir, "*.bat", SearchOption.AllDirectories);
                        if (batches.Length > 0) { target = batches[0]; workDir = Path.GetDirectoryName(batches[0]); }
                    }

                    if (string.IsNullOrWhiteSpace(target))
                    {
                        // Try HTML entry point
                        string[] htmls = Directory.GetFiles(appDir, "index.html", SearchOption.AllDirectories);
                        if (htmls.Length > 0) { target = htmls[0]; workDir = Path.GetDirectoryName(htmls[0]); }
                    }

                    if (string.IsNullOrWhiteSpace(target)) continue;

                    seen.Add(Path.GetFileName(appDir).ToLowerInvariant());
                    var entry = new GameEntry
                    {
                        Name = Titles.Normalize(title),
                        Provider = "itch.io",
                        ProviderKey = "itch",
                        Kind = "StoreGame",
                        Target = target,
                        Arguments = args,
                        WorkingDirectory = workDir,
                        IconPath = target,
                        InstallDir = appDir,
                        Id = gameId ?? "",
                        CoverUrl = coverUrl,
                        Source = "itch-app",
                        Developer = developerName,
                        Year = ExtractYear(publishedAt)
                    };
                    // The storefront page doubles as a metadata provider. Only
                    // fill values the receipt could not supply.
                    EnrichFromStorePage(entry, pageUrl);
                    games.Add(entry);
                }
            }

            if (games.Count == 0) return null;
            return games;
        }

        private static string ExtractJsonField(string json, string field)
        {
            // Simple extraction: find "field": "value" or "field": value
            var match = System.Text.RegularExpressions.Regex.Match(json, "\"" + field + "\"\\s*:\\s*\"([^\"]*)\"");
            if (match.Success) return match.Groups[1].Value;
            match = System.Text.RegularExpressions.Regex.Match(json, "\"" + field + "\"\\s*:\\s*(\\d+)");
            if (match.Success) return match.Groups[1].Value;
            return "";
        }

        private static string ExtractYear(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return "";
            var match = System.Text.RegularExpressions.Regex.Match(value, @"(\d{4})");
            return match.Success ? match.Groups[1].Value : "";
        }

        // itch stores many useful fields in the public game page's "More
        // information" panel. Treat the storefront itself as the highest
        // priority metadata provider so every installed game gets whatever the
        // creator published, without falling back to a guess.
        private static void EnrichFromStorePage(GameEntry game, string pageUrl)
        {
            if (game == null || string.IsNullOrWhiteSpace(pageUrl)) return;
            try
            {
                var request = (HttpWebRequest)WebRequest.Create(pageUrl);
                request.UserAgent = Http.UserAgent;
                request.Timeout = 10000;
                request.ReadWriteTimeout = 10000;
                string html;
                using (var response = request.GetResponse())
                using (var reader = new StreamReader(response.GetResponseStream()))
                {
                    html = reader.ReadToEnd();
                }

                string authors = ExtractInfoRow(html, "Authors");
                if (string.IsNullOrWhiteSpace(authors)) authors = ExtractInfoRow(html, "Author");
                string publisher = ExtractInfoRow(html, "Publisher");
                string genre = ExtractInfoRow(html, "Genre");
                if (string.IsNullOrWhiteSpace(genre)) genre = ExtractInfoRow(html, "Genres");
                string tags = ExtractInfoRow(html, "Tags");

                if (string.IsNullOrWhiteSpace(authors)) authors = ExtractAuthorFromHeader(html);
                if (string.IsNullOrWhiteSpace(authors)) authors = AuthorFromUrl(pageUrl);

                if (!string.IsNullOrWhiteSpace(authors)) game.Developer = authors;
                if (!string.IsNullOrWhiteSpace(publisher)) game.Publisher = publisher;
                // On itch the creator is normally both developer and publisher,
                // unless the page lists a separate publisher.
                if (string.IsNullOrWhiteSpace(game.Publisher)) game.Publisher = game.Developer;
                game.Genres = BuildGenres(genre, tags);
            }
            catch { }
        }

        private static string ExtractInfoRow(string html, string label)
        {
            string pattern = "<tr>\\s*<td[^>]*>" + System.Text.RegularExpressions.Regex.Escape(label)
                + "</td>\\s*<td[^>]*>(.*?)</td>\\s*</tr>";
            var match = System.Text.RegularExpressions.Regex.Match(html, pattern,
                System.Text.RegularExpressions.RegexOptions.Singleline
                | System.Text.RegularExpressions.RegexOptions.IgnoreCase);
            if (!match.Success) return "";
            string value = System.Text.RegularExpressions.Regex.Replace(match.Groups[1].Value, "<[^>]+>", "");
            value = WebUtility.HtmlDecode(value);
            value = System.Text.RegularExpressions.Regex.Replace(value, "\\s+", " ").Trim();
            return value.Trim(' ', ',');
        }

        private static string ExtractAuthorFromHeader(string html)
        {
            var match = System.Text.RegularExpressions.Regex.Match(html,
                "<span[^>]*class=\"[^\"]*full_label[^\"]*\"[^>]*>View all by\\s*(.*?)</span>",
                System.Text.RegularExpressions.RegexOptions.Singleline
                | System.Text.RegularExpressions.RegexOptions.IgnoreCase);
            if (match.Success)
            {
                string value = System.Text.RegularExpressions.Regex.Replace(match.Groups[1].Value, "<[^>]+>", "");
                return System.Text.RegularExpressions.Regex.Replace(WebUtility.HtmlDecode(value), "\\s+", " ").Trim();
            }

            // Fall back to page titles such as "Game by Author".
            match = System.Text.RegularExpressions.Regex.Match(html, "<title>(.*?)</title>",
                System.Text.RegularExpressions.RegexOptions.Singleline
                | System.Text.RegularExpressions.RegexOptions.IgnoreCase);
            if (match.Success)
            {
                string title = System.Text.RegularExpressions.Regex.Replace(
                    WebUtility.HtmlDecode(match.Groups[1].Value), "\\s+", " ").Trim();
                int by = title.LastIndexOf(" by ", StringComparison.OrdinalIgnoreCase);
                if (by >= 0 && by + 4 < title.Length) return title.Substring(by + 4).Trim();
            }
            return "";
        }

        // The page subdomain is the creator's itch username, so it is a useful
        // last resort when the page hides the display name.
        private static string AuthorFromUrl(string pageUrl)
        {
            try
            {
                var uri = new Uri(pageUrl);
                string host = uri.Host;
                int dot = host.IndexOf('.');
                if (dot <= 0) return "";
                string handle = host.Substring(0, dot).Replace('-', ' ').Replace('_', ' ');
                return System.Globalization.CultureInfo.CurrentCulture.TextInfo.ToTitleCase(handle);
            }
            catch { return ""; }
        }

        private static string BuildGenres(string genre, string tags)
        {
            var values = new List<string>();
            if (!string.IsNullOrWhiteSpace(genre))
            {
                values.Add(genre.Trim());
            }
            if (!string.IsNullOrWhiteSpace(tags))
            {
                foreach (var tag in tags.Split(','))
                {
                    string value = tag.Trim();
                    if (value.Length == 0) continue;
                    if (values.Contains(value, StringComparer.OrdinalIgnoreCase)) continue;
                    values.Add(value);
                    if (!string.IsNullOrWhiteSpace(genre) && values.Count >= 3) break;
                    if (string.IsNullOrWhiteSpace(genre) && values.Count >= 4) break;
                }
            }
            return string.Join(", ", values.ToArray());
        }

        private static string FindGameExecutable(string directory, int depth)
        {
            if (depth <= 0 || !Directory.Exists(directory)) return null;
            try
            {
                // Reject runtime helpers
                string[] reject = { "python", "pythonw", "nwjc", "steamcmd", "zsync", "chardetect", "crash", "helper", "setup", "install", "unins", "prereq", "redist", "vcredist", "dxsetup", "ffmpeg", "ffplay", "ffprobe" };
                foreach (var file in Directory.GetFiles(directory, "*.exe"))
                {
                    string name = Path.GetFileNameWithoutExtension(file).ToLowerInvariant();
                    bool skip = false;
                    foreach (var r in reject) { if (name.Contains(r)) { skip = true; break; } }
                    if (skip) continue;
                    return file;
                }
                foreach (var sub in Directory.GetDirectories(directory))
                {
                    string result = FindGameExecutable(sub, depth - 1);
                    if (result != null) return result;
                }
            }
            catch { }
            return null;
        }
    }
}
