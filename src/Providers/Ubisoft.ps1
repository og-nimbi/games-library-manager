# Ubisoft Connect: launcher, Installs registry keys, uninstall records.

function Get-UbisoftLauncherPath {
    $candidates = @(
        '%ProgramFiles(x86)%\Ubisoft\Ubisoft Game Launcher\UbisoftConnect.exe',
        '%ProgramFiles%\Ubisoft\Ubisoft Game Launcher\UbisoftConnect.exe',
        '%LOCALAPPDATA%\Ubisoft\Ubisoft Game Launcher\UbisoftConnect.exe',
        '%ProgramFiles(x86)%\Ubisoft\Ubisoft Game Launcher\UbisoftGameLauncher.exe',
        '%ProgramFiles%\Ubisoft\Ubisoft Game Launcher\UbisoftGameLauncher.exe'
    )
    $candidates += Get-StoreInstallCandidates -RelativePaths @(
        'Ubisoft\Ubisoft Game Launcher\UbisoftConnect.exe',
        'Ubisoft\Ubisoft Game Launcher\UbisoftGameLauncher.exe'
    )

    $app = Get-InstalledApplications | Where-Object { $_.DisplayName -match '(?i)^Ubisoft Connect$' } | Select-Object -First 1
    if ($app) {
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe') { $candidates = @($app.DisplayIcon) + $candidates }
        if ($app.InstallLocation) {
            $candidates += (Join-Path $app.InstallLocation 'UbisoftConnect.exe')
            $candidates += (Join-Path $app.InstallLocation 'UbisoftGameLauncher.exe')
        }
    }

    return Find-FirstExistingPath -Paths $candidates -PathType Leaf
}

function Get-UbisoftRegistryGames {
    $games = New-Object System.Collections.Generic.List[object]
    $roots = @(
        'HKLM:\SOFTWARE\WOW6432Node\Ubisoft\Launcher\Installs',
        'HKLM:\SOFTWARE\Ubisoft\Launcher\Installs',
        'HKCU:\Software\Ubisoft\Launcher\Installs'
    )
    $uninstallApps = Get-InstalledApplications

    foreach ($root in $roots) {
        foreach ($key in (Get-RegistrySubKeys $root)) {
            try {
                $props = Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction Stop
                $installDir = [string](Get-PropertyValue $props 'InstallDir')
                if (!$installDir) { continue }
                $installDir = Expand-PathValue $installDir
                if (!$installDir -or !(Test-Path -LiteralPath $installDir -PathType Container -ErrorAction SilentlyContinue)) { continue }

                $installId = [string](Get-PropertyValue $props 'InstallId')
                if (!$installId) { $installId = $key.PSChildName }

                $name = [string](Get-PropertyValue $props 'DisplayName')
                if (!$name) {
                    $match = $uninstallApps | Where-Object { $_.InstallLocation -and $_.InstallLocation.TrimEnd('\') -ieq $installDir.TrimEnd('\') } | Select-Object -First 1
                    if ($match) { $name = $match.DisplayName }
                }
                if (!$name) { $name = $key.PSChildName }

                $exe = Find-GameExecutable -Directory $installDir -Depth 3 -PreferName $name
                $target = $exe
                if (!$target -and $installId) { $target = 'uplay://launch/' + $installId + '/0' }
                if (!$target) { continue }

                $games.Add((New-GameEntry -Name $name -Provider 'Ubisoft Connect' -ProviderKey 'ubisoft' -Kind 'StoreGame' `
                    -Target $target -IconPath $exe -InstallDir $installDir -Id $installId -Source 'ubisoft-registry'))
            } catch {
                Write-Log "Ubisoft: could not read $($key.PSChildName): $($_.Exception.Message)" -Level Debug
            }
        }
    }

    return @(ConvertTo-Array $games)
}

function Get-UbisoftProvider {
    $launcherPath = Get-UbisoftLauncherPath
    $games = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    foreach ($game in (Get-UbisoftRegistryGames)) {
        $key = $game.InstallDir.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        $games.Add($game)
    }

    $apps = Get-InstalledApplications | Where-Object {
        $_.InstallLocation -and
        ($_.Publisher -match '(?i)Ubisoft' -or $_.Publisher -match '(?i)Uplay') -and
        $_.DisplayName -notmatch '(?i)(Ubisoft Connect|Uplay|redistributable|runtime|directx|visual c\+\+)'
    }

    foreach ($app in $apps) {
        $key = $app.InstallLocation.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }

        $exe = $null
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe' -and (Test-Path -LiteralPath $app.DisplayIcon -PathType Leaf -ErrorAction SilentlyContinue)) { $exe = $app.DisplayIcon }
        if (!$exe) { $exe = Find-GameExecutable -Directory $app.InstallLocation -Depth 3 -PreferName $app.DisplayName }
        if (!$exe) { continue }

        $seen[$key] = $true
        $games.Add((New-GameEntry -Name $app.DisplayName -Provider 'Ubisoft Connect' -ProviderKey 'ubisoft' -Kind 'StoreGame' `
            -Target $exe -IconPath $exe -InstallDir $app.InstallLocation -Source 'ubisoft-uninstall'))
    }

    if (!$launcherPath -and $games.Count -eq 0) { return $null }

    $launcher = $null
    if ($launcherPath) {
        $launcher = New-GameEntry -Name 'Ubisoft Connect' -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $launcherPath -IconPath $launcherPath -Source 'ubisoft-launcher'
    }

    return New-ProviderResult -Key 'ubisoft' -DisplayName 'Ubisoft Connect' -Launcher $launcher -Games $games -IconPath $launcherPath
}
