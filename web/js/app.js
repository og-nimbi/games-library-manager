// Viewer bootstrap. Hydrate entries into memory once; search/filter operate on
// the in-memory array. Covers come from the local cache (relative paths).
(function () {
  "use strict";

  const entries = Array.isArray(window.GLM_ENTRIES) ? window.GLM_ENTRIES : [];
  const imageCache = new Map();

  function el(tag, cls, text) {
    const n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  }

  function launch(shortcut) {
    if (!shortcut) return;
    const path = toWindowsPath(shortcut);
    if (window.chrome && window.chrome.webview) {
      try {
        window.chrome.webview.postMessage(JSON.stringify({ action: "launch", path: path }));
        return;
      } catch (e) { }
    }
    window.location.href = "gameslibrary://launch/" + encodeURIComponent(shortcut);
  }

  function toWindowsPath(p) {
    if (!p) return "";
    let path = String(p);
    if (!/^[a-zA-Z]:/.test(path) && !path.startsWith("/") && window.GLM_LIBRARY_ROOT) {
      path = window.GLM_LIBRARY_ROOT + "/" + path;
    }
    return path.replace(/\//g, "\\");
  }

  let currentSort = "name";

  function sortList(list) {
    const copy = list.slice();
    if (currentSort === "provider") {
      copy.sort(function (a, b) {
        const pa = (a.provider || "").toLowerCase();
        const pb = (b.provider || "").toLowerCase();
        if (pa !== pb) return pa < pb ? -1 : 1;
        return (a.title || "").toLowerCase().localeCompare((b.title || "").toLowerCase());
      });
    } else {
      copy.sort(function (a, b) {
        return (a.title || "").toLowerCase().localeCompare((b.title || "").toLowerCase());
      });
    }
    return copy;
  }

  function card(e) {
    const c = el("article", "card");
    if (e.cover) {
      const img = el("img", "card__cover");
      img.loading = "lazy";
      img.alt = e.title || "";
      if (!imageCache.has(e.cover)) imageCache.set(e.cover, e.cover);
      img.src = e.cover;
      img.onerror = function () { img.replaceWith(el("div", "card__cover card__placeholder", "No art")); };
      c.appendChild(img);
    } else {
      c.appendChild(el("div", "card__cover card__placeholder", "No art"));
    }
    c.appendChild(el("div", "card__title", e.title || ""));
    if (e.provider) c.appendChild(el("div", "card__provider", e.provider));
    const actions = el("div", "card__actions");
    const playBtn = el("button", "play-btn", "Play");
    const methods = Array.isArray(e.launchMethods) && e.launchMethods.length ? e.launchMethods : [{ name: "Play", shortcut: e.shortcut }];
    const primary = methods[0];
    playBtn.addEventListener("click", function (ev) { ev.stopPropagation(); launch(e.shortcut || primary.shortcut); });
    actions.appendChild(playBtn);
    const cogBtn = el("button", "cog-btn", "\u2699");
    cogBtn.title = "Edit game settings";
    cogBtn.addEventListener("click", function (ev) { ev.stopPropagation(); openModal(e); });
    actions.appendChild(cogBtn);
    c.appendChild(actions);
    c.addEventListener("click", function () { selectEntry(e); });
    return c;
  }

  function render(list) {
    const root = document.getElementById("grid");
    if (!root) return;
    root.innerHTML = "";
    const frag = document.createDocumentFragment();
    const sorted = sortList(list);
    for (let i = 0; i < sorted.length; i++) frag.appendChild(card(sorted[i]));
    root.appendChild(frag);
  }

  function filter(q) {
    q = (q || "").toLowerCase().trim();
    if (!q) return entries;
    return entries.filter(function (e) { return (e.title || "").toLowerCase().includes(q); });
  }

  const search = document.getElementById("search");
  if (search) search.addEventListener("input", function () { render(filter(search.value)); });

  // Provider filter chips
  const providers = Array.from(new Set(entries.map(function (e) { return e.provider; }))).sort();
  const chipBar = document.getElementById("chips");
  if (chipBar) {
    const all = el("button", "chip chip--active", "All");
    all.addEventListener("click", function () { render(entries); setActive(all); });
    chipBar.appendChild(all);
    providers.forEach(function (p) {
      const b = el("button", "chip", p);
      b.addEventListener("click", function () {
        render(entries.filter(function (e) { return e.provider === p; }));
        setActive(b);
      });
      chipBar.appendChild(b);
    });
  }
  function setActive(btn) {
    const chips = document.querySelectorAll(".chip");
    for (let i = 0; i < chips.length; i++) chips[i].classList.remove("chip--active");
    btn.classList.add("chip--active");
  }

  // Sort pills
  const sortBar = document.getElementById("sorts");
  if (sortBar) {
    const pills = sortBar.querySelectorAll(".sort-pill");
    for (let i = 0; i < pills.length; i++) {
      pills[i].addEventListener("click", function () {
        currentSort = this.getAttribute("data-sort") || "name";
        for (let j = 0; j < pills.length; j++) pills[j].classList.remove("sort-pill--active");
        this.classList.add("sort-pill--active");
        render(filter(search ? search.value : ""));
      });
    }
  }

  // Sidebar (always visible column)
  const sidebar = document.getElementById("sidebar");
  const sidebarHero = document.getElementById("sidebar-hero");
  const sidebarTitle = document.getElementById("sidebar-title");
  const sidebarMeta = document.getElementById("sidebar-meta");
  const clearBtn = document.getElementById("clear-btn");
  const appCog = document.getElementById("app-cog");
  const appPage = document.getElementById("app-page");
  const appClose = document.getElementById("app-close");
  const appSave = document.getElementById("app-save");

  let current = null;

  function clearSelection() {
    current = null;
    if (sidebar) sidebar.classList.add("hidden");
  }

  function selectEntry(e) {
    current = e;
    if (sidebar) sidebar.classList.remove("hidden");
    if (sidebarHero) {
      const heroSrc = e.hero || "";
      if (heroSrc) { sidebarHero.src = heroSrc; sidebarHero.style.display = ""; }
      else { sidebarHero.removeAttribute("src"); sidebarHero.style.display = "none"; }
    }
    if (sidebarTitle) sidebarTitle.textContent = e.title || "";
    if (sidebarMeta) {
      sidebarMeta.innerHTML = "";
      const rows = [
        ["Source", e.source || e.provider],
        ["Rating", e.rating],
        ["Publisher", e.publisher],
        ["Developer", e.developer],
        ["Year", e.year],
        ["Genres", e.genres]
      ];
      for (let i = 0; i < rows.length; i++) {
        if (!rows[i][1]) continue;
        const div = el("div", "meta-row");
        const label = el("span", "meta-label", rows[i][0]);
        const value = el("span", "meta-value", rows[i][1]);
        div.appendChild(label);
        div.appendChild(value);
        sidebarMeta.appendChild(div);
      }
    }
  }

  if (clearBtn) clearBtn.addEventListener("click", clearSelection);

  function showMain() {
    if (appPage) appPage.classList.add("hidden");
    document.querySelectorAll("header.bar, .layout, .providers").forEach(function (n) { if (n) n.style.display = ""; });
  }
  function showSettings() {
    if (appPage) appPage.classList.remove("hidden");
    document.querySelectorAll("header.bar, .layout, .providers").forEach(function (n) { if (n) n.style.display = "none"; });
  }
  if (appCog && appPage) appCog.addEventListener("click", showSettings);
  if (appClose && appPage) appClose.addEventListener("click", showMain);

  if (appSave && appPage) {
    appSave.addEventListener("click", function () {
      const pairs = [
        ["steamApiKey", document.getElementById("sec-steamApiKey").value],
        ["steam64Id", document.getElementById("sec-steam64Id").value],
        ["steamgriddb", document.getElementById("sec-steamgriddb").value],
        ["igdbClientId", document.getElementById("sec-igdbClientId").value],
        ["igdbClientSecret", document.getElementById("sec-igdbClientSecret").value]
      ];
      if (window.chrome && window.chrome.webview) {
        pairs.forEach(function (p) {
          if (p[1]) {
            window.chrome.webview.postMessage(JSON.stringify({ action: "setSecret", name: p[0], value: p[1] }));
          }
        });
      }
      showMain();
    });
  }

  // Clicking empty grid background clears selection.
  const grid = document.getElementById("grid");
  if (grid) {
    grid.addEventListener("click", function (ev) {
      if (ev.target === grid) clearSelection();
    });
  }

  if (editCancel && modal) editCancel.addEventListener("click", function () { modal.classList.add("hidden"); });

  if (editSave && modal) {
    editSave.addEventListener("click", function () {
      let methods = [];
      try { methods = JSON.parse(editMethods.value || "[]"); } catch (err) { methods = []; }
      const patch = {
        gameOverrides: [{
          match: { provider: current.provider, id: current.id || current.title },
          title: editTitle.value,
          cover: editCover.value,
          hero: editHero.value,
          icon: editIcon.value,
          launchMethods: methods
        }]
      };
      const blob = new Blob([JSON.stringify(patch, null, 2)], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "game-override-" + (current.id || current.title).replace(/[^a-z0-9]/gi, "_") + ".json";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      modal.classList.add("hidden");
    });
  }

  document.addEventListener("keydown", function (ev) {
    if (ev.key === "Escape") {
      if (appPage && !appPage.classList.contains("hidden")) showSettings();
    }
  });

  const foldersSave = document.getElementById("folders-save");
  if (foldersSave) {
    foldersSave.addEventListener("click", function () {
      const text = document.getElementById("cfg-shortcutFolders").value;
      const folders = text.split("\n").map(function (s) { return s.trim(); }).filter(Boolean);
      const patch = { scan: { shortcutFolders: folders } };
      const blob = new Blob([JSON.stringify(patch, null, 2)], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "shortcut-folders-patch.json";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    });
  }

  render(entries);
})();
