# itch.io: app-* launcher, apps folder, receipt.json.gz metadata.

function Get-ItchLauncherPath {
    $app = Get-InstalledApplications | Where-Object { $_.DisplayName -ieq 'itch' } | Select-Object -First 1
    $candidates = @()
    if ($app) {
        # DisplayIcon is usually app.ico, so only accept it when it is the executable.
        if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe') {
            $candidates += $app.DisplayIcon
        }
        if ($app.InstallLocation) { $candidates += (Join-Path $app.InstallLocation 'itch.exe') }
    }

    $candidates += @(
        '%LOCALAPPDATA%\Programs\itch\itch.exe',
        '%LOCALAPPDATA%\itch\itch.exe',
        '%ProgramFiles%\itch\itch.exe',
        '%ProgramFiles(x86)%\itch\itch.exe'
    )

    $found = Find-FirstExistingPath -Paths $candidates -PathType Leaf
    if ($found) { return $found }

    $roots = @(
        '%LOCALAPPDATA%\itch',
        '%LOCALAPPDATA%\Programs\itch',
        '%ProgramFiles%\itch',
        '%ProgramFiles(x86)%\itch'
    )

    foreach ($drive in @(Get-AllFixedDriveRoots)) {
        $roots += (Join-Path $drive 'itch')
    }

    foreach ($root in $roots) {
        $expanded = Expand-PathValue $root
        if (!$expanded -or !(Test-Path -LiteralPath $expanded -PathType Container -ErrorAction SilentlyContinue)) { continue }

        $direct = Join-Path $expanded 'itch.exe'
        if (Test-Path -LiteralPath $direct -PathType Leaf -ErrorAction SilentlyContinue) { return $direct }

        $versioned = @(Get-ChildItem -LiteralPath $expanded -Directory -Filter 'app-*' -ErrorAction SilentlyContinue | Sort-Object Name -Descending)
        foreach ($folder in $versioned) {
            $exe = Join-Path $folder.FullName 'itch.exe'
            if (Test-Path -LiteralPath $exe -PathType Leaf -ErrorAction SilentlyContinue) { return $exe }
        }
    }

    return $null
}

function Get-ItchAppsRoots {
    param([string]$LauncherPath)

    $roots = @(
        '%APPDATA%\itch\apps',
        '%LOCALAPPDATA%\itch\apps'
    )

    foreach ($drive in @(Get-AllFixedDriveRoots)) {
        $roots += (Join-Path $drive 'itch\apps')
    }

    if ($LauncherPath) {
        $launcherDir = Split-Path -Parent $LauncherPath
        $roots += (Join-Path (Split-Path -Parent $launcherDir) 'apps')
    }

    $apps = Get-InstalledApplications | Where-Object { $_.DisplayName -ieq 'itch' } | Select-Object -First 1
    if ($apps -and $apps.InstallLocation) {
        $roots += (Join-Path $apps.InstallLocation 'apps')
    }

    $result = New-Object System.Collections.Generic.List[string]
    foreach ($root in $roots) {
        $expanded = Expand-PathValue $root
        if (!$expanded) { continue }
        if (!(Test-Path -LiteralPath $expanded -PathType Container -ErrorAction SilentlyContinue)) { continue }
        if (!($result -contains $expanded)) { $result.Add($expanded) }
    }

    return @($result)
}

function Get-JarMainClass {
    param([string]$Path)

    if (!$Path) { return $null }

    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $zip = [IO.Compression.ZipFile]::OpenRead($Path)
        try {
            $entry = $zip.Entries | Where-Object { $_.FullName -ieq 'META-INF/MANIFEST.MF' } | Select-Object -First 1
            if (!$entry) { return $null }

            $reader = New-Object IO.StreamReader($entry.Open())
            try { $text = $reader.ReadToEnd() } finally { $reader.Dispose() }

            $match = [regex]::Match($text, '(?im)^Main-Class:\s*([^\r\n]+)')
            if ($match.Success) { return $match.Groups[1].Value.Trim() }
        } finally {
            $zip.Dispose()
        }
    } catch {
    }

    return $null
}

