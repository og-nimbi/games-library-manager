using System;
using System.IO;
using System.Text.RegularExpressions;
namespace GamesLibraryManager
{
    public static class Titles
    {
        public static string Normalize(string title, string source = "", string id = "", string installDir = "")
        {
            if (string.IsNullOrWhiteSpace(title)) return title;

            // Curated overrides
            string overrideTitle = GetCuratedOverride(title, source, id, installDir);
            if (!string.IsNullOrWhiteSpace(overrideTitle)) return overrideTitle;

            string t = title.Trim();

            // Locale apostrophes -> ASCII
            t = Regex.Replace(t, @"[\u00B4\u2018\u2019\u02BC]", "'");

            // Remove leading metadata tags such as [18+, NO AI ART!], [Demo], or [v1.2].
            var tagPattern = @"^\s*\[([^\]]*)\]\s*";
            while (Regex.IsMatch(t, tagPattern))
            {
                var m = Regex.Match(t, tagPattern);
                string tagText = m.Groups[1].Value;
                if (!Regex.IsMatch(tagText, @"(?i)(18\+|nsfw|adult|uncensored|no\s+ai|ai\s+art|free|demo|patreon|early\s+access|release|version|update|repack|^v?\d)")) break;
                t = t.Substring(m.Length);
            }

            // Version and build markers
            t = Regex.Replace(t, @"(?i)\bv\d+\.\d+(?:\.\d+)*[a-z]?\b", " ");
            t = Regex.Replace(t, @"(?i)\bv\d{3,}[a-z]?\b", " ");
            t = Regex.Replace(t, @"(?i)\b(ver|version)\.?\s*\d+(?:\.\d+)*[a-z]?\b", " ");
            t = Regex.Replace(t, @"(?i)\b(build|rev|revision)\s*\d+\b", " ");

            // Release dates
            t = Regex.Replace(t, @"(?i)[,;]?\s*\b(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?\s+(19|20)\d{2}\b\.?", " ");

            // Marketing noise
            t = Regex.Replace(t, @"(?i)\bover\s+\d+\s+(?:animations?|images?|scenes?|hours?)\b!?", " ");
            t = Regex.Replace(t, @"(?i)\b\d+\+?\s+(?:animations?|images?|scenes?)\b!?", " ");
            t = Regex.Replace(t, @"(?i)\b(?:windows\s+)?free\s+version\b", " ");
            t = Regex.Replace(t, @"(?i)\b(?:full|final|complete)\s+(?:game|version|release)\b", " ");
            t = Regex.Replace(t, @"(?i)\s*[-:]\s*a\s+free[- ]to[- ]play\s+(?:visual\s+novel|game)\s*$", " ");
            t = Regex.Replace(t, @"(?i)\s*[-:]\s*(?:early\s+access|uncensored\s+patch|repack)\s*$", " ");

            // Parenthetical or bracketed metadata groups
            t = Regex.Replace(t, @"(?i)\s*[\(\[]([^\)\]]*(?:18\+|nsfw|adult|uncensored|patched|repack|update|version|windows|free|demo|early\s+access|patreon|release)[^\)\]]*)[\)\]]", " ");

            // Normalize " - " separators to ": "
            t = Regex.Replace(t, @"\s+-\s*(?=\S)", ": ");

            // Tidy whitespace
            t = Regex.Replace(t, @"\s*,\s*(?=,|$)", "");
            t = Regex.Replace(t, @"^\s*[,;:|\-\u2013\u2014]+\s*", "");
            t = Regex.Replace(t, @"\s*[,;:|\-]+\s*$", "");
            t = Regex.Replace(t, @"\s{2,}", " ");
            t = t.Trim().TrimEnd('.', ',', ';', ':', '!', '?', '-').Trim();

            if (string.IsNullOrWhiteSpace(t)) t = title.Trim();

            // Strip emoji (non-BMP)
            t = Regex.Replace(t, @"[\uD800-\uDBFF][\uDC00-\uDFFF]", "");
            t = t.Trim();

            return t;
        }

        private static string GetCuratedOverride(string title, string source, string id, string installDir)
        {
            // Titles that must stay exactly as published
            if (source != null && id != null)
            {
                string key = (source.ToLowerInvariant() + "|" + id);
                if (key == "steam-appmanifest|1577420") return "Love Sucks: Night One";
                if (key == "steam-appmanifest|1719310") return "Love Sucks: Night Two";
                if (key == "steam-appmanifest|421670") return "CUPID: A free to play Visual Novel";
            }

            if (title != null)
            {
                if (title.Equals("Love Sucks: Night One", StringComparison.OrdinalIgnoreCase)) return "Love Sucks: Night One";
                if (title.Equals("Love Sucks: Night Two", StringComparison.OrdinalIgnoreCase)) return "Love Sucks: Night Two";
                if (title.Equals("CUPID - A free to play Visual Novel", StringComparison.OrdinalIgnoreCase)) return "CUPID: A free to play Visual Novel";
            }

            string folder = "";
            if (!string.IsNullOrWhiteSpace(installDir))
            {
                try { folder = Path.GetFileName(Path.GetFullPath(installDir)); } catch { folder = ""; }
            }

            // itch.io: Relicts of Aeson
            if (source != null && source.Equals("itch-app", StringComparison.OrdinalIgnoreCase) && id == "1185708") return "Relicts of Aeson";
            if (folder.Equals("relicts-auf-aeson", StringComparison.OrdinalIgnoreCase)) return "Relicts of Aeson";

            // itch.io: MyFutaFamily
            if (source != null && source.Equals("itch-app", StringComparison.OrdinalIgnoreCase) && folder.Equals("myfutafamily", StringComparison.OrdinalIgnoreCase)) return "My Futa Family";
            if (folder.Equals("myfutafamily", StringComparison.OrdinalIgnoreCase)) return "My Futa Family";
            if (title != null && title.Equals("MyFutaFamily", StringComparison.OrdinalIgnoreCase)) return "My Futa Family";

            // Steam: pact with a witch
            if (source != null && source.Equals("steam-appmanifest", StringComparison.OrdinalIgnoreCase) && id == "865570") return "Pact With a Witch";
            if (title != null && title.Equals("pact with a witch", StringComparison.OrdinalIgnoreCase)) return "Pact With a Witch";

            // Steam: CUPID
            if (source != null && source.Equals("steam-appmanifest", StringComparison.OrdinalIgnoreCase) && id == "421670") return "CUPID: A free to play Visual Novel";
            if (title != null && title.Equals("CUPID - A free to play Visual Novel", StringComparison.OrdinalIgnoreCase)) return "CUPID: A free to play Visual Novel";

            // Steam: Love Kami
            if (source != null && source.Equals("steam-appmanifest", StringComparison.OrdinalIgnoreCase) && id == "547340") return "Love Kami: Divinity Stage";
            if (title != null && Regex.IsMatch(title, @"(?i)^\s*LoveKami\s*-\s*Divinity\s+Stage-?\s*$")) return "Love Kami: Divinity Stage";

            return null;
        }
    }
}
