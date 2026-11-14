using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;
using System.Web.Script.Serialization;

namespace GamesLibraryManager
{
    public class SteamMetadata
    {
        public string Developer = "";
        public string Publisher = "";
        public string Year = "";
        public string Genres = "";
        public string HeroUrl = "";
    }

    public class GameMetadata
    {
        public string Developer = "";
        public string Publisher = "";
        public string Year = "";
        public string Genres = "";
        public string Rating = "";
        public string CoverUrl = "";
        public string HeroUrl = "";
    }

    public static class Metadata
    {
        private static readonly DateTime Epoch = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);
        private static readonly object CacheLock = new object();
        private static readonly Dictionary<string, GameMetadata> IgdbCache = new Dictionary<string, GameMetadata>(StringComparer.OrdinalIgnoreCase);
        private static readonly Dictionary<string, string> SgdbCoverCache = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        private static readonly Dictionary<string, string> SgdbHeroCache = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        private static readonly Dictionary<string, GameMetadata> VndbCache = new Dictionary<string, GameMetadata>(StringComparer.OrdinalIgnoreCase);
        private static string _igdbToken = "";
        private static DateTime _igdbTokenExpiry = DateTime.MinValue;

        // Enrich a game using metadata providers in priority order. Provider-owned
        // values are never overwritten; remote providers only fill gaps so the
        // same chain works for every storefront, not just Steam.
        public static void Enrich(GameEntry game, string root)
        {
            if (game == null) return;
            if (!NeedsMetadata(game) && !NeedsArt(game)) return;

            string artId = ArtworkId(game);

            // 1. IGDB (keyed) has the broadest developer/publisher/genre/art data.
            if (NeedsMetadata(game) || NeedsArt(game))
            {
                var igdb = GetIgdbMetadata(game.Name);
                ApplyMetadata(game, igdb, artId, root);
            }

            // 2. VNDB (keyless) is the strongest source for visual novels. It is
            //    matched strictly by title so it never mislabels other games.
            if (NeedsMetadata(game) || NeedsArt(game))
            {
                var vndb = GetVndbMetadata(game.Name);
                ApplyMetadata(game, vndb, artId, root);
            }

            // 3. SteamGridDB (keyed) is an artwork-only fallback, also by title.
            if (string.IsNullOrWhiteSpace(game.CoverPath))
            {
                string url = GetSteamGridDbUrl(game.Name, "grids");
                if (!string.IsNullOrWhiteSpace(url))
                {
                    string cover = Artwork.ResolveFromUrl(url, artId + "_cover", root);
                    if (!string.IsNullOrWhiteSpace(cover)) game.CoverPath = cover;
                }
            }
            if (string.IsNullOrWhiteSpace(game.HeroPath) && game.ProviderKey != "itch")
            {
                string url = GetSteamGridDbUrl(game.Name, "heroes");
                if (!string.IsNullOrWhiteSpace(url))
                {
                    string hero = Artwork.ResolveFromUrl(url, artId + "_hero", root);
                    if (!string.IsNullOrWhiteSpace(hero)) game.HeroPath = hero;
                }
            }

            // itch.io covers are square, so they are the one store allowed to
            // reuse the cover as the hero image.
            if (game.ProviderKey == "itch" && string.IsNullOrWhiteSpace(game.HeroPath)
                && !string.IsNullOrWhiteSpace(game.CoverPath))
            {
                game.HeroPath = game.CoverPath;
            }
        }

