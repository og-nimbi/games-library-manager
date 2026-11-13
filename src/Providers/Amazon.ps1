# Amazon Games: launcher, library folders, uninstall records, lightweight manifests.

function Get-AmazonLauncherPath {
    $candidates = @(
        '%LOCALAPPDATA%\Amazon Games\App\Amazon Games.exe',
        '%ProgramFiles%\Amazon Games\App\Amazon Games.exe',
        '%ProgramFiles(x86)%\Amazon Games\App\Amazon Games.exe'
    )
    $candidates += Get-StoreInstallCandidates -RelativePaths @('Amazon Games\App\Amazon Games.exe')

    $app = Get-InstalledApplications | Where-Object { $_.DisplayName -ieq 'Amazon Games' } | Select-Object -First 1
    if ($app) {
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe') { $candidates = @($app.DisplayIcon) + $candidates }
        if ($app.InstallLocation) { $candidates += (Join-Path $app.InstallLocation 'App\Amazon Games.exe') }
    }

    return Find-FirstExistingPath -Paths $candidates -PathType Leaf
}

function Get-AmazonGameRoots {
    $roots = Get-StoreInstallCandidates -RelativePaths @(
        'Amazon Games\Library',
        'Amazon Games\Games',
        'Games\Amazon Games',
        'Games\Amazon'
    )

    $result = New-Object System.Collections.Generic.List[string]
    foreach ($root in $roots) {
        if ($root -and (Test-Path -LiteralPath $root -PathType Container -ErrorAction SilentlyContinue) -and !($result -contains $root)) {
            $result.Add($root)
        }
    }
    return @($result)
}

function Get-AmazonJsonGames {
    $games = New-Object System.Collections.Generic.List[object]
    $dataRoots = @(
        (Join-Path $env:LOCALAPPDATA 'Amazon Games\Data\Games'),
        (Join-Path $env:ProgramData 'Amazon Games\Data\Games')
    )

    foreach ($root in $dataRoots) {
        foreach ($file in (Get-JsonFiles -Directory $root -Depth 2)) {
            try {
                $json = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            } catch { continue }

            $installLocation = [string](Get-PropertyValue $json 'InstallLocation')
            if (!$installLocation) { $installLocation = [string](Get-PropertyValue $json 'installLocation') }
            if (!$installLocation) { continue }
            $installLocation = Expand-PathValue $installLocation
            if (!$installLocation -or !(Test-Path -LiteralPath $installLocation -PathType Container -ErrorAction SilentlyContinue)) { continue }

            $name = [string](Get-PropertyValue $json 'ProductTitle')
            if (!$name) { $name = [string](Get-PropertyValue $json 'DisplayName') }
            if (!$name) { $name = [string](Get-PropertyValue $json 'GameName') }
            if (!$name) { $name = Split-Path -Leaf $installLocation }

            $exe = Find-GameExecutable -Directory $installLocation -Depth 3 -PreferName $name
            if (!$exe) { continue }

            $games.Add((New-GameEntry -Name $name -Provider 'Amazon Games' -ProviderKey 'amazon' -Kind 'StoreGame' `
                -Target $exe -IconPath $exe -InstallDir $installLocation -Id ([string](Get-PropertyValue $json 'Id')) -Source 'amazon-manifest'))
        }
    }

    return @(ConvertTo-Array $games)
}

function Get-AmazonProvider {
    $launcherPath = Get-AmazonLauncherPath
    $games = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    $uninstallGames = Get-InstalledApplications | Where-Object {
        $_.Publisher -match '(?i)amazon' -and $_.DisplayName -notmatch '(?i)^Amazon Games$' -and $_.InstallLocation
    }

    foreach ($app in $uninstallGames) {
        $key = $app.InstallLocation.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $exe = $null
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe' -and (Test-Path -LiteralPath $app.DisplayIcon -PathType Leaf -ErrorAction SilentlyContinue)) { $exe = $app.DisplayIcon }
        if (!$exe) { $exe = Find-GameExecutable -Directory $app.InstallLocation -Depth 3 -PreferName $app.DisplayName }
        if (!$exe) { continue }
        $seen[$key] = $true
        $games.Add((New-GameEntry -Name $app.DisplayName -Provider 'Amazon Games' -ProviderKey 'amazon' -Kind 'StoreGame' `
            -Target $exe -IconPath $exe -InstallDir $app.InstallLocation -Source 'amazon-uninstall'))
    }

    foreach ($root in (Get-AmazonGameRoots)) {
        foreach ($folder in @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)) {
            $key = $folder.FullName.ToLowerInvariant()
            if ($seen.ContainsKey($key)) { continue }
            if ($folder.Name -match '(?i)^(app|data|library|games|cache|logs?)$') { continue }

            $exe = Find-GameExecutable -Directory $folder.FullName -Depth 3 -PreferName $folder.Name
            if (!$exe) { continue }

            $name = $folder.Name
            $match = $uninstallGames | Where-Object { $_.InstallLocation -and $_.InstallLocation.TrimEnd('\') -ieq $folder.FullName.TrimEnd('\') } | Select-Object -First 1
            if ($match) { $name = $match.DisplayName }

            $seen[$key] = $true
            $games.Add((New-GameEntry -Name $name -Provider 'Amazon Games' -ProviderKey 'amazon' -Kind 'StoreGame' `
                -Target $exe -IconPath $exe -InstallDir $folder.FullName -Source 'amazon-folder'))
        }
    }

    foreach ($game in (Get-AmazonJsonGames)) {
        $key = $game.InstallDir.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        $games.Add($game)
    }

    if (!$launcherPath -and $games.Count -eq 0) { return $null }

    $launcher = $null
    if ($launcherPath) {
        $launcher = New-GameEntry -Name 'Amazon Games' -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $launcherPath -IconPath $launcherPath -Source 'amazon-launcher'
    }

    return New-ProviderResult -Key 'amazon' -DisplayName 'Amazon Games' -Launcher $launcher -Games $games -IconPath $launcherPath
}