function Find-ItchJavaArchive {
    param(
        [string]$Directory,
        [string]$PreferName = ''
    )

    if (!$Directory) { return $null }

    $jars = @(
        Get-ChildItem -LiteralPath $Directory -Filter '*.jar' -File -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $_.FullName -notmatch '(?i)\\(jre|jdk|runtime|jmods)\\' -and
                $_.Name -notmatch '(?i)(sources|javadoc)\.jar$'
            }
    )
    if ($jars.Count -eq 0) { return $null }

    $preferred = ''
    if ($PreferName) { $preferred = ($PreferName -replace '[^a-zA-Z0-9]', '').ToLowerInvariant() }

    $scored = foreach ($jar in $jars) {
        $score = 0.0
        $base = $jar.BaseName
        $normalized = ($base -replace '[^a-zA-Z0-9]', '').ToLowerInvariant()

        # A jar with a Main-Class manifest entry is directly launchable.
        if (Get-JarMainClass $jar.FullName) { $score += 2000 }

        if ($preferred) {
            if ($normalized -eq $preferred) { $score += 800 }
            elseif ($normalized.Contains($preferred) -or $preferred.Contains($normalized)) { $score += 400 }
        }

        if ($base -match '(?i)^(game|client|main|start|launcher)$') { $score += 300 }
        if ($jar.FullName -match '(?i)\\libs?\\') { $score -= 60 }
        if ($jar.FullName -match '(?i)\\mods?\\') { $score -= 80 }

        $score -= ($jar.FullName.Split([IO.Path]::DirectorySeparatorChar).Count * 5)
        $score += [math]::Min(($jar.Length / 1MB) * 20, 400)

        [pscustomobject]@{ File = $jar; Score = $score }
    }

    return ($scored | Sort-Object Score -Descending | Select-Object -First 1).File.FullName
}

function Find-ItchJavaRuntime {
    param([string]$Directory)

    $javaNames = @('javaw.exe', 'java.exe')

    # Prefer a runtime bundled with the game so the shortcut works even when
    # Java is not installed system-wide.
    if ($Directory) {
        foreach ($name in $javaNames) {
            $bundled = @(
                Get-ChildItem -LiteralPath $Directory -Filter $name -File -Recurse -Depth 4 -Force -ErrorAction SilentlyContinue |
                    Sort-Object { $_.FullName.Split([IO.Path]::DirectorySeparatorChar).Count }
            )
            if ($bundled.Count -gt 0) { return $bundled[0].FullName }
        }
    }

    foreach ($name in $javaNames) {
        $command = Get-Command $name -ErrorAction SilentlyContinue |
            Where-Object { $_.Source -and (Test-Path -LiteralPath $_.Source -PathType Leaf -ErrorAction SilentlyContinue) } |
            Select-Object -First 1
        if ($command) { return $command.Source }
    }

    $globs = @(
        '%ProgramFiles%\Java\*\bin\javaw.exe',
        '%ProgramFiles(x86)%\Java\*\bin\javaw.exe',
        '%ProgramFiles%\Eclipse Adoptium\*\bin\javaw.exe',
        '%ProgramFiles%\Eclipse Foundation\*\bin\javaw.exe',
        '%ProgramFiles%\Amazon Corretto\*\bin\javaw.exe',
        '%ProgramFiles%\Zulu\*\bin\javaw.exe',
        '%ProgramFiles%\BellSoft\*\bin\javaw.exe',
        '%ProgramFiles%\Microsoft\jdk-*\bin\javaw.exe'
    )

    foreach ($glob in $globs) {
        $expanded = Expand-PathValue $glob
        $hits = @(Get-ChildItem -Path $expanded -File -ErrorAction SilentlyContinue | Sort-Object FullName -Descending)
        if ($hits.Count -gt 0) { return $hits[0].FullName }
    }

    $registryRoots = @(
        'HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment',
        'HKLM:\SOFTWARE\JavaSoft\JRE',
        'HKLM:\SOFTWARE\JavaSoft\JDK',
        'HKLM:\SOFTWARE\WOW6432Node\JavaSoft\Java Runtime Environment',
        'HKLM:\SOFTWARE\WOW6432Node\JavaSoft\JRE',
        'HKLM:\SOFTWARE\WOW6432Node\JavaSoft\JDK'
    )

    foreach ($root in $registryRoots) {
        if (!(Test-Path -LiteralPath $root -ErrorAction SilentlyContinue)) { continue }
        $versions = @(Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue | Sort-Object Name -Descending)
        foreach ($version in $versions) {
            $home = [string](Get-ItemProperty -LiteralPath $version.PSPath -Name 'JavaHome' -ErrorAction SilentlyContinue).JavaHome
            if (!$home) { continue }
            $candidate = Join-Path $home 'bin\javaw.exe'
            if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) { return $candidate }
        }
    }

    return $null
}

