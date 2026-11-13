# Epic Games: LauncherInstalled.dat and per-game .item manifests.

function Get-EpicInstalledApplication {
    return Get-InstalledApplications | Where-Object {
        $_.DisplayName -match '(?i)^Epic Games Launcher' -or
        $_.UninstallString -match '(?i)EpicGamesLauncher' -or
        ($_.Publisher -match '(?i)Epic Games' -and $_.DisplayName -match '(?i)Launcher')
    } | Select-Object -First 1
}

function Get-EpicLauncherPath {
    # Registry values and leftover files can survive an incomplete uninstall,
    # so only trust them when the launcher still has an uninstall record.
    $app = Get-EpicInstalledApplication
    if (!$app) {
        Write-Log 'Epic: launcher is not installed (no uninstall record); ignoring leftover files.' -Level Debug
        return $null
    }

    $candidates = @()

    if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe') { $candidates += $app.DisplayIcon }
    if ($app.InstallLocation) {
        $candidates += (Join-Path $app.InstallLocation 'Portal\Binaries\Win64\EpicGamesLauncher.exe')
        $candidates += (Join-Path $app.InstallLocation 'Portal\Binaries\Win32\EpicGamesLauncher.exe')
        $candidates += (Join-Path $app.InstallLocation 'EpicGamesLauncher.exe')
    }

    $candidates += @(
        (Get-RegistryValue 'HKCU:\Software\Epic Games\EOS' 'ModSdkCommand'),
        (Get-RegistryValue 'HKLM:\SOFTWARE\WOW6432Node\EpicGames\EpicGamesLauncher' 'AppDataPath')
    )

    $candidates += Get-StoreInstallCandidates -RelativePaths @(
        'Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe',
        'Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe'
    )
    $candidates += @(
        '%ProgramFiles%\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe',
        '%ProgramFiles(x86)%\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe'
    )

    return Find-FirstExistingPath -Paths $candidates -PathType Leaf
}

function Get-EpicManifestDirectories {
    $directories = @(
        (Join-Path $env:ProgramData 'Epic\EpicGamesLauncher\Data\Manifests')
    )

    foreach ($drive in (Get-AllFixedDriveRoots)) {
        $directories += (Join-Path $drive 'ProgramData\Epic\EpicGamesLauncher\Data\Manifests')
    }

    return @($directories | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container -ErrorAction SilentlyContinue) } | Sort-Object -Unique)
}

function Get-EpicProvider {
    $launcherPath = Get-EpicLauncherPath

    # Without the launcher, manifest leftovers cannot launch anything and must
    # not create an Epic Games folder or provider shortcut.
    if (!$launcherPath) { return $null }

    $games = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    foreach ($manifestDir in (Get-EpicManifestDirectories)) {
        foreach ($manifest in @(Get-ChildItem -LiteralPath $manifestDir -Filter '*.item' -File -ErrorAction SilentlyContinue)) {
            try {
                $item = Get-Content -LiteralPath $manifest.FullName -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            } catch {
                Write-Log "Epic: could not read $($manifest.Name): $($_.Exception.Message)" -Level Debug
                continue
            }

            $appName = Get-PropertyValue $item 'AppName'
            if (!$appName) { $appName = $manifest.BaseName }
            if ($seen.ContainsKey([string]$appName)) { continue }

            $categories = @(Get-PropertyValue $item 'AppCategories')
            if ($categories -match '(?i)(engine|plugin|asset|code)') { continue }

            $displayName = Get-PropertyValue $item 'DisplayName'
            if (!$displayName) { $displayName = Get-PropertyValue $item 'MandatoryAppFolderName' }
            if (!$displayName) { $displayName = [string]$appName }

            $installLocation = Get-PropertyValue $item 'InstallLocation'
            if ($installLocation) { $installLocation = Expand-PathValue ([string]$installLocation) }
            if (!$installLocation -or !(Test-Path -LiteralPath $installLocation -PathType Container -ErrorAction SilentlyContinue)) {
                Write-Log "Epic: skipping leftover manifest '$($manifest.Name)' (install folder is missing)." -Level Debug
                continue
            }

            $exe = $null
            $launchExecutable = Get-PropertyValue $item 'LaunchExecutable'
            if ($installLocation -and $launchExecutable) {
                $candidate = Join-Path $installLocation ([string]$launchExecutable)
                if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) { $exe = $candidate }
            }
            if (!$exe -and $installLocation) {
                $exe = Find-GameExecutable -Directory $installLocation -Depth 3 -PreferName ([string]$displayName)
            }

            $seen[[string]$appName] = $true
            $games.Add((New-GameEntry -Name ([string]$displayName) -Provider 'Epic Games' -ProviderKey 'epic' -Kind 'StoreGame' `
                -Target ('com.epicgames.launcher://apps/' + $appName + '?action=launch&silent=true') `
                -IconPath $exe -InstallDir $installLocation -Id ([string]$appName) -Source 'epic-manifest'))
        }
    }

    $installedData = Join-Path $env:ProgramData 'Epic\UnrealEngineLauncher\LauncherInstalled.dat'
    if (Test-Path -LiteralPath $installedData -PathType Leaf -ErrorAction SilentlyContinue) {
        try {
            $data = Get-Content -LiteralPath $installedData -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            foreach ($install in @(Get-PropertyValue $data 'InstallationList')) {
                $appName = [string](Get-PropertyValue $install 'AppName')
                if (!$appName -or $seen.ContainsKey($appName)) { continue }

                $installLocation = Expand-PathValue ([string](Get-PropertyValue $install 'InstallLocation'))
                if (!$installLocation -or !(Test-Path -LiteralPath $installLocation -PathType Container -ErrorAction SilentlyContinue)) { continue }

                $exe = Find-GameExecutable -Directory $installLocation -Depth 3 -PreferName $appName
                $seen[$appName] = $true
                $games.Add((New-GameEntry -Name $appName -Provider 'Epic Games' -ProviderKey 'epic' -Kind 'StoreGame' `
                    -Target ('com.epicgames.launcher://apps/' + $appName + '?action=launch&silent=true') `
                    -IconPath $exe -InstallDir $installLocation -Id $appName -Source 'epic-launcher-installed'))
            }
        } catch {
            Write-Log "Epic: could not read LauncherInstalled.dat: $($_.Exception.Message)" -Level Debug
        }
    }

    if (!$launcherPath -and $games.Count -eq 0) { return $null }

    $launcher = $null
    if ($launcherPath) {
        $launcher = New-GameEntry -Name 'Epic Games' -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $launcherPath -IconPath $launcherPath -Source 'epic-launcher'
    }

    return New-ProviderResult -Key 'epic' -DisplayName 'Epic Games' -Launcher $launcher -Games $games -IconPath $launcherPath
}
