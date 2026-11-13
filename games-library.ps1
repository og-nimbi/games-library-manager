# Games Library Manager entrypoint.
# Scans installed storefront games, standalone games, and community launchers,
# then rebuilds an organized shortcut library.

[CmdletBinding()]
param(
    [string]$LibraryRoot,
    [string]$Config,
    [switch]$DryRun,
    [switch]$Open,
    [switch]$Force,
    [switch]$NoIndex,
    [switch]$NoClean,
    [switch]$NoFolderIcons,
    [string[]]$Only,
    [switch]$InitRoms,
    [string]$RomRoot,
    [string]$SetSecret,
    [string]$RemoveSecret,
    [switch]$ListSecrets,
    [string]$ApplyGameSettings,
    [string]$ApplySettings,
    [switch]$RegisterProtocol,
    [switch]$UnregisterProtocol,
    [string]$Launch,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

function Show-Usage {
    Write-Host ''
    Write-Host 'Games Library Manager' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Usage:'
    Write-Host '  games-library.cmd [options]'
    Write-Host ''
    Write-Host 'Options:'
    Write-Host '  -LibraryRoot <path>   Folder that will contain the generated library.'
    Write-Host '                        Default: libraryRoot from config (D:\Games).'
    Write-Host '  -Config <path>        JSON settings file. Default: config\settings.json.'
    Write-Host '  -DryRun               Scan and report without writing any files.'
    Write-Host '  -Open                 Open the HTML index (or library folder) when done.'
    Write-Host '  -Force                Back up and replace an unmanaged non-empty library root.'
    Write-Host '  -NoIndex              Do not generate _library\index.html.'
    Write-Host '  -NoClean              Do not remove shortcuts left by an earlier run.'
    Write-Host '  -NoFolderIcons        Do not write desktop.ini folder icons.'
    Write-Host '  -Only <providers>     Comma-separated providers, e.g. steam,itch,standalone.'
    Write-Host '  -InitRoms             Create a per-console ROM folder structure and exit.'
    Write-Host '  -RomRoot <path>       Target for -InitRoms. Default: first scan.romRoots'
    Write-Host '                        entry, or D:\ROMs when none is configured.'
    Write-Host '  -SetSecret <name>     Store an API key or secret securely (DPAPI) and exit.'
    Write-Host '  -RemoveSecret <name>  Remove a stored secret and exit.'
    Write-Host '  -ListSecrets          List stored secret names (values are never shown).'
    Write-Host '  -ApplyGameSettings <file>  Merge a per-game settings patch into config and rebuild.'
    Write-Host '  -ApplySettings <file>  Merge a top-level config patch into settings.json and rebuild.'
    Write-Host '  -RegisterProtocol     Register the gameslibrary:// handler and exit.'
    Write-Host '  -UnregisterProtocol   Remove the gameslibrary:// handler and exit.'
    Write-Host '  -Launch <uri>         Launch a shortcut by relative path or protocol URI and exit.'
    Write-Host '  -Help                 Show this help.'
    Write-Host ''
    Write-Host 'Providers:'
    Write-Host '  steam, epic, gog, itch, amazon, legacyGames, ea, ubisoft, battleNet,'
    Write-Host '  rockstar, riot, wargaming, hiRez, xbox, standalone, customLaunchers,'
    Write-Host '  emulators'
    Write-Host ''
    Write-Host 'Examples:'
    Write-Host '  games-library.cmd -DryRun'
    Write-Host '  games-library.cmd -Force'
    Write-Host '  games-library.cmd -Only steam,itch -NoFolderIcons'
    Write-Host '  games-library.cmd -InitRoms -RomRoot D:\ROMs'
    Write-Host '  games-library.cmd -InitRoms -RomRoot D:\ROMs -DryRun'
    Write-Host ''
}

if ($Help) {
    Show-Usage
    return
}

try {
    $scriptRoot = $PSScriptRoot
    if (!$scriptRoot) { $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }

    # Load a local .env file (gitignored) so dev API keys are available as
    # environment variables. Real environment variables always take precedence.
    # (Import-DotEnv is defined in Common.ps1, loaded below.)

    $coreDir = Join-Path $scriptRoot 'src\Core'
    $coreFiles = @('Common.ps1', 'Discovery.ps1', 'Titles.ps1', 'Shortcuts.ps1', 'Index.ps1', 'Library.ps1', 'Secrets.ps1', 'Artwork.ps1', 'Metadata.ps1')
    foreach ($name in $coreFiles) {
        $path = Join-Path $coreDir $name
        if (!(Test-Path -LiteralPath $path -PathType Leaf -ErrorAction SilentlyContinue)) {
            throw "Missing core module: $path"
        }
        . $path
    }

    # Load a local .env file (gitignored) so dev API keys are available as
    # environment variables. Real environment variables always take precedence.
    Import-DotEnv -Path (Join-Path $scriptRoot '.env')

    $providerDir = Join-Path $scriptRoot 'src\Providers'
    if (!(Test-Path -LiteralPath $providerDir -PathType Container -ErrorAction SilentlyContinue)) {
        throw "Missing provider folder: $providerDir"
    }

    $providerFiles = @(
        Get-ChildItem -LiteralPath $providerDir -Filter '*.ps1' -File -ErrorAction Stop |
            Where-Object { $_.Name -ne 'Providers.ps1' } |
            Sort-Object Name
    )
    foreach ($file in $providerFiles) { . $file.FullName }

    $providersModule = Join-Path $providerDir 'Providers.ps1'
    if (!(Test-Path -LiteralPath $providersModule -PathType Leaf -ErrorAction SilentlyContinue)) {
        throw "Missing provider registry: $providersModule"
    }
    . $providersModule

    if (!$Config) { $Config = Join-Path $scriptRoot 'config\settings.json' }
    if (![IO.Path]::IsPathRooted($Config)) { $Config = Join-Path (Get-Location).Path $Config }

    $settings = Get-GamesLibraryConfig -ConfigPath $Config

    $root = $LibraryRoot
    if (!$root) { $root = [string](Get-PropertyValue $settings 'libraryRoot') }
    if (!$root) { throw 'No library root was provided and the config has no libraryRoot.' }

    # Secret management commands. These never scan or build the library.
    if ($SetSecret) {
        $secure = Read-Host -Prompt ("Enter value for secret '{0}'" -f $SetSecret) -AsSecureString
        $plain = ConvertFrom-SecureStringPlain -Secure $secure
        if ([string]::IsNullOrWhiteSpace($plain)) {
            Write-Log 'No value entered; secret was not stored.' -Level Warn
            return
        }
        Set-StoredSecret -Name $SetSecret -Value $plain
        return
    }

    if ($RemoveSecret) {
        Remove-StoredSecret -Name $RemoveSecret
        return
    }

    if ($ListSecrets) {
        $names = @(Get-StoredSecretNames)
        if ($names.Count -eq 0) {
            Write-Host 'No secrets are stored.'
        } else {
            Write-Host 'Stored secrets:'
            foreach ($name in $names) { Write-Host ('  ' + $name) }
        }
        return
    }

    # Merge a per-game settings patch into the config, then continue building.
    if ($ApplyGameSettings) {
        $patchPath = $ApplyGameSettings
        if (![IO.Path]::IsPathRooted($patchPath)) { $patchPath = Join-Path (Get-Location).Path $patchPath }
        if (!(Test-Path -LiteralPath $patchPath -PathType Leaf -ErrorAction SilentlyContinue)) {
            throw "Game settings patch not found: $patchPath"
        }

        $patch = Get-Content -LiteralPath $patchPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $patchOverrides = @()
        $topOverride = Get-PropertyValue $patch 'match'
        if ($topOverride) {
            $patchOverrides = @($patch)
        } else {
            $patchOverrides = @(Get-PropertyValue $patch 'gameOverrides')
        }

        if ($patchOverrides.Count -eq 0) {
            throw 'The patch file contains no gameOverrides.'
        }

        $configPath = $Config
        if (!$configPath) { $configPath = Join-Path $scriptRoot 'config\settings.json' }
        if (![IO.Path]::IsPathRooted($configPath)) { $configPath = Join-Path (Get-Location).Path $configPath }

        $current = Get-GamesLibraryConfig -ConfigPath $configPath
        $existing = @(Get-PropertyValue $current 'gameOverrides')
        $current.gameOverrides = @($existing + $patchOverrides)
        $current | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $configPath -Encoding UTF8 -Force
        Write-Log "Applied $($patchOverrides.Count) game override(s) to $configPath." -Level Ok

        # Reload settings so this run uses the new overrides.
        $settings = Get-GamesLibraryConfig -ConfigPath $configPath
    }

    # Merge a top-level config patch (artwork, metadata, providers, scan, ...) into
    # settings.json, then continue building.
    if ($ApplySettings) {
        $patchPath = $ApplySettings
        if (![IO.Path]::IsPathRooted($patchPath)) { $patchPath = Join-Path (Get-Location).Path $patchPath }
        if (!(Test-Path -LiteralPath $patchPath -PathType Leaf -ErrorAction SilentlyContinue)) {
            throw "Settings patch not found: $patchPath"
        }

        $patch = Get-Content -LiteralPath $patchPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $patchHash = @{}
        if ($patch -is [System.Collections.IDictionary]) {
            foreach ($k in $patch.Keys) { $patchHash[$k] = $patch[$k] }
        } else {
            foreach ($p in $patch.PSObject.Properties) { $patchHash[$p.Name] = $p.Value }
        }

        $configPath = $Config
        if (!$configPath) { $configPath = Join-Path $scriptRoot 'config\settings.json' }
        if (![IO.Path]::IsPathRooted($configPath)) { $configPath = Join-Path (Get-Location).Path $configPath }

        $current = Get-GamesLibraryConfig -ConfigPath $configPath
        # Merge: for object values, shallow-merge keys; otherwise replace.
        foreach ($key in $patchHash.Keys) {
            $existing = Get-PropertyValue $current $key
            $incoming = $patchHash[$key]
            if ($existing -is [System.Collections.IDictionary] -and $incoming -isnot [string] -and $incoming -isnot [array]) {
                $incHash = @{}
                if ($incoming -is [System.Collections.IDictionary]) {
                    foreach ($k in $incoming.Keys) { $incHash[$k] = $incoming[$k] }
                } else {
                    foreach ($p in $incoming.PSObject.Properties) { $incHash[$p.Name] = $p.Value }
                }
                if ($existing -is [hashtable]) {
                    foreach ($k in $incHash.Keys) { $existing[$k] = $incHash[$k] }
                    $current[$key] = $existing
                } else {
                    $current[$key] = $incHash
                }
            } else {
                $current[$key] = $incoming
            }
        }

        $current | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $configPath -Encoding UTF8 -Force
        Write-Log "Applied settings patch to $configPath." -Level Ok

        $settings = Get-GamesLibraryConfig -ConfigPath $configPath
    }

    # Protocol handler registration (no admin required: HKCU).
    if ($RegisterProtocol) {
        $command = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $PSCommandPath + '" -Launch "%1"'
        $key = 'HKCU:\Software\Classes\gameslibrary'
        New-Item -Path $key -Force | Out-Null
        Set-ItemProperty -Path $key -Name '(Default)' -Value 'URL:Games Library Protocol' -ErrorAction SilentlyContinue
        New-ItemProperty -Path $key -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
        $commandKey = Join-Path $key 'shell\open\command'
        New-Item -Path $commandKey -Force | Out-Null
        Set-Item -Path $commandKey -Value $command
        Write-Log "Registered gameslibrary:// protocol handler." -Level Ok
        Write-Log "Command: $command" -Level Debug
        return
    }

    if ($UnregisterProtocol) {
        $key = 'HKCU:\Software\Classes\gameslibrary'
        if (Test-Path -LiteralPath $key -ErrorAction SilentlyContinue) {
            Remove-Item -LiteralPath $key -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "Removed gameslibrary:// protocol handler." -Level Ok
        } else {
            Write-Log "gameslibrary:// protocol handler is not registered." -Level Debug
        }
        return
    }

    if ($Launch) {
        $relative = $Launch
        if ($relative -match '^gameslibrary://') {
            try {
                $uri = [Uri]$relative
                $relative = [Uri]::UnescapeDataString($uri.AbsolutePath.TrimStart('/'))
            } catch {
                $relative = $Launch
            }
        }

        $root = $LibraryRoot
        if (!$root) { $root = [string](Get-PropertyValue $settings 'libraryRoot') }
        if (!$root) { $root = 'D:\Games' }

        $relative = $relative -replace '/', '\'
        $fullPath = Join-Path $root $relative
        if (!(Test-PathUnderRoot -Root $root -Path $fullPath)) {
            Write-Log "Launch target is outside the library root: $relative" -Level Warn
            return
        }
        if (!(Test-Path -LiteralPath $fullPath -PathType Leaf -ErrorAction SilentlyContinue)) {
            Write-Log "Launch target not found: $relative" -Level Warn
            return
        }

        try {
            Start-Process -FilePath $fullPath
            Write-Log "Launched: $relative" -Level Ok
        } catch {
            Write-Log "Could not launch '$relative': $($_.Exception.Message)" -Level Warn
        }
        return
    }

    # Optional one-shot ROM folder scaffold. Does not scan or build.
    if ($InitRoms) {
        $romRoot = $RomRoot
        if (!$romRoot) {
            $scanSettings = Get-PropertyValue $settings 'scan'
            $configuredRomRoots = @(Get-PropertyValue $scanSettings 'romRoots' | Where-Object { $_ })
            if ($configuredRomRoots.Count -gt 0) { $romRoot = [string]$configuredRomRoots[0] }
        }
        if (!$romRoot) { $romRoot = 'D:\ROMs' }

        $scaffold = Initialize-RomFolderStructure -Root $romRoot -DryRun:$DryRun
        return
    }

    # The .cmd wrapper passes "steam,itch" as a single argument, so split on
    # commas and semicolons before matching provider names.
    $onlyList = New-Object System.Collections.Generic.List[string]
    foreach ($item in @($Only)) {
        if (!$item) { continue }
        foreach ($part in ([string]$item -split '[,;]')) {
            $p = $part.Trim()
            if ($p -and !$onlyList.Contains($p)) { $onlyList.Add($p) }
        }
    }
    $onlyArray = @(ConvertTo-Array $onlyList)

    if ($onlyArray.Count -gt 0) {
        $catalog = Get-ProviderCatalog
        $matchedProviders = 0
        foreach ($item in $onlyArray) {
            $match = $catalog | Where-Object {
                $_.Key -ieq $item -or $_.DisplayName -ieq $item -or
                $_.File -ieq $item -or ([IO.Path]::GetFileNameWithoutExtension($_.File) -ieq $item)
            } | Select-Object -First 1

            if ($match) {
                $matchedProviders++
            } else {
                Write-Log "Unknown provider in -Only: $item" -Level Warn
            }
        }

        if ($matchedProviders -eq 0) {
            throw ('No providers matched -Only: ' + ($onlyArray -join ', '))
        }
    }

    $results = @(Invoke-ProviderScans -Config $settings -Only $onlyArray)

    $summary = Build-GamesLibrary -Config $settings -Root $root -Providers $results `
        -DryRun:$DryRun -NoIndex:$NoIndex -NoClean:$NoClean -NoFolderIcons:$NoFolderIcons -Force:$Force

    if ($Open -and !$DryRun) {
        $indexPath = Join-Path $summary.Root '_library\index.html'
        $targetPath = $null
        if (!$NoIndex -and (Test-Path -LiteralPath $indexPath -PathType Leaf -ErrorAction SilentlyContinue)) {
            $targetPath = $indexPath
        } else {
            $targetPath = $summary.Root
        }

        $edgePath = Get-EdgeExecutablePath
        if ($edgePath -and $targetPath -match '\.html?$') {
            $fileUri = ConvertTo-FileUri -Path $targetPath
            Start-Process -FilePath $edgePath -ArgumentList ('--app="' + $fileUri + '"')
        } elseif (Test-Path -LiteralPath $targetPath -PathType Leaf -ErrorAction SilentlyContinue) {
            Start-Process -FilePath $targetPath
        } else {
            Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $targetPath + '"')
        }
    }

    if ($summary.Backup) {
        Write-Host ''
        Write-Host "Previous library was backed up to: $($summary.Backup)" -ForegroundColor Yellow
    }
} catch {
    Write-Host ''
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    if ($_.ScriptStackTrace) { Write-Verbose $_.ScriptStackTrace }
    Write-Host ''
    Write-Host 'Run games-library.cmd -Help for usage.' -ForegroundColor DarkGray
    exit 1
}
