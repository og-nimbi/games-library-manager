# Common helpers: logging, configuration, path and name utilities, entries.

if ($null -eq $script:DryRun) { $script:DryRun = $false }
$script:LogFilePath = $null
$script:WarningCount = 0
$script:LogBuffer = New-Object System.Collections.Generic.List[string]

function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('Info', 'Ok', 'Warn', 'Error', 'Debug')][string]$Level = 'Info'
    )

    $color = 'Gray'
    $prefix = 'INFO'
    switch ($Level) {
        'Ok'    { $color = 'Green';   $prefix = ' OK ' }
        'Warn'  { $color = 'Yellow';  $prefix = 'WARN'; $script:WarningCount++ }
        'Error' { $color = 'Red';     $prefix = 'FAIL'; $script:WarningCount++ }
        'Debug' { $color = 'DarkGray'; $prefix = 'DBG ' }
        default { $color = 'Gray';    $prefix = 'INFO' }
    }

    $line = '[{0}] {1} {2}' -f (Get-Date -Format 'HH:mm:ss'), $prefix, $Message
    Write-Host $line -ForegroundColor $color

    if ($script:DryRun) { return }

    if ($script:LogFilePath) {
        try {
            Add-Content -LiteralPath $script:LogFilePath -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
        } catch {
        }
    } elseif ($null -ne $script:LogBuffer) {
        $script:LogBuffer.Add($line)
    }
}

function Flush-LogBuffer {
    if ($script:DryRun) { return }
    if (!$script:LogFilePath) { return }
    if ($null -eq $script:LogBuffer -or $script:LogBuffer.Count -eq 0) { return }

    try {
        Add-Content -LiteralPath $script:LogFilePath -Value @($script:LogBuffer) -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
    }

    $script:LogBuffer.Clear()
}

