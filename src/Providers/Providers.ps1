# Provider catalog, selection, execution, and merging of config-defined entries.

function Get-ProviderCatalog {
    return @(
        [pscustomobject]@{ Key = 'steam';           DisplayName = 'Steam';                File = 'Steam.ps1';           Function = 'Get-SteamProvider' }
        [pscustomobject]@{ Key = 'epic';            DisplayName = 'Epic Games';           File = 'Epic.ps1';            Function = 'Get-EpicProvider' }
        [pscustomobject]@{ Key = 'gog';             DisplayName = 'GOG';                  File = 'Gog.ps1';             Function = 'Get-GogProvider' }
        [pscustomobject]@{ Key = 'itch';            DisplayName = 'itch.io';              File = 'Itch.ps1';            Function = 'Get-ItchProvider' }
        [pscustomobject]@{ Key = 'amazon';          DisplayName = 'Amazon Games';         File = 'Amazon.ps1';          Function = 'Get-AmazonProvider' }
        [pscustomobject]@{ Key = 'legacyGames';     DisplayName = 'Legacy Games';         File = 'LegacyGames.ps1';     Function = 'Get-LegacyProvider' }
        [pscustomobject]@{ Key = 'ea';              DisplayName = 'EA app';               File = 'EA.ps1';              Function = 'Get-EaProvider' }
        [pscustomobject]@{ Key = 'ubisoft';         DisplayName = 'Ubisoft Connect';      File = 'Ubisoft.ps1';         Function = 'Get-UbisoftProvider' }
        [pscustomobject]@{ Key = 'battleNet';       DisplayName = 'Battle.net';           File = 'BattleNet.ps1';       Function = 'Get-BattleNetProvider' }
        [pscustomobject]@{ Key = 'rockstar';        DisplayName = 'Rockstar Games';       File = 'Rockstar.ps1';        Function = 'Get-RockstarProvider' }
        [pscustomobject]@{ Key = 'riot';            DisplayName = 'Riot Games';           File = 'Riot.ps1';            Function = 'Get-RiotProvider' }
        [pscustomobject]@{ Key = 'wargaming';       DisplayName = 'Wargaming';            File = 'Wargaming.ps1';       Function = 'Get-WargamingProvider' }
        [pscustomobject]@{ Key = 'hiRez';           DisplayName = 'Hi-Rez Studios';       File = 'HiRez.ps1';           Function = 'Get-HiRezProvider' }
        [pscustomobject]@{ Key = 'xbox';            DisplayName = 'Xbox';                 File = 'Xbox.ps1';            Function = 'Get-XboxProvider' }
        [pscustomobject]@{ Key = 'standalone';      DisplayName = 'Standalone';           File = 'Standalone.ps1';      Function = 'Get-StandaloneProvider' }
        [pscustomobject]@{ Key = 'customLaunchers'; DisplayName = 'Custom Launchers';     File = 'CustomLaunchers.ps1'; Function = 'Get-CustomLauncherProvider' }
        [pscustomobject]@{ Key = 'emulators';       DisplayName = 'Emulators';            File = 'Emulators.ps1';      Function = 'Get-EmulatorProvider' }
    )
}

function Test-ProviderSelected {
    param(
        $Definition,
        $Config,
        [string[]]$Only
    )

    $onlyItems = @($Only | Where-Object { $_ })
    if ($onlyItems.Count -gt 0) {
        $fileName = [IO.Path]::GetFileNameWithoutExtension([string]$Definition.File)
        foreach ($item in $onlyItems) {
            if ($item -ieq $Definition.Key -or $item -ieq $Definition.DisplayName -or $item -ieq $Definition.File -or $item -ieq $fileName) {
                return $true
            }
        }
        return $false
    }

    $providers = Get-PropertyValue $Config 'providers'
    if ($null -ne $providers) {
        $value = Get-PropertyValue $providers $Definition.Key
        if ($null -ne $value) { return [bool]$value }
    }

    return $true
}

function Get-SelectedProviderDefinitions {
    param(
        $Config,
        [string[]]$Only
    )

    $selected = New-Object System.Collections.Generic.List[object]
    foreach ($definition in (Get-ProviderCatalog)) {
        if (Test-ProviderSelected -Definition $definition -Config $Config -Only $Only) {
            $selected.Add($definition)
        }
    }

    return @(ConvertTo-Array $selected)
}