        private static void ApplyMetadata(GameEntry game, GameMetadata meta, string artId, string root)
        {
            if (meta == null) return;
            if (string.IsNullOrWhiteSpace(game.Developer)) game.Developer = meta.Developer;
            if (string.IsNullOrWhiteSpace(game.Publisher)) game.Publisher = meta.Publisher;
            if (string.IsNullOrWhiteSpace(game.Year)) game.Year = meta.Year;
            if (string.IsNullOrWhiteSpace(game.Genres)) game.Genres = meta.Genres;
            if (string.IsNullOrWhiteSpace(game.Rating)) game.Rating = meta.Rating;

            if (string.IsNullOrWhiteSpace(game.CoverPath) && !string.IsNullOrWhiteSpace(meta.CoverUrl))
            {
                string cover = Artwork.ResolveFromUrl(meta.CoverUrl, artId + "_cover", root);
                if (!string.IsNullOrWhiteSpace(cover)) game.CoverPath = cover;
            }
            if (string.IsNullOrWhiteSpace(game.HeroPath) && !string.IsNullOrWhiteSpace(meta.HeroUrl))
            {
                string hero = Artwork.ResolveFromUrl(meta.HeroUrl, artId + "_hero", root);
                if (!string.IsNullOrWhiteSpace(hero)) game.HeroPath = hero;
            }
        }

        private static bool NeedsMetadata(GameEntry game)
        {
            return string.IsNullOrWhiteSpace(game.Developer)
                || string.IsNullOrWhiteSpace(game.Publisher)
                || string.IsNullOrWhiteSpace(game.Year)
                || string.IsNullOrWhiteSpace(game.Genres)
                || string.IsNullOrWhiteSpace(game.Rating);
        }

        private static bool NeedsArt(GameEntry game)
        {
            return string.IsNullOrWhiteSpace(game.CoverPath)
                || string.IsNullOrWhiteSpace(game.HeroPath);
        }

        private static string ArtworkId(GameEntry game)
        {
            string id = string.IsNullOrWhiteSpace(game.Id) ? Slug(game.Name) : game.Id;
            foreach (char c in Path.GetInvalidFileNameChars()) id = id.Replace(c, '_');
            id = id.Replace(' ', '_');
            string prefix = string.IsNullOrWhiteSpace(game.ProviderKey) ? "game" : game.ProviderKey;
            return prefix + "_" + id;
        }

        private static string Slug(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return "unknown";
            var sb = new StringBuilder();
            foreach (char c in value.ToLowerInvariant())
            {
                if (char.IsLetterOrDigit(c)) sb.Append(c);
                else if (sb.Length > 0 && sb[sb.Length - 1] != '_') sb.Append('_');
            }
            string s = sb.ToString().Trim('_');
            return string.IsNullOrWhiteSpace(s) ? "unknown" : s;
        }

        public static SteamMetadata GetSteamMetadata(string appId)
        {
            var result = new SteamMetadata();
            if (string.IsNullOrWhiteSpace(appId)) return result;
            try
            {
                EnableTls();
                string url = "https://store.steampowered.com/api/appdetails?appids=" + appId;
                string json = HttpGet(url, null, null);
                if (string.IsNullOrWhiteSpace(json)) return result;

                int devIdx = json.IndexOf("\"developers\":[\"");
                if (devIdx >= 0)
                {
                    int start = devIdx + "\"developers\":[\"".Length;
                    int end = json.IndexOf("\"", start);
                    if (end > start) result.Developer = json.Substring(start, end - start);
                }
                int pubIdx = json.IndexOf("\"publishers\":[\"");
                if (pubIdx >= 0)
                {
                    int start = pubIdx + "\"publishers\":[\"".Length;
                    int end = json.IndexOf("\"", start);
                    if (end > start) result.Publisher = json.Substring(start, end - start);
                }
                int rdIdx = json.IndexOf("\"release_date\":{\"coming_soon\":");
                if (rdIdx >= 0)
                {
                    int dateIdx = json.IndexOf("\"date\":\"", rdIdx);
                    if (dateIdx >= 0)
                    {
                        int start = dateIdx + "\"date\":\"".Length;
                        int end = json.IndexOf("\"", start);
                        if (end > start)
                        {
                            string dateStr = json.Substring(start, end - start);
                            var m = System.Text.RegularExpressions.Regex.Match(dateStr, @"(\d{4})");
                            if (m.Success) result.Year = m.Groups[1].Value;
                        }
                    }
                }
                int genIdx = json.IndexOf("\"genres\":[");
                if (genIdx >= 0)
                {
                    var genreNames = new List<string>();
                    int descIdx = json.IndexOf("\"description\":\"", genIdx);
                    int bracketEnd = json.IndexOf("]", genIdx);
                    while (descIdx >= 0 && descIdx < bracketEnd)
                    {
                        int s = descIdx + "\"description\":\"".Length;
                        int e = json.IndexOf("\"", s);
                        if (e > s) genreNames.Add(json.Substring(s, e - s));
                        descIdx = json.IndexOf("\"description\":\"", e);
                        if (descIdx > bracketEnd) break;
                    }
                    result.Genres = string.Join(", ", genreNames.ToArray());
                }
                if (json.Contains("\"background_raw\":\""))
                {
                    result.HeroUrl = "https://cdn.akamai.steamstatic.com/steam/apps/" + appId + "/library_hero.jpg";
                }
            }
            catch { }
            return result;
        }

