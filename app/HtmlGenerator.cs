using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace GamesLibraryManager
{
    public static class HtmlGenerator
    {
        public static string GenerateIndex(List<GameEntry> games, string generatedAt, Dictionary<string, string> launchers)
        {
            var sb = new StringBuilder();
            sb.Append("<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'>");
            sb.Append("<meta name='viewport' content='width=device-width, initial-scale=1'>");
            sb.Append("<title>Games Library</title>");
            sb.Append("<style>");
            // Inline essential CSS
            sb.Append("body{background:#0b1020;color:#e8ecff;font-family:system-ui,-apple-system,'Segoe UI',sans-serif;margin:0;padding:24px}");
            sb.Append(".bar{display:flex;flex-direction:column;gap:8px;margin-bottom:16px;padding:24px 24px 0}");
            sb.Append(".bar h1{margin:0 0 4px;font-size:1.9rem;font-weight:700;background:linear-gradient(120deg,#fff,#7c8cff,#c06bff);-webkit-background-clip:text;background-clip:text;color:transparent}");
            sb.Append(".sub{color:#9aa4c7;font-size:.9rem}");
            sb.Append(".toolbar{display:flex;flex-wrap:wrap;gap:10px;align-items:center;margin-top:4px}");
            sb.Append("#search{padding:10px 16px;border-radius:999px;border:1px solid rgba(255,255,255,.16);background:rgba(255,255,255,.07);color:#e8ecff}");
            sb.Append(".chips{display:flex;flex-wrap:wrap;gap:6px}");
            sb.Append(".chip,.sort-pill{padding:7px 14px;border-radius:999px;border:1px solid rgba(255,255,255,.16);background:rgba(255,255,255,.07);color:#e8ecff;cursor:pointer;font-size:.8rem;backdrop-filter:blur(16px)}");
            sb.Append(".chip--active,.sort-pill--active{background:linear-gradient(120deg,#7c8cff,#c06bff);border-color:transparent;color:#fff;box-shadow:0 0 16px rgba(124,140,255,.35)}");
            // Shared button base: every button-like control centers its contents.
            sb.Append("button,.btn{display:inline-flex;align-items:center;justify-content:center;gap:4px;text-align:center;font-family:inherit;line-height:1;text-decoration:none;box-sizing:border-box}");
            sb.Append(".btn{padding:7px 14px;border-radius:999px;border:1px solid rgba(255,255,255,.16);background:rgba(255,255,255,.07);color:#e8ecff;cursor:pointer;font-size:.8rem;backdrop-filter:blur(16px);transition:transform .15s ease,box-shadow .15s ease,border-color .15s ease}");
            sb.Append(".btn:hover{transform:translateY(-1px);border-color:rgba(255,255,255,.24)}");
            sb.Append(".btn--primary{background:linear-gradient(120deg,#7c8cff,#c06bff);border-color:transparent;color:#fff}");
            sb.Append(".btn--primary:hover{box-shadow:0 0 16px rgba(124,140,255,.35)}");
            sb.Append(".btn--icon{width:24px;height:24px;min-width:24px;padding:0;font-size:.85rem}");
            sb.Append(".btn--floating{position:fixed;right:24px;bottom:24px;z-index:20;width:48px;height:48px;min-width:48px;padding:0;border-radius:50%;font-size:1.35rem;box-shadow:0 16px 48px rgba(0,0,0,.5),0 0 24px rgba(124,140,255,.35)}");
            sb.Append(".btn svg{width:16px;height:16px;display:block;fill:currentColor;pointer-events:none}");
            sb.Append(".btn--floating svg{width:22px;height:22px}");
            sb.Append(".sorts{display:flex;gap:6px;margin-left:auto}");
            sb.Append(".layout{display:flex;gap:18px;align-items:flex-start;padding:0 24px 24px}");
            sb.Append(".layout__main{flex:1;min-width:0}");
            sb.Append(".grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:14px}");
            sb.Append(".card{background:rgba(255,255,255,.07);border:1px solid rgba(255,255,255,.16);border-radius:14px;overflow:hidden;cursor:pointer;backdrop-filter:blur(16px);box-shadow:0 8px 32px rgba(0,0,0,.35);transition:transform .18s ease,box-shadow .18s ease}");
            sb.Append(".card:hover{transform:translateY(-4px);border-color:rgba(255,255,255,.24);box-shadow:0 16px 48px rgba(0,0,0,.5),0 0 24px rgba(124,140,255,.35)}");
            sb.Append(".card__cover{aspect-ratio:1/1;object-fit:fill;width:100%}");
            sb.Append(".card__title{font-size:.85rem;padding:8px 10px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;font-weight:500}");
            sb.Append(".card__provider{font-size:.72rem;color:#9aa4c7;padding:0 10px 10px}");
            sb.Append(".card__actions{display:flex;align-items:center;gap:6px;padding:6px 8px 8px}");
            sb.Append(".card__actions button{display:inline-flex;align-items:center;justify-content:center;height:24px;padding:0 10px;font-size:.72rem;line-height:1;border-radius:999px;border:1px solid rgba(255,255,255,.16);background:rgba(255,255,255,.07);color:#e8ecff;cursor:pointer}");
            sb.Append(".card__actions .play-btn{background:linear-gradient(120deg,#7c8cff,#c06bff);border:none;color:#fff;flex:0 0 auto}");
            sb.Append(".card__actions .cog-btn{width:24px;min-width:24px;padding:0;flex:0 0 auto}");
            sb.Append(".card__placeholder{aspect-ratio:2/3;display:flex;align-items:center;justify-content:center;background:linear-gradient(135deg,#7c8cff,#c06bff);color:#fff;font-size:.8rem;text-align:center;padding:8px}");
            sb.Append(".sidebar{width:360px;flex-shrink:0;background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.16);border-radius:14px;padding:20px;position:sticky;top:16px;max-height:calc(100vh-32px);overflow-y:auto;backdrop-filter:blur(24px);box-shadow:0 16px 48px rgba(0,0,0,.5)}");
            sb.Append(".sidebar.hidden{display:none}");
            sb.Append(".sidebar__header{display:flex;align-items:center;justify-content:space-between;margin-bottom:12px}");
            sb.Append(".sidebar__heading{font-size:1.1rem;font-weight:600}");
            sb.Append(".sidebar__hero{width:100%;aspect-ratio:16/9;object-fit:fill;border-radius:14px;margin-bottom:12px;background:rgba(255,255,255,.07);box-shadow:0 8px 32px rgba(0,0,0,.35)}");
            sb.Append(".sidebar__title{margin:0 0 8px;font-size:1.35rem;font-weight:700}");
            sb.Append(".sidebar__meta{color:#9aa4c7;font-size:.85rem;margin-bottom:16px;line-height:1.7}");
            sb.Append(".meta-row{display:flex;gap:8px;margin:4px 0;font-size:.85rem}");
            sb.Append(".meta-label{color:#9aa4c7;font-weight:600;min-width:80px}");
            sb.Append(".meta-value{color:#e8ecff}");
            sb.Append(".clear-btn{padding:8px 16px;border-radius:999px;border:1px solid rgba(255,255,255,.16);background:rgba(255,255,255,.07);color:#e8ecff;cursor:pointer}");
            sb.Append(".providers{margin:0 24px 16px}");
            sb.Append(".providers h2{margin:0 0 10px;font-size:1.1rem;font-weight:600}");
            sb.Append(".provider-tiles{display:grid;grid-template-columns:repeat(auto-fill,minmax(130px,1fr));gap:10px}");
            sb.Append(".provider-tile{background:rgba(255,255,255,.07);border:1px solid rgba(255,255,255,.16);border-radius:10px;padding:14px 10px;text-align:center;cursor:pointer;backdrop-filter:blur(16px);box-shadow:0 8px 32px rgba(0,0,0,.35);transition:transform .15s ease,box-shadow .15s ease;min-height:60px;display:flex;align-items:center;justify-content:center;font-family:inherit;appearance:none}");
            sb.Append(".provider-tile:hover{transform:translateY(-2px);border-color:rgba(255,255,255,.24);box-shadow:0 16px 48px rgba(0,0,0,.5),0 0 24px rgba(124,140,255,.35)}");
            sb.Append(".provider-tile--missing{opacity:.45;cursor:not-allowed}");
            sb.Append(".provider-tile--missing:hover{transform:none;border-color:rgba(255,255,255,.16);box-shadow:0 8px 32px rgba(0,0,0,.35)}");
            sb.Append(".provider-tile__title{font-size:.85rem;font-weight:600;color:#e8ecff;white-space:normal;word-break:break-word;line-height:1.3}");
            sb.Append("</style></head><body>");

            // Header
            sb.Append("<header class='bar'><div class='bar__brand'><h1>Games Library</h1></div>");
            sb.Append("<div class='sub'><span id='result-count'>" + games.Count + " games</span> &middot; generated " + HtmlEncode(generatedAt) + "</div>");
            sb.Append("<div class='toolbar'><input id='search' type='search' placeholder='Search games...'>");
            sb.Append("<div id='chips' class='chips' aria-label='Filter by store'></div>");
            sb.Append("<div id='sorts' class='sorts' aria-label='Sort'>");
            sb.Append("<button class='sort-pill sort-pill--active' data-sort='name'>Name</button>");
            sb.Append("<button class='sort-pill' data-sort='provider'>Store</button></div></div></header>");

            // Provider tiles
            var providers = new SortedSet<string>();
            foreach (var g in games) providers.Add(g.Provider);
            sb.Append("<section class='providers'><h2>Launchers</h2><div class='provider-tiles'>");
            foreach (var p in providers)
            {
                string launcherPath = "";
                if (launchers != null && launchers.ContainsKey(p)) launcherPath = launchers[p] ?? "";
                string tileClass = string.IsNullOrWhiteSpace(launcherPath)
                    ? "provider-tile provider-tile--missing"
                    : "provider-tile";
                string title = string.IsNullOrWhiteSpace(launcherPath) ? "Launcher not found" : "Launch " + p;
                sb.Append("<button type='button' class='" + tileClass + "' data-provider='" + HtmlEncode(p)
                    + "' data-launch='" + HtmlEncode(launcherPath) + "' title='" + HtmlEncode(title)
                    + "' onclick=\"launchLauncher(this)\"><div class='provider-tile__title'>" + HtmlEncode(p) + "</div></button>");
            }
            sb.Append("</div></section>");

            // Main layout + sidebar
            sb.Append("<div class='layout'><main id='grid' class='grid layout__main' aria-label='Games'></main>");
            sb.Append("<aside id='sidebar' class='sidebar hidden' aria-label='Game details'>");
            sb.Append("<div class='sidebar__header'><span class='sidebar__heading'>Details</span></div>");
            sb.Append("<div id='sidebar-content'>");
            sb.Append("<img id='sidebar-hero' class='sidebar__hero' alt=''>");
            sb.Append("<h2 id='sidebar-title' class='sidebar__title'></h2>");
            sb.Append("<div id='sidebar-meta' class='sidebar__meta'></div>");
            sb.Append("<button id='clear-btn' class='clear-btn'>Clear selection</button>");
            sb.Append("</div></aside></div>");

            // Floating settings link (uses the same button system as everything else)
            sb.Append("<a href='settings.html' class='btn btn--primary btn--floating' title='App settings' aria-label='App settings'>" + Icons.Gear() + "</a>");

            // Script
            sb.Append("<script>");
            sb.Append("const entries = " + ToJson(games) + ";");
            sb.Append("const ICON_PLAY = `" + Icons.Play() + "`;");
            sb.Append("const ICON_COG = `" + Icons.Gear() + "`;");
            sb.Append(@"
const imageCache = new Map();
let activeProvider = '';
let activeSort = 'name';
let query = '';

function el(tag, cls, text) { const n = document.createElement(tag); if (cls) n.className = cls; if (text != null) n.textContent = text; return n; }

function launch(shortcut) {
  if (!shortcut) return;
  const path = shortcut.replace(/\//g, '\\\\');
  if (window.chrome && window.chrome.webview) {
    try { window.chrome.webview.postMessage(JSON.stringify({ action: 'launch', path: path })); return; } catch (e) { }
  }
}

function launchLauncher(btn) {
  if (!btn) return;
  launch(btn.getAttribute('data-launch') || '');
}
window.launchLauncher = launchLauncher;

function card(e) {
  const c = el('article', 'card');
  if (e.cover) {
    const img = el('img', 'card__cover');
    img.loading = 'lazy';
    img.alt = e.title || '';
    img.src = e.cover;
    img.onerror = function () { img.replaceWith(el('div', 'card__cover card__placeholder', 'No art')); };
    c.appendChild(img);
  } else {
    c.appendChild(el('div', 'card__cover card__placeholder', 'No art'));
  }
  c.appendChild(el('div', 'card__title', e.title || ''));
  if (e.provider) c.appendChild(el('div', 'card__provider', e.provider));
  const actions = el('div', 'card__actions');
  const playBtn = el('button', 'btn btn--primary play-btn');
  playBtn.type = 'button';
  playBtn.title = 'Play';
  playBtn.setAttribute('aria-label', 'Play');
  playBtn.innerHTML = ICON_PLAY;
  playBtn.addEventListener('click', function (ev) { ev.stopPropagation(); launch(e.shortcut); });
  actions.appendChild(playBtn);
  const cogBtn = el('button', 'btn btn--icon cog-btn');
  cogBtn.type = 'button';
  cogBtn.title = 'Edit game settings';
  cogBtn.setAttribute('aria-label', 'Game settings');
  cogBtn.innerHTML = ICON_COG;
  cogBtn.addEventListener('click', function (ev) { ev.stopPropagation(); });
  actions.appendChild(cogBtn);
  c.appendChild(actions);
  c.addEventListener('click', function () { selectEntry(e); });
  return c;
}

function visibleEntries() {
  let list = entries.slice();
  if (activeProvider) list = list.filter(function (e) { return e.provider === activeProvider; });
  if (query) {
    const q = query.toLowerCase();
    list = list.filter(function (e) { return (e.title || '').toLowerCase().indexOf(q) !== -1; });
  }
  list.sort(function (a, b) {
    if (activeSort === 'provider') {
      const byProvider = (a.provider || '').localeCompare(b.provider || '');
      if (byProvider !== 0) return byProvider;
    }
    return (a.title || '').toLowerCase().localeCompare((b.title || '').toLowerCase());
  });
  return list;
}

function render() {
  const root = document.getElementById('grid');
  if (!root) return;
  root.innerHTML = '';
  const list = visibleEntries();
  const frag = document.createDocumentFragment();
  for (let i = 0; i < list.length; i++) frag.appendChild(card(list[i]));
  root.appendChild(frag);
  const countEl = document.getElementById('result-count');
  if (countEl) countEl.textContent = list.length + (list.length === 1 ? ' game' : ' games');
}

function renderChips() {
  const chips = document.getElementById('chips');
  if (!chips) return;
  chips.innerHTML = '';
  const counts = {};
  for (let i = 0; i < entries.length; i++) {
    const p = entries[i].provider || 'Other';
    counts[p] = (counts[p] || 0) + 1;
  }
  const names = Object.keys(counts).sort();
  const makeChip = function (label, value) {
    const b = el('button', 'chip' + (activeProvider === value ? ' chip--active' : ''), label);
    b.type = 'button';
    b.addEventListener('click', function () { setProvider(value); });
    return b;
  };
  chips.appendChild(makeChip('All ' + entries.length, ''));
  for (let i = 0; i < names.length; i++) chips.appendChild(makeChip(names[i] + ' ' + counts[names[i]], names[i]));
}

function setProvider(p) {
  activeProvider = p || '';
  renderChips();
  render();
}
window.filterProvider = setProvider;

const search = document.getElementById('search');
if (search) search.addEventListener('input', function () { query = search.value || ''; render(); });

const sortButtons = document.querySelectorAll('.sort-pill');
for (let i = 0; i < sortButtons.length; i++) {
  sortButtons[i].addEventListener('click', function () {
    activeSort = this.getAttribute('data-sort') || 'name';
    for (let j = 0; j < sortButtons.length; j++) sortButtons[j].classList.remove('sort-pill--active');
    this.classList.add('sort-pill--active');
    render();
  });
}

const sidebar = document.getElementById('sidebar');
const sidebarHero = document.getElementById('sidebar-hero');
const sidebarTitle = document.getElementById('sidebar-title');
const sidebarMeta = document.getElementById('sidebar-meta');
const clearBtn = document.getElementById('clear-btn');
let current = null;
function clearSelection() { current = null; if (sidebar) sidebar.classList.add('hidden'); }
function selectEntry(e) {
  current = e;
  if (sidebar) sidebar.classList.remove('hidden');
  if (sidebarHero) {
    const heroSrc = e.hero || '';
    if (heroSrc) { sidebarHero.src = heroSrc; sidebarHero.style.display = ''; }
    else { sidebarHero.removeAttribute('src'); sidebarHero.style.display = 'none'; }
  }
  if (sidebarTitle) sidebarTitle.textContent = e.title || '';
  if (sidebarMeta) {
    sidebarMeta.innerHTML = '';
    const rows = [['Source', e.provider || e.source], ['Rating', e.rating], ['Publisher', e.publisher], ['Developer', e.developer], ['Year', e.year], ['Genres', e.genres]];
    for (let i = 0; i < rows.length; i++) {
      if (!rows[i][1]) continue;
      const div = el('div', 'meta-row');
      const label = el('span', 'meta-label', rows[i][0]);
      const value = el('span', 'meta-value', rows[i][1]);
      div.appendChild(label); div.appendChild(value);
      sidebarMeta.appendChild(div);
    }
  }
}
if (clearBtn) clearBtn.addEventListener('click', clearSelection);
renderChips();
render();
");
            sb.Append("</script></body></html>");

            return sb.ToString();
        }

        private static string HtmlEncode(string s)
        {
            if (s == null) return "";
            return s.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("\"", "&quot;");
        }

        private static string ToJson(List<GameEntry> games)
        {
            var sb = new StringBuilder();
            sb.Append("[");
            for (int i = 0; i < games.Count; i++)
            {
                if (i > 0) sb.Append(",");
                var g = games[i];
                sb.Append("{");
                sb.Append("\"title\":\"" + EscapeJson(g.Name) + "\",");
                sb.Append("\"provider\":\"" + EscapeJson(g.Provider) + "\",");
                string cover = g.CoverPath ?? "";
                if (cover.StartsWith("_library\\")) cover = cover.Substring(9);
                if (cover.StartsWith("_library/")) cover = cover.Substring(9);
                cover = cover.Replace("\\", "/");
                string hero = g.HeroPath ?? "";
                if (hero.StartsWith("_library\\")) hero = hero.Substring(9);
                if (hero.StartsWith("_library/")) hero = hero.Substring(9);
                hero = hero.Replace("\\", "/");
                sb.Append("\"cover\":\"" + EscapeJson(cover) + "\",");
                sb.Append("\"hero\":\"" + EscapeJson(hero) + "\",");
                sb.Append("\"shortcut\":\"" + EscapeJson(g.ShortcutPath) + "\",");
                sb.Append("\"source\":\"" + EscapeJson(g.Source) + "\",");
                sb.Append("\"rating\":\"" + EscapeJson(g.Rating) + "\",");
                sb.Append("\"publisher\":\"" + EscapeJson(g.Publisher) + "\",");
                sb.Append("\"developer\":\"" + EscapeJson(g.Developer) + "\",");
                sb.Append("\"year\":\"" + EscapeJson(g.Year) + "\",");
                sb.Append("\"genres\":\"" + EscapeJson(g.Genres) + "\"");
                sb.Append("}");
            }
            sb.Append("]");
            return sb.ToString();
        }

        private static string EscapeJson(string s)
        {
            if (s == null) return "";
            return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "\\r");
        }
        public static string GenerateSettings()
        {
            var sb = new StringBuilder();
            sb.Append("<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'>");
            sb.Append("<meta name='viewport' content='width=device-width, initial-scale=1'>");
            sb.Append("<title>Games Library - Settings</title>");
            sb.Append("<style>");
            sb.Append("body{background:#0b1020;color:#e8ecff;font-family:system-ui,sans-serif;margin:0;padding:24px}");
            sb.Append(".bar{display:flex;flex-direction:column;gap:8px;margin-bottom:16px;padding:24px 24px 0}");
            sb.Append(".bar h1{margin:0;font-size:1.9rem;font-weight:700;background:linear-gradient(120deg,#fff,#7c8cff,#c06bff);-webkit-background-clip:text;background-clip:text;color:transparent}");
            sb.Append(".settings-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px;max-width:1080px;margin:0 auto}");
            sb.Append("@media (max-width:820px){.settings-grid{grid-template-columns:1fr}}");
            sb.Append(".settings-section{background:rgba(255,255,255,.07);border:1px solid rgba(255,255,255,.16);border-radius:14px;padding:16px 20px;backdrop-filter:blur(16px)}");
            sb.Append(".settings-section--wide{grid-column:1/-1}");
            sb.Append(".settings-section h3{margin:0 0 8px;font-size:1.05rem}");
            sb.Append(".settings-section label{display:block;margin:8px 0;font-size:.9rem}");
            sb.Append(".settings-section input[type=password],.settings-section input[type=text]{display:block;width:100%;margin-top:4px;padding:8px 12px;border-radius:8px;border:1px solid rgba(255,255,255,.16);background:rgba(255,255,255,.07);color:#e8ecff;box-sizing:border-box}");
            sb.Append(".settings-section textarea{display:block;width:100%;margin-top:4px;padding:8px 12px;border-radius:8px;border:1px solid rgba(255,255,255,.16);background:rgba(255,255,255,.07);color:#e8ecff;box-sizing:border-box}");
            sb.Append(".cred-links{display:flex;flex-wrap:wrap;gap:8px;margin:8px 0}");
            sb.Append(".cred-link{padding:6px 12px;border-radius:999px;border:1px solid rgba(255,255,255,.16);background:rgba(255,255,255,.07);color:#7c8cff;font-size:.8rem}");
            sb.Append(".btn{display:inline-flex;align-items:center;justify-content:center;gap:6px;padding:8px 16px;border-radius:999px;border:1px solid rgba(255,255,255,.16);background:rgba(255,255,255,.07);color:#e8ecff;cursor:pointer;font-size:.9rem;line-height:1;text-decoration:none;font-family:inherit;box-sizing:border-box;backdrop-filter:blur(16px);transition:transform .15s ease,box-shadow .15s ease,border-color .15s ease}");
            sb.Append(".btn:hover{transform:translateY(-1px);border-color:rgba(255,255,255,.24)}");
            sb.Append(".btn--primary{background:linear-gradient(120deg,#7c8cff,#c06bff);border-color:transparent;color:#fff}");
            sb.Append(".btn--primary:hover{box-shadow:0 0 16px rgba(124,140,255,.35)}");
            sb.Append(".btn--floating{position:fixed;right:24px;bottom:24px;z-index:20;width:48px;height:48px;min-width:48px;padding:0;border-radius:50%;font-size:1.35rem;box-shadow:0 16px 48px rgba(0,0,0,.5),0 0 24px rgba(124,140,255,.35)}");
            sb.Append(".btn svg{width:16px;height:16px;display:block;fill:currentColor;pointer-events:none}");
            sb.Append(".btn--floating svg{width:22px;height:22px}");
            sb.Append(".settings-section .radio-group{display:flex;gap:24px;margin:12px 0;align-items:center;flex-wrap:wrap}");
            sb.Append(".settings-section .radio{display:inline-flex;align-items:center;gap:8px;margin:0;font-size:.95rem;line-height:1.4;cursor:pointer}");
            sb.Append(".settings-section .radio input[type=radio]{display:inline-block;position:static;width:16px;height:16px;margin:0;flex:0 0 auto;accent-color:#7c8cff}");
            sb.Append(".path-list{display:flex;flex-direction:column;gap:8px;margin:6px 0}");
            sb.Append(".path-row{display:flex;gap:8px;align-items:center}");
            sb.Append(".path-row input{margin-top:0!important;flex:1 1 0;min-width:0}");
            sb.Append(".path-row .cfg-launcher-key{flex:0 0 140px}");
            sb.Append(".btn--icon{width:36px;height:36px;min-width:36px;padding:0;font-size:1.1rem;line-height:1}");
            sb.Append(".hint{color:#9aa4c7;font-size:.85rem;margin:4px 0}");
            sb.Append("</style></head><body>");
            sb.Append("<header class='bar'><div class='bar__brand'><h1>Settings</h1></div>");
            sb.Append("<a href='index.html' class='btn btn--primary btn--floating' title='Back' aria-label='Back'>" + Icons.ArrowLeft() + "</a></header>");
            sb.Append("<div class='settings-grid'>");
            sb.Append("<section class='settings-section'>");
            sb.Append("<h3>Metadata providers</h3>");
            sb.Append("<p class='hint'>Providers requiring API keys are skipped automatically when no key is stored.</p>");
            sb.Append("</section>");
            sb.Append("<section class='settings-section'>");
            sb.Append("<h3>Credentials</h3>");
            sb.Append("<div class='cred-links'>");
            sb.Append("<a class='cred-link' href='https://steamcommunity.com/dev/apikey' target='_blank' rel='noopener'>Steam Web API key</a>");
            sb.Append("<a class='cred-link' href='https://steamid.io/' target='_blank' rel='noopener'>Steam 64 ID</a>");
            sb.Append("<a class='cred-link' href='https://www.steamgriddb.com/profile/preferences/api' target='_blank' rel='noopener'>SteamGridDB API key</a>");
            sb.Append("<a class='cred-link' href='https://dev.twitch.tv/console/apps' target='_blank' rel='noopener'>IGDB Client ID + Secret</a>");
            sb.Append("</div></section>");
            sb.Append("<section class='settings-section'>");
            sb.Append("<h3>API keys (stored securely)</h3>");
            sb.Append("<p class='hint'>Encrypted for this Windows user. Leave blank to keep existing.</p>");
            sb.Append("<label>Steam Web API key<input type='password' id='sec-steamApiKey' placeholder='leave blank to keep'></label>");
            sb.Append("<label>Steam 64 ID<input type='text' id='sec-steam64Id' placeholder='leave blank to keep'></label>");
            sb.Append("<label>SteamGridDB API key<input type='password' id='sec-steamgriddb' placeholder='leave blank to keep'></label>");
            sb.Append("<label>IGDB Client ID<input type='password' id='sec-igdbClientId' placeholder='leave blank to keep'></label>");
            sb.Append("<label>IGDB Client Secret<input type='password' id='sec-igdbClientSecret' placeholder='leave blank to keep'></label>");
            sb.Append("<div style='margin-top:12px'><button id='app-save' class='btn btn--primary'>Save keys</button></div>");
            sb.Append("</section>");
            sb.Append("<section class='settings-section'>");
            sb.Append("<h3>Launcher executables</h3>");
            sb.Append("<p class='hint'>Optional safety backup. Set a launcher executable path to use before auto-detection. Provider key matches the store name (e.g. Steam, itch.io, Epic Games or steam/itch/epic).</p>");
            sb.Append("<div id='cfg-launchers' class='path-list'>");
            if (Config.LauncherPaths.Count == 0)
            {
                sb.Append("<div class='path-row' data-list='launchers'><input type='text' class='cfg-launcher-key' placeholder='Provider (e.g. steam, itch, epic)' value=''><input type='text' class='cfg-launcher-path' placeholder='C:\\Path\\To\\launcher.exe' value=''><button type='button' class='btn btn--icon remove-row' title='Remove' aria-label='Remove'>×</button></div>");
            }
            else
            {
                foreach (var kv in Config.LauncherPaths)
                {
                    sb.Append("<div class='path-row' data-list='launchers'><input type='text' class='cfg-launcher-key' placeholder='Provider (e.g. steam, itch, epic)' value='" + HtmlEncode(kv.Key) + "'><input type='text' class='cfg-launcher-path' placeholder='C:\\Path\\To\\launcher.exe' value='" + HtmlEncode(kv.Value) + "'><button type='button' class='btn btn--icon remove-row' title='Remove' aria-label='Remove'>×</button></div>");
                }
            }
            sb.Append("</div>");
            sb.Append("<div style='margin-top:8px;display:flex;gap:8px;flex-wrap:wrap'><button id='launchers-add' type='button' class='btn'>Add launcher</button><button id='launchers-save' class='btn btn--primary'>Save launcher paths</button></div>");
            sb.Append("<p class='hint'>Changes apply the next time the library is rebuilt.</p>");
            sb.Append("</section>");
            sb.Append("<section class='settings-section settings-section--wide'>");
            sb.Append("<h3>Native library folders</h3>");
            sb.Append("<p class='hint'>When enabled, the app creates game folders and shortcuts in your library root. Disabling this also stops shortcut creation; the app grid still launches games directly.</p>");
            sb.Append("<div class='radio-group'>");
            sb.Append("<label class='radio'><input type='radio' name='cfg-createLibraryFolders' value='true'" + (Config.CreateLibraryFolders ? " checked" : "") + ">Enabled</label>");
            sb.Append("<label class='radio'><input type='radio' name='cfg-createLibraryFolders' value='false'" + (Config.CreateLibraryFolders ? "" : " checked") + ">Disabled</label>");
            sb.Append("</div>");
            sb.Append("<label>Library root<input type='text' id='cfg-libraryRoot' value='" + HtmlEncode(Config.LibraryRoot) + "' placeholder='D:\\Games'></label>");
            sb.Append("<label>Existing shortcut folders</label>");
            sb.Append("<div id='cfg-shortcut-folders' class='path-list'>");
            if (Config.ShortcutFolders == null || Config.ShortcutFolders.Length == 0)
            {
                sb.Append("<div class='path-row'><input type='text' class='cfg-shortcut-folder' placeholder='D:\\Shortcuts\\Steam' value=''><button type='button' class='btn btn--icon remove-row' title='Remove' aria-label='Remove'>×</button></div>");
            }
            else
            {
                foreach (var f in Config.ShortcutFolders)
                {
                    sb.Append("<div class='path-row'><input type='text' class='cfg-shortcut-folder' placeholder='D:\\Shortcuts\\Steam' value='" + HtmlEncode(f) + "'><button type='button' class='btn btn--icon remove-row' title='Remove' aria-label='Remove'>×</button></div>");
                }
            }
            sb.Append("</div>");
            sb.Append("<div style='margin-top:8px;display:flex;gap:8px;flex-wrap:wrap'><button id='shortcut-folders-add' type='button' class='btn'>Add folder</button><button id='folders-save' class='btn btn--primary'>Save library settings</button></div>");
            sb.Append("<p class='hint'>Changes apply the next time the library is rebuilt.</p>");
            sb.Append("</section>");
            sb.Append("<section class='settings-section settings-section--wide'>");
            sb.Append("<h3>Cache and library refresh</h3>");
            sb.Append("<p class='hint'>The app uses a local scan cache for fast launch. Resetting the cache clears it and performs a full rescan to repopulate game data, artwork, and metadata.</p>");
            sb.Append("<div style='margin-top:12px'><button id='cache-reset' class='btn btn--primary'>Reset cache and rescan</button></div>");
            sb.Append("<p class='hint'>This may take a while depending on library size and network metadata lookups.</p>");
            sb.Append("</section>");
            sb.Append("</div>");
            sb.Append("<script src='settings.js'></script>");
            sb.Append("</body></html>");
            return sb.ToString();
        }
    }
}
