// Settings page bootstrap. Handles secure key storage via host postMessage.
(function () {
  "use strict";

  function el(tag, cls, text) {
    const n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  }

  const appSave = document.getElementById("app-save");
  if (appSave) {
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
      window.location.href = "index.html";
    });
  }

  function makeLauncherRow(key, path) {
    const row = el("div", "path-row");
    row.setAttribute("data-list", "launchers");
    const keyInput = el("input", "cfg-launcher-key");
    keyInput.type = "text";
    keyInput.placeholder = "Provider (e.g. steam, itch, epic)";
    keyInput.value = key || "";
    const pathInput = el("input", "cfg-launcher-path");
    pathInput.type = "text";
    pathInput.placeholder = "C:\\Path\\To\\launcher.exe";
    pathInput.value = path || "";
    const removeBtn = el("button", "btn btn--icon remove-row", "×");
    removeBtn.type = "button";
    removeBtn.title = "Remove";
    removeBtn.addEventListener("click", function () {
      const list = row.parentNode;
      row.remove();
      if (list && !list.querySelector(".path-row")) list.appendChild(makeLauncherRow("", ""));
    });
    row.appendChild(keyInput);
    row.appendChild(pathInput);
    row.appendChild(removeBtn);
    return row;
  }

  function makeFolderRow(path) {
    const row = el("div", "path-row");
    const pathInput = el("input", "cfg-shortcut-folder");
    pathInput.type = "text";
    pathInput.placeholder = "D:\\Shortcuts\\Steam";
    pathInput.value = path || "";
    const removeBtn = el("button", "btn btn--icon remove-row", "×");
    removeBtn.type = "button";
    removeBtn.title = "Remove";
    removeBtn.addEventListener("click", function () {
      const list = row.parentNode;
      row.remove();
      if (list && !list.querySelector(".path-row")) list.appendChild(makeFolderRow(""));
    });
    row.appendChild(pathInput);
    row.appendChild(removeBtn);
    return row;
  }

  document.querySelectorAll(".remove-row").forEach(function (btn) {
    btn.addEventListener("click", function () {
      const row = btn.closest(".path-row");
      if (!row) return;
      const list = row.parentNode;
      row.remove();
      if (list && !list.querySelector(".path-row")) {
        if (list.id === "cfg-launchers") list.appendChild(makeLauncherRow("", ""));
        else list.appendChild(makeFolderRow(""));
      }
    });
  });

  const launchersAdd = document.getElementById("launchers-add");
  if (launchersAdd) {
    launchersAdd.addEventListener("click", function () {
      const list = document.getElementById("cfg-launchers");
      if (list) list.appendChild(makeLauncherRow("", ""));
    });
  }

  const launchersSave = document.getElementById("launchers-save");
  if (launchersSave) {
    launchersSave.addEventListener("click", function () {
      const launchers = {};
      document.querySelectorAll("#cfg-launchers .path-row").forEach(function (row) {
        const keyEl = row.querySelector(".cfg-launcher-key");
        const pathEl = row.querySelector(".cfg-launcher-path");
        const key = keyEl ? keyEl.value.trim() : "";
        const path = pathEl ? pathEl.value.trim() : "";
        if (key || path) launchers[key] = path;
      });
      if (window.chrome && window.chrome.webview) {
        window.chrome.webview.postMessage(JSON.stringify({
          action: "setConfig",
          config: { launchers: launchers }
        }));
      }
      launchersSave.textContent = "Saved";
      setTimeout(function () { launchersSave.textContent = "Save launcher paths"; }, 1500);
    });
  }

  const foldersAdd = document.getElementById("shortcut-folders-add");
  if (foldersAdd) {
    foldersAdd.addEventListener("click", function () {
      const list = document.getElementById("cfg-shortcut-folders");
      if (list) list.appendChild(makeFolderRow(""));
    });
  }

  const foldersSave = document.getElementById("folders-save");
  if (foldersSave) {
    foldersSave.addEventListener("click", function () {
      const checked = document.querySelector("input[name='cfg-createLibraryFolders']:checked");
      const createFolders = checked ? checked.value === "true" : true;
      const rootInput = document.getElementById("cfg-libraryRoot");
      const libraryRoot = rootInput ? rootInput.value.trim() : "";
      const folders = [];
      document.querySelectorAll("#cfg-shortcut-folders .cfg-shortcut-folder").forEach(function (input) {
        const v = (input.value || "").trim();
        if (v) folders.push(v);
      });
      if (window.chrome && window.chrome.webview) {
        window.chrome.webview.postMessage(JSON.stringify({
          action: "setConfig",
          config: {
            createLibraryFolders: createFolders,
            libraryRoot: libraryRoot,
            scan: { shortcutFolders: folders }
          }
        }));
      }
      foldersSave.textContent = "Saved";
      setTimeout(function () { foldersSave.textContent = "Save library settings"; }, 1500);
    });
  }

  const cacheReset = document.getElementById("cache-reset");
  if (cacheReset) {
    cacheReset.addEventListener("click", function () {
      if (window.chrome && window.chrome.webview) {
        cacheReset.disabled = true;
        cacheReset.textContent = "Resetting...";
        window.chrome.webview.postMessage(JSON.stringify({ action: "resetCache" }));
      }
    });
  }
})();