# Hi-Rez Studios launcher and game folders.

function Get-HiRezLauncherPath {
    $candidates = @(
        '%ProgramFiles(x86)%\Hi-Rez Studios\HiRezLauncherUI.exe',
        '%ProgramFiles%\Hi-Rez Studios\HiRezLauncherUI.exe',
        '%LOCALAPPDATA%\Hi-Rez Studios\HiRezLauncherUI.exe'
    )
    $candidates += Get-StoreInstallCandidates -RelativePaths @('Hi-Rez Studios\HiRezLauncherUI.exe')

    $app = Get-InstalledApplications | Where-Object { $_.DisplayName -match '(?i)^Hi-Rez' } | Select-Object -First 1
    if ($app) {
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe') { $candidates = @($app.DisplayIcon) + $candidates }
        if ($app.InstallLocation) { $candidates += (Join-Path $app.InstallLocation 'HiRezLauncherUI.exe') }
    }

    return Find-FirstExistingPath -Paths $candidates -PathType Leaf
}

function Get-HiRezGameRoots {
    $roots = @(
        '%ProgramFiles(x86)%\Hi-Rez Studios',
        '%ProgramFiles%\Hi-Rez Studios',
        '%LOCALAPPDATA%\Hi-Rez Studios'
    )
    $roots += Get-StoreInstallCandidates -RelativePaths @('Hi-Rez Studios', 'Games\Hi-Rez Studios')

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

function Get-HiRezProvider {
    $launcherPath = Get-HiRezLauncherPath
    $games = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    foreach ($root in (Get-HiRezGameRoots)) {
        foreach ($folder in @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)) {
            if ($folder.Name -match '(?i)^(launcher|redist|support|logs?|cache)$') { continue }
            $key = $folder.FullName.ToLowerInvariant()
            if ($seen.ContainsKey($key)) { continue }

            $exe = Find-GameExecutable -Directory $folder.FullName -Depth 4 -PreferName $folder.Name
            if (!$exe) { continue }

            $seen[$key] = $true
            $games.Add((New-GameEntry -Name $folder.Name -Provider 'Hi-Rez Studios' -ProviderKey 'hiRez' -Kind 'StoreGame' `
                -Target $exe -IconPath $exe -InstallDir $folder.FullName -Source 'hirez-folder'))
        }
    }

    $apps = Get-InstalledApplications | Where-Object {
        $_.InstallLocation -and
        ($_.Publisher -match '(?i)Hi-Rez' -or $_.DisplayName -match '(?i)^(SMITE|Paladins|Rogue Company|Realm Royale|Divine Knockout)') -and
        $_.DisplayName -notmatch '(?i)(launcher|redistributable|runtime|directx|visual c\+\+)'
    }

    foreach ($app in $apps) {
        $key = $app.DisplayName.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $exe = $null
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe' -and (Test-Path -LiteralPath $app.DisplayIcon -PathType Leaf -ErrorAction SilentlyContinue)) { $exe = $app.DisplayIcon }
        if (!$exe) { $exe = Find-GameExecutable -Directory $app.InstallLocation -Depth 4 -PreferName $app.DisplayName }
        if (!$exe) { continue }
        $seen[$key] = $true
        $games.Add((New-GameEntry -Name $app.DisplayName -Provider 'Hi-Rez Studios' -ProviderKey 'hiRez' -Kind 'StoreGame' `
            -Target $exe -IconPath $exe -InstallDir $app.InstallLocation -Source 'hirez-uninstall'))
    }

    if (!$launcherPath -and $games.Count -eq 0) { return $null }

    $launcher = $null
    if ($launcherPath) {
        $launcher = New-GameEntry -Name 'Hi-Rez Studios' -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $launcherPath -IconPath $launcherPath -Source 'hirez-launcher'
    }

    return New-ProviderResult -Key 'hiRez' -DisplayName 'Hi-Rez Studios' -Launcher $launcher -Games $games -IconPath $launcherPath
}
