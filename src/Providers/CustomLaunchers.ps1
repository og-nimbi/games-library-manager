# Community and custom launchers: XIVLauncher, RuneLite, mod managers, config entries.

function Get-CustomLauncherDefinitions {
    return @(
        @{
            Name           = 'XIVLauncher'
            UninstallNames = '(?i)^XIVLauncher'
            Paths          = @(
                '%LOCALAPPDATA%\XIVLauncher\XIVLauncher.exe',
                '%LOCALAPPDATA%\XIVLauncher.Core\XIVLauncher.exe',
                '%APPDATA%\XIVLauncher\XIVLauncher.exe',
                '%ProgramFiles%\XIVLauncher\XIVLauncher.exe'
            )
            ExeNames       = @('XIVLauncher.exe', 'XIVLauncher.Core.exe')
        },
        @{
            Name           = 'RuneLite'
            UninstallNames = '(?i)^RuneLite'
            Paths          = @(
                '%LOCALAPPDATA%\RuneLite\RuneLite.exe',
                '%ProgramFiles%\RuneLite\RuneLite.exe',
                '%ProgramFiles(x86)%\RuneLite\RuneLite.exe'
            )
            ExeNames       = @('RuneLite.exe')
        },
        @{
            Name           = 'WoWUp'
            UninstallNames = '(?i)^WoWUp'
            Paths          = @(
                '%LOCALAPPDATA%\Programs\WoWUp\WoWUp.exe',
                '%LOCALAPPDATA%\Programs\wowup\WoWUp.exe',
                '%LOCALAPPDATA%\WoWUp\WoWUp.exe',
                '%ProgramFiles%\WoWUp\WoWUp.exe'
            )
            ExeNames       = @('WoWUp.exe', 'wowup.exe')
        },
        @{
            Name           = 'CurseForge'
            UninstallNames = '(?i)^CurseForge'
            Paths          = @(
                '%LOCALAPPDATA%\Programs\CurseForge\CurseForge.exe',
                '%LOCALAPPDATA%\CurseForge\CurseForge.exe',
                '%ProgramFiles%\CurseForge\CurseForge.exe',
                '%ProgramFiles(x86)%\CurseForge\CurseForge.exe'
            )
            ExeNames       = @('CurseForge.exe')
        },
        @{
            Name           = 'Prism Launcher'
            UninstallNames = '(?i)^Prism Launcher'
            Paths          = @(
                '%LOCALAPPDATA%\Programs\PrismLauncher\prismlauncher.exe',
                '%ProgramFiles%\PrismLauncher\prismlauncher.exe',
                '%ProgramFiles(x86)%\PrismLauncher\prismlauncher.exe'
            )
            ExeNames       = @('prismlauncher.exe', 'PrismLauncher.exe')
        },
        @{
            Name           = 'MultiMC'
            UninstallNames = '(?i)^MultiMC'
            Paths          = @(
                '%LOCALAPPDATA%\Programs\MultiMC\MultiMC.exe',
                '%ProgramFiles%\MultiMC\MultiMC.exe',
                '%ProgramFiles(x86)%\MultiMC\MultiMC.exe'
            )
            ExeNames       = @('MultiMC.exe')
        },
        @{
            Name           = 'ATLauncher'
            UninstallNames = '(?i)^ATLauncher'
            Paths          = @(
                '%LOCALAPPDATA%\Programs\ATLauncher\ATLauncher.exe',
                '%ProgramFiles%\ATLauncher\ATLauncher.exe',
                '%ProgramFiles(x86)%\ATLauncher\ATLauncher.exe'
            )
            ExeNames       = @('ATLauncher.exe')
        },
        @{
            Name           = 'GDLauncher'
            UninstallNames = '(?i)^GDLauncher'
            Paths          = @(
                '%LOCALAPPDATA%\Programs\gdlauncher\GDLauncher.exe',
                '%APPDATA%\gdlauncher\GDLauncher.exe'
            )
            ExeNames       = @('GDLauncher.exe')
        },
        @{
            Name           = 'Heroic Games Launcher'
            UninstallNames = '(?i)^Heroic'
            Paths          = @(
                '%LOCALAPPDATA%\Programs\Heroic\Heroic.exe',
                '%LOCALAPPDATA%\Heroic\Heroic.exe',
                '%ProgramFiles%\Heroic\Heroic.exe'
            )
            ExeNames       = @('Heroic.exe')
        },
        @{
            Name           = 'Playnite'
            UninstallNames = '(?i)^Playnite'
            Paths          = @(
                '%LOCALAPPDATA%\Playnite\Playnite.DesktopApp.exe',
                '%ProgramFiles%\Playnite\Playnite.DesktopApp.exe',
                '%ProgramFiles(x86)%\Playnite\Playnite.DesktopApp.exe'
            )
            ExeNames       = @('Playnite.DesktopApp.exe', 'Playnite.FullscreenApp.exe')
        },
        @{
            Name           = 'Vortex'
            UninstallNames = '(?i)^Vortex'
            Paths          = @(
                '%ProgramFiles%\Black Tree Gaming Ltd\Vortex\Vortex.exe',
                '%LOCALAPPDATA%\Programs\Vortex\Vortex.exe'
            )
            ExeNames       = @('Vortex.exe')
        },
        @{
            Name           = 'FiveM'
            UninstallNames = '(?i)^FiveM'
            Paths          = @(
                '%LOCALAPPDATA%\FiveM\FiveM.app\FiveM.exe',
                '%LOCALAPPDATA%\FiveM\FiveM.exe'
            )
            ExeNames       = @('FiveM.exe')
        }
    )
}

