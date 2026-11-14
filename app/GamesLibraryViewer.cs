using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace GamesLibraryViewer
{
    [ComVisible(true)]
    [ClassInterface(ClassInterfaceType.AutoDual)]
    public class Launcher
    {
        private static string SecretStorePath()
        {
            string baseDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "GamesLibraryManager");
            if (!Directory.Exists(baseDir)) Directory.CreateDirectory(baseDir);
            return Path.Combine(baseDir, "secrets.dat");
        }

        public void SetSecret(string name, string value)
        {
            if (string.IsNullOrWhiteSpace(name)) return;
            try
            {
                var store = LoadSecretStore();
                byte[] bytes = Encoding.UTF8.GetBytes(value ?? "");
                byte[] protectedBytes = ProtectedData.Protect(bytes, null, DataProtectionScope.CurrentUser);
                store[name] = Convert.ToBase64String(protectedBytes);
                SaveSecretStore(store);
                try { System.IO.File.AppendAllText(@"D:\Games\_library\hostdbg.txt", "Secret stored: " + name + "\n"); } catch { }
            }
            catch (Exception ex)
            {
                try { System.IO.File.AppendAllText(@"D:\Games\_library\hostdbg.txt", "SetSecret EXC: " + ex.Message + "\n"); } catch { }
            }
        }

        public string GetSecretNames()
        {
            var store = LoadSecretStore();
            return string.Join(",", store.Keys);
        }

        public bool HasSecret(string name)
        {
            var store = LoadSecretStore();
            return store.ContainsKey(name);
        }

        private static System.Collections.Generic.Dictionary<string, string> LoadSecretStore()
        {
            var store = new System.Collections.Generic.Dictionary<string, string>();
            string path = SecretStorePath();
            if (!File.Exists(path)) return store;
            try
            {
                string raw = File.ReadAllText(path);
                if (string.IsNullOrWhiteSpace(raw)) return store;
                // Simple JSON parse: keys are quoted strings.
                // Use a minimal approach: split by lines.
                // Actually, use System.Web.Script.Serialization if available; fallback to manual.
                // We'll use a simple regex to extract "key": "value".
                foreach (System.Text.RegularExpressions.Match m in System.Text.RegularExpressions.Regex.Matches(raw, "\"([^\"]+)\"\\s*:\\s*\"([^\"]*)\""))
                {
                    store[m.Groups[1].Value] = m.Groups[2].Value;
                }
            }
            catch { }
            return store;
        }

        private static void SaveSecretStore(System.Collections.Generic.Dictionary<string, string> store)
        {
            string path = SecretStorePath();
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
            File.WriteAllText(path, sb.ToString());
        }

        public void Launch(string path)
        {
            try { System.IO.File.AppendAllText(@"D:\Games\_library\hostdbg.txt", "Launch called: " + path + "\n"); } catch { }
            if (string.IsNullOrWhiteSpace(path)) return;
            System.Threading.Tasks.Task.Run(() =>
            {
                try
                {
                    var psi = new System.Diagnostics.ProcessStartInfo(path) { UseShellExecute = true };
                    System.Diagnostics.Process.Start(psi);
                    try { System.IO.File.AppendAllText(@"D:\Games\_library\hostdbg.txt", "Started OK: " + path + "\n"); } catch { }
                }
                catch (Exception ex)
                {
                    try { System.IO.File.AppendAllText(@"D:\Games\_library\hostdbg.txt", "EXC: " + ex.Message + "\n"); } catch { }
                }
            });
        }

        public void Rebuild()
        {
            // Legacy script-based rebuild removed. The C# app performs scan/build on launch.
            // Keep this method as a safe no-op for compatibility with existing UI messages.
            try { System.IO.File.AppendAllText(@"D:\Games\_library\hostdbg.txt", "Rebuild requested (legacy rebuild removed; restart app to rescan)\n"); } catch { }
        }

        public void Log(string msg)
        {
            try { System.IO.File.AppendAllText(@"D:\Games\_library\hostdbg.txt", msg + "\n"); } catch { }
        }
    }

    public class MainForm : Form
    {
        private WebView2 wv;

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
            Load += MainForm_Load;
            this.Tag = url;
        }

        private async void MainForm_Load(object sender, EventArgs e)
        {
            try
            {
                await wv.EnsureCoreWebView2Async();
                try { System.IO.File.AppendAllText(@"D:\Games\_library\hostdbg.txt", "CoreWebView2 ready\n"); } catch { }
                wv.CoreWebView2.AddHostObjectToScript("launcher", new Launcher());
                try { System.IO.File.AppendAllText(@"D:\Games\_library\hostdbg.txt", "Host object added\n"); } catch { }
                wv.CoreWebView2.WebMessageReceived += (ss, ee) =>
                {
                    try
                    {
                        string msg = ee.TryGetWebMessageAsString();
                        try { System.IO.File.AppendAllText(@"D:\Games\_library\hostdbg.txt", "MSG: " + msg + "\n"); } catch { }
                        if (msg.Contains("\"launch\""))
                        {
                            int q1 = msg.LastIndexOf("\"", msg.Length - 1);
                            int q2 = msg.LastIndexOf("\"", q1 - 1);
                            if (q1 > q2 && q2 >= 0)
                            {
                                string path = msg.Substring(q2 + 1, q1 - q2 - 1).Replace("\\\\", "\\");
                                new Launcher().Launch(path);
                            }
                        }
                        else if (msg.Contains("\"rebuild\""))
                        {
                            new Launcher().Rebuild();
                        }
                        else if (msg.Contains("\"setSecret\""))
                        {
                            // Extract name and value from JSON.
                            try
                            {
                                // naive parse
                                int ni = msg.IndexOf("\"name\"");
                                int vi = msg.IndexOf("\"value\"");
                                string name = "", value = "";
                                if (ni >= 0)
                                {
                                    int q1 = msg.IndexOf("\"", ni + 6);
                                    int q2 = msg.IndexOf("\"", q1 + 1);
                                    if (q1 >= 0 && q2 > q1) name = msg.Substring(q1 + 1, q2 - q1 - 1);
                                }
                                if (vi >= 0)
                                {
                                    int q1 = msg.IndexOf("\"", vi + 7);
                                    int q2 = msg.IndexOf("\"", q1 + 1);
                                    if (q1 >= 0 && q2 > q1) value = msg.Substring(q1 + 1, q2 - q1 - 1);
                                }
                                new Launcher().SetSecret(name, value);
                            }
                            catch { }
                        }
                    }
                    catch (Exception ex)
                    {
                        try { System.IO.File.AppendAllText(@"D:\Games\_library\hostdbg.txt", "MSG EXC: " + ex.Message + "\n"); } catch { }
                    }
                };
                wv.CoreWebView2.NavigationCompleted += (ss, ee) =>
                {
                    try { System.IO.File.AppendAllText(@"D:\Games\_library\hostdbg.txt", "NavCompleted: " + ee.IsSuccess + " " + ee.WebErrorStatus + "\n"); } catch { }
                };
                wv.Source = new Uri((string)this.Tag);
            }
            catch (Exception ex)
            {
                try { System.IO.File.AppendAllText(@"D:\Games\_library\hostdbg.txt", "LOAD EXC: " + ex.ToString() + "\n"); } catch { }
                try { MessageBox.Show("WebView2 init failed: " + ex.Message, "Games Library"); } catch { }
            }
        }
    }

    internal static class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            try
            {
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                string url = "file:///" + AppDomain.CurrentDomain.BaseDirectory.Replace("\\", "/") + "index.html";
                if (args.Length > 0 && !string.IsNullOrWhiteSpace(args[0])) url = args[0];
                Application.Run(new MainForm(url));
            }
            catch (Exception ex)
            {
                try { System.IO.File.WriteAllText(@"D:\Games\_library\hostdbg.txt", "MAIN EXC: " + ex.ToString()); } catch { }
            }
        }
    }
}