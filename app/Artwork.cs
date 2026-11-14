using System;
using System.IO;
using System.Net;

namespace GamesLibraryManager
{
    public static class Artwork
    {
        public static string ResolveSteamCover(string appId, string root)
        {
            if (string.IsNullOrWhiteSpace(appId)) return null;
            string url = "https://cdn.akamai.steamstatic.com/steam/apps/" + appId + "/header.jpg";
            string dir = Path.Combine(root, "_library", "artwork", "metadata");
            Directory.CreateDirectory(dir);
            string file = Path.Combine(dir, "steam_" + appId + "_cover.jpg");
            if (File.Exists(file)) return "_library/artwork/metadata/steam_" + appId + "_cover.jpg".Replace("_library/", "");
            try
            {
                using (var client = new WebClient())
                {
                    client.Headers.Add("User-Agent", Http.UserAgent);
                    client.DownloadFile(url, file);
                }
                if (File.Exists(file) && new FileInfo(file).Length > 64)
                    return "artwork/metadata/steam_" + appId + "_cover.jpg";
            }
            catch { }
            return null;
        }

        public static string ResolveSteamHero(string appId, string root)
        {
            if (string.IsNullOrWhiteSpace(appId)) return null;
            string url = "https://cdn.akamai.steamstatic.com/steam/apps/" + appId + "/library_hero.jpg";
            string dir = Path.Combine(root, "_library", "artwork", "metadata");
            Directory.CreateDirectory(dir);
            string file = Path.Combine(dir, "steam_" + appId + "_hero.jpg");
            if (File.Exists(file)) return "artwork/metadata/steam_" + appId + "_hero.jpg";
            try
            {
                using (var client = new WebClient())
                {
                    client.Headers.Add("User-Agent", Http.UserAgent);
                    client.DownloadFile(url, file);
                }
                if (File.Exists(file) && new FileInfo(file).Length > 64)
                    return "artwork/metadata/steam_" + appId + "_hero.jpg";
            }
            catch { }
            return null;
        }

        public static string ResolveItchCover(string coverUrl, string id, string root)
        {
            if (string.IsNullOrWhiteSpace(coverUrl)) return null;
            string dir = Path.Combine(root, "_library", "artwork", "metadata");
            Directory.CreateDirectory(dir);
            string ext = ".jpg";
            if (coverUrl.EndsWith(".png", StringComparison.OrdinalIgnoreCase)) ext = ".png";
            else if (coverUrl.EndsWith(".gif", StringComparison.OrdinalIgnoreCase)) ext = ".gif";
            string file = Path.Combine(dir, "itch_" + id + ext);
            string rel = "artwork/metadata/itch_" + id + ext;
            if (File.Exists(file)) return rel;
            try
            {
                using (var client = new WebClient())
                {
                    client.Headers.Add("User-Agent", Http.UserAgent);
                    client.DownloadFile(coverUrl, file);
                }
                if (File.Exists(file) && new FileInfo(file).Length > 64) return rel;
            }
            catch { }
            return null;
        }
        public static string ResolveFromUrl(string url, string id, string root)
        {
            if (string.IsNullOrWhiteSpace(url)) return null;
            string dir = Path.Combine(root, "_library", "artwork", "metadata");
            Directory.CreateDirectory(dir);
            string ext = ".jpg";
            if (url.EndsWith(".png", StringComparison.OrdinalIgnoreCase)) ext = ".png";
            else if (url.EndsWith(".gif", StringComparison.OrdinalIgnoreCase)) ext = ".gif";
            else if (url.EndsWith(".webp", StringComparison.OrdinalIgnoreCase)) ext = ".jpg";
            string file = Path.Combine(dir, id + ext);
            string rel = "artwork/metadata/" + id + ext;
            if (File.Exists(file)) return rel;
            try
            {
                using (var client = new WebClient())
                {
                    client.Headers.Add("User-Agent", Http.UserAgent);
                    client.DownloadFile(url, file);
                }
                if (File.Exists(file) && new FileInfo(file).Length > 64) return rel;
            }
            catch { }
            return null;
        }
    }
}
