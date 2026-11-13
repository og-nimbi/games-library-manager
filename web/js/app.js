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
    window.location.href = "gameslibrary://launch/" + encodeURIComponent(shortcut);
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
  const sidebarEmpty = document.getElementById("sidebar-empty");
  const sidebarContent = document.getElementById("sidebar-content");
  const sidebarHero = document.getElementById("sidebar-hero");
  const sidebarTitle = document.getElementById("sidebar-title");
  const sidebarMeta = document.getElementById("sidebar-meta");
  const playBtn = document.getElementById("play-btn");
  const launchMenu = document.getElementById("launch-menu");
  const cogBtn = document.getElementById("cog-btn");
  const appCog = document.getElementById("app-cog");
  const clearBtn = document.getElementById("clear-btn");

  let current = null;

  function clearSelection() {
    current = null;
    if (sidebarEmpty) sidebarEmpty.style.display = "";
    if (sidebarContent) sidebarContent.classList.add("hidden");
  }

  function selectEntry(e) {
    current = e;
    if (sidebarEmpty) sidebarEmpty.style.display = "none";
    if (sidebarContent) sidebarContent.classList.remove("hidden");
    if (sidebarHero) {
      if (e.cover) { sidebarHero.src = e.cover; sidebarHero.style.display = ""; }
      else { sidebarHero.removeAttribute("src"); sidebarHero.style.display = "none"; }
    }
    if (sidebarTitle) sidebarTitle.textContent = e.title || "";
    if (sidebarMeta) {
      sidebarMeta.innerHTML = "";
      const rows = [
        ["Provider", e.provider],
        ["Type", e.kind],
        ["Source", e.source || e.provider]
      ];
      for (let i = 0; i < rows.length; i++) {
        sidebarMeta.appendChild(el("div", null, rows[i][0] + ": " + (rows[i][1] || "")));
      }
    }
    if (playBtn) {
      const methods = Array.isArray(e.launchMethods) && e.launchMethods.length ? e.launchMethods : [{ name: "Play", shortcut: e.shortcut }];
      const primary = methods[0];
      playBtn.onclick = function () { launch(primary.shortcut); };
      playBtn.textContent = "Play";
      if (launchMenu) {
        launchMenu.innerHTML = "";
        const prev = playBtn.parentNode.querySelector(".launch-toggle");
        if (prev) prev.remove();
        if (methods.length > 1) {
          const toggle = el("button", "launch-toggle", "\u25BE");
          toggle.addEventListener("click", function (ev) {
            ev.stopPropagation();
            launchMenu.classList.toggle("hidden");
          });
          playBtn.parentNode.insertBefore(toggle, launchMenu);
          methods.forEach(function (m) {
            const b = el("button", null, m.name || "Launch");
            b.addEventListener("click", function () { launch(m.shortcut); launchMenu.classList.add("hidden"); });
            launchMenu.appendChild(b);
          });
        }
      }
    }
  }

  // Per-game settings modal (cog button).
  const modal = document.getElementById("edit-modal");
  const editTitle = document.getElementById("edit-title");
  const editCover = document.getElementById("edit-cover");
  const editHero = document.getElementById("edit-hero");
  const editIcon = document.getElementById("edit-icon");
  const editMethods = document.getElementById("edit-methods");
  const editSave = document.getElementById("edit-save");
  const editCancel = document.getElementById("edit-cancel");

  function openModal(e) {
    if (!modal || !e) return;
    if (editTitle) editTitle.value = e.title || "";
    if (editCover) editCover.value = e.cover || "";
    if (editHero) editHero.value = e.hero || "";
    if (editIcon) editIcon.value = e.icon || "";
    if (editMethods) editMethods.value = JSON.stringify(e.launchMethods || [], null, 2);
    modal.classList.remove("hidden");
  }

  if (cogBtn) cogBtn.addEventListener("click", function () { if (current) openModal(current); });

  // App settings modal (app cog).
  const appModal = document.getElementById("app-modal");
  const appClose = document.getElementById("app-close");
  const appSave = document.getElementById("app-save");
  if (appCog && appModal) {
    appCog.addEventListener("click", function () { appModal.classList.remove("hidden"); });
  }
  if (appClose && appModal) {
    appClose.addEventListener("click", function () { appModal.classList.add("hidden"); });
  }
  if (appSave && appModal) {
    appSave.addEventListener("click", function () {
      const patch = {
        metadata: {
          enabled: true,
          providers: {
            steamStore: { enabled: !!document.getElementById("cfg-steamStore").checked },
            steamGridDb: { enabled: !!document.getElementById("cfg-steamGridDb").checked },
            igdb: { enabled: !!document.getElementById("cfg-igdb").checked },
            vndb: { enabled: !!document.getElementById("cfg-vndb").checked }
          }
        }
      };
      const blob = new Blob([JSON.stringify(patch, null, 2)], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "settings-patch.json";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      appModal.classList.add("hidden");
    });
  }

  if (clearBtn) clearBtn.addEventListener("click", clearSelection);

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
      if (modal && !modal.classList.contains("hidden")) modal.classList.add("hidden");
      else if (appModal && !appModal.classList.contains("hidden")) appModal.classList.add("hidden");
    }
  });

  render(entries);
})();
