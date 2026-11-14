namespace GamesLibraryManager
{
    // Inline SVG icons for buttons. SVG keeps glyphs centered and crisp at any
    // zoom instead of relying on font symbols with inconsistent metrics.
    public static class Icons
    {
        private static string Wrap(string body)
        {
            return "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='currentColor' aria-hidden='true' focusable='false'>" + body + "</svg>";
        }

        public static string Play()
        {
            return Wrap("<path d='M8 5v14l11-7z'/>");
        }

        public static string Gear()
        {
            return Wrap("<path d='M19.14 12.94c.04-.3.06-.61.06-.94s-.02-.64-.07-.94l2.03-1.58a.49.49 0 0 0 .12-.61l-1.92-3.32a.49.49 0 0 0-.59-.22l-2.39.96a7.03 7.03 0 0 0-1.62-.94l-.36-2.54a.48.48 0 0 0-.48-.41h-3.84a.48.48 0 0 0-.48.41l-.36 2.54c-.59.24-1.13.55-1.62.94l-2.39-.96a.48.48 0 0 0-.59.22L2.73 8.87a.48.48 0 0 0 .12.61l2.03 1.58c-.05.3-.07.63-.07.94s.02.64.07.94l-2.03 1.58a.49.49 0 0 0-.12.61l1.92 3.32c.12.22.37.3.59.22l2.39-.96c.5.39 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.48-.41l.36-2.54c.59-.24 1.13-.55 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32a.49.49 0 0 0-.12-.61l-2.03-1.58zM12 15.6A3.6 3.6 0 1 1 12 8.4a3.6 3.6 0 0 1 0 7.2z'/>");
        }

        public static string ArrowLeft()
        {
            return Wrap("<path d='M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z'/>");
        }
    }
}