function Resolve-CustomLauncherExecutable {
    param($Definition)

    foreach ($path in @($Definition.Paths)) {
        if (!$path) { continue }
        $expanded = Expand-PathValue $path
        if (!$expanded) { continue }

        if (Test-Path -LiteralPath $expanded -PathType Leaf -ErrorAction SilentlyContinue) {
            return $expanded
        }

        if (Test-Path -LiteralPath $expanded -PathType Container -ErrorAction SilentlyContinue) {
            foreach ($exeName in @($Definition.ExeNames)) {
                if (!$exeName) { continue }
                $candidate = Join-Path $expanded $exeName
                if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) {
                    return $candidate
                }
            }
        }
    }

    $uninstallNames = [string]$Definition.UninstallNames
    if ($uninstallNames) {
        $app = Get-InstalledApplications | Where-Object {
            $_.DisplayName -and $_.DisplayName -match $uninstallNames
        } | Select-Object -First 1

        if ($app) {
            if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe' -and
                (Test-Path -LiteralPath $app.DisplayIcon -PathType Leaf -ErrorAction SilentlyContinue)) {
                return $app.DisplayIcon
            }

            if ($app.InstallLocation -and (Test-Path -LiteralPath $app.InstallLocation -PathType Container -ErrorAction SilentlyContinue)) {
                foreach ($exeName in @($Definition.ExeNames)) {
                    if (!$exeName) { continue }
                    $candidate = Join-Path $app.InstallLocation $exeName
                    if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) {
                        return $candidate
                    }
                }

                $found = Find-GameExecutable -Directory $app.InstallLocation -Depth 2 -PreferName $Definition.Name
                if ($found) { return $found }
            }
        }
    }

    return $null
}

function Get-ConfiguredCustomLauncherGames {
    param($Config)

    $games = New-Object System.Collections.Generic.List[object]

    foreach ($raw in @(Get-PropertyValue $Config 'customLaunchers')) {
        if ($null -eq $raw) { continue }

        if ($raw -is [string]) {
            $targetValue = $raw
            $name = [IO.Path]::GetFileNameWithoutExtension($raw)
        } else {
            $targetValue = [string](Get-PropertyValue $raw 'path')
            if (!$targetValue) { $targetValue = [string](Get-PropertyValue $raw 'target') }
            if (!$targetValue) { $targetValue = [string](Get-PropertyValue $raw 'exe') }

            $name = [string](Get-PropertyValue $raw 'name')
        }

        if (!$targetValue) { continue }

        $target = Expand-PathValue $targetValue
        if (!$target) { continue }

        if (Test-Path -LiteralPath $target -PathType Container -ErrorAction SilentlyContinue) {
            $target = Find-GameExecutable -Directory $target -Depth 2 -PreferName $name
        } elseif (!(Test-Path -LiteralPath $target -PathType Leaf -ErrorAction SilentlyContinue) -and !(Test-UrlTarget $target)) {
            Write-Log "Custom launcher target not found: $targetValue" -Level Warn
            continue
        }

        if (!$target) { continue }
        if (!$name) { $name = [IO.Path]::GetFileNameWithoutExtension($target) }

        $arguments = ''
        $workingDirectory = ''
        $icon = ''
        $description = ''

        if (!($raw -is [string])) {
            $arguments = [string](Get-PropertyValue $raw 'arguments')
            $workingDirectory = [string](Get-PropertyValue $raw 'workingDirectory')
            $icon = [string](Get-PropertyValue $raw 'icon')
            $description = [string](Get-PropertyValue $raw 'description')
        }

        $games.Add((New-GameEntry -Name $name -Provider 'Custom Launchers' -ProviderKey 'customLaunchers' `
            -Kind 'CustomLauncher' -Target $target -Arguments $arguments -WorkingDirectory $workingDirectory `
            -IconPath $icon -Description $description -Source 'config-custom-launcher'))
    }

    return @(ConvertTo-Array $games)
}

function Get-CustomLauncherProvider {
    param($Config)

    $games = New-Object System.Collections.Generic.List[object]
    $seenTargets = @{}

    $candidates = New-Object System.Collections.Generic.List[object]
    foreach ($configGame in (Get-ConfiguredCustomLauncherGames -Config $Config)) {
        $candidates.Add($configGame)
    }

    foreach ($definition in (Get-CustomLauncherDefinitions)) {
        $exe = $null
        try {
            $exe = Resolve-CustomLauncherExecutable -Definition $definition
        } catch {
            Write-Log "Custom launchers: error while checking '$($definition.Name)': $($_.Exception.Message)" -Level Warn
        }

        if (!$exe) { continue }

        $candidates.Add((New-GameEntry -Name $definition.Name -Provider 'Custom Launchers' -ProviderKey 'customLaunchers' `
            -Kind 'CustomLauncher' -Target $exe -IconPath $exe -InstallDir (Split-Path -Parent $exe) `
            -Source 'custom-launcher-known'))
    }

    foreach ($game in $candidates) {
        $key = $game.Target
        if (!$key) { $key = $game.Name }
        try { $key = $key.ToLowerInvariant() } catch { }
        if ($seenTargets.ContainsKey($key)) { continue }

        $seenTargets[$key] = $true
        $games.Add($game)
    }

    if ($games.Count -eq 0) { return $null }

    return New-ProviderResult -Key 'customLaunchers' -DisplayName 'Custom Launchers' -Games $games
}