function Get-CustomEntryProvider {
    param(
        $Raw,
        $Catalog
    )

    $providedKey = [string](Get-PropertyValue $Raw 'providerKey')
    $providedName = [string](Get-PropertyValue $Raw 'provider')

    if ($providedKey) {
        $match = $Catalog | Where-Object { $_.Key -ieq $providedKey } | Select-Object -First 1
        if ($match) {
            return [pscustomobject]@{ Key = $match.Key; DisplayName = $match.DisplayName; Known = $true }
        }
    }

    if ($providedName) {
        $match = $Catalog | Where-Object {
            $_.Key -ieq $providedName -or $_.DisplayName -ieq $providedName
        } | Select-Object -First 1

        if ($match) {
            return [pscustomobject]@{ Key = $match.Key; DisplayName = $match.DisplayName; Known = $true }
        }

        return [pscustomobject]@{ Key = (ConvertTo-ProviderKey $providedName); DisplayName = $providedName; Known = $false }
    }

    return [pscustomobject]@{ Key = 'custom'; DisplayName = 'Custom'; Known = $false }
}

function ConvertTo-CustomEntryGame {
    param($Raw)

    if ($null -eq $Raw) { return $null }

    $name = [string](Get-PropertyValue $Raw 'name')
    $targetValue = [string](Get-PropertyValue $Raw 'target')
    if (!$targetValue) { $targetValue = [string](Get-PropertyValue $Raw 'path') }
    if (!$targetValue) { return $null }

    $target = Expand-PathValue $targetValue
    if (!$target) { return $null }

    $isUrl = Test-UrlTarget $target
    if (!$isUrl -and ![IO.Path]::IsPathRooted($target)) {
        $target = Join-Path (Get-Location).Path $target
    }

    if (Test-Path -LiteralPath $target -PathType Container -ErrorAction SilentlyContinue) {
        $target = Find-GameExecutable -Directory $target -Depth 2 -PreferName $name
    }

    if (!$target) { return $null }
    if (!$isUrl -and !(Test-Path -LiteralPath $target -PathType Leaf -ErrorAction SilentlyContinue)) {
        Write-Log "Custom entry target not found: $targetValue" -Level Warn
        return $null
    }

    if (!$name) { $name = [IO.Path]::GetFileNameWithoutExtension($target) }

    $providerInfo = $null
    $kind = [string](Get-PropertyValue $Raw 'kind')
    if (!$kind) { $kind = 'Custom' }

    return New-GameEntry -Name $name -Provider 'Custom' -ProviderKey 'custom' -Kind $kind `
        -Target $target `
        -Arguments ([string](Get-PropertyValue $Raw 'arguments')) `
        -WorkingDirectory ([string](Get-PropertyValue $Raw 'workingDirectory')) `
        -IconPath ([string](Get-PropertyValue $Raw 'icon')) `
        -Id ([string](Get-PropertyValue $Raw 'id')) `
        -Description ([string](Get-PropertyValue $Raw 'description')) `
        -Source 'config-custom-entry'
}

function Merge-CustomEntries {
    param(
        $Results,
        $Config,
        [string[]]$SelectedKeys,
        [bool]$FilterBySelection = $false
    )

    $list = New-Object System.Collections.Generic.List[object]
    foreach ($result in @(ConvertTo-Array $Results)) { $list.Add($result) }

    $rawEntries = @(Get-PropertyValue $Config 'customEntries')
    if ($rawEntries.Count -eq 0) { return @(ConvertTo-Array $list) }

    $catalog = Get-ProviderCatalog

    foreach ($raw in $rawEntries) {
        if ($null -eq $raw) { continue }

        $providerInfo = Get-CustomEntryProvider -Raw $raw -Catalog $catalog
        if ($FilterBySelection -and $providerInfo.Known -and $SelectedKeys -notcontains $providerInfo.Key) {
            continue
        }

        $entry = ConvertTo-CustomEntryGame -Raw $raw
        if (!$entry) {
            Write-Log 'Custom entry was skipped because its target could not be resolved.' -Level Warn
            continue
        }

        $entry.Provider = $providerInfo.DisplayName
        $entry.ProviderKey = $providerInfo.Key

        $match = $null
        foreach ($result in $list) {
            if ($result.Key -ieq $providerInfo.Key -or $result.DisplayName -ieq $providerInfo.DisplayName) {
                $match = $result
                break
            }
        }

        if ($match) {
            $games = New-Object System.Collections.Generic.List[object]
            foreach ($game in @($match.Games)) { $games.Add($game) }
            $games.Add($entry)
            $match.Games = @(ConvertTo-Array $games)
        } else {
            $list.Add((New-ProviderResult -Key $providerInfo.Key -DisplayName $providerInfo.DisplayName -Games @($entry)))
        }
    }

    return @(ConvertTo-Array $list)
}

function Get-NormalizedDirectory {
    param([string]$Path)

    if (!$Path) { return $null }
    try {
        return [IO.Path]::GetFullPath($Path).TrimEnd('\').ToLowerInvariant()
    } catch {
        return $Path.TrimEnd('\').ToLowerInvariant()
    }
}

function Remove-DuplicateStandaloneGames {
    param($Results)

    $storeDirectories = New-Object System.Collections.Generic.List[string]
    $storeTargets = @{}

    foreach ($result in @(ConvertTo-Array $Results)) {
        if ($result.Key -ieq 'standalone') { continue }

        foreach ($game in @($result.Games)) {
            $directory = Get-NormalizedDirectory $game.InstallDir
            if ($directory) {
                $storeDirectories.Add($directory)
            } elseif ($game.Target -and !(Test-UrlTarget $game.Target)) {
                $directory = Get-NormalizedDirectory (Split-Path -Parent $game.Target)
                if ($directory) { $storeDirectories.Add($directory) }
            }

            if ($game.Target) {
                $storeTargets[$game.Target.ToLowerInvariant()] = $true
            }
        }
    }

    if ($storeDirectories.Count -eq 0 -and $storeTargets.Count -eq 0) { return @(ConvertTo-Array $Results) }

    $removed = 0

    foreach ($result in @(ConvertTo-Array $Results)) {
        if ($result.Key -ine 'standalone') { continue }

        $kept = New-Object System.Collections.Generic.List[object]

        foreach ($game in @($result.Games)) {
            $duplicate = $false
            $directory = Get-NormalizedDirectory $game.InstallDir

            if ($directory) {
                foreach ($storeDirectory in $storeDirectories) {
                    if ($directory -eq $storeDirectory -or $directory.StartsWith($storeDirectory + '\')) {
                        $duplicate = $true
                        break
                    }
                }
            }

            if (!$duplicate -and $game.Target -and $storeTargets.ContainsKey($game.Target.ToLowerInvariant())) {
                $duplicate = $true
            }

            if ($duplicate) {
                Write-Log "Standalone: skipping '$($game.Name)' (already managed by a store provider)." -Level Debug
                $removed++
            } else {
                $kept.Add($game)
            }
        }

        $result.Games = @(ConvertTo-Array $kept)
    }

    if ($removed -gt 0) {
        Write-Log "Standalone: skipped $removed duplicate(s) found by store providers." -Level Debug
    }

    return @(ConvertTo-Array $Results)
}

function Merge-CustomLaunchMethods {
    param(
        $Results,
        $Config
    )

    $raw = @(Get-PropertyValue $Config 'customLaunchMethods')
    if ($raw.Count -eq 0) { return @(ConvertTo-Array $Results) }

    foreach ($entry in $raw) {
        if ($null -eq $entry) { continue }
        $matchName = [string](Get-PropertyValue $entry 'game')
        if ([string]::IsNullOrWhiteSpace($matchName)) { continue }

        $methodName = [string](Get-PropertyValue $entry 'name')
        if ([string]::IsNullOrWhiteSpace($methodName)) { $methodName = 'Custom' }
        $shortcut = [string](Get-PropertyValue $entry 'shortcut')
        if ([string]::IsNullOrWhiteSpace($shortcut)) { $shortcut = [string](Get-PropertyValue $entry 'target') }

        $method = [pscustomobject]@{
            Name     = $methodName
            Shortcut = $shortcut
        }

        foreach ($result in @(ConvertTo-Array $Results)) {
            foreach ($game in @($result.Games)) {
                if ($null -eq $game) { continue }
                if ($game.Name -ieq $matchName -or ($game.Id -and $game.Id -ieq $matchName)) {
                    $existing = @($game.LaunchMethods)
                    $game.LaunchMethods = @($existing + $method)
                }
            }
        }
    }

    return @(ConvertTo-Array $Results)
}

function Apply-GameOverrides {
    param(
        $Results,
        $Config
    )

    $raw = @(Get-PropertyValue $Config 'gameOverrides')
    if ($raw.Count -eq 0) { return @(ConvertTo-Array $Results) }

    foreach ($override in $raw) {
        if ($null -eq $override) { continue }
        $match = Get-PropertyValue $override 'match'
        $matchProvider = [string](Get-PropertyValue $match 'provider')
        $matchId = [string](Get-PropertyValue $match 'id')
        $matchName = [string](Get-PropertyValue $match 'name')

        $newTitle = [string](Get-PropertyValue $override 'title')
        $newCover = [string](Get-PropertyValue $override 'cover')
        $newHero = [string](Get-PropertyValue $override 'hero')
        $newIcon = [string](Get-PropertyValue $override 'icon')
        $newMethods = @(Get-PropertyValue $override 'launchMethods' | Where-Object { $_ })

        foreach ($result in @(ConvertTo-Array $Results)) {
            foreach ($game in @($result.Games)) {
                if ($null -eq $game) { continue }

                $providerMatches = $true
                if ($matchProvider) { $providerMatches = ($game.Provider -ieq $matchProvider -or $result.DisplayName -ieq $matchProvider) }
                $idMatches = $true
                if ($matchId) { $idMatches = ([string]$game.Id -ieq $matchId) }
                $nameMatches = $true
                if ($matchName) { $nameMatches = ($game.Name -ieq $matchName) }

                if (!($providerMatches -and $idMatches -and $nameMatches)) { continue }

                if ($newTitle) { $game.Name = $newTitle }
                if ($newCover) { $game.CoverPath = $newCover }
                if ($newHero) { $game.HeroPath = $newHero }
                if ($newIcon) { $game.IconPath = $newIcon }
                if ($newMethods.Count -gt 0) {
                    $converted = @()
                    foreach ($m in $newMethods) {
                        if ($null -eq $m) { continue }
                        $converted += [pscustomobject]@{
                            Name     = [string](Get-PropertyValue $m 'name')
                            Shortcut = [string](Get-PropertyValue $m 'shortcut')
                        }
                    }
                    $game.LaunchMethods = @($converted)
                }
            }
        }
    }

    return @(ConvertTo-Array $Results)
}

function Invoke-ProviderScans {
    param(
        $Config,
        [string[]]$Only
    )

    $selected = @(Get-SelectedProviderDefinitions -Config $Config -Only $Only)
    if ($selected.Count -eq 0) {
        if (@($Only | Where-Object { $_ }).Count -gt 0) {
            Write-Log ("No providers matched -Only '{0}'." -f (@($Only) -join ', ')) -Level Warn
        }
        return @()
    }

    $results = New-Object System.Collections.Generic.List[object]

    foreach ($definition in $selected) {
        $command = Get-Command $definition.Function -ErrorAction SilentlyContinue
        if (!$command) {
            Write-Log "Provider module '$($definition.File)' is not loaded; skipping $($definition.DisplayName)." -Level Warn
            continue
        }

        Write-Log "Scanning $($definition.DisplayName)..." -Level Debug

        $result = $null
        try {
            $result = & $definition.Function -Config $Config
        } catch {
            Write-Log "$($definition.DisplayName): scan failed: $($_.Exception.Message)" -Level Warn
            $result = $null
        }

        if ($result) {
            # A provider may return several results (the emulator provider emits
            # one result per installed emulator).
            foreach ($item in @(ConvertTo-Array $result)) {
                if ($item) { $results.Add($item) }
            }
        } else {
            Write-Log "$($definition.DisplayName): nothing found." -Level Debug
        }
    }

    $filterBySelection = (@($Only | Where-Object { $_ }).Count -gt 0)
    $selectedKeys = @($selected | ForEach-Object { $_.Key })

    $merged = Merge-CustomEntries -Results $results -Config $Config -SelectedKeys $selectedKeys -FilterBySelection $filterBySelection
    $merged = @(Remove-DuplicateStandaloneGames -Results $merged)
    $merged = @(Merge-CustomLaunchMethods -Results $merged -Config $Config)
    $merged = @(Apply-GameOverrides -Results $merged -Config $Config)
    return $merged
}
