# Battle.net: launcher and known Blizzard game install keys.

function Get-BattleNetLauncherPath {
    $candidates = @(
        '%ProgramFiles(x86)%\Battle.net\Battle.net.exe',
        '%ProgramFiles%\Battle.net\Battle.net.exe',
        '%LOCALAPPDATA%\Battle.net\Battle.net.exe'
    )
    $candidates += Get-StoreInstallCandidates -RelativePaths @('Battle.net\Battle.net.exe')

    $app = Get-InstalledApplications | Where-Object { $_.DisplayName -match '(?i)^Battle\.net$' } | Select-Object -First 1
    if ($app) {
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe') { $candidates = @($app.DisplayIcon) + $candidates }
        if ($app.InstallLocation) { $candidates += (Join-Path $app.InstallLocation 'Battle.net.exe') }
    }

    return Find-FirstExistingPath -Paths $candidates -PathType Leaf
}

function Get-BattleNetGameDefinitions {
    return @(
        @{ Name = 'World of Warcraft'; Key = 'World of Warcraft'; Protocol = 'battlenet://WoW'; Exes = @('_retail_\Wow.exe', 'Wow.exe') },
        @{ Name = 'Diablo III'; Key = 'Diablo III'; Protocol = 'battlenet://D3'; Exes = @('Diablo III64.exe', 'x64\Diablo III64.exe', 'Diablo III.exe') },
        @{ Name = 'Diablo IV'; Key = 'Diablo IV'; Protocol = 'battlenet://D4'; Exes = @('Diablo IV.exe', 'Diablo IV Launcher.exe') },
        @{ Name = 'StarCraft II'; Key = 'StarCraft II'; Protocol = 'battlenet://S2'; Exes = @('SC2_x64.exe', 'SC2.exe') },
        @{ Name = 'Hearthstone'; Key = 'Hearthstone'; Protocol = 'battlenet://WTCG'; Exes = @('Hearthstone.exe') },
        @{ Name = 'Heroes of the Storm'; Key = 'Heroes of the Storm'; Protocol = 'battlenet://Heroes'; Exes = @('HeroesOfTheStorm_x64.exe', 'HeroesOfTheStorm.exe') },
        @{ Name = 'Overwatch'; Key = 'Overwatch'; Protocol = 'battlenet://Pro'; Exes = @('Overwatch.exe', '_retail_\Overwatch.exe') },
        @{ Name = 'Warcraft III'; Key = 'Warcraft III'; Protocol = 'battlenet://W3'; Exes = @('Warcraft III.exe', 'x86_64\Warcraft III.exe') }
    )
}

function Get-BattleNetGameInstallPath {
    param([string]$GameKey)

    $keys = @(
        ('HKLM:\SOFTWARE\WOW6432Node\Blizzard Entertainment\' + $GameKey),
        ('HKLM:\SOFTWARE\Blizzard Entertainment\' + $GameKey),
        ('HKCU:\Software\Blizzard Entertainment\' + $GameKey)
    )

    foreach ($key in $keys) {
        $path = Get-RegistryValue -Path $key -Name 'InstallPath'
        if ($path) {
            $expanded = Expand-PathValue ([string]$path)
            if ($expanded -and (Test-Path -LiteralPath $expanded -PathType Container -ErrorAction SilentlyContinue)) { return $expanded }
        }
    }

    return $null
}

function Get-BattleNetProvider {
    $launcherPath = Get-BattleNetLauncherPath
    $games = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    foreach ($definition in (Get-BattleNetGameDefinitions)) {
        $installDir = Get-BattleNetGameInstallPath -GameKey $definition.Key
        if (!$installDir) { continue }

        $exe = $null
        foreach ($relative in $definition.Exes) {
            $candidate = Join-Path $installDir $relative
            if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) { $exe = $candidate; break }
        }
        if (!$exe) { $exe = Find-GameExecutable -Directory $installDir -Depth 2 -PreferName $definition.Name }

        $target = $exe
        if (!$target) { $target = $definition.Protocol }

        $seen[$definition.Name.ToLowerInvariant()] = $true
        $games.Add((New-GameEntry -Name $definition.Name -Provider 'Battle.net' -ProviderKey 'battleNet' -Kind 'StoreGame' `
            -Target $target -IconPath $exe -InstallDir $installDir -Id $definition.Key -Source 'battlenet-registry'))
    }

    $apps = Get-InstalledApplications | Where-Object {
        $_.Publisher -match '(?i)Blizzard' -and
        $_.DisplayName -notmatch '(?i)(Battle\.net|Blizzard|redistributable|runtime|directx|visual c\+\+)' -and
        $_.InstallLocation
    }

    foreach ($app in $apps) {
        $key = $app.DisplayName.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $exe = $null
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe' -and (Test-Path -LiteralPath $app.DisplayIcon -PathType Leaf -ErrorAction SilentlyContinue)) { $exe = $app.DisplayIcon }
        if (!$exe) { $exe = Find-GameExecutable -Directory $app.InstallLocation -Depth 2 -PreferName $app.DisplayName }
        if (!$exe) { continue }

        $seen[$key] = $true
        $games.Add((New-GameEntry -Name $app.DisplayName -Provider 'Battle.net' -ProviderKey 'battleNet' -Kind 'StoreGame' `
            -Target $exe -IconPath $exe -InstallDir $app.InstallLocation -Source 'battlenet-uninstall'))
    }

    if (!$launcherPath -and $games.Count -eq 0) { return $null }

    $launcher = $null
    if ($launcherPath) {
        $launcher = New-GameEntry -Name 'Battle.net' -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $launcherPath -IconPath $launcherPath -Source 'battlenet-launcher'
    }

    return New-ProviderResult -Key 'battleNet' -DisplayName 'Battle.net' -Launcher $launcher -Games $games -IconPath $launcherPath
}