        // ---- IGDB (works by title for every storefront) ----

        public static GameMetadata GetIgdbMetadata(string title)
        {
            if (string.IsNullOrWhiteSpace(title)) return null;
            lock (CacheLock)
            {
                if (IgdbCache.ContainsKey(title)) return IgdbCache[title];
            }

            string clientId = Secrets.GetSecret("igdbClientId");
            string clientSecret = Secrets.GetSecret("igdbClientSecret");
            if (string.IsNullOrWhiteSpace(clientId) || string.IsNullOrWhiteSpace(clientSecret)) return null;

            string token = GetIgdbToken(clientId, clientSecret);
            if (string.IsNullOrWhiteSpace(token)) return null;

            string safeTitle = title.Replace("\"", " ").Replace("\\", " ").Trim();
            // Exact title lookup first. A fuzzy search can return a different game
            // (for example "Loverse" -> "Making Lovers"), which would attach the
            // wrong metadata, so only an exact normalized match is accepted.
            string body = "where name = \"" + safeTitle + "\"; fields name,first_release_date,genres.name,"
                + "involved_companies.company.name,involved_companies.developer,involved_companies.publisher,"
                + "cover.image_id,artworks.image_id,rating,aggregated_rating; limit 5;";

            GameMetadata meta = null;
            try
            {
                EnableTls();
                var headers = new Dictionary<string, string>();
                headers["Client-ID"] = clientId;
                headers["Authorization"] = "Bearer " + token;
                string json = HttpPost("https://api.igdb.com/v4/games", body, "text/plain", headers);
                meta = ParseIgdbResult(json, title);
            }
            catch { }

            lock (CacheLock)
            {
                IgdbCache[title] = meta;
            }
            return meta;
        }

        private static string GetIgdbToken(string clientId, string clientSecret)
        {
            lock (CacheLock)
            {
                if (!string.IsNullOrWhiteSpace(_igdbToken) && DateTime.UtcNow < _igdbTokenExpiry)
                    return _igdbToken;
            }
            try
            {
                EnableTls();
                string url = "https://id.twitch.tv/oauth2/token?client_id=" + Uri.EscapeDataString(clientId)
                    + "&client_secret=" + Uri.EscapeDataString(clientSecret)
                    + "&grant_type=client_credentials";
                string json = HttpPost(url, "", "application/x-www-form-urlencoded", null);
                var ser = new JavaScriptSerializer();
                var data = ser.Deserialize<Dictionary<string, object>>(json);
                string token = data != null && data.ContainsKey("access_token") ? Convert.ToString(data["access_token"]) : "";
                double expires = data != null && data.ContainsKey("expires_in") ? Convert.ToDouble(data["expires_in"]) : 3600;
                lock (CacheLock)
                {
                    _igdbToken = token;
                    _igdbTokenExpiry = DateTime.UtcNow.AddSeconds(Math.Max(60, expires - 60));
                }
                return token;
            }
            catch { return ""; }
        }