function Find-ItchFlashGame {
    param(
        [string]$Directory,
        [string]$PreferName = ''
    )

    if (!$Directory) { return $null }

    $swfs = @(
        Get-ChildItem -LiteralPath $Directory -Filter '*.swf' -File -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $_.FullName -notmatch '(?i)\\(ruffle|flash|player)\\' -and
                $_.Name -notmatch '(?i)^(ruffle|preloader|loader)\.swf$'
            }
    )
    if ($swfs.Count -eq 0) { return $null }

    $preferred = ''
    if ($PreferName) { $preferred = ($PreferName -replace '[^a-zA-Z0-9]', '').ToLowerInvariant() }

    $scored = foreach ($swf in $swfs) {
        $score = 0.0
        $normalized = ($swf.BaseName -replace '[^a-zA-Z0-9]', '').ToLowerInvariant()

        if ($preferred) {
            if ($normalized -eq $preferred) { $score += 800 }
            elseif ($normalized.Contains($preferred) -or $preferred.Contains($normalized)) { $score += 400 }
        }

        if ($swf.BaseName -match '(?i)^(game|main|play|start|index)$') { $score += 300 }
        $score -= ($swf.FullName.Split([IO.Path]::DirectorySeparatorChar).Count * 5)
        $score += [math]::Min($swf.Length / 1MB, 400)

        [pscustomobject]@{ File = $swf; Score = $score }
    }

    return ($scored | Sort-Object Score -Descending | Select-Object -First 1).File.FullName
}

function Find-ItchFlashPlayer {
    param([string]$Directory)

    if ($Directory) {
        foreach ($pattern in @('flashplayer*.exe', 'ruffle*.exe')) {
            $bundled = @(
                Get-ChildItem -LiteralPath $Directory -Filter $pattern -File -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
                    Sort-Object { $_.FullName.Split([IO.Path]::DirectorySeparatorChar).Count }
            )
            if ($bundled.Count -gt 0) { return $bundled[0].FullName }
        }
    }

    $candidates = @(
        '%WINDIR%\System32\Macromed\Flash\FlashPlayerProjector.exe',
        '%ProgramFiles%\Ruffle\ruffle.exe',
        '%ProgramFiles(x86)%\Ruffle\ruffle.exe',
        '%LOCALAPPDATA%\Ruffle\ruffle.exe',
        '%LOCALAPPDATA%\Programs\Ruffle\ruffle.exe'
    )

    foreach ($candidate in $candidates) {
        $expanded = Expand-PathValue $candidate
        if ($expanded -and (Test-Path -LiteralPath $expanded -PathType Leaf -ErrorAction SilentlyContinue)) { return $expanded }
    }

    foreach ($name in @('ruffle.exe', 'FlashPlayerProjector.exe')) {
        $command = Get-Command $name -ErrorAction SilentlyContinue |
            Where-Object { $_.Source -and (Test-Path -LiteralPath $_.Source -PathType Leaf -ErrorAction SilentlyContinue) } |
            Select-Object -First 1
        if ($command) { return $command.Source }
    }

    return $null
}

function Find-ItchWebEntryPoint {
    param([string]$Directory)

    if (!$Directory) { return $null }

    $names = '(?i)^(index|index2|game|play|default|start)\.html?$'
    $files = @(
        Get-ChildItem -LiteralPath $Directory -Filter '*.htm*' -File -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match $names } |
            Sort-Object @{ Expression = { $_.FullName.Split([IO.Path]::DirectorySeparatorChar).Count } }, @{ Expression = { $_.Name } }
    )
    if ($files.Count -gt 0) { return $files[0].FullName }

    # Fall back to a single loose HTML file if the build has no conventional name.
    $all = @(Get-ChildItem -LiteralPath $Directory -Filter '*.htm*' -File -Recurse -Depth 2 -Force -ErrorAction SilentlyContinue)
    if ($all.Count -eq 1) { return $all[0].FullName }

    return $null
}

function Find-ItchBatchLauncher {
    param([string]$Directory)

    if (!$Directory) { return $null }

    $batches = @(
        Get-ChildItem -LiteralPath $Directory -File -Recurse -Depth 2 -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -imatch '^\.(bat|cmd)$' }
    )

    foreach ($batch in $batches) {
        $text = ''
        try { $text = (Get-Content -LiteralPath $batch.FullName -TotalCount 100 -ErrorAction SilentlyContinue) -join "`n" } catch { $text = '' }
        if ($text -match '(?i)(\bjava(w)?\b|\.jar\b)') { return $batch.FullName }
    }

    return $null
}

