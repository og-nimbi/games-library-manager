# Wargaming Game Center and World of Tanks / Warships / Warplanes.

function Get-WargamingLauncherPath {
    $candidates = @(
        '%ProgramFiles(x86)%\Wargaming.net\GameCenter\WargamingGameCenter.exe',
        '%ProgramFiles%\Wargaming.net\GameCenter\WargamingGameCenter.exe',
        '%LOCALAPPDATA%\Wargaming.net\GameCenter\WargamingGameCenter.exe'
    )
    $candidates += Get-StoreInstallCandidates -RelativePaths @(
        'Wargaming.net\GameCenter\WargamingGameCenter.exe',
        'Wargaming.net\GameCenter\wgc.exe'
    )

    $app = Get-InstalledApplications | Where-Object { $_.DisplayName -match '(?i)^Wargaming Game Center$' } | Select-Object -First 1
    if ($app) {
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe') { $candidates = @($app.DisplayIcon) + $candidates }
        if ($app.InstallLocation) { $candidates += (Join-Path $app.InstallLocation 'WargamingGameCenter.exe') }
    }

    return Find-FirstExistingPath -Paths $candidates -PathType Leaf
}

function Get-WargamingDefinitions {
    return @(
        @{ Name = 'World of Tanks'; Exes = @('WorldOfTanks.exe', 'win64\WorldOfTanks.exe', 'World_of_Tanks\WorldOfTanks.exe') },
        @{ Name = 'World of Warships'; Exes = @('WorldOfWarships.exe', 'bin\Win64\WorldOfWarships64.exe', 'World_of_Warships\WorldOfWarships.exe') },
        @{ Name = 'World of Warplanes'; Exes = @('WorldOfWarplanes.exe', 'World_of_Warplanes\WorldOfWarplanes.exe') }
    )
}

function Get-WargamingProvider {
    $launcherPath = Get-WargamingLauncherPath
    $games = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    $searchRoots = Get-StoreInstallCandidates -RelativePaths @(
        'Wargaming.net',
        'Games\Wargaming.net',
        'Games\World_of_Tanks',
        'Games\World_of_Warships',
        'Games\World_of_Warplanes'
    )

    foreach ($definition in (Get-WargamingDefinitions)) {
        $installDir = $null
        $exe = $null

        foreach ($root in $searchRoots) {
            if (!(Test-Path -LiteralPath $root -PathType Container -ErrorAction SilentlyContinue)) { continue }
            foreach ($relative in $definition.Exes) {
                $candidate = Join-Path $root $relative
                if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) {
                    $installDir = $root
                    $exe = $candidate
                    break
                }
            }
            if ($exe) { break }
        }

        if (!$exe) {
            $app = Get-InstalledApplications | Where-Object { $_.DisplayName -ieq $definition.Name -and $_.InstallLocation } | Select-Object -First 1
            if ($app) {
                $installDir = $app.InstallLocation
                if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe' -and (Test-Path -LiteralPath $app.DisplayIcon -PathType Leaf -ErrorAction SilentlyContinue)) {
                    $exe = $app.DisplayIcon
                } else {
                    $exe = Find-GameExecutable -Directory $installDir -Depth 3 -PreferName $definition.Name
                }
            }
        }

        if (!$exe) { continue }
        $seen[$definition.Name.ToLowerInvariant()] = $true
        $games.Add((New-GameEntry -Name $definition.Name -Provider 'Wargaming' -ProviderKey 'wargaming' -Kind 'StoreGame' `
            -Target $exe -IconPath $exe -InstallDir $installDir -Source 'wargaming-known'))
    }

    $apps = Get-InstalledApplications | Where-Object {
        $_.InstallLocation -and
        ($_.Publisher -match '(?i)Wargaming' -or $_.DisplayName -match '(?i)^World of (Tanks|Warships|Warplanes)') -and
        $_.DisplayName -notmatch '(?i)(Game Center|redistributable|runtime|directx|visual c\+\+)'
    }

    foreach ($app in $apps) {
        $key = $app.DisplayName.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $exe = $null
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe' -and (Test-Path -LiteralPath $app.DisplayIcon -PathType Leaf -ErrorAction SilentlyContinue)) { $exe = $app.DisplayIcon }
        if (!$exe) { $exe = Find-GameExecutable -Directory $app.InstallLocation -Depth 3 -PreferName $app.DisplayName }
        if (!$exe) { continue }
        $seen[$key] = $true
        $games.Add((New-GameEntry -Name $app.DisplayName -Provider 'Wargaming' -ProviderKey 'wargaming' -Kind 'StoreGame' `
            -Target $exe -IconPath $exe -InstallDir $app.InstallLocation -Source 'wargaming-uninstall'))
    }

    if (!$launcherPath -and $games.Count -eq 0) { return $null }

    $launcher = $null
    if ($launcherPath) {
        $launcher = New-GameEntry -Name 'Wargaming Game Center' -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $launcherPath -IconPath $launcherPath -Source 'wargaming-launcher'
    }

    return New-ProviderResult -Key 'wargaming' -DisplayName 'Wargaming' -Launcher $launcher -Games $games -IconPath $launcherPath
}
