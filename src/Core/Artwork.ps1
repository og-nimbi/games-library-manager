# Artwork cache: store-first resolution, local caching, and download helpers.

function Get-ArtworkCacheRoot {
    param([string]$Root)
    return (Join-Path $Root '_library\artwork')
}

function Get-ArtworkIndexPath {
    param([string]$Root)
    return (Join-Path (Get-ArtworkCacheRoot -Root $Root) 'index.json')
}

function Read-ArtworkIndex {
    param([string]$Root)

    $path = Get-ArtworkIndexPath -Root $Root
    if (!(Test-Path -LiteralPath $path -PathType Leaf -ErrorAction SilentlyContinue)) { return @{} }

    try {
        $raw = Get-Content -LiteralPath $path -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) { return @{} }
        $obj = $raw | ConvertFrom-Json -ErrorAction Stop
        $table = @{}
        foreach ($prop in $obj.PSObject.Properties) { $table[[string]$prop.Name] = $prop.Value }
        return $table
    } catch {
        Write-Log "Could not read artwork index: $($_.Exception.Message)" -Level Warn
        return @{}
    }
}

function Write-ArtworkIndex {
    param(
        [string]$Root,
        [hashtable]$Index
    )

    $dir = Get-ArtworkCacheRoot -Root $Root
    if (!(Test-Path -LiteralPath $dir -PathType Container -ErrorAction SilentlyContinue)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $path = Get-ArtworkIndexPath -Root $Root
    $Index | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $path -Encoding UTF8 -Force
}

function Get-ArtworkExtension {
    param([string]$Source)

    if ([string]::IsNullOrWhiteSpace($Source)) { return '.jpg' }
    $ext = [IO.Path]::GetExtension($Source)
    if ([string]::IsNullOrWhiteSpace($ext)) { return '.jpg' }
    $ext = $ext.ToLowerInvariant()
    if ($ext -notin @('.jpg', '.jpeg', '.png', '.gif', '.webp')) { return '.jpg' }
    if ($ext -eq '.jpeg') { $ext = '.jpg' }
    return $ext
}

function Get-SteamRoots {
    $roots = @()
    foreach ($drive in @(Get-AllFixedDriveRoots)) {
        $roots += (Join-Path $drive 'steam')
        $roots += (Join-Path $drive 'Steam')
        $roots += (Join-Path $drive 'Program Files (x86)\Steam')
        $roots += (Join-Path $drive 'Program Files\Steam')
    }
    $roots += '%ProgramFiles(x86)%\Steam'
    $roots += '%ProgramFiles%\Steam'
    $result = New-Object System.Collections.Generic.List[string]
    foreach ($root in $roots) {
        $expanded = Expand-PathValue $root
        if ($expanded -and (Test-Path -LiteralPath $expanded -PathType Container -ErrorAction SilentlyContinue)) {
            if (!($result -contains $expanded)) { $result.Add($expanded) }
        }
    }
    return @(ConvertTo-Array $result)
}

function Resolve-SteamArtSource {
    param([string]$AppId)

    if ([string]::IsNullOrWhiteSpace($AppId)) { return $null }

    foreach ($steamRoot in @(Get-SteamRoots)) {
        $cacheDir = Join-Path $steamRoot 'appcache\librarycache'
        $appDir = Join-Path $cacheDir $AppId
        if (!(Test-Path -LiteralPath $appDir -PathType Container -ErrorAction SilentlyContinue)) { continue }

        foreach ($name in @('library_600x900.jpg', 'header.jpg', 'capsule_616x353.jpg')) {
            $candidate = Join-Path $appDir $name
            if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) { return $candidate }
        }
    }

    return $null
}

function Copy-ArtworkFromLocal {
    param(
        [string]$Root,
        [string]$Provider,
        [string]$Id,
        [string]$SourcePath
    )

    if ([string]::IsNullOrWhiteSpace($SourcePath) -or !(Test-Path -LiteralPath $SourcePath -PathType Leaf -ErrorAction SilentlyContinue)) { return $null }

    $ext = Get-ArtworkExtension -Source $SourcePath
    $safeId = ($Id -replace '[^a-zA-Z0-9._-]', '_')
    if ([string]::IsNullOrWhiteSpace($safeId)) { $safeId = 'unknown' }

    $relativeDir = Join-Path '_library' (Join-Path 'artwork' $Provider)
    $relativeFile = Join-Path $relativeDir ($safeId + $ext)
    $fullDir = Join-Path $Root $relativeDir
    $fullFile = Join-Path $Root $relativeFile

    if (!(Test-Path -LiteralPath $fullDir -PathType Container -ErrorAction SilentlyContinue)) {
        New-Item -ItemType Directory -Path $fullDir -Force | Out-Null
    }

    if (!(Test-Path -LiteralPath $fullFile -PathType Leaf -ErrorAction SilentlyContinue)) {
        try { Copy-Item -LiteralPath $SourcePath -Destination $fullFile -Force -ErrorAction Stop } catch {
            Write-Log "Could not cache artwork from '$SourcePath': $($_.Exception.Message)" -Level Warn
            return $null
        }
    }

    return $relativeFile
}

