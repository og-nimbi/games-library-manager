# Rockstar Games Launcher and Rockstar registry installs.

function Get-RockstarLauncherPath {
    $candidates = @(
        '%ProgramFiles%\Rockstar Games\Launcher\Launcher.exe',
        '%ProgramFiles(x86)%\Rockstar Games\Launcher\Launcher.exe',
        '%LOCALAPPDATA%\Rockstar Games\Launcher\Launcher.exe'
    )
    $candidates += Get-StoreInstallCandidates -RelativePaths @('Rockstar Games\Launcher\Launcher.exe')

    $app = Get-InstalledApplications | Where-Object { $_.DisplayName -match '(?i)^Rockstar Games Launcher$' } | Select-Object -First 1
    if ($app) {
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe') { $candidates = @($app.DisplayIcon) + $candidates }
        if ($app.InstallLocation) { $candidates += (Join-Path $app.InstallLocation 'Launcher.exe') }
    }

    return Find-FirstExistingPath -Paths $candidates -PathType Leaf
}

function Get-RockstarExeCandidates {
    param([string]$Name)

    if ($Name -match '(?i)Grand Theft Auto V|GTA V|GTAV') { return @('GTA5.exe', 'PlayGTAV.exe') }
    if ($Name -match '(?i)Red Dead Redemption 2|RDR2') { return @('RDR2.exe', 'PlayRDR2.exe') }
    if ($Name -match '(?i)Grand Theft Auto IV|GTA IV') { return @('GTAIV.exe', 'PlayGTAIV.exe') }
    if ($Name -match '(?i)L\.A\. Noire|LA Noire') { return @('LANoire.exe', 'L.A.Noire.exe') }
    if ($Name -match '(?i)Max Payne 3') { return @('MaxPayne3.exe') }
    if ($Name -match '(?i)Bully') { return @('Bully.exe') }
    return @()
}

function Get-RockstarRegistryGames {
    $games = New-Object System.Collections.Generic.List[object]
    $roots = @(
        'HKLM:\SOFTWARE\WOW6432Node\Rockstar Games',
        'HKLM:\SOFTWARE\Rockstar Games',
        'HKCU:\Software\Rockstar Games'
    )

    foreach ($root in $roots) {
        foreach ($key in (Get-RegistrySubKeys $root)) {
            if ($key.PSChildName -match '(?i)^(Launcher|Social Club|Rockstar Games Social Club)$') { continue }
            try {
                $props = Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction Stop
                $installDir = [string](Get-PropertyValue $props 'InstallFolder')
                if (!$installDir) { $installDir = [string](Get-PropertyValue $props 'InstallPath') }
                if (!$installDir) { continue }
                $installDir = Expand-PathValue $installDir
                if (!$installDir -or !(Test-Path -LiteralPath $installDir -PathType Container -ErrorAction SilentlyContinue)) { continue }

                $name = $key.PSChildName
                $exe = $null
                foreach ($relative in (Get-RockstarExeCandidates $name)) {
                    $candidate = Join-Path $installDir $relative
                    if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) { $exe = $candidate; break }
                }
                if (!$exe) { $exe = Find-GameExecutable -Directory $installDir -Depth 2 -PreferName $name }
                if (!$exe) { continue }

                $games.Add((New-GameEntry -Name $name -Provider 'Rockstar Games' -ProviderKey 'rockstar' -Kind 'StoreGame' `
                    -Target $exe -IconPath $exe -InstallDir $installDir -Source 'rockstar-registry'))
            } catch {
                Write-Log "Rockstar: could not read $($key.PSChildName): $($_.Exception.Message)" -Level Debug
            }
        }
    }

    return @(ConvertTo-Array $games)
}

function Get-RockstarProvider {
    $launcherPath = Get-RockstarLauncherPath
    $games = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    foreach ($game in (Get-RockstarRegistryGames)) {
        $key = $game.Name.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        $games.Add($game)
    }

    $apps = Get-InstalledApplications | Where-Object {
        $_.Publisher -match '(?i)Rockstar' -and
        $_.InstallLocation -and
        $_.DisplayName -notmatch '(?i)(Launcher|Social Club|redistributable|runtime|directx|visual c\+\+)'
    }

    foreach ($app in $apps) {
        $key = $app.DisplayName.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $exe = $null
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe' -and (Test-Path -LiteralPath $app.DisplayIcon -PathType Leaf -ErrorAction SilentlyContinue)) { $exe = $app.DisplayIcon }
        if (!$exe) { $exe = Find-GameExecutable -Directory $app.InstallLocation -Depth 2 -PreferName $app.DisplayName }
        if (!$exe) { continue }

        $seen[$key] = $true
        $games.Add((New-GameEntry -Name $app.DisplayName -Provider 'Rockstar Games' -ProviderKey 'rockstar' -Kind 'StoreGame' `
            -Target $exe -IconPath $exe -InstallDir $app.InstallLocation -Source 'rockstar-uninstall'))
    }

    if (!$launcherPath -and $games.Count -eq 0) { return $null }

    $launcher = $null
    if ($launcherPath) {
        $launcher = New-GameEntry -Name 'Rockstar Games' -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $launcherPath -IconPath $launcherPath -Source 'rockstar-launcher'
    }

    return New-ProviderResult -Key 'rockstar' -DisplayName 'Rockstar Games' -Launcher $launcher -Games $games -IconPath $launcherPath
}