        private static GameMetadata ParseIgdbResult(string json, string title)
        {
            if (string.IsNullOrWhiteSpace(json)) return null;
            var ser = new JavaScriptSerializer();
            ser.MaxJsonLength = int.MaxValue;
            var list = AsArray(ser.Deserialize<object>(json));
            if (list == null || list.Length == 0) return null;

            Dictionary<string, object> best = null;
            string wanted = MatchKey(title);
            foreach (var item in list)
            {
                var d = item as Dictionary<string, object>;
                if (d == null) continue;
                if (MatchKey(Str(Get(d, "name"))) == wanted)
                {
                    best = d;
                    break;
                }
            }
            if (best == null) return null;

            var meta = new GameMetadata();
            meta.Developer = JoinCompanies(Get(best, "involved_companies"), true);
            meta.Publisher = JoinCompanies(Get(best, "involved_companies"), false);

            object frd = Get(best, "first_release_date");
            if (frd != null)
            {
                try
                {
                    double seconds = Convert.ToDouble(frd);
                    meta.Year = Epoch.AddSeconds(seconds).ToString("yyyy");
                }
                catch { }
            }

            meta.Genres = JoinValues(Get(best, "genres"), "name");

            var cover = Get(best, "cover") as Dictionary<string, object>;
            if (cover != null) meta.CoverUrl = IgdbImage(Str(Get(cover, "image_id")), "t_cover_big");

            var artworks = AsArray(Get(best, "artworks"));
            if (artworks != null && artworks.Length > 0)
            {
                var art = artworks[0] as Dictionary<string, object>;
                if (art != null) meta.HeroUrl = IgdbImage(Str(Get(art, "image_id")), "t_1080p");
            }

            object rating = Get(best, "aggregated_rating");
            if (rating == null) rating = Get(best, "rating");
            if (rating != null)
            {
                try
                {
                    double r = Convert.ToDouble(rating);
                    if (r > 0) meta.Rating = ((int)Math.Round(r)).ToString() + "/100";
                }
                catch { }
            }
            return meta;
        }

        private static string IgdbImage(string imageId, string size)
        {
            if (string.IsNullOrWhiteSpace(imageId)) return "";
            return "https://images.igdb.com/igdb/image/upload/" + size + "/" + imageId + ".jpg";
        }

        private static string JoinCompanies(object value, bool developer)
        {
            var arr = AsArray(value);
            if (arr == null) return "";
            var names = new List<string>();
            foreach (var item in arr)
            {
                var d = item as Dictionary<string, object>;
                if (d == null) continue;
                bool flag = ToBool(Get(d, developer ? "developer" : "publisher"));
                if (!flag) continue;
                var company = Get(d, "company") as Dictionary<string, object>;
                string name = company == null ? "" : Str(Get(company, "name"));
                if (!string.IsNullOrWhiteSpace(name) && !names.Contains(name)) names.Add(name);
            }
            return string.Join(", ", names.ToArray());
        }

        private static string JoinValues(object value, string field)
        {
            var arr = AsArray(value);
            if (arr == null) return "";
            var names = new List<string>();
            foreach (var item in arr)
            {
                var d = item as Dictionary<string, object>;
                if (d == null) continue;
                string name = Str(Get(d, field));
                if (!string.IsNullOrWhiteSpace(name) && !names.Contains(name)) names.Add(name);
            }
            return string.Join(", ", names.ToArray());
        }

        private static object Get(Dictionary<string, object> dict, string key)
        {
            if (dict == null) return null;
            object value;
            return dict.TryGetValue(key, out value) ? value : null;
        }

        // JavaScriptSerializer returns ArrayList for JSON arrays, not object[].
        // Normalize both shapes so every parser handles the same data.
        private static object[] AsArray(object value)
        {
            if (value == null) return null;
            var array = value as object[];
            if (array != null) return array;
            var list = value as System.Collections.IList;
            if (list == null) return null;
            var result = new object[list.Count];
            list.CopyTo(result, 0);
            return result;
        }

        private static string Str(object value)
        {
            return value == null ? "" : Convert.ToString(value);
        }

        private static bool ToBool(object value)
        {
            if (value == null) return false;
            try { return Convert.ToBoolean(value); }
            catch { return false; }
        }

        // ---- VNDB (keyless, visual novels, strict title match) ----