function Fetch-ArtworkFromUrl {
    param(
        [string]$Root,
        [string]$Provider,
        [string]$Id,
        [string]$Url,
        [int]$TimeoutSeconds = 15
    )

    if ([string]::IsNullOrWhiteSpace($Url)) { return $null }

    $ext = Get-ArtworkExtension -Source $Url
    $safeId = ($Id -replace '[^a-zA-Z0-9._-]', '_')
    if ([string]::IsNullOrWhiteSpace($safeId)) { $safeId = 'unknown' }

    $relativeDir = Join-Path '_library' (Join-Path 'artwork' $Provider)
    $relativeFile = Join-Path $relativeDir ($safeId + $ext)
    $fullDir = Join-Path $Root $relativeDir
    $fullFile = Join-Path $Root $relativeFile

    if (Test-Path -LiteralPath $fullFile -PathType Leaf -ErrorAction SilentlyContinue) {
        return $relativeFile
    }

    if (!(Test-Path -LiteralPath $fullDir -PathType Container -ErrorAction SilentlyContinue)) {
        New-Item -ItemType Directory -Path $fullDir -Force | Out-Null
    }

    $tempFile = $fullFile + '.tmp'
    try {
        $client = New-Object System.Net.WebClient
        $client.Headers.Add('User-Agent', 'GamesLibraryManager/1.0')
        # System.Net.WebClient has no per-request timeout; use a background job
        # is overkill. Rely on the OS default and guard with a try/catch.
        $client.DownloadFile($Url, $tempFile)

        if (!(Test-Path -LiteralPath $tempFile -PathType Leaf -ErrorAction SilentlyContinue)) { throw 'download produced no file' }
        if ((Get-Item -LiteralPath $tempFile).Length -lt 64) { throw 'downloaded file is too small' }

        Move-Item -LiteralPath $tempFile -Destination $fullFile -Force -ErrorAction Stop
        return $relativeFile
    } catch {
        Write-Log "Could not fetch artwork from '$Url': $($_.Exception.Message)" -Level Debug
        if (Test-Path -LiteralPath $tempFile -ErrorAction SilentlyContinue) {
            Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
        }
        return $null
    } finally {
        if ($client) { $client.Dispose() }
    }
}

function Resolve-GameArtwork {
    param(
        [string]$Root,
        [Parameter(Mandatory = $true)]$Game,
        [string]$SteamRoot = '',
        $Config = $null
    )

    if ($Game.CoverPath) { return $Game.CoverPath }

    $provider = [string]$Game.Provider
    $providerKey = [string]$Game.ProviderKey
    $id = [string]$Game.Id

    # Steam: use the locally cached header image.
    if ($providerKey -eq 'steam' -or $provider -ieq 'Steam') {
        if (![string]::IsNullOrWhiteSpace($id)) {
            $source = Resolve-SteamArtSource -AppId $id
            if ($source) {
                $relative = Copy-ArtworkFromLocal -Root $Root -Provider 'steam' -Id $id -SourcePath $source
                if ($relative) { $Game.CoverPath = $relative; return $relative }
            }
        }
    }

    # itch.io: download the store cover URL.
    if ($providerKey -eq 'itch' -or $provider -ieq 'itch.io') {
        $url = [string]$Game.CoverUrl
        if (![string]::IsNullOrWhiteSpace($url)) {
            if ([string]::IsNullOrWhiteSpace($id)) { $id = [string]$Game.Name }
            $relative = Fetch-ArtworkFromUrl -Root $Root -Provider 'itch' -Id $id -Url $url
            if ($relative) { $Game.CoverPath = $relative; return $relative }
        }
    }

    # Metadata providers (remote) as a fallback.
    if ($Config) {
        try {
            $relative = Resolve-MetadataArtwork -Root $Root -Game $Game -Config $Config
            if ($relative) { return $relative }
        } catch {
            Write-Log "Metadata: error for '$($Game.Name)': $($_.Exception.Message)" -Level Debug
        }
    }

    return $null
}