function Get-ItchProvider {
    $launcherPath = Get-ItchLauncherPath
    $games = New-Object System.Collections.Generic.List[object]
    $seen = @{}
    $textInfo = (Get-Culture).TextInfo

    foreach ($appsRoot in (Get-ItchAppsRoots -LauncherPath $launcherPath)) {
        foreach ($appDir in @(Get-ChildItem -LiteralPath $appsRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'downloads' })) {
            if ($seen.ContainsKey($appDir.Name.ToLowerInvariant())) { continue }

            $title = $null
            $gameId = $null
            $coverUrl = ''
            $receipt = Read-ItchReceipt -AppDirectory $appDir.FullName
            if ($receipt) {
                $game = Get-PropertyValue $receipt 'game'
                if ($game) {
                    $title = [string](Get-PropertyValue $game 'title')
                    $gameId = [string](Get-PropertyValue $game 'id')
                    $coverUrl = [string](Get-PropertyValue $game 'coverUrl')
                    if ([string]::IsNullOrWhiteSpace($coverUrl)) {
                        $coverUrl = [string](Get-PropertyValue $game 'stillCoverUrl')
                    }
                }
            }

            if (!$title) {
                $title = $textInfo.ToTitleCase(($appDir.Name -replace '[-_]', ' '))
            }

            $target = $null
            $targetArguments = ''
            $workingDirectory = ''

            $icon = ''  # Do not use extracted_icon.ico: its colors come out wrong.
                        # The executable's own icon is the reliable source.

            $exe = Find-GameExecutable -Directory $appDir.FullName -Depth 4 -PreferName $appDir.Name
            if (!$exe) { $exe = Find-GameExecutable -Directory $appDir.FullName -Depth 4 -PreferName $title }

            if ($exe) {
                $target = $exe
            } else {
                # No native executable: try Java, Flash, HTML, and launcher scripts.
                $jar = Find-ItchJavaArchive -Directory $appDir.FullName -PreferName $title
                if ($jar) {
                    $java = Find-ItchJavaRuntime -Directory $appDir.FullName
                    if ($java) {
                        $target = $java
                        $targetArguments = '-jar "' + $jar + '"'
                        $workingDirectory = Split-Path -Parent $jar
                    } else {
                        $batch = Find-ItchBatchLauncher -Directory $appDir.FullName
                        if ($batch) {
                            $target = $batch
                            $workingDirectory = Split-Path -Parent $batch
                        } else {
                            Write-Log "itch.io: Java runtime not found and no launcher script for '$($appDir.Name)'." -Level Warn
                        }
                    }
                }

                if (!$target) {
                    $swf = Find-ItchFlashGame -Directory $appDir.FullName -PreferName $title
                    if ($swf) {
                        $player = Find-ItchFlashPlayer -Directory $appDir.FullName
                        if ($player) {
                            $target = $player
                            $targetArguments = '"' + $swf + '"'
                            $workingDirectory = Split-Path -Parent $player
                        } else {
                            $web = Find-ItchWebEntryPoint -Directory $appDir.FullName
                            if ($web) {
                                $target = ConvertTo-FileUri $web
                            } else {
                                $target = $swf
                                Write-Log "itch.io: no Flash player found for '$($appDir.Name)'; shortcut will use the .swf file association." -Level Debug
                            }
                        }
                    }
                }

                if (!$target) {
                    $web = Find-ItchWebEntryPoint -Directory $appDir.FullName
                    if ($web) { $target = ConvertTo-FileUri $web }
                }
            }

            if (!$target) {
                Write-Log "itch.io: no launchable entry point found for '$($appDir.Name)'." -Level Warn
                continue
            }

            if (!$icon -and !(Test-UrlTarget $target)) { $icon = $target }

            $seen[$appDir.Name.ToLowerInvariant()] = $true
            $games.Add((New-GameEntry -Name $title -Provider 'itch.io' -ProviderKey 'itch' -Kind 'StoreGame' `
                -Target $target -Arguments $targetArguments -WorkingDirectory $workingDirectory -IconPath $icon `
                -InstallDir $appDir.FullName -Id $gameId -CoverUrl $coverUrl -Source 'itch-app'))
        }
    }

    if (!$launcherPath -and $games.Count -eq 0) { return $null }

    $launcher = $null
    $launcherIcon = $launcherPath
    if ($launcherPath) {
        $app = Get-InstalledApplications | Where-Object { $_.DisplayName -ieq 'itch' } | Select-Object -First 1
        if ($app -and $app.DisplayIcon -and (Test-Path -LiteralPath $app.DisplayIcon -PathType Leaf -ErrorAction SilentlyContinue)) {
            $launcherIcon = $app.DisplayIcon
        }

        $launcher = New-GameEntry -Name 'itch.io' -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $launcherPath -IconPath $launcherIcon -Source 'itch-launcher'
    }

    return New-ProviderResult -Key 'itch' -DisplayName 'itch.io' -Launcher $launcher -Games $games -IconPath $launcherIcon
}
