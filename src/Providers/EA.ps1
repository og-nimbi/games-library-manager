# EA app / Origin: launcher, uninstall records, EA Games registry keys.

function Get-EaLauncherPath {
    $candidates = @(
        '%ProgramFiles%\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe',
        '%ProgramFiles(x86)%\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe',
        '%LOCALAPPDATA%\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe',
        '%ProgramFiles(x86)%\Origin\Origin.exe',
        '%ProgramFiles%\Origin\Origin.exe'
    )
    $candidates += Get-StoreInstallCandidates -RelativePaths @(
        'Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe',
        'Origin\Origin.exe'
    )

    $app = Get-InstalledApplications | Where-Object { $_.DisplayName -match '(?i)^(EA app|Origin)$' } | Select-Object -First 1
    if ($app) {
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe') { $candidates = @($app.DisplayIcon) + $candidates }
        if ($app.InstallLocation) {
            $candidates += (Join-Path $app.InstallLocation 'EA Desktop\EADesktop.exe')
            $candidates += (Join-Path $app.InstallLocation 'Origin.exe')
        }
    }

    return Find-FirstExistingPath -Paths $candidates -PathType Leaf
}

function Get-EaRegistryGames {
    $games = New-Object System.Collections.Generic.List[object]
    $roots = @(
        'HKLM:\SOFTWARE\WOW6432Node\EA Games',
        'HKLM:\SOFTWARE\EA Games',
        'HKCU:\Software\EA Games',
        'HKCU:\Software\Electronic Arts\EA Games'
    )

    foreach ($root in $roots) {
        foreach ($key in (Get-RegistrySubKeys $root)) {
            try {
                $props = Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction Stop
                $name = [string](Get-PropertyValue $props 'DisplayName')
                if (!$name) { $name = $key.PSChildName }

                $installDir = [string](Get-PropertyValue $props 'Install Dir')
                if (!$installDir) { $installDir = [string](Get-PropertyValue $props 'InstallLocation') }
                if (!$installDir) { $installDir = [string](Get-PropertyValue $props 'InstallPath') }
                if (!$installDir) { continue }
                $installDir = Expand-PathValue $installDir
                if (!$installDir -or !(Test-Path -LiteralPath $installDir -PathType Container -ErrorAction SilentlyContinue)) { continue }

                $exe = Find-GameExecutable -Directory $installDir -Depth 3 -PreferName $name
                if (!$exe) { continue }

                $games.Add((New-GameEntry -Name $name -Provider 'EA app' -ProviderKey 'ea' -Kind 'StoreGame' `
                    -Target $exe -IconPath $exe -InstallDir $installDir -Id ([string](Get-PropertyValue $props 'GameID')) -Source 'ea-registry'))
            } catch {
                Write-Log "EA: could not read $($key.PSChildName): $($_.Exception.Message)" -Level Debug
            }
        }
    }

    return @(ConvertTo-Array $games)
}

function Get-EaProvider {
    $launcherPath = Get-EaLauncherPath
    $games = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    $apps = Get-InstalledApplications | Where-Object {
        $_.InstallLocation -and
        ($_.Publisher -match '(?i)Electronic Arts' -or $_.Publisher -match '(?i)^EA$') -and
        $_.DisplayName -notmatch '(?i)(EA app|Origin|EA Desktop|EA Help|EA Connect|EA Update|AntiCheat|redistributable|runtime|directx|visual c\+\+)'
    }

    foreach ($app in $apps) {
        $key = $app.InstallLocation.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }

        $exe = $null
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe' -and (Test-Path -LiteralPath $app.DisplayIcon -PathType Leaf -ErrorAction SilentlyContinue)) { $exe = $app.DisplayIcon }
        if (!$exe) { $exe = Find-GameExecutable -Directory $app.InstallLocation -Depth 3 -PreferName $app.DisplayName }
        if (!$exe) { continue }

        $seen[$key] = $true
        $games.Add((New-GameEntry -Name $app.DisplayName -Provider 'EA app' -ProviderKey 'ea' -Kind 'StoreGame' `
            -Target $exe -IconPath $exe -InstallDir $app.InstallLocation -Source 'ea-uninstall'))
    }

    foreach ($game in (Get-EaRegistryGames)) {
        $key = $game.InstallDir.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        $games.Add($game)
    }

    if (!$launcherPath -and $games.Count -eq 0) { return $null }

    $launcher = $null
    if ($launcherPath) {
        $launcher = New-GameEntry -Name 'EA app' -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $launcherPath -IconPath $launcherPath -Source 'ea-launcher'
    }

    return New-ProviderResult -Key 'ea' -DisplayName 'EA app' -Launcher $launcher -Games $games -IconPath $launcherPath
}
