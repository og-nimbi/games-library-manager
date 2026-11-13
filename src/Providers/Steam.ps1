# Steam: registry install path, libraryfolders.vdf, appmanifest_*.acf.

function Get-SteamInstallPath {
    $candidates = @(
        (Get-RegistryValue 'HKCU:\Software\Valve\Steam' 'SteamExe'),
        (Get-RegistryValue 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' 'InstallPath'),
        (Get-RegistryValue 'HKLM:\SOFTWARE\Valve\Steam' 'InstallPath')
    )

    $candidates += Get-StoreInstallCandidates -RelativePaths @('Steam\steam.exe', 'SteamLibrary\steam.exe')

    foreach ($candidate in $candidates) {
        if (!$candidate) { continue }
        $expanded = Expand-PathValue $candidate
        if (!$expanded) { continue }

        if (Test-Path -LiteralPath $expanded -PathType Leaf -ErrorAction SilentlyContinue) {
            if ([IO.Path]::GetFileName($expanded) -ieq 'steam.exe') { return $expanded }
            $nested = Join-Path $expanded 'steam.exe'
            if (Test-Path -LiteralPath $nested -PathType Leaf -ErrorAction SilentlyContinue) { return $nested }
            continue
        }

        $nested = Join-Path $expanded 'steam.exe'
        if (Test-Path -LiteralPath $nested -PathType Leaf -ErrorAction SilentlyContinue) { return $nested }
    }

    return $null
}

function Unescape-VdfPath {
    param([string]$Value)
    if (!$Value) { return $null }
    return ($Value -replace '\\\\', '\')
}

function Get-VdfField {
    param(
        [string]$Text,
        [string]$Name
    )

    $match = [regex]::Match($Text, '"' + [regex]::Escape($Name) + '"\s+"([^"]*)"')
    if ($match.Success) { return (Unescape-VdfPath $match.Groups[1].Value) }
    return $null
}

function Get-SteamLibraryFolders {
    param([string]$SteamExe)

    $folders = @{}
    $steamRoot = Split-Path -Parent $SteamExe
    $folders[[IO.Path]::GetFullPath($steamRoot)] = $true

    $vdf = Join-Path $steamRoot 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf -PathType Leaf -ErrorAction SilentlyContinue) {
        try {
            $text = Get-Content -LiteralPath $vdf -Raw -ErrorAction Stop
            foreach ($match in [regex]::Matches($text, '"path"\s+"([^"]+)"')) {
                $path = Unescape-VdfPath $match.Groups[1].Value
                $path = Expand-PathValue $path
                if ($path -and (Test-Path -LiteralPath $path -PathType Container -ErrorAction SilentlyContinue)) {
                    $folders[[IO.Path]::GetFullPath($path)] = $true
                }
            }
        } catch {
            Write-Log "Steam: could not read libraryfolders.vdf: $($_.Exception.Message)" -Level Debug
        }
    }

    foreach ($drive in (Get-AllFixedDriveRoots)) {
        foreach ($relative in @('SteamLibrary', 'Steam', 'Games\Steam')) {
            $candidate = Join-Path $drive $relative
            $apps = Join-Path $candidate 'steamapps'
            if (Test-Path -LiteralPath $apps -PathType Container -ErrorAction SilentlyContinue) {
                $folders[[IO.Path]::GetFullPath($candidate)] = $true
            }
        }
    }

    return @($folders.Keys)
}

function Get-SteamProvider {
    $steamExe = Get-SteamInstallPath
    $games = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    if ($steamExe) {
        foreach ($library in (Get-SteamLibraryFolders -SteamExe $steamExe)) {
            $appsDir = Join-Path $library 'steamapps'
            $commonDir = Join-Path $appsDir 'common'
            if (!(Test-Path -LiteralPath $appsDir -PathType Container -ErrorAction SilentlyContinue)) { continue }

            foreach ($manifest in @(Get-ChildItem -LiteralPath $appsDir -Filter 'appmanifest_*.acf' -File -ErrorAction SilentlyContinue)) {
                try {
                    $text = Get-Content -LiteralPath $manifest.FullName -Raw -ErrorAction Stop
                    $appId = Get-VdfField $text 'appid'
                    if (!$appId) { $appId = ($manifest.BaseName -replace '^appmanifest_', '') }
                    if ($seen.ContainsKey($appId)) { continue }

                    $name = Get-VdfField $text 'name'
                    $installDir = Get-VdfField $text 'installdir'
                    $stateFlags = Get-VdfField $text 'StateFlags'

                    if ($stateFlags) {
                        $stateNumber = 0
                        if ([int]::TryParse($stateFlags, [ref]$stateNumber)) {
                            if (($stateNumber -band 4) -eq 0) { continue }
                        }
                    }

                    if (!$name) { continue }
                    if ($appId -eq '228980') { continue }
                    if ($name -match '(?i)(steamworks common redistributables|steam linux runtime|proton|steamvr|soundtrack|dedicated server|redistributable)') { continue }

                    $gameDir = $null
                    if ($installDir) {
                        $candidate = Join-Path $commonDir $installDir
                        if (Test-Path -LiteralPath $candidate -PathType Container -ErrorAction SilentlyContinue) { $gameDir = $candidate }
                    }

                    $exe = $null
                    if ($gameDir) {
                        $exe = Find-GameExecutable -Directory $gameDir -Depth 3 -PreferName $installDir
                    }

                    $seen[$appId] = $true
                    $games.Add((New-GameEntry -Name $name -Provider 'Steam' -ProviderKey 'steam' -Kind 'StoreGame' `
                        -Target ('steam://rungameid/' + $appId) -IconPath $exe -InstallDir $gameDir -Id $appId -Source 'steam-appmanifest'))
                } catch {
                    Write-Log "Steam: could not read $($manifest.Name): $($_.Exception.Message)" -Level Warn
                }
            }
        }
    } else {
        Write-Log 'Steam: install path not found.' -Level Debug
    }

    if (!$steamExe -and $games.Count -eq 0) { return $null }

    $launcher = $null
    if ($steamExe) {
        $launcher = New-GameEntry -Name 'Steam' -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $steamExe -IconPath $steamExe -Source 'steam-registry'
    }

    return New-ProviderResult -Key 'steam' -DisplayName 'Steam' -Launcher $launcher -Games $games -IconPath $steamExe
}
