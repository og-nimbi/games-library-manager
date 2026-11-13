# Riot Games: Riot Client and installed Riot product folders.

function Get-RiotLauncherPath {
    $candidates = @(
        '%ProgramFiles%\Riot Games\Riot Client\RiotClientServices.exe',
        '%ProgramFiles(x86)%\Riot Games\Riot Client\RiotClientServices.exe'
    )
    $candidates += Get-StoreInstallCandidates -RelativePaths @('Riot Games\Riot Client\RiotClientServices.exe')

    $app = Get-InstalledApplications | Where-Object { $_.DisplayName -match '(?i)^Riot Client$' } | Select-Object -First 1
    if ($app) {
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe') { $candidates = @($app.DisplayIcon) + $candidates }
        if ($app.InstallLocation) { $candidates += (Join-Path $app.InstallLocation 'RiotClientServices.exe') }
    }

    return Find-FirstExistingPath -Paths $candidates -PathType Leaf
}

function Get-RiotGameDefinitions {
    return @(
        @{ Name = 'League of Legends'; Folder = 'League of Legends'; Product = 'league_of_legends'; Exes = @('LeagueClient.exe', 'Game\League of Legends.exe') },
        @{ Name = 'VALORANT'; Folder = 'VALORANT'; Product = 'valorant'; Exes = @('live\VALORANT.exe', 'ShooterGame\Binaries\Win64\VALORANT-Win64-Shipping.exe') },
        @{ Name = 'Legends of Runeterra'; Folder = 'Legends of Runeterra'; Product = 'bacon_league'; Exes = @('Legends of Runeterra.exe') }
    )
}

function Get-RiotProvider {
    $launcherPath = Get-RiotLauncherPath
    $games = New-Object System.Collections.Generic.List[object]

    $riotRoots = @(
        '%ProgramFiles%\Riot Games',
        '%ProgramFiles(x86)%\Riot Games'
    )
    foreach ($drive in @(Get-AllFixedDriveRoots)) {
        $riotRoots += (Join-Path $drive 'Riot Games')
    }
    $riotRoots += Get-StoreInstallCandidates -RelativePaths @('Riot Games')

    foreach ($definition in (Get-RiotGameDefinitions)) {
        $installDir = $null
        foreach ($root in $riotRoots) {
            $expanded = Expand-PathValue $root
            if (!$expanded) { continue }
            $candidate = Join-Path $expanded $definition.Folder
            if (Test-Path -LiteralPath $candidate -PathType Container -ErrorAction SilentlyContinue) {
                $installDir = $candidate
                break
            }
        }
        if (!$installDir) { continue }

        $exe = $null
        foreach ($relative in $definition.Exes) {
            $candidate = Join-Path $installDir $relative
            if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) { $exe = $candidate; break }
        }
        if (!$exe) { $exe = Find-GameExecutable -Directory $installDir -Depth 4 -PreferName $definition.Name }

        $target = $exe
        $arguments = ''
        if ($launcherPath) {
            $target = $launcherPath
            $arguments = '--launch-product=' + $definition.Product + ' --launch-patchline=live'
        }
        if (!$target) { continue }

        $icon = $exe
        if (!$icon) { $icon = $launcherPath }

        $games.Add((New-GameEntry -Name $definition.Name -Provider 'Riot Games' -ProviderKey 'riot' -Kind 'StoreGame' `
            -Target $target -Arguments $arguments -IconPath $icon -InstallDir $installDir -Id $definition.Product -Source 'riot-folder'))
    }

    if (!$launcherPath -and $games.Count -eq 0) { return $null }

    $launcher = $null
    if ($launcherPath) {
        $launcher = New-GameEntry -Name 'Riot Client' -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $launcherPath -IconPath $launcherPath -Source 'riot-launcher'
    }

    return New-ProviderResult -Key 'riot' -DisplayName 'Riot Games' -Launcher $launcher -Games $games -IconPath $launcherPath
}