        public static GameMetadata GetVndbMetadata(string title)
        {
            if (string.IsNullOrWhiteSpace(title)) return null;
            lock (CacheLock)
            {
                if (VndbCache.ContainsKey(title)) return VndbCache[title];
            }

            string body = "{\"filters\":[\"search\",\"=\",\"" + JsonEscape(title) + "\"],"
                + "\"fields\":\"title,alttitle,released,developers.name,image.url,"
                + "screenshots.url,rating,titles.title,titles.latin\",\"results\":10}";

            GameMetadata meta = null;
            try
            {
                EnableTls();
                string json = HttpPost("https://api.vndb.org/kana/vn", body, "application/json", null);
                meta = ParseVndbResult(json, title);
            }
            catch { }

            lock (CacheLock)
            {
                VndbCache[title] = meta;
            }
            return meta;
        }

        private static GameMetadata ParseVndbResult(string json, string title)
        {
            if (string.IsNullOrWhiteSpace(json)) return null;
            var ser = new JavaScriptSerializer();
            ser.MaxJsonLength = int.MaxValue;
            var root = ser.Deserialize<Dictionary<string, object>>(json);
            var results = AsArray(Get(root, "results"));
            if (results == null) return null;

            Dictionary<string, object> best = null;
            string wanted = MatchKey(title);
            foreach (var item in results)
            {
                var d = item as Dictionary<string, object>;
                if (d == null) continue;
                if (VndbTitleMatches(d, wanted))
                {
                    best = d;
                    break;
                }
            }
            if (best == null) return null;

            var meta = new GameMetadata();
            meta.Developer = JoinValues(Get(best, "developers"), "name");

            string released = Str(Get(best, "released"));
            var yearMatch = System.Text.RegularExpressions.Regex.Match(released, @"(\d{4})");
            if (yearMatch.Success) meta.Year = yearMatch.Groups[1].Value;

            object ratingValue = Get(best, "rating");
            if (ratingValue != null)
            {
                try
                {
                    double r = Convert.ToDouble(ratingValue);
                    if (r > 0) meta.Rating = ((int)Math.Round(r)).ToString() + "/100";
                }
                catch { }
            }

            var image = Get(best, "image") as Dictionary<string, object>;
            if (image != null) meta.CoverUrl = AbsoluteUrl(Str(Get(image, "url")));

            var screenshots = AsArray(Get(best, "screenshots"));
            if (screenshots != null && screenshots.Length > 0)
            {
                var shot = screenshots[0] as Dictionary<string, object>;
                if (shot != null) meta.HeroUrl = AbsoluteUrl(Str(Get(shot, "url")));
            }
            return meta;
        }

        private static bool VndbTitleMatches(Dictionary<string, object> entry, string wanted)
        {
            if (wanted.Length == 0) return false;
            if (MatchKey(Str(Get(entry, "title"))) == wanted) return true;
            if (MatchKey(Str(Get(entry, "alttitle"))) == wanted) return true;
            var titles = AsArray(Get(entry, "titles"));
            if (titles != null)
            {
                foreach (var item in titles)
                {
                    var d = item as Dictionary<string, object>;
                    if (d == null) continue;
                    if (MatchKey(Str(Get(d, "title"))) == wanted) return true;
                    if (MatchKey(Str(Get(d, "latin"))) == wanted) return true;
                }
            }
            return false;
        }

        // Compare titles by letters and digits only so punctuation, spacing and
        // casing never turn an exact match into a false negative.
        private static string MatchKey(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return "";
            var sb = new StringBuilder();
            foreach (char c in value.ToLowerInvariant())
            {
                if (char.IsLetterOrDigit(c)) sb.Append(c);
            }
            return sb.ToString();
        }

        private static string AbsoluteUrl(string url)
        {
            if (string.IsNullOrWhiteSpace(url)) return "";
            if (url.StartsWith("//", StringComparison.Ordinal)) return "https:" + url;
            return url;
        }

