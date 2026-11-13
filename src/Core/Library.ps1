# Library build: root safety, manifest, stale cleanup, shortcut layout.

function Get-LibraryManifestPath {
    param([string]$Root)
    return (Join-Path $Root '_library\manifest.json')
}

function Get-PreviousManifest {
    param([string]$Root)

    $manifestPath = Get-LibraryManifestPath $Root
    if (!(Test-Path -LiteralPath $manifestPath -PathType Leaf -ErrorAction SilentlyContinue)) { return $null }

    try {
        return (Get-Content -LiteralPath $manifestPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
    } catch {
        Write-Log "Existing manifest could not be read: $($_.Exception.Message)" -Level Warn
        return $null
    }
}

function Test-PathUnderRoot {
    param(
        [string]$Root,
        [string]$Path
    )

    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    $pathFull = [IO.Path]::GetFullPath($Path)
    return $pathFull.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)
}

function Get-RelativePathFromRoot {
    param(
        [string]$Root,
        [string]$Path
    )

    if (!(Test-PathUnderRoot -Root $Root -Path $Path)) { return $null }
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    $pathFull = [IO.Path]::GetFullPath($Path)
    return $pathFull.Substring($rootFull.Length)
}

function Get-UniqueBaseName {
    param(
        [string]$BaseName,
        [hashtable]$Used
    )

    $name = $BaseName
    $index = 2
    while ($Used.ContainsKey($name.ToLowerInvariant())) {
        $name = '{0} ({1})' -f $BaseName, $index
        $index++
    }

    $Used[$name.ToLowerInvariant()] = $true
    return $name
}

function Initialize-LibraryRoot {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [switch]$Force
    )

    $expanded = Expand-PathValue $Root
    if (!$expanded) { throw 'Library root is empty.' }
    if (![IO.Path]::IsPathRooted($expanded)) { $expanded = Join-Path (Get-Location).Path $expanded }

    $full = [IO.Path]::GetFullPath($expanded).TrimEnd('\')
    if ($full -match '^[a-zA-Z]:$') { throw "Refusing to use a drive root as the library: $full" }
    if ($env:WINDIR -and $full -ieq ([IO.Path]::GetFullPath($env:WINDIR)).TrimEnd('\')) {
        throw "Refusing to use the Windows directory as the library: $full"
    }

    $manifestPath = Get-LibraryManifestPath $full
    $managed = Test-Path -LiteralPath $manifestPath -PathType Leaf -ErrorAction SilentlyContinue

    if (!(Test-Path -LiteralPath $full -PathType Container -ErrorAction SilentlyContinue)) {
        if (!$script:DryRun) { New-Item -ItemType Directory -Path $full -Force | Out-Null }
        return [pscustomobject]@{ Root = $full; Managed = $false; Backup = $null }
    }

    if ($managed) {
        return [pscustomobject]@{ Root = $full; Managed = $true; Backup = $null }
    }

    $items = @(Get-ChildItem -LiteralPath $full -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' })
    if ($items.Count -eq 0) {
        return [pscustomobject]@{ Root = $full; Managed = $false; Backup = $null }
    }

    if (!$Force) {
        if ($script:DryRun) {
            Write-Log "Library root '$full' is not managed by this tool. A real run needs -Force (the existing folder will be backed up first)." -Level Warn
            return [pscustomobject]@{ Root = $full; Managed = $false; Backup = $null }
        }
        throw "Library root '$full' already contains files and is not managed by this tool. Re-run with -Force to back it up and rebuild, or choose another -LibraryRoot."
    }

    $backup = $full + '_backup_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
    $suffix = 2
    while (Test-Path -LiteralPath $backup) {
        $backup = $full + '_backup_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + $suffix
        $suffix++
    }

    if ($script:DryRun) {
        Write-Log "Would back up '$full' to '$backup' and rebuild." -Level Info
        return [pscustomobject]@{ Root = $full; Managed = $false; Backup = $backup }
    }

    Move-Item -LiteralPath $full -Destination $backup -Force -ErrorAction Stop
    New-Item -ItemType Directory -Path $full -Force | Out-Null
    Write-Log "Existing library backed up to: $backup" -Level Info

    return [pscustomobject]@{ Root = $full; Managed = $false; Backup = $backup }
}

function Remove-StaleArtifacts {
    param(
        [string]$Root,
        [string[]]$NewFiles,
        [string[]]$NewDirectories,
        [switch]$Preview
    )

    $previous = Get-PreviousManifest $Root
    if (!$previous) { return 0 }

    $newFileSet = @{}
    foreach ($file in $NewFiles) { $newFileSet[$file.ToLowerInvariant()] = $true }

    $removed = 0
    foreach ($relative in @($previous.files)) {
        if (!$relative) { continue }
        if ($relative.StartsWith('_library\', [StringComparison]::OrdinalIgnoreCase)) { continue }
        if ($newFileSet.ContainsKey($relative.ToLowerInvariant())) { continue }

        $fullPath = Join-Path $Root $relative
        if (!(Test-PathUnderRoot -Root $Root -Path $fullPath)) { continue }
        if (Test-Path -LiteralPath $fullPath -PathType Leaf -ErrorAction SilentlyContinue) {
            # A dry run must never delete anything, but should still report what
            # would be removed.
            if ($Preview) {
                $removed++
                continue
            }

            try {
                Remove-Item -LiteralPath $fullPath -Force -ErrorAction Stop
                $removed++
            } catch {
                Write-Log "Could not remove stale file '$fullPath': $($_.Exception.Message)" -Level Warn
            }
        }
    }

    $newDirectorySet = @{}
    foreach ($directory in $NewDirectories) { $newDirectorySet[$directory.ToLowerInvariant()] = $true }

    foreach ($relative in @($previous.directories)) {
        if (!$relative) { continue }
        if ($relative -ieq '_library') { continue }
        if ($newDirectorySet.ContainsKey($relative.ToLowerInvariant())) { continue }

        $fullPath = Join-Path $Root $relative
        if (!(Test-PathUnderRoot -Root $Root -Path $fullPath)) { continue }
        if (Test-Path -LiteralPath $fullPath -PathType Container -ErrorAction SilentlyContinue) {
            $children = @(Get-ChildItem -LiteralPath $fullPath -Force -ErrorAction SilentlyContinue)
            if ($children.Count -eq 0 -and !$Preview) {
                try { Remove-Item -LiteralPath $fullPath -Force -ErrorAction Stop } catch { }
            }
        }
    }

    if ($removed -gt 0) {
        if ($Preview) {
            Write-Log "Dry run: $removed stale shortcut(s) would be removed." -Level Info
        } else {
            Write-Log "Removed $removed stale shortcut(s)." -Level Info
        }
    }
    return $removed
}

function Get-ProviderFolderIcon {
    param($Provider)

    if ($Provider.Launcher) {
        $icon = Resolve-ShortcutIcon -Entry $Provider.Launcher -FallbackIcon $Provider.IconPath
        if ($icon) { return $icon }
    }

    foreach ($game in @($Provider.Games)) {
        $icon = Resolve-ShortcutIcon -Entry $game -FallbackIcon $Provider.IconPath
        if ($icon) { return $icon }
    }

    if ($Provider.IconPath -and (Test-Path -LiteralPath $Provider.IconPath -PathType Leaf -ErrorAction SilentlyContinue)) {
        return $Provider.IconPath
    }

    return $null
}

function Write-LibraryManifest {
    param(
        [string]$Root,
        [string[]]$Files,
        [string[]]$Directories,
        $Providers,
        [string]$GeneratedAt
    )

    $providerRecords = New-Object System.Collections.Generic.List[object]

    foreach ($provider in @($Providers | Sort-Object DisplayName)) {
        $launcherRelative = $null
        if ($provider.Launcher -and $provider.Launcher.ShortcutPath) {
            $launcherRelative = Get-RelativePathFromRoot -Root $Root -Path $provider.Launcher.ShortcutPath
        }

        $gameRecords = New-Object System.Collections.Generic.List[object]
        foreach ($game in @($provider.Games | Sort-Object Name)) {
            $shortcutRelative = $null
            if ($game.ShortcutPath) {
                $shortcutRelative = Get-RelativePathFromRoot -Root $Root -Path $game.ShortcutPath
            }
            $gameRecords.Add([ordered]@{
                name      = $game.Name
                kind      = $game.Kind
                target    = $game.Target
                shortcut  = $shortcutRelative
                installDir = $game.InstallDir
                id        = $game.Id
                source    = $game.Source
            })
        }

        $providerRecords.Add([ordered]@{
            key      = $provider.Key
            name     = $provider.DisplayName
            launcher = $launcherRelative
            games    = @(ConvertTo-Array $gameRecords)
        })
    }

    $manifest = [ordered]@{
        generator   = 'games-library-manager'
        version     = 1
        generatedAt = $GeneratedAt
        libraryRoot = $Root
        files       = @($Files | Sort-Object -Unique)
        directories = @($Directories | Sort-Object -Unique)
        providers   = @(ConvertTo-Array $providerRecords)
    }

    $manifestPath = Get-LibraryManifestPath $Root
    $json = $manifest | ConvertTo-Json -Depth 10
    Set-Content -LiteralPath $manifestPath -Value $json -Encoding UTF8 -Force
}

function Build-GamesLibrary {
    param(
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyCollection()]$Providers = @(),
        [switch]$DryRun,
        [switch]$NoIndex,
        [switch]$NoClean,
        [switch]$NoFolderIcons,
        [switch]$Force
    )

    $script:DryRun = [bool]$DryRun
    $script:WarningCount = 0

    $rootInfo = Initialize-LibraryRoot -Root $Root -Force:$Force
    $Root = $rootInfo.Root

    if (!$script:DryRun) {
        $metaDir = Join-Path $Root '_library'
        New-Item -ItemType Directory -Path $metaDir -Force | Out-Null
        $script:LogFilePath = Join-Path $metaDir 'last-run.log'
        try {
            Add-Content -LiteralPath $script:LogFilePath -Value ('--- ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' ---') -Encoding UTF8
        } catch { }
        Flush-LogBuffer
    }

    Write-Log 'Games Library Manager' -Level Ok
    Write-Log "Library root: $Root"

    $files = New-Object System.Collections.Generic.List[string]
    $directories = New-Object System.Collections.Generic.List[string]
    $usedFolders = @{ 'providers' = $true; '_library' = $true }

    $providerLaunchers = @($Providers | Where-Object { $_.Launcher } | Sort-Object DisplayName)
    if ($providerLaunchers.Count -gt 0) {
        $providersDir = Join-Path $Root 'Providers'
        if (!$script:DryRun) { New-Item -ItemType Directory -Path $providersDir -Force | Out-Null }
        $directories.Add('Providers')

        $usedNames = @{}
        foreach ($provider in $providerLaunchers) {
            $baseName = Get-UniqueBaseName -BaseName (Get-SafeFileName $provider.DisplayName) -Used $usedNames
            $shortcutPath = New-ShortcutFile -Directory $providersDir -BaseName $baseName -Entry $provider.Launcher -FallbackIcon $provider.IconPath
            if ($shortcutPath) {
                $relative = Get-RelativePathFromRoot -Root $Root -Path $shortcutPath
                if ($relative) { $files.Add($relative) }
                $provider.Launcher | Add-Member -NotePropertyName ShortcutPath -NotePropertyValue $shortcutPath -Force
            }
        }

        if ($Config.createFolderIcons -and !$NoFolderIcons) {
            $first = $providerLaunchers[0]
            $folderIcon = Resolve-ShortcutIcon -Entry $first.Launcher -FallbackIcon $first.IconPath
            if ($folderIcon) {
                $iniPath = Join-Path $providersDir 'desktop.ini'
                if (Set-FolderIcon -Folder $providersDir -IconPath $folderIcon -IniPath $iniPath) {
                    $relative = Get-RelativePathFromRoot -Root $Root -Path $iniPath
                    if ($relative) { $files.Add($relative) }
                }
            }
        }
    }

    foreach ($provider in @($Providers | Sort-Object DisplayName)) {
        $games = @($provider.Games | Where-Object { $_ } | Sort-Object Name)
        if ($games.Count -eq 0) { continue }

        $folderName = Get-UniqueBaseName -BaseName (Get-SafeFileName $provider.DisplayName) -Used $usedFolders
        $providerDir = Join-Path $Root $folderName
        if (!$script:DryRun) { New-Item -ItemType Directory -Path $providerDir -Force | Out-Null }
        $directories.Add($folderName)

        $usedNames = @{}
        foreach ($game in $games) {
            $baseName = Get-UniqueBaseName -BaseName (Get-SafeFileName $game.Name) -Used $usedNames
            $shortcutPath = New-ShortcutFile -Directory $providerDir -BaseName $baseName -Entry $game -FallbackIcon $provider.IconPath
            if ($shortcutPath) {
                $relative = Get-RelativePathFromRoot -Root $Root -Path $shortcutPath
                if ($relative) { $files.Add($relative) }
                $game | Add-Member -NotePropertyName ShortcutPath -NotePropertyValue $shortcutPath -Force
            }
        }

        if ($Config.createFolderIcons -and !$NoFolderIcons) {
            $folderIcon = Get-ProviderFolderIcon -Provider $provider
            if ($folderIcon) {
                $iniPath = Join-Path $providerDir 'desktop.ini'
                if (Set-FolderIcon -Folder $providerDir -IconPath $folderIcon -IniPath $iniPath) {
                    $relative = Get-RelativePathFromRoot -Root $Root -Path $iniPath
                    if ($relative) { $files.Add($relative) }
                }
            }
        }
    }

    # Attach a primary launch method (the game's own shortcut) to every entry.
    # Custom launch methods from config are preserved alongside it.
    foreach ($provider in @($Providers)) {
        foreach ($game in @($provider.Games)) {
            if (!$game) { continue }
            $relative = ''
            if ($game.ShortcutPath) {
                try { $relative = Get-RelativePathFromRoot -Root $Root -Path $game.ShortcutPath } catch { $relative = '' }
            }
            if ([string]::IsNullOrWhiteSpace($relative) -and $game.ShortcutPath) { $relative = $game.ShortcutPath }
            $primary = [pscustomobject]@{ Name = 'Play'; Shortcut = $relative }
            $existing = @($game.LaunchMethods | Where-Object { $_ -and $_.Shortcut -ne $relative })
            $game.LaunchMethods = @($primary) + $existing
        }
    }

    # Resolve store-first artwork into the local cache. Best-effort: a failure
    # leaves CoverPath empty and the viewer shows a placeholder.
    $artworkIndex = @{}
    foreach ($provider in @($Providers)) {
        foreach ($game in @($provider.Games)) {
            if (!$game) { continue }
            try {
                $relative = Resolve-GameArtwork -Root $Root -Game $game -Config $Config
                if ($relative) {
                    $artworkIndex[([string]$game.ProviderKey + '|' + [string]$game.Id)] = @{
                        provider   = [string]$game.ProviderKey
                        id         = [string]$game.Id
                        file       = $relative
                        source     = [string]$game.Source
                        fetchedAt  = (Get-Date).ToString('o')
                    }
                }
            } catch {
                Write-Log "Artwork: could not resolve for '$($game.Name)': $($_.Exception.Message)" -Level Debug
            }
        }
        if ($provider.Launcher) {
            try { Resolve-GameArtwork -Root $Root -Game $provider.Launcher | Out-Null } catch { }
        }
    }
    if ($artworkIndex.Count -gt 0) {
        try { Write-ArtworkIndex -Root $Root -Index $artworkIndex } catch {
            Write-Log "Artwork: could not write index: $($_.Exception.Message)" -Level Warn
        }
    }

    $skipCleanup = $NoClean -or !$Config.removeStaleShortcuts
    $staleRemoved = 0
    if (!$skipCleanup) {
        $staleRemoved = Remove-StaleArtifacts -Root $Root -NewFiles @($files) -NewDirectories @($directories) -Preview:([bool]$script:DryRun)
    }

    $manifestFiles = @($files)
    $manifestDirectories = @($directories)
    if ($skipCleanup) {
        $previous = Get-PreviousManifest $Root
        if ($previous) {
            $manifestFiles = @(@($previous.files) + @($files) | Where-Object { $_ } | Sort-Object -Unique)
            $manifestDirectories = @(@($previous.directories) + @($directories) | Where-Object { $_ } | Sort-Object -Unique)
        }
    }

    $generatedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

    $totalGames = 0
    foreach ($provider in @($Providers | Sort-Object DisplayName)) {
        $count = @($provider.Games).Count
        if ($count -gt 0) {
            Write-Log ("{0}: {1} game(s)" -f $provider.DisplayName, $count) -Level Info
            $totalGames += $count
        }
    }

    if ($script:DryRun) {
        Write-Log "Dry run complete. $totalGames game(s), $(@($providerLaunchers).Count) provider shortcut(s); no files were written." -Level Ok
        return [pscustomobject]@{
            Root        = $Root
            TotalGames  = $totalGames
            Providers   = @($providerLaunchers).Count
            StaleRemoved = 0
            Backup      = $rootInfo.Backup
            DryRun      = $true
        }
    }

    Write-LibraryManifest -Root $Root -Files $manifestFiles -Directories $manifestDirectories -Providers $Providers -GeneratedAt $generatedAt

    if ($Config.createHtmlIndex -and !$NoIndex) {
        $indexPath = Join-Path $Root '_library\index.html'
        New-GamesLibraryIndex -IndexPath $indexPath -Providers $Providers -GeneratedAt $generatedAt
        Write-Log "HTML index: $indexPath" -Level Info
    }

    Write-Log "Done. $totalGames game(s), $(@($providerLaunchers).Count) provider shortcut(s), $staleRemoved stale item(s) removed." -Level Ok
    if ($script:WarningCount -gt 0) {
        Write-Log "$($script:WarningCount) warning(s) were logged. See _library\last-run.log." -Level Warn
    }

    return [pscustomobject]@{
        Root         = $Root
        TotalGames   = $totalGames
        Providers    = @($providerLaunchers).Count
        StaleRemoved = $staleRemoved
        Backup       = $rootInfo.Backup
        DryRun       = $false
    }
}
