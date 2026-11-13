# HTML index generation (cover-grid viewer).

function ConvertTo-JsonString {
    param([string]$Value)
    if ($null -eq $Value) { $Value = '' }
    $s = [string]$Value
    $s = $s.Replace('\', '\\').Replace('"', '\"')
    $s = $s.Replace("`r", '\r').Replace("`n", '\n').Replace("`t", '\t')
    # Strip control characters that would break JSON.
    $s = $s -replace '[\x00-\x1F]', ''
    return '"' + $s + '"'
}

function Get-WebAsset {
    param(
        [string]$RelativePath,
        [string]$Fallback
    )

    $candidate = ''
    try {
        $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $candidate = Join-Path $root $RelativePath
    } catch {
        $candidate = ''
    }

    if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue)) {
        try { return (Get-Content -LiteralPath $candidate -Raw -ErrorAction Stop) } catch { }
    }

    # Also try relative to the current working directory.
    if (Test-Path -LiteralPath $RelativePath -PathType Leaf -ErrorAction SilentlyContinue) {
        try { return (Get-Content -LiteralPath $RelativePath -Raw -ErrorAction Stop) } catch { }
    }

    return $Fallback
}

function New-GamesLibraryIndex {
    param(
        [Parameter(Mandatory = $true)][string]$IndexPath,
        [Parameter(Mandatory = $true)]$Providers,
        [string]$GeneratedAt = ''
    )

    if (!$GeneratedAt) { $GeneratedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm') }

    $withGames = @($Providers | Where-Object { @($_.Games).Count -gt 0 } | Sort-Object DisplayName)
    $totalGames = 0
    foreach ($provider in $withGames) { $totalGames += @($provider.Games).Count }

    # Build the entries array (compact JSON) for in-memory hydration.
    $entryLines = New-Object System.Collections.Generic.List[string]
    foreach ($provider in $withGames) {
        $games = @($provider.Games | Sort-Object Name)
        foreach ($game in $games) {
            $shortcut = ''
            if ($game.ShortcutPath) {
                try { $shortcut = Get-RelativePathFromRoot -Root (Split-Path -Parent $IndexPath) -Path $game.ShortcutPath } catch { $shortcut = '' }
            }
            if (!$shortcut -and $game.ShortcutPath) { $shortcut = $game.ShortcutPath }

            $cover = ''
            if ($game.CoverPath) {
                $cover = [string]$game.CoverPath
                # CoverPath is library-root-relative (_library\artwork\...);
                # the index lives in _library\, so drop that prefix.
                if ($cover -match '^_library[\\/](.+)$') { $cover = $Matches[1] }
                $cover = $cover -replace '\\', '/'
            }

            # Launch methods (primary + custom). Each has name + relative shortcut.
            $methodParts = New-Object System.Collections.Generic.List[string]
            $methods = @($game.LaunchMethods)
            if ($methods.Count -eq 0 -and $game.ShortcutPath) {
                $rel = ''
                try { $rel = Get-RelativePathFromRoot -Root (Split-Path -Parent $IndexPath) -Path $game.ShortcutPath } catch { $rel = '' }
                if ([string]::IsNullOrWhiteSpace($rel)) { $rel = $game.ShortcutPath }
                $methods = @([pscustomobject]@{ Name = 'Play'; Shortcut = ($rel -replace '\\', '/') })
            }
            foreach ($m in $methods) {
                if (!$m) { continue }
                $mShortcut = [string]$m.Shortcut
                if ([string]::IsNullOrWhiteSpace($mShortcut) -and $m.Target) { $mShortcut = [string]$m.Target }
                $mShortcut = $mShortcut -replace '\\', '/'
                $methodParts.Add('{"name":' + (ConvertTo-JsonString $m.Name) + ',"shortcut":' + (ConvertTo-JsonString $mShortcut) + '}')
            }
            $methodsJson = '[' + ($methodParts -join ',') + ']'
            $fields = @()
            $fields += '"title":' + (ConvertTo-JsonString $game.Name)
            $fields += '"provider":' + (ConvertTo-JsonString $provider.DisplayName)
            $fields += '"kind":' + (ConvertTo-JsonString $game.Kind)
            $fields += '"shortcut":' + (ConvertTo-JsonString $shortcut)
            $fields += '"cover":' + (ConvertTo-JsonString $cover)
            $fields += '"hero":' + (ConvertTo-JsonString ($game.HeroPath -replace '\\', '/'))
            $fields += '"icon":' + (ConvertTo-JsonString $game.IconPath)
            $fields += '"id":' + (ConvertTo-JsonString $game.Id)
            $fields += '"launchMethods":' + $methodsJson
            $entryLines.Add('{' + ($fields -join ',') + '}')
        }
    }
    $entriesJson = '[' + ($entryLines -join ',') + ']'

    # Discover secret names referenced by config so the settings page can show
    # configured/not-configured status without ever exposing values.
    $secretNames = New-Object System.Collections.Generic.List[string]
    try {
        $cfg = Get-GamesLibraryConfig -ConfigPath $null 2>$null
    } catch { $cfg = $null }
    # Best effort: scan the actual settings file used by the build is not
    # available here, so leave the list empty; the page still renders.

    $cssFallback = 'body{background:#0b1020;color:#e8ecff;font-family:system-ui,-apple-system,"Segoe UI",sans-serif;margin:0;padding:24px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:12px}.card{background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.14);border-radius:12px;overflow:hidden}.card__cover{aspect-ratio:2/3;object-fit:cover;width:100%}.card__title{font-size:.85rem;padding:6px 8px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}'
    $css = Get-WebAsset -RelativePath 'web\dist\app.css' -Fallback $cssFallback

    $jsFallback = 'window.GLM_ENTRIES=window.GLM_ENTRIES||[];(function(){var e=window.GLM_ENTRIES||[];var r=document.getElementById("grid");if(r){var f=document.createDocumentFragment();for(var i=0;i<e.length;i++){var c=document.createElement("article");c.className="card";var t=document.createElement("div");t.className="card__title";t.textContent=e[i].title||"";c.appendChild(t);f.appendChild(c);}r.appendChild(f);}})();'
    $js = Get-WebAsset -RelativePath 'web\js\app.js' -Fallback $jsFallback

    $html = New-Object System.Collections.Generic.List[string]
    $html.Add('<!DOCTYPE html>')
    $html.Add('<html lang="en">')
    $html.Add('<head>')
    $html.Add('<meta charset="utf-8">')
    $html.Add('<meta name="viewport" content="width=device-width, initial-scale=1">')
    $html.Add('<title>Games Library</title>')
    $html.Add('<link rel="icon" type="image/x-icon" href="app.ico">')
    $html.Add('<style>')
    $html.Add($css)
    $html.Add('</style>')
    $html.Add('</head>')
    $html.Add('<body>')
    $html.Add('<header class="bar">')
    $html.Add('<div class="bar__brand"><img src="app.ico" alt="" class="bar__logo"><h1>Games Library</h1></div>')
    $html.Add('<div class="sub">' + $totalGames + ' games in ' + $withGames.Count + ' sections &middot; generated ' + (ConvertTo-HtmlText $GeneratedAt) + '</div>')
    $html.Add('<div class="toolbar">')
    $html.Add('<input id="search" type="search" placeholder="Search games..." aria-label="Search games">')
    $html.Add('<div id="chips" class="chips" aria-label="Filter by store"></div>')
    $html.Add('<div id="sorts" class="sorts" aria-label="Sort">')
    $html.Add('<button class="sort-pill sort-pill--active" data-sort="name">Name</button>')
    $html.Add('<button class="sort-pill" data-sort="provider">Store</button>')
    $html.Add('</div>')
    $html.Add('</div>')
    $html.Add('</header>')

    # Provider launcher shortcuts.
    $launchers = @($Providers | Where-Object { $_.Launcher } | Sort-Object DisplayName)
    if ($launchers.Count -gt 0) {
        $html.Add('<section class="providers">')
        $html.Add('<h2>Providers</h2>')
        $html.Add('<div class="grid">')
        foreach ($provider in $launchers) {
            $launcher = $provider.Launcher
            $href = ''
            if ($launcher.ShortcutPath) { $href = ConvertTo-FileUri $launcher.ShortcutPath }
            $html.Add('<article class="card">')
            if ($href) {
                $html.Add('<a href="' + (ConvertTo-HtmlText $href) + '" class="card__title">' + (ConvertTo-HtmlText $provider.DisplayName) + '</a>')
            } else {
                $html.Add('<div class="card__title">' + (ConvertTo-HtmlText $provider.DisplayName) + '</div>')
            }
            $html.Add('</article>')
        }
        $html.Add('</div>')
        $html.Add('</section>')
    }

    $html.Add('<div class="layout">')
    $html.Add('<main id="grid" class="grid layout__main" aria-label="Games"></main>')
    # Detail sidebar (always visible column).
    $html.Add('<aside id="sidebar" class="sidebar" aria-label="Game details">')
    $html.Add('<div class="sidebar__header">')
    $html.Add('<span class="sidebar__heading">Details</span>')
    $html.Add('<button id="app-cog" class="cog-btn" title="App settings">&#9881;</button>')
    $html.Add('</div>')
    $html.Add('<div id="sidebar-empty" class="sidebar__empty">Select a game to see details.</div>')
    $html.Add('<div id="sidebar-content" class="hidden">')
    $html.Add('<img id="sidebar-hero" class="sidebar__hero" alt="">')
    $html.Add('<h2 id="sidebar-title" class="sidebar__title"></h2>')
    $html.Add('<div id="sidebar-meta" class="sidebar__meta"></div>')
    $html.Add('<div class="sidebar__actions">')
    $html.Add('<button id="play-btn" class="play-btn">Play</button>')
    $html.Add('<button id="cog-btn" class="cog-btn" title="Edit game settings">&#9881;</button>')
    $html.Add('<div id="launch-menu" class="launch-menu hidden"></div>')
    $html.Add('</div>')
    $html.Add('<button id="clear-btn" class="clear-btn">Clear selection</button>')
    $html.Add('</div>')
    $html.Add('</aside>')
    $html.Add('</div>')

    # Edit modal (per-game settings patch generator).
    $html.Add('<div id="edit-modal" class="modal hidden">')
    $html.Add('<div class="modal__card">')
    $html.Add('<h3>Edit game settings</h3>')
    $html.Add('<label>Title<input id="edit-title" type="text"></label>')
    $html.Add('<label>Cover path<input id="edit-cover" type="text" placeholder="artwork/steam/421670.jpg"></label>')
    $html.Add('<label>Hero path<input id="edit-hero" type="text" placeholder="artwork/steam/421670-hero.jpg"></label>')
    $html.Add('<label>Icon path<input id="edit-icon" type="text"></label>')
    $html.Add('<label>Launch methods (JSON array)<textarea id="edit-methods" rows="4" placeholder="[{&quot;name&quot;:&quot;Modded&quot;,&quot;shortcut&quot;:&quot;Steam\\\\Game (Modded).url&quot;}]"></textarea></label>')
    $html.Add('<div class="modal__actions">')
    $html.Add('<button id="edit-save" class="play-btn">Download patch</button>')
    $html.Add('<button id="edit-cancel" class="launch-toggle">Cancel</button>')
    $html.Add('</div>')
    $html.Add('<p class="hint">Apply with: games-library.cmd -ApplyGameSettings &lt;file&gt;</p>')
    $html.Add('</div>')
    $html.Add('</div>')

    # App settings modal.
    $html.Add('<div id="app-modal" class="modal hidden">')
    $html.Add('<div class="modal__card">')
    $html.Add('<h3>App settings</h3>')
    $html.Add('<p class="hint">Metadata providers (artwork). Toggle and download a patch; apply with games-library.cmd -ApplySettings &lt;file&gt;.</p>')
    $html.Add('<label><input type="checkbox" id="cfg-steamStore" checked> Steam store (keyless)</label>')
    $html.Add('<label><input type="checkbox" id="cfg-vndb"> VNDB (keyless, visual novels)</label>')
    $html.Add('<label><input type="checkbox" id="cfg-steamGridDb"> SteamGridDB (requires API key)</label>')
    $html.Add('<label><input type="checkbox" id="cfg-igdb"> IGDB (requires client id + secret)</label>')
    $html.Add('<p class="hint">Get credentials:</p>')
    $html.Add('<div class="cred-links">')
    $html.Add('<a class="cred-link" href="https://steamcommunity.com/dev/apikey" target="_blank" rel="noopener">Steam Web API key</a>')
    $html.Add('<a class="cred-link" href="https://steamid.io/" target="_blank" rel="noopener">Steam 64 ID</a>')
    $html.Add('<a class="cred-link" href="https://www.steamgriddb.com/profile/preferences/api" target="_blank" rel="noopener">SteamGridDB API key</a>')
    $html.Add('<a class="cred-link" href="https://dev.twitch.tv/console/apps" target="_blank" rel="noopener">IGDB Client ID + Secret</a>')
    $html.Add('</div>')
    $html.Add('<p class="hint">Secrets: games-library.cmd -SetSecret steamgriddb / igdbClientId / igdbClientSecret</p>')
    $html.Add('<div class="modal__actions">')
    $html.Add('<button id="app-save" class="play-btn">Download patch</button>')
    $html.Add('<button id="app-close" class="launch-toggle">Close</button>')
    $html.Add('</div>')
    $html.Add('</div>')
    $html.Add('</div>')

    # Settings page (read-only for secrets; copy-command buttons).
    $html.Add('<details class="settings">')
    $html.Add('<summary>Settings</summary>')
    $html.Add('<div class="settings__row"><span class="settings__label">Secrets are managed via the CLI.</span></div>')
    $html.Add('<div class="settings__row"><code>games-library.cmd -SetSecret &lt;name&gt;</code></div>')
    $html.Add('<div class="settings__row"><code>games-library.cmd -ListSecrets</code></div>')
    $html.Add('<div class="settings__row"><code>games-library.cmd -RemoveSecret &lt;name&gt;</code></div>')
    $html.Add('</details>')

    $html.Add('<footer>Generated by Games Library Manager. Shortcuts can be moved or renamed; rebuild to refresh them.</footer>')

    # Embed entries data and viewer script.
    $html.Add('<script>')
    $html.Add('window.GLM_ENTRIES = ' + $entriesJson + ';')
    $html.Add($js)
    $html.Add('</script>')

    $html.Add('</body>')
    $html.Add('</html>')

    $directory = Split-Path -Parent $IndexPath
    if (!(Test-Path -LiteralPath $directory -PathType Container -ErrorAction SilentlyContinue)) {
        if (!$script:DryRun) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
    }

    # Copy the app icon into _library so the page can use it as a favicon/logo.
    if (!$script:DryRun) {
        $assetIcon = ''
        try {
            $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            $candidate = Join-Path $repoRoot 'assets\games.ico'
            if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) { $assetIcon = $candidate }
        } catch { }
        if ($assetIcon) {
            $destIcon = Join-Path $directory 'app.ico'
            try { Copy-Item -LiteralPath $assetIcon -Destination $destIcon -Force -ErrorAction Stop } catch {
                Write-Log "Could not copy app icon: $($_.Exception.Message)" -Level Debug
            }
        }
    }

    if ($script:DryRun) {
        Write-Log "Would write HTML index: $IndexPath" -Level Debug
        return
    }

    Set-Content -LiteralPath $IndexPath -Value ($html -join "`r`n") -Encoding UTF8 -Force
}