        private static string JsonEscape(string value)
        {
            if (value == null) return "";
            var sb = new StringBuilder();
            foreach (char c in value)
            {
                switch (c)
                {
                    case '"': sb.Append("\\\""); break;
                    case '\\': sb.Append("\\\\"); break;
                    case '\b': sb.Append("\\b"); break;
                    case '\f': sb.Append("\\f"); break;
                    case '\n': sb.Append("\\n"); break;
                    case '\r': sb.Append("\\r"); break;
                    case '\t': sb.Append("\\t"); break;
                    default:
                        if (c < ' ') sb.Append("\\u" + ((int)c).ToString("x4"));
                        else sb.Append(c);
                        break;
                }
            }
            return sb.ToString();
        }

        // ---- SteamGridDB (artwork fallback by title) ----

        public static string GetSteamGridDbUrl(string title, string kind)
        {
            if (string.IsNullOrWhiteSpace(title)) return null;
            var cache = kind == "heroes" ? SgdbHeroCache : SgdbCoverCache;
            lock (CacheLock)
            {
                if (cache.ContainsKey(title)) return cache[title];
            }

            string key = Secrets.GetSecret("steamgriddb");
            if (string.IsNullOrWhiteSpace(key)) return null;

            string result = null;
            try
            {
                EnableTls();
                var headers = new Dictionary<string, string>();
                headers["Authorization"] = "Bearer " + key;

                string searchUrl = "https://www.steamgriddb.com/api/v2/search/autocomplete/" + Uri.EscapeDataString(title);
                string searchJson = HttpGet(searchUrl, headers, null);
                var ser = new JavaScriptSerializer();
                ser.MaxJsonLength = int.MaxValue;
                var searchRoot = ser.Deserialize<Dictionary<string, object>>(searchJson);
                string gameId = "";
                if (searchRoot != null)
                {
                    var data = AsArray(Get(searchRoot, "data"));
                    if (data != null && data.Length > 0)
                    {
                        var first = data[0] as Dictionary<string, object>;
                        if (first != null)
                        {
                            object idValue = Get(first, "id");
                            if (idValue != null) gameId = Convert.ToString(idValue);
                        }
                    }
                }

                string assetUrl = "";
                if (!string.IsNullOrWhiteSpace(gameId))
                {
                    assetUrl = "https://www.steamgriddb.com/api/v2/" + kind + "/game/" + gameId;
                    string assetJson = HttpGet(assetUrl, headers, null);
                    var assetRoot = ser.Deserialize<Dictionary<string, object>>(assetJson);
                    if (assetRoot != null)
                    {
                        var data = AsArray(Get(assetRoot, "data"));
                        if (data != null && data.Length > 0)
                        {
                            var first = data[0] as Dictionary<string, object>;
                            if (first != null) result = Str(Get(first, "url"));
                        }
                    }
                }
            }
            catch { }

            lock (CacheLock)
            {
                cache[title] = result;
            }
            return result;
        }

        // ---- HTTP helpers ----

        private static void EnableTls()
        {
            try { ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072; }
            catch { }
        }

        private static string HttpGet(string url, Dictionary<string, string> headers, string contentType)
        {
            using (var client = new TimedWebClient())
            {
                client.Headers.Add("User-Agent", Http.UserAgent);
                if (headers != null)
                {
                    foreach (var kv in headers) client.Headers.Add(kv.Key, kv.Value);
                }
                return client.DownloadString(url);
            }
        }

        private static string HttpPost(string url, string body, string contentType, Dictionary<string, string> headers)
        {
            using (var client = new TimedWebClient())
            {
                client.Headers.Add("User-Agent", Http.UserAgent);
                if (!string.IsNullOrWhiteSpace(contentType)) client.Headers[HttpRequestHeader.ContentType] = contentType;
                if (headers != null)
                {
                    foreach (var kv in headers) client.Headers.Add(kv.Key, kv.Value);
                }
                return client.UploadString(url, "POST", body ?? "");
            }
        }

        private class TimedWebClient : WebClient
        {
            private const int TimeoutMs = 12000;

            protected override WebRequest GetWebRequest(Uri address)
            {
                var request = base.GetWebRequest(address);
                if (request != null)
                {
                    request.Timeout = TimeoutMs;
                    var http = request as HttpWebRequest;
                    if (http != null) http.ReadWriteTimeout = TimeoutMs;
                }
                return request;
            }
        }
    }
}
