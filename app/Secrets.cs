using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace GamesLibraryManager
{
    public static class Secrets
    {
        private static string StorePath
        {
            get
            {
                string baseDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "GamesLibraryManager");
                if (!Directory.Exists(baseDir)) Directory.CreateDirectory(baseDir);
                return Path.Combine(baseDir, "secrets.dat");
            }
        }

        public static Dictionary<string, string> LoadStore()
        {
            var store = new Dictionary<string, string>();
            string path = StorePath;
            if (!File.Exists(path)) return store;
            try
            {
                string raw = File.ReadAllText(path);
                if (string.IsNullOrWhiteSpace(raw)) return store;
                // Simple JSON parse
                foreach (var line in raw.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries))
                {
                    // naive: "key":"value"
                }
                // Use a simple approach: find all "key":"value" pairs
                int i = 0;
                while (i < raw.Length)
                {
                    int k1 = raw.IndexOf('"', i);
                    if (k1 < 0) break;
                    int k2 = raw.IndexOf('"', k1 + 1);
                    if (k2 < 0) break;
                    string key = raw.Substring(k1 + 1, k2 - k1 - 1);
                    int c = raw.IndexOf(':', k2);
                    if (c < 0) break;
                    int v1 = raw.IndexOf('"', c);
                    if (v1 < 0) break;
                    int v2 = raw.IndexOf('"', v1 + 1);
                    if (v2 < 0) break;
                    string val = raw.Substring(v1 + 1, v2 - v1 - 1);
                    store[key] = val;
                    i = v2 + 1;
                }
            }
            catch { }
            return store;
        }

        public static void SaveStore(Dictionary<string, string> store)
        {
            var sb = new System.Text.StringBuilder();
            sb.Append("{");
            bool first = true;
            foreach (var kv in store)
            {
                if (!first) sb.Append(",");
                first = false;
                sb.Append("\"" + kv.Key + "\":\"" + kv.Value + "\"");
            }
            sb.Append("}");
            File.WriteAllText(StorePath, sb.ToString());
        }

        public static void SetSecret(string name, string value)
        {
            if (string.IsNullOrWhiteSpace(name)) return;
            var store = LoadStore();
            byte[] bytes = Encoding.UTF8.GetBytes(value ?? "");
            byte[] protectedBytes = ProtectedData.Protect(bytes, null, DataProtectionScope.CurrentUser);
            store[name] = Convert.ToBase64String(protectedBytes);
            SaveStore(store);
        }

        public static string GetSecret(string name)
        {
            var store = LoadStore();
            if (!store.ContainsKey(name)) return null;
            try
            {
                byte[] bytes = Convert.FromBase64String(store[name]);
                byte[] plain = ProtectedData.Unprotect(bytes, null, DataProtectionScope.CurrentUser);
                return Encoding.UTF8.GetString(plain);
            }
            catch { return null; }
        }

        public static string[] GetSecretNames()
        {
            var store = LoadStore();
            var names = new string[store.Count];
            int i = 0;
            foreach (var key in store.Keys) names[i++] = key;
            return names;
        }

        public static bool HasSecret(string name)
        {
            return LoadStore().ContainsKey(name);
        }
    }
}