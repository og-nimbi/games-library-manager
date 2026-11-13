# Legacy Games: launcher and per-game folders / uninstall records.

function Get-LegacyLauncherPath {
    $candidates = @(
        '%ProgramFiles(x86)%\Legacy Games\Legacy Games Launcher.exe',
        '%ProgramFiles%\Legacy Games\Legacy Games Launcher.exe',
        '%LOCALAPPDATA%\Legacy Games\Legacy Games Launcher.exe',
        '%LOCALAPPDATA%\Programs\Legacy Games\Legacy Games Launcher.exe'
    )
    $candidates += Get-StoreInstallCandidates -RelativePaths @('Legacy Games\Legacy Games Launcher.exe')

    $app = Get-InstalledApplications | Where-Object { $_.DisplayName -match '(?i)^Legacy Games' } | Select-Object -First 1
    if ($app) {
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe') { $candidates = @($app.DisplayIcon) + $candidates }
        if ($app.InstallLocation) {
            $candidates += (Join-Path $app.InstallLocation 'Legacy Games Launcher.exe')
        }
    }

    return Find-FirstExistingPath -Paths $candidates -PathType Leaf
}

function Get-LegacyGameRoots {
    $roots = @(
        '%ProgramFiles(x86)%\Legacy Games',
        '%ProgramFiles%\Legacy Games',
        '%LOCALAPPDATA%\Legacy Games',
        '%LOCALAPPDATA%\Programs\Legacy Games'
    )
    $roots += Get-StoreInstallCandidates -RelativePaths @('Legacy Games', 'Games\Legacy Games')

    $result = New-Object System.Collections.Generic.List[string]
    foreach ($root in $roots) {
        $expanded = Expand-PathValue $root
        if (!$expanded) { continue }
        if ((Test-Path -LiteralPath $expanded -PathType Container -ErrorAction SilentlyContinue) -and !($result -contains $expanded)) {
            $result.Add($expanded)
        }
    }
    return @($result)
}

function Get-LegacyProvider {
    $launcherPath = Get-LegacyLauncherPath
    $games = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    $apps = Get-InstalledApplications | Where-Object {
        $_.InstallLocation -and (
            $_.Publisher -match '(?i)Legacy Games' -or
            $_.DisplayName -match '(?i)Legacy Games' -or
            $_.InstallLocation -match '(?i)Legacy Games'
        ) -and $_.DisplayName -notmatch '(?i)^Legacy Games( Launcher)?$'
    }

    foreach ($app in $apps) {
        $key = $app.InstallLocation.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }

        $exe = $null
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe' -and (Test-Path -LiteralPath $app.DisplayIcon -PathType Leaf -ErrorAction SilentlyContinue)) { $exe = $app.DisplayIcon }
        if (!$exe) { $exe = Find-GameExecutable -Directory $app.InstallLocation -Depth 3 -PreferName $app.DisplayName }
        if (!$exe) { continue }

        $seen[$key] = $true
        $games.Add((New-GameEntry -Name $app.DisplayName -Provider 'Legacy Games' -ProviderKey 'legacyGames' -Kind 'StoreGame' `
            -Target $exe -IconPath $exe -InstallDir $app.InstallLocation -Source 'legacy-uninstall'))
    }

    foreach ($root in (Get-LegacyGameRoots)) {
        foreach ($folder in @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)) {
            $key = $folder.FullName.ToLowerInvariant()
            if ($seen.ContainsKey($key)) { continue }
            if ($folder.Name -match '(?i)^(app|bin|cache|data|logs?|redist|support)$') { continue }

            $exe = Find-GameExecutable -Directory $folder.FullName -Depth 3 -PreferName $folder.Name
            if (!$exe) { continue }

            $name = $folder.Name
            $match = $apps | Where-Object { $_.InstallLocation -and $_.InstallLocation.TrimEnd('\') -ieq $folder.FullName.TrimEnd('\') } | Select-Object -First 1
            if ($match) { $name = $match.DisplayName }

            $seen[$key] = $true
            $games.Add((New-GameEntry -Name $name -Provider 'Legacy Games' -ProviderKey 'legacyGames' -Kind 'StoreGame' `
                -Target $exe -IconPath $exe -InstallDir $folder.FullName -Source 'legacy-folder'))
        }
    }

    if (!$launcherPath -and $games.Count -eq 0) { return $null }

    $launcher = $null
    if ($launcherPath) {
        $launcher = New-GameEntry -Name 'Legacy Games' -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $launcherPath -IconPath $launcherPath -Source 'legacy-launcher'
    }

    return New-ProviderResult -Key 'legacyGames' -DisplayName 'Legacy Games' -Launcher $launcher -Games $games -IconPath $launcherPath
}