function Import-DotEnv {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    if (!(Test-Path -LiteralPath $Path -PathType Leaf -ErrorAction SilentlyContinue)) { return }

    foreach ($line in (Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $trimmed = $line.Trim()
        if ($trimmed.StartsWith('#')) { continue }
        $idx = $trimmed.IndexOf('=')
        if ($idx -lt 1) { continue }

        $key = $trimmed.Substring(0, $idx).Trim()
        $value = $trimmed.Substring($idx + 1).Trim()
        if ([string]::IsNullOrWhiteSpace($key)) { continue }

        # Strip surrounding quotes.
        if ($value.Length -ge 2 -and (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'")))) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        # Do not overwrite real environment variables.
        $existing = [Environment]::GetEnvironmentVariable($key)
        if ([string]::IsNullOrEmpty($existing)) {
            [Environment]::SetEnvironmentVariable($key, $value)
        }
    }
}
function Expand-PathValue {
    param([string]$Path)

    $p = $Path.Trim().Trim('"')
    if ($p -eq '~') { return $env:USERPROFILE }
    if ($p.StartsWith('~\') -or $p.StartsWith('~/')) {
        $p = Join-Path $env:USERPROFILE $p.Substring(2)
    }

    # Registry values often use forward slashes (for example d:/steam/steam.exe).
    if ($p -match '^[a-zA-Z]:[/\\]') { $p = $p -replace '/', '\' }

    return [Environment]::ExpandEnvironmentVariables($p)
}

function Test-UrlTarget {
    param([string]$Target)

    if ([string]::IsNullOrWhiteSpace($Target)) { return $false }
    $t = $Target.Trim()

    # A Windows drive path such as D:\Games is not a URI.
    if ($t -match '^[a-zA-Z]:[\\/]') { return $false }
    if ($t -match '^[a-zA-Z][a-zA-Z0-9+.-]*:') { return $true }
    return $false
}

function Remove-Emoji {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) { return $Text }

    $clean = $Text
    # Surrogate pairs cover every non-BMP character, which includes most emoji.
    # WScript shortcut COM cannot save names containing these code points.
    $clean = $clean -replace '[\uD800-\uDFFF]', ''
    # Variation selectors, zero-width joiner, and the combining keycap mark.
    $clean = $clean -replace '[\u200D\u20E3\uFE0E\uFE0F]', ''
    # BMP emoji blocks: misc symbols, dingbats, and misc symbols and arrows.
    $clean = $clean -replace '[\u2600-\u27BF\u2B00-\u2BFF]', ''
    $clean = $clean -replace '\s{2,}', ' '
    return $clean.Trim()
}

function Get-SafeFileName {
    param(
        [string]$Name,
        [string]$Fallback = 'Game'
    )

    $safe = Remove-Emoji ([string]$Name)
    if ([string]::IsNullOrWhiteSpace($safe)) { $safe = $Fallback }

    $safe = $safe -replace '[<>:"/\\|?*]', ''
    $safe = $safe -replace '[\x00-\x1F]', ''
    $safe = $safe -replace '\s+', ' '
    $safe = $safe.Trim().TrimEnd('.')

    if (!$safe) { $safe = $Fallback }
    if ($safe -match '(?i)^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$') { $safe = '_' + $safe }
    if ($safe.Length -gt 120) { $safe = $safe.Substring(0, 120).Trim().TrimEnd('.') }

    return $safe
}

function ConvertTo-HashtableDeep {
    param($Value)

    if ($null -eq $Value) { return $null }

    if ($Value -is [System.Collections.IDictionary]) {
        $h = @{}
        foreach ($k in $Value.Keys) { $h[[string]$k] = ConvertTo-HashtableDeep $Value[$k] }
        return $h
    }

    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        $h = @{}
        foreach ($p in $Value.PSObject.Properties) { $h[$p.Name] = ConvertTo-HashtableDeep $p.Value }
        return $h
    }

    if ($Value -is [System.Collections.IEnumerable] -and !($Value -is [string])) {
        return @($Value | ForEach-Object { ConvertTo-HashtableDeep $_ })
    }

    return $Value
}

function Merge-Hashtable {
    param(
        [hashtable]$Base,
        [hashtable]$Override
    )

    $result = @{}
    foreach ($k in $Base.Keys) { $result[$k] = $Base[$k] }

    foreach ($k in $Override.Keys) {
        $existing = $result[$k]
        $incoming = $Override[$k]
        if ($existing -is [hashtable] -and $incoming -is [hashtable]) {
            $result[$k] = Merge-Hashtable -Base $existing -Override $incoming
        } else {
            $result[$k] = $incoming
        }
    }

    return $result
}

function Get-DefaultConfig {
    return @{
        libraryRoot        = 'D:\Games'
        createHtmlIndex    = $true
        createFolderIcons  = $true
        removeStaleShortcuts = $true
        providers          = @{
            steam           = $true
            epic            = $true
            gog             = $true
            itch            = $true
            amazon          = $true
            legacyGames     = $true
            ea              = $true
            ubisoft         = $true
            battleNet       = $true
            rockstar        = $true
            riot            = $true
            wargaming       = $true
            hiRez           = $true
            xbox            = $true
            standalone      = $true
            customLaunchers = $true
            emulators       = $true
        }
        scan               = @{
            extraGameRoots         = @()
            standaloneSearchRoots  = @(
                '%ProgramFiles%',
                '%ProgramFiles(x86)%',
                '%LOCALAPPDATA%\Programs'
            )
            standaloneDepth        = 4
            deepDriveScan          = $false
            romRoots               = @()
            romDepth               = 5
            emulatorRoots          = @()
        }
        customEntries      = @()
        customLaunchers    = @()
        customLaunchMethods = @()
        gameOverrides     = @()
        artwork           = @{
            enabled        = $true
            preferStoreArt = $true
            writeIcoIcons  = $false
            cacheDir       = '_library\artwork'
            requestTimeoutSeconds = 15
        }
        metadata          = @{
            enabled = $true
            providers = @{
                steamStore  = @{ enabled = $true }
                steamGridDb = @{ enabled = $false; apiKey = '{secret:steamgriddb}' }
                igdb        = @{ enabled = $false; clientId = '{secret:igdbClientId}'; clientSecret = '{secret:igdbClientSecret}' }
                vndb        = @{ enabled = $false }
            }
        }
    }
}

function Get-GamesLibraryConfig {
    param([string]$ConfigPath)

    $defaults = Get-DefaultConfig
    if (!$ConfigPath) { return $defaults }
    if (!(Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
        Write-Log "Config file not found: $ConfigPath. Using defaults." -Level Warn
        return $defaults
    }

    try {
        $raw = Get-Content -LiteralPath $ConfigPath -Raw -ErrorAction Stop
        $userObject = $raw | ConvertFrom-Json -ErrorAction Stop
        $userHash = ConvertTo-HashtableDeep $userObject
        return Merge-Hashtable -Base $defaults -Override $userHash
    } catch {
        Write-Log "Could not read config '$ConfigPath': $($_.Exception.Message). Using defaults." -Level Warn
        return $defaults
    }
}

function ConvertTo-Array {
    param($Value)

    if ($null -eq $Value) { return }

    # Windows PowerShell 5.1 cannot apply @() directly to List[object].
    if ($Value -is [System.Collections.Generic.List[object]]) {
        return $Value.ToArray()
    }

    return @($Value)
}

function New-GameEntry {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Provider,
        [Parameter(Mandatory = $true)][string]$ProviderKey,
        [string]$Kind = 'StoreGame',
        [Parameter(Mandatory = $true)][string]$Target,
        [string]$Arguments = '',
        [string]$WorkingDirectory = '',
        [string]$IconPath = '',
        [string]$InstallDir = '',
        [string]$Id = '',
        [string]$Source = '',
        [string]$Description = '',
        [string]$CoverPath = '',
        [string]$CoverUrl = '',
        [string]$HeroPath = '',
        $LaunchMethods = @()
    )

    $entryName = Get-NormalizedGameTitle -Title $Name -Source $Source -Id $Id -InstallDir $InstallDir
    if ([string]::IsNullOrWhiteSpace($entryName)) { $entryName = Remove-Emoji $Name }
    if ([string]::IsNullOrWhiteSpace($entryName)) { $entryName = [string]$Name }

    $target = $Target.Trim()
    $isUrl = Test-UrlTarget $target

    $icon = $IconPath
    if (!$icon -and !$isUrl -and (Test-Path -LiteralPath $target -PathType Leaf -ErrorAction SilentlyContinue)) {
        $icon = $target
    }

    if (!$WorkingDirectory -and !$isUrl) {
        if (Test-Path -LiteralPath $target -PathType Leaf -ErrorAction SilentlyContinue) {
            $WorkingDirectory = Split-Path -Parent $target
        }
    }

    if (!$Description) { $Description = '{0} ({1})' -f $entryName, $Provider }

    return [pscustomobject]@{
        Name             = [string]$entryName
        Provider         = [string]$Provider
        ProviderKey      = [string]$ProviderKey
        Kind             = [string]$Kind
        Target           = [string]$target
        Arguments        = [string]$Arguments
        WorkingDirectory = [string]$WorkingDirectory
        IconPath         = [string]$icon
        InstallDir       = [string]$InstallDir
        Id               = [string]$Id
        Source           = [string]$Source
        Description      = [string]$Description
        IsUrl            = [bool]$isUrl
        CoverPath        = [string]$CoverPath
        CoverUrl         = [string]$CoverUrl
        HeroPath         = [string]$HeroPath
        LaunchMethods    = @($LaunchMethods)
    }
}

function New-ProviderResult {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$DisplayName,
        $Launcher = $null,
        $Games = @(),
        [string]$IconPath = ''
    )

    return [pscustomobject]@{
        Key         = $Key
        DisplayName = $DisplayName
        Launcher    = $Launcher
        Games       = @(ConvertTo-Array $Games)
        IconPath    = $IconPath
    }
}

function ConvertTo-ProviderKey {
    param([string]$Name)
    if (!$Name) { return 'custom' }
    return ($Name.ToLowerInvariant() -replace '[^a-z0-9]', '')
}

function ConvertTo-HtmlText {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    return $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

function ConvertTo-FileUri {
    param([string]$Path)
    $full = [IO.Path]::GetFullPath($Path) -replace '\\', '/'
    return 'file:///' + [Uri]::EscapeUriString($full)
}
