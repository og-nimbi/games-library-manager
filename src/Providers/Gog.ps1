# GOG: Galaxy launcher, GOG.com game registry keys, GOG Games folders.

function Get-GogLauncherPath {
    $candidates = @(
        (Get-RegistryValue 'HKCU:\Software\GOG.com\GalaxyClient\paths' 'client'),
        (Get-RegistryValue 'HKCU:\Software\GOG.com\GalaxyClient\paths' 'clientExecutable'),
        (Get-RegistryValue 'HKCU:\Software\GOG.com\GalaxyClient' 'InstallPath'),
        (Get-RegistryValue 'HKLM:\SOFTWARE\WOW6432Node\GOG.com\GalaxyClient' 'InstallPath')
    )

    $galaxy = Get-InstalledApplications | Where-Object { $_.DisplayName -match '(?i)^GOG Galaxy$' } | Select-Object -First 1
    if ($galaxy) {
        if ($galaxy.DisplayIcon -and [IO.Path]::GetExtension($galaxy.DisplayIcon) -ieq '.exe') { $candidates += $galaxy.DisplayIcon }
        if ($galaxy.InstallLocation) { $candidates += (Join-Path $galaxy.InstallLocation 'GalaxyClient.exe') }
    }

    $candidates += Get-StoreInstallCandidates -RelativePaths @(
        'GOG Galaxy\GalaxyClient.exe',
        'GOG.com\GalaxyClient\GalaxyClient.exe',
        'Program Files\GOG Galaxy\GalaxyClient.exe'
    )
    $candidates += @(
        '%ProgramFiles(x86)%\GOG Galaxy\GalaxyClient.exe',
        '%ProgramFiles%\GOG Galaxy\GalaxyClient.exe'
    )

    foreach ($candidate in $candidates) {
        if (!$candidate) { continue }
        $path = Expand-PathValue $candidate
        if (!$path) { continue }
        if (Test-Path -LiteralPath $path -PathType Leaf -ErrorAction SilentlyContinue) { return $path }
        $nested = Join-Path $path 'GalaxyClient.exe'
        if (Test-Path -LiteralPath $nested -PathType Leaf -ErrorAction SilentlyContinue) { return $nested }
    }

    return $null
}

function Get-GogRegistryGames {
    $games = New-Object System.Collections.Generic.List[object]
    $seen = @{}
    $roots = @(
        'HKCU:\Software\GOG.com\Games',
        'HKLM:\SOFTWARE\GOG.com\Games',
        'HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games'
    )

    foreach ($root in $roots) {
        foreach ($key in (Get-RegistrySubKeys $root)) {
            try {
                $props = Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction Stop
                $gameId = [string](Get-PropertyValue $props 'gameID')
                if (!$gameId) { $gameId = $key.PSChildName }
                if ($seen.ContainsKey($gameId)) { continue }

                $name = [string](Get-PropertyValue $props 'gameName')
                if (!$name) { $name = [string](Get-PropertyValue $props 'displayName') }
                if (!$name) { continue }

                $installDir = [string](Get-PropertyValue $props 'path')
                if ($installDir) { $installDir = Expand-PathValue $installDir }

                $exe = [string](Get-PropertyValue $props 'exe')
                if ($exe) {
                    $exe = Expand-PathValue $exe
                    if (![IO.Path]::IsPathRooted($exe) -and $installDir) { $exe = Join-Path $installDir $exe }
                }
                if (!$exe -or !(Test-Path -LiteralPath $exe -PathType Leaf -ErrorAction SilentlyContinue)) {
                    if ($installDir) { $exe = Find-GameExecutable -Directory $installDir -Depth 3 -PreferName $name }
                }

                $target = $exe
                if (!$target -and $gameId) { $target = 'goggalaxy://openGameView/' + $gameId }
                if (!$target) { continue }

                $workingDir = [string](Get-PropertyValue $props 'workingDir')
                if ($workingDir) { $workingDir = Expand-PathValue $workingDir }

                $seen[$gameId] = $true
                $games.Add((New-GameEntry -Name $name -Provider 'GOG' -ProviderKey 'gog' -Kind 'StoreGame' `
                    -Target $target -WorkingDirectory $workingDir -IconPath $exe -InstallDir $installDir -Id $gameId -Source 'gog-registry'))
            } catch {
                Write-Log "GOG: could not read $($key.PSChildName): $($_.Exception.Message)" -Level Debug
            }
        }
    }

    return @(ConvertTo-Array $games)
}

function Get-GogFolderGames {
    $games = New-Object System.Collections.Generic.List[object]
    $seenDirs = @{}
    $roots = Get-StoreInstallCandidates -RelativePaths @('GOG Games', 'GOG\Games', 'Games\GOG')

    foreach ($root in $roots) {
        if (!(Test-Path -LiteralPath $root -PathType Container -ErrorAction SilentlyContinue)) { continue }
        foreach ($folder in @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)) {
            $key = $folder.FullName.ToLowerInvariant()
            if ($seenDirs.ContainsKey($key)) { continue }
            $exe = Find-GameExecutable -Directory $folder.FullName -Depth 3 -PreferName $folder.Name
            if (!$exe) { continue }
            $seenDirs[$key] = $true
            $games.Add((New-GameEntry -Name $folder.Name -Provider 'GOG' -ProviderKey 'gog' -Kind 'StoreGame' `
                -Target $exe -IconPath $exe -InstallDir $folder.FullName -Source 'gog-folder'))
        }
    }

    return @(ConvertTo-Array $games)
}

function Get-GogProvider {
    $launcherPath = Get-GogLauncherPath
    $games = New-Object System.Collections.Generic.List[object]
    $seenTargets = @{}

    foreach ($game in (@(Get-GogRegistryGames) + @(Get-GogFolderGames))) {
        $key = $game.Name.ToLowerInvariant()
        if ($seenTargets.ContainsKey($key)) { continue }
        $seenTargets[$key] = $true
        $games.Add($game)
    }

    if (!$launcherPath -and $games.Count -eq 0) { return $null }

    $launcher = $null
    if ($launcherPath) {
        $launcher = New-GameEntry -Name 'GOG Galaxy' -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $launcherPath -IconPath $launcherPath -Source 'gog-galaxy'
    }

    return New-ProviderResult -Key 'gog' -DisplayName 'GOG' -Launcher $launcher -Games $games -IconPath $launcherPath
}
