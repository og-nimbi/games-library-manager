# Xbox / Microsoft Store games via AppX package manifests.

function Get-XboxGamePattern {
    return '(?i)(Halo|Forza|FlightSimulator|Gears|SeaOfThieves|Minecraft|AgeOfEmpires|Psychonauts|Doom|Wolfenstein|Fallout|ElderScrolls|Skyrim|Starfield|Quake|CrashBandicoot|Spyro|TonyHawk|Diablo|Overwatch|CallOfDuty|Solitaire|Roblox|Asphalt|Disney|DragonQuest|FinalFantasy|Octopath|Yakuza|Persona|HollowKnight|Cuphead|Stardew|Terraria|NoMansSky|HiFiRush|Pentiment|Grounded|StateOfDecay|Ori|Wasteland|Dishonored|Prey|Rage|EvilWithin|Ghostwire|Redfall|IndianaJones|SouthOfMidnight|Avowed|Clockwork|Keeper)'
}

function Get-XboxExcludedPattern {
    return '(?i)(GamingApp|XboxApp|XboxGameBar|XboxGamingOverlay|XboxIdentityProvider|XboxSpeechToText|XboxGameCallableUI|WindowsStore|DesktopAppInstaller|VCLibs|UI\.Xaml|NET\.Native|Services\.Store)'
}

function Get-XboxAppAumid {
    try {
        $package = Get-AppxPackage -Name 'Microsoft.GamingApp' -ErrorAction SilentlyContinue | Select-Object -First 1
        if (!$package) { return $null }
        $manifest = Get-AppxPackageManifest -Package $package -ErrorAction Stop
        $application = @($manifest.Package.Applications.Application) | Select-Object -First 1
        if (!$application -or !$application.Id) { return $null }
        return ($package.PackageFamilyName + '!' + $application.Id)
    } catch {
        return $null
    }
}

function Get-XboxProvider {
    $explorer = Join-Path $env:WINDIR 'explorer.exe'
    $shellIcon = Join-Path $env:WINDIR 'System32\shell32.dll'
    if (!(Test-Path -LiteralPath $explorer -PathType Leaf -ErrorAction SilentlyContinue)) { return $null }

    $games = New-Object System.Collections.Generic.List[object]
    $pattern = Get-XboxGamePattern
    $excluded = Get-XboxExcludedPattern

    try {
        $packages = @(Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object {
            !$_.IsFramework -and !$_.IsResourcePackage -and !$_.IsBundle -and
            $_.Name -match $pattern -and $_.Name -notmatch $excluded
        })
    } catch {
        Write-Log "Xbox: could not enumerate AppX packages: $($_.Exception.Message)" -Level Debug
        $packages = @()
    }

    foreach ($package in $packages) {
        try {
            $manifest = Get-AppxPackageManifest -Package $package -ErrorAction Stop
            $application = @($manifest.Package.Applications.Application) | Select-Object -First 1
            if (!$application -or !$application.Id) { continue }

            $displayName = [string]$application.VisualElements.DisplayName
            if (!$displayName -or $displayName -like 'ms-resource:*') {
                $displayName = $package.Name -replace '^Microsoft\.', '' -replace '^BethesdaSoftworks\.', '' -replace '\.', ' '
            }

            $aumid = $package.PackageFamilyName + '!' + $application.Id
            $games.Add((New-GameEntry -Name $displayName -Provider 'Xbox' -ProviderKey 'xbox' -Kind 'StoreGame' `
                -Target $explorer -Arguments ('shell:AppsFolder\' + $aumid) -WorkingDirectory $env:WINDIR `
                -IconPath $shellIcon -InstallDir $package.InstallLocation -Id $aumid -Source 'xbox-appx'))
        } catch {
            Write-Log "Xbox: could not read manifest for $($package.Name): $($_.Exception.Message)" -Level Debug
        }
    }

    # explorer.exe always exists, so only offer an Xbox shortcut when the Xbox app
    # or at least one Xbox game is actually present.
    $launcher = $null
    $xboxAumid = Get-XboxAppAumid
    if ($xboxAumid -or $games.Count -gt 0) {
        $launcherArgs = 'shell:AppsFolder'
        if ($xboxAumid) { $launcherArgs = 'shell:AppsFolder\' + $xboxAumid }

        $launcher = New-GameEntry -Name 'Xbox' -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $explorer -Arguments $launcherArgs -WorkingDirectory $env:WINDIR -IconPath $shellIcon -Source 'xbox-launcher'
    }

    if (!$launcher -and $games.Count -eq 0) { return $null }

    return New-ProviderResult -Key 'xbox' -DisplayName 'Xbox' -Launcher $launcher -Games $games -IconPath $shellIcon
}
