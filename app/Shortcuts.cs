using System;
using System.IO;

namespace GamesLibraryManager
{
    public static class Shortcuts
    {
        public static string CreateUrlShortcut(string path, string url, string iconPath)
        {
            var lines = new System.Collections.Generic.List<string>();
            lines.Add("[{000214A0-0000-0000-C000-000000000046}]");
            lines.Add("Prop3=19,2");
            lines.Add("[InternetShortcut]");
            lines.Add("URL=" + url);
            if (!string.IsNullOrWhiteSpace(iconPath) && File.Exists(iconPath))
            {
                lines.Add("IconFile=" + iconPath);
                lines.Add("IconIndex=0");
            }
            string content = string.Join("\r\n", lines) + "\r\n";
            File.WriteAllText(path, content, System.Text.Encoding.Default);
            return path;
        }

        public static string CreateLnkShortcut(string path, string target, string arguments, string workingDir, string iconPath, string description)
        {
            try
            {
                Type shellType = Type.GetTypeFromProgID("WScript.Shell");
                dynamic shell = Activator.CreateInstance(shellType);
                dynamic shortcut = shell.CreateShortcut(path);
                shortcut.TargetPath = target;
                if (!string.IsNullOrWhiteSpace(arguments)) shortcut.Arguments = arguments;
                if (!string.IsNullOrWhiteSpace(workingDir)) shortcut.WorkingDirectory = workingDir;
                if (!string.IsNullOrWhiteSpace(iconPath) && File.Exists(iconPath)) shortcut.IconLocation = iconPath + ",0";
                if (!string.IsNullOrWhiteSpace(description)) shortcut.Description = description;
                shortcut.Save();
                return path;
            }
            catch (Exception ex)
            {
                Console.WriteLine("Lnk creation error: " + ex.Message);
                return null;
            }
        }

        public static bool IsUrlTarget(string target)
        {
            if (string.IsNullOrWhiteSpace(target)) return false;
            return target.Contains("://");
        }
    }
}