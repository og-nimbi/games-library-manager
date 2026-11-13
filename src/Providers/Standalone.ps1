# Standalone games: known launchers/install paths, registry records, extra roots.

function ConvertTo-StandaloneDirectory {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $expanded = Expand-PathValue $Value
    if (!$expanded) { return $null }

    if (Test-Path -LiteralPath $expanded -PathType Container -ErrorAction SilentlyContinue) {
        return $expanded
    }

    if (Test-Path -LiteralPath $expanded -PathType Leaf -ErrorAction SilentlyContinue) {
        $name = [IO.Path]::GetFileName($expanded)
        if ($name -match '(?i)\.exe$' -and $name -notmatch '(?i)^(unins|uninstall)') {
            return (Split-Path -Parent $expanded)
        }
    }

    return $null
}

function Get-StandaloneRegistryDirectory {
    param([string[]]$Paths)

    $valueNames = @(
        'InstallPath', 'Install Path', 'InstallLocation', 'Install Location',
        'Install Dir', 'InstallDir', 'Install_Dir', 'Path', 'GamePath', 'Game Path',
        'ExePath', 'Executable', 'DisplayIcon'
    )

    foreach ($path in @($Paths)) {
        if (!$path) { continue }
        try {
            $item = Get-Item -LiteralPath $path -ErrorAction Stop
        } catch {
            continue
        }

        foreach ($name in $valueNames) {
            $value = $item.GetValue($name)
            $directory = ConvertTo-StandaloneDirectory ([string]$value)
            if ($directory) { return $directory }
        }

        $defaultValue = $item.GetValue('')
        $directory = ConvertTo-StandaloneDirectory ([string]$defaultValue)
        if ($directory) { return $directory }
    }

    return $null
}

function Get-StandaloneDefinitions {
    return @(
        @{
            Name          = 'Final Fantasy XIV'
            UninstallNames = '(?i)^FINAL FANTASY XIV'
            RegistryPaths = @(
                'HKLM:\SOFTWARE\WOW6432Node\SquareEnix\FINAL FANTASY XIV',
                'HKLM:\SOFTWARE\SquareEnix\FINAL FANTASY XIV'
            )
            InstallPaths  = @(
                '%ProgramFiles(x86)%\SquareEnix\FINAL FANTASY XIV - A Realm Reborn',
                '%ProgramFiles%\SquareEnix\FINAL FANTASY XIV - A Realm Reborn'
            )
            FolderNames   = @(
                'SquareEnix\FINAL FANTASY XIV - A Realm Reborn',
                'FINAL FANTASY XIV - A Realm Reborn',
                'FINAL FANTASY XIV Online',
                'SquareEnix\FINAL FANTASY XIV Online'
            )
            ExeCandidates = @(
                'ffxivboot64.exe', 'ffxivboot.exe',
                'boot\ffxivboot64.exe', 'boot\ffxivboot.exe',
                'game\ffxiv_dx11.exe'
            )
        },
        @{
            Name          = 'Guild Wars 2'
            UninstallNames = '(?i)^Guild Wars 2$'
            RegistryPaths = @(
                'HKLM:\SOFTWARE\WOW6432Node\ArenaNet\Guild Wars 2',
                'HKLM:\SOFTWARE\ArenaNet\Guild Wars 2',
                'HKCU:\Software\ArenaNet\Guild Wars 2'
            )
            InstallPaths  = @(
                '%ProgramFiles%\Guild Wars 2',
                '%ProgramFiles(x86)%\Guild Wars 2'
            )
            FolderNames   = @('Guild Wars 2', 'ArenaNet\Guild Wars 2', 'Games\Guild Wars 2')
            ExeCandidates = @('Gw2-64.exe', 'Gw2.exe')
        },
        @{
            Name          = 'Path of Exile'
            UninstallNames = '(?i)^Path of Exile$'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles(x86)%\Grinding Gear Games\Path of Exile',
                '%ProgramFiles%\Grinding Gear Games\Path of Exile'
            )
            FolderNames   = @(
                'Grinding Gear Games\Path of Exile',
                'Path of Exile',
                'Games\Path of Exile'
            )
            ExeCandidates = @('PathOfExile_x64.exe', 'PathOfExile.exe', 'PathOfExileSteam.exe')
        },
        @{
            Name          = 'Path of Exile 2'
            UninstallNames = '(?i)^Path of Exile 2$'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles(x86)%\Grinding Gear Games\Path of Exile 2',
                '%ProgramFiles%\Grinding Gear Games\Path of Exile 2'
            )
            FolderNames   = @(
                'Grinding Gear Games\Path of Exile 2',
                'Path of Exile 2',
                'Games\Path of Exile 2'
            )
            ExeCandidates = @('PathOfExile_x64.exe', 'PathOfExile.exe')
        },
        @{
            Name          = 'Star Citizen'
            UninstallNames = '(?i)^(Star Citizen|RSI Launcher)$'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles%\Roberts Space Industries'
            )
            FolderNames   = @('Roberts Space Industries', 'RSI Launcher')
            ExeCandidates = @(
                'RSI Launcher\RSI Launcher.exe',
                'StarCitizen\LIVE\StarCitizen.exe',
                'StarCitizen\LIVE\Bin64\StarCitizen.exe'
            )
        },
        @{
            Name          = 'Escape from Tarkov'
            UninstallNames = '(?i)Escape from Tarkov'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles%\Battlestate Games\EFT'
            )
            FolderNames   = @('Battlestate Games\EFT', 'EFT', 'Escape from Tarkov')
            ExeCandidates = @('EscapeFromTarkov.exe')
        },
        @{
            Name          = 'Black Desert Online'
            UninstallNames = '(?i)^Black Desert Online$'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles%\Pearl Abyss\Black Desert Online',
                '%ProgramFiles(x86)%\Pearl Abyss\Black Desert Online'
            )
            FolderNames   = @(
                'Pearl Abyss\Black Desert Online',
                'Black Desert Online',
                'Games\Black Desert Online'
            )
            ExeCandidates = @(
                'BlackDesertLauncher.exe',
                'bin64\BlackDesert64.exe',
                'BlackDesert64.exe'
            )
        },
        @{
            Name          = 'Genshin Impact'
            UninstallNames = '(?i)^Genshin Impact$'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles%\Genshin Impact',
                '%ProgramFiles%\Genshin Impact Game',
                '%ProgramFiles%\HoYoPlay\games\Genshin Impact Game'
            )
            FolderNames   = @(
                'Genshin Impact',
                'Genshin Impact Game',
                'HoYoPlay\games\Genshin Impact Game',
                'Games\Genshin Impact Game'
            )
            ExeCandidates = @(
                'Genshin Impact Game\GenshinImpact.exe',
                'GenshinImpact.exe',
                'YuanShen.exe',
                'launcher.exe'
            )
        },
        @{
            Name          = 'Honkai: Star Rail'
            UninstallNames = '(?i)^Honkai:? Star Rail$'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles%\Star Rail',
                '%ProgramFiles%\Honkai Star Rail',
                '%ProgramFiles%\HoYoPlay\games\Star Rail Game'
            )
            FolderNames   = @(
                'Star Rail',
                'Honkai Star Rail',
                'Star Rail Game',
                'HoYoPlay\games\Star Rail Game'
            )
            ExeCandidates = @(
                'StarRail.exe',
                'Game\StarRail.exe',
                'Star Rail Game\StarRail.exe',
                'launcher.exe'
            )
        },
        @{
            Name          = 'Zenless Zone Zero'
            UninstallNames = '(?i)^Zenless Zone Zero$'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles%\ZenlessZoneZero Game',
                '%ProgramFiles%\Zenless Zone Zero',
                '%ProgramFiles%\HoYoPlay\games\ZenlessZoneZero Game'
            )
            FolderNames   = @(
                'ZenlessZoneZero Game',
                'Zenless Zone Zero',
                'HoYoPlay\games\ZenlessZoneZero Game'
            )
            ExeCandidates = @(
                'ZenlessZoneZero.exe',
                'ZenlessZoneZero Game\ZenlessZoneZero.exe',
                'launcher.exe'
            )
        },
        @{
            Name          = 'Wuthering Waves'
            UninstallNames = '(?i)^Wuthering Waves$'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles%\Wuthering Waves',
                '%ProgramFiles%\Wuthering Waves Game'
            )
            FolderNames   = @(
                'Wuthering Waves',
                'Wuthering Waves Game',
                'Games\Wuthering Waves Game'
            )
            ExeCandidates = @(
                'Wuthering Waves.exe',
                'Wuthering Waves Game\Wuthering Waves.exe',
                'Wuthering Waves Game\Client\Binaries\Win64\Client-Win64-Shipping.exe',
                'launcher.exe'
            )
        },
        @{
            Name          = 'Minecraft'
            UninstallNames = '(?i)^Minecraft Launcher$'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles(x86)%\Minecraft Launcher',
                '%ProgramFiles%\Minecraft Launcher',
                '%LOCALAPPDATA%\Programs\Minecraft Launcher'
            )
            FolderNames   = @('Minecraft Launcher')
            ExeCandidates = @('MinecraftLauncher.exe')
        },
        @{
            Name          = 'The Elder Scrolls Online'
            UninstallNames = '(?i)Elder Scrolls Online'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles(x86)%\Zenimax Online\The Elder Scrolls Online',
                '%ProgramFiles%\Zenimax Online\The Elder Scrolls Online'
            )
            FolderNames   = @(
                'Zenimax Online\The Elder Scrolls Online',
                'The Elder Scrolls Online'
            )
            ExeCandidates = @(
                'game\client\eso64.exe',
                'eso64.exe',
                'Bethesda.net_Launcher.exe'
            )
        },
        @{
            Name          = 'Star Wars: The Old Republic'
            UninstallNames = '(?i)Star Wars.*Old Republic'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles(x86)%\Electronic Arts\BioWare\Star Wars - The Old Republic',
                '%ProgramFiles%\Electronic Arts\BioWare\Star Wars - The Old Republic'
            )
            FolderNames   = @(
                'Electronic Arts\BioWare\Star Wars - The Old Republic',
                'Star Wars - The Old Republic'
            )
            ExeCandidates = @('swtor.exe', 'Launcher.exe')
        },
        @{
            Name          = 'Warframe'
            UninstallNames = '(?i)^Warframe$'
            RegistryPaths = @()
            InstallPaths  = @(
                '%LOCALAPPDATA%\Warframe'
            )
            FolderNames   = @('Warframe')
            ExeCandidates = @('Warframe.x64.exe', 'Warframe.exe', 'Launcher.exe')
        },
        @{
            Name          = 'Elite Dangerous'
            UninstallNames = '(?i)^Elite Dangerous'
            RegistryPaths = @()
            InstallPaths  = @(
                '%LOCALAPPDATA%\Frontier Developments\Elite Dangerous',
                '%ProgramFiles%\Frontier Developments\Elite Dangerous',
                '%ProgramFiles(x86)%\Frontier Developments\Elite Dangerous',
                '%ProgramFiles(x86)%\Frontier\EDLaunch'
            )
            FolderNames   = @(
                'Frontier Developments\Elite Dangerous',
                'Elite Dangerous',
                'Frontier\EDLaunch',
                'Games\Elite Dangerous'
            )
            ExeCandidates = @(
                'EDLaunch.exe',
                'Products\elite-dangerous-64\EliteDangerous64.exe',
                'EliteDangerous64.exe',
                'EliteDangerous.exe'
            )
        },
        @{
            Name          = 'EVE Online'
            UninstallNames = '(?i)^EVE Online'
            RegistryPaths = @()
            InstallPaths  = @(
                '%LOCALAPPDATA%\CCP\EVE',
                '%ProgramFiles(x86)%\CCP\EVE',
                '%ProgramFiles%\CCP\EVE'
            )
            FolderNames   = @('CCP\EVE', 'EVE Online', 'Games\EVE Online')
            ExeCandidates = @('launcher\eve.exe', 'Launcher\eve.exe', 'eve.exe')
        },
        @{
            Name          = 'Albion Online'
            UninstallNames = '(?i)^Albion Online'
            RegistryPaths = @()
            InstallPaths  = @(
                '%LOCALAPPDATA%\AlbionOnline',
                '%ProgramFiles%\Albion Online',
                '%ProgramFiles(x86)%\Albion Online'
            )
            FolderNames   = @('AlbionOnline', 'Albion Online', 'Games\Albion Online')
            ExeCandidates = @('AlbionLauncher.exe', 'Albion-Online.exe', 'AlbionOnline.exe')
        },
        @{
            Name          = 'RuneScape'
            UninstallNames = '(?i)^(RuneScape|Old School RuneScape|Jagex Launcher)'
            RegistryPaths = @()
            InstallPaths  = @(
                '%LOCALAPPDATA%\Jagex\launcher\JagexLauncher.exe',
                '%ProgramFiles(x86)%\Jagex\RuneScape Launcher\RuneScape.exe',
                '%ProgramFiles%\Jagex\RuneScape Launcher\RuneScape.exe'
            )
            FolderNames   = @('Jagex\launcher', 'Jagex\RuneScape Launcher', 'RuneScape')
            ExeCandidates = @('JagexLauncher.exe', 'RuneScape.exe')
        },
        @{
            Name          = 'Star Trek Online'
            UninstallNames = '(?i)^Star Trek Online'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles(x86)%\Cryptic Studios\Star Trek Online\Live',
                '%ProgramFiles%\Cryptic Studios\Star Trek Online\Live'
            )
            FolderNames   = @('Cryptic Studios\Star Trek Online\Live', 'Star Trek Online')
            ExeCandidates = @('Star Trek Online.exe', 'StarTrekOnline.exe', 'GameClient.exe', 'Launcher.exe')
        },
        @{
            Name          = 'Neverwinter'
            UninstallNames = '(?i)^Neverwinter'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles(x86)%\Cryptic Studios\Neverwinter\Live',
                '%ProgramFiles%\Cryptic Studios\Neverwinter\Live'
            )
            FolderNames   = @('Cryptic Studios\Neverwinter\Live', 'Neverwinter')
            ExeCandidates = @('Neverwinter.exe', 'GameClient.exe', 'Launcher.exe')
        },
        @{
            Name          = 'The Lord of the Rings Online'
            UninstallNames = '(?i)Lord of the Rings Online'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles(x86)%\StandingStoneGames\The Lord of the Rings Online',
                '%ProgramFiles%\StandingStoneGames\The Lord of the Rings Online'
            )
            FolderNames   = @(
                'StandingStoneGames\The Lord of the Rings Online',
                'The Lord of the Rings Online'
            )
            ExeCandidates = @('TurbineLauncher.exe', 'LotroLauncher.exe', 'lotroclient64.exe', 'lotroclient.exe')
        },
        @{
            Name          = 'Dungeons & Dragons Online'
            UninstallNames = '(?i)Dungeons.*Dragons Online'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles(x86)%\StandingStoneGames\Dungeons & Dragons Online',
                '%ProgramFiles%\StandingStoneGames\Dungeons & Dragons Online'
            )
            FolderNames   = @(
                'StandingStoneGames\Dungeons & Dragons Online',
                'Dungeons & Dragons Online'
            )
            ExeCandidates = @('TurbineLauncher.exe', 'DndLauncher.exe', 'dndclient.exe')
        },
        @{
            Name          = 'Honkai Impact 3rd'
            UninstallNames = '(?i)^Honkai Impact 3rd'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles%\Honkai Impact 3rd',
                '%ProgramFiles%\HoYoPlay\games\Honkai Impact 3rd'
            )
            FolderNames   = @('Honkai Impact 3rd', 'HoYoPlay\games\Honkai Impact 3rd')
            ExeCandidates = @('BH3.exe', 'Games\BH3.exe', 'launcher.exe')
        },
        @{
            Name          = 'Tower of Fantasy'
            UninstallNames = '(?i)^Tower of Fantasy'
            RegistryPaths = @()
            InstallPaths  = @(
                '%ProgramFiles%\Tower of Fantasy'
            )
            FolderNames   = @('Tower of Fantasy', 'Games\Tower of Fantasy')
            ExeCandidates = @(
                'Launcher.exe',
                'TowerOfFantasy.exe',
                'QRSL.exe',
                'Client\Binaries\Win64\QRSL-Win64-Shipping.exe'
            )
        }
    )
}

function Resolve-StandaloneDefinition {
    param(
        $Definition,
        [string[]]$SearchRoots,
        [int]$Depth = 4
    )

    $installDir = Get-StandaloneRegistryDirectory -Paths @($Definition.RegistryPaths)

    if (!$installDir) {
        foreach ($path in @($Definition.InstallPaths)) {
            if (!$path) { continue }
            $candidate = ConvertTo-StandaloneDirectory $path
            if ($candidate) { $installDir = $candidate; break }
        }
    }

    if (!$installDir) {
        $uninstallNames = [string]$Definition.UninstallNames
        if ($uninstallNames) {
            $app = Get-InstalledApplications | Where-Object {
                $_.DisplayName -and $_.DisplayName -match $uninstallNames
            } | Select-Object -First 1

            if ($app) {
                $candidate = ConvertTo-StandaloneDirectory $app.InstallLocation
                if (!$candidate) { $candidate = ConvertTo-StandaloneDirectory $app.DisplayIcon }
                if ($candidate) { $installDir = $candidate }
            }
        }
    }

    if (!$installDir) {
        foreach ($root in @($SearchRoots)) {
            if (!$root) { continue }
            $expandedRoot = Expand-PathValue $root
            if (!$expandedRoot -or !(Test-Path -LiteralPath $expandedRoot -PathType Container -ErrorAction SilentlyContinue)) { continue }

            foreach ($folder in @($Definition.FolderNames)) {
                if (!$folder) { continue }
                $candidate = Join-Path $expandedRoot $folder
                if (Test-Path -LiteralPath $candidate -PathType Container -ErrorAction SilentlyContinue) {
                    $installDir = $candidate
                    break
                }
            }
            if ($installDir) { break }
        }
    }

    if (!$installDir) { return $null }

    $exe = $null
    foreach ($relative in @($Definition.ExeCandidates)) {
        if (!$relative) { continue }
        $candidate = Join-Path $installDir $relative
        if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) {
            $exe = $candidate
            break
        }
    }

    if (!$exe) {
        $exe = Find-GameExecutable -Directory $installDir -Depth $Depth -PreferName $Definition.Name
    }

    if (!$exe) { return $null }

    return New-GameEntry -Name $Definition.Name -Provider 'Standalone' -ProviderKey 'standalone' -Kind 'Standalone' `
        -Target $exe -IconPath $exe -InstallDir $installDir -Source 'standalone-known'
}

function Get-RobloxStandaloneEntry {
    $versions = Join-Path $env:LOCALAPPDATA 'Roblox\Versions'
    if (!(Test-Path -LiteralPath $versions -PathType Container -ErrorAction SilentlyContinue)) { return $null }

    $folders = @(
        Get-ChildItem -LiteralPath $versions -Directory -Filter 'version-*' -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending
    )

    foreach ($folder in $folders) {
        $exe = Join-Path $folder.FullName 'RobloxPlayerBeta.exe'
        if (Test-Path -LiteralPath $exe -PathType Leaf -ErrorAction SilentlyContinue) {
            return New-GameEntry -Name 'Roblox' -Provider 'Standalone' -ProviderKey 'standalone' -Kind 'Standalone' `
                -Target $exe -IconPath $exe -InstallDir $folder.FullName -Source 'roblox-version'
        }
    }

    return $null
}

function Get-ExtraRootStandaloneGames {
    param(
        [string[]]$Roots,
        [int]$Depth = 4
    )

    $games = New-Object System.Collections.Generic.List[object]
    $skipPattern = '(?i)^(bin|binaries|data|content|cache|logs?|redist|redistributables|support|tools|temp|tmp|downloads?|updates?|installer|engine|plugins?|mods?|savegames?|saves|screenshots?|configs?|docs?|documentation)$'

    foreach ($root in @($Roots)) {
        if (!$root) { continue }
        $expanded = Expand-PathValue $root
        if (!$expanded -or !(Test-Path -LiteralPath $expanded -PathType Container -ErrorAction SilentlyContinue)) {
            if ($root) { Write-Log "Standalone: extra root not found: $root" -Level Debug }
            continue
        }

        $leaf = Split-Path -Leaf $expanded
        $rootExe = Find-GameExecutable -Directory $expanded -Depth 1 -PreferName $leaf

        if ($rootExe -and $leaf -notmatch $skipPattern) {
            $leafKey = ($leaf -replace '[^a-zA-Z0-9]', '').ToLowerInvariant()
            $exeKey = ([IO.Path]::GetFileNameWithoutExtension($rootExe) -replace '[^a-zA-Z0-9]', '').ToLowerInvariant()

            $nameMatches = $false
            if ($leafKey -and $exeKey) {
                if ($exeKey -eq $leafKey -or $exeKey.Contains($leafKey) -or $leafKey.Contains($exeKey)) {
                    $nameMatches = $true
                }
            }

            if ($nameMatches) {
                $games.Add((New-GameEntry -Name $leaf -Provider 'Standalone' -ProviderKey 'standalone' -Kind 'Standalone' `
                    -Target $rootExe -IconPath $rootExe -InstallDir $expanded -Source 'extra-root'))
                continue
            }
        }

        foreach ($folder in @(Get-ChildItem -LiteralPath $expanded -Directory -ErrorAction SilentlyContinue)) {
            if ($folder.Name -match $skipPattern) { continue }

            $exe = Find-GameExecutable -Directory $folder.FullName -Depth $Depth -PreferName $folder.Name
            if (!$exe) { continue }

            $games.Add((New-GameEntry -Name $folder.Name -Provider 'Standalone' -ProviderKey 'standalone' -Kind 'Standalone' `
                -Target $exe -IconPath $exe -InstallDir $folder.FullName -Source 'extra-root'))
        }
    }

    return @(ConvertTo-Array $games)
}

function Get-StandaloneProvider {
    param($Config)

    $scan = Get-PropertyValue $Config 'scan'
    $searchRoots = @(Get-PropertyValue $scan 'standaloneSearchRoots')

    $depth = 4
    $depthValue = Get-PropertyValue $scan 'standaloneDepth'
    if ($null -ne $depthValue) {
        try { $depth = [int]$depthValue } catch { $depth = 4 }
    }
    if ($depth -lt 1) { $depth = 1 }
    if ($depth -gt 6) { $depth = 6 }

    $games = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    foreach ($definition in (Get-StandaloneDefinitions)) {
        $entry = $null
        try {
            $entry = Resolve-StandaloneDefinition -Definition $definition -SearchRoots $searchRoots -Depth $depth
        } catch {
            Write-Log "Standalone: error while checking '$($definition.Name)': $($_.Exception.Message)" -Level Warn
        }

        if (!$entry) { continue }

        $key = $entry.InstallDir
        if ($key) {
            try { $key = [IO.Path]::GetFullPath($key).TrimEnd('\').ToLowerInvariant() } catch { $key = $key.ToLowerInvariant() }
        } else {
            $key = $entry.Target.ToLowerInvariant()
        }
        if ($seen.ContainsKey($key)) { continue }

        $seen[$key] = $true
        $games.Add($entry)
    }

    $roblox = Get-RobloxStandaloneEntry
    if ($roblox) {
        $key = $roblox.InstallDir.ToLowerInvariant()
        if (!$seen.ContainsKey($key)) {
            $seen[$key] = $true
            $games.Add($roblox)
        }
    }

    $extraRoots = @(Get-PropertyValue $scan 'extraGameRoots')
    foreach ($entry in (Get-ExtraRootStandaloneGames -Roots $extraRoots -Depth $depth)) {
        $key = $entry.InstallDir
        try { $key = [IO.Path]::GetFullPath($key).TrimEnd('\').ToLowerInvariant() } catch { $key = $key.ToLowerInvariant() }
        if ($seen.ContainsKey($key)) { continue }

        $seen[$key] = $true
        $games.Add($entry)
    }

    if ($games.Count -eq 0) { return $null }

    return New-ProviderResult -Key 'standalone' -DisplayName 'Standalone' -Games $games
}
