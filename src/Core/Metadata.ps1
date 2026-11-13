# Metadata providers: remote artwork/metadata with caching, rate limiting, and
# negative caching. Store art (Artwork.ps1) always takes priority.

$script:MetadataLastRequest = @{}

function Get-MetadataConfig {
    param($Config)
    $m = Get-PropertyValue $Config 'metadata'
    if ($null -eq $m) { $m = @{} }
    return $m
}

function Test-MetadataEnabled {
    param($Config)
    $m = Get-MetadataConfig -Config $Config
    $enabled = Get-PropertyValue $m 'enabled'
    if ($null -eq $enabled) { return $true }
    return [bool]$enabled
}

function Get-MetadataProviderEnabled {
    param($Config, [string]$Name)
    $m = Get-MetadataConfig -Config $Config
    $providers = Get-PropertyValue $m 'providers'
    if ($null -eq $providers) { return $true }
    $p = Get-PropertyValue $providers $Name
    if ($null -eq $p) { return $true }
    $e = Get-PropertyValue $p 'enabled'
    if ($null -eq $e) { return $true }
    return [bool]$e
}

function Get-MetadataCredential {
    param($Config, [string]$Provider, [string]$Field)
    $m = Get-MetadataConfig -Config $Config
    $providers = Get-PropertyValue $m 'providers'
    if ($null -eq $providers) { return $null }
    $p = Get-PropertyValue $providers $Provider
    if ($null -eq $p) { return $null }
    $v = [string](Get-PropertyValue $p $Field)
    return (Resolve-SecretValue $v)
}

function Invoke-MetadataThrottle {
    param([string]$HostName, [int]$MinDelayMs = 250)

    $now = [DateTime]::UtcNow
    if ($script:MetadataLastRequest.ContainsKey($HostName)) {
        $last = $script:MetadataLastRequest[$HostName]
        $elapsed = ($now - $last).TotalMilliseconds
        if ($elapsed -lt $MinDelayMs) {
            Start-Sleep -Milliseconds ([int]($MinDelayMs - $elapsed))
        }
    }
    $script:MetadataLastRequest[$HostName] = [DateTime]::UtcNow
}

function Get-SteamStoreArtUrl {
    param([string]$AppId)

    if ([string]::IsNullOrWhiteSpace($AppId)) { return $null }

    Invoke-MetadataThrottle -HostName 'store.steampowered.com' -MinDelayMs 300

    $url = 'https://store.steampowered.com/api/appdetails?appids=' + $AppId + '&filters=basic'
    try {
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        $json = $resp.Content | ConvertFrom-Json -ErrorAction Stop
        $prop = $json.PSObject.Properties | Where-Object { $_.Name -eq $AppId } | Select-Object -First 1
        if (!$prop) { return $null }
        $data = $prop.Value
        if (!$data.success) { return $null }
        $d = $data.data
        if ($d.header_image) { return [string]$d.header_image }
        if ($d.capsule_image) { return [string]$d.capsule_image }
    } catch {
        Write-Log "Steam store lookup failed for $AppId`: $($_.Exception.Message)" -Level Debug
    }

    return $null
}

function Get-SteamGridDbArtUrl {
    param(
        $Config,
        [string]$AppId,
        [string]$Type = 'grids'
    )

    $key = Get-MetadataCredential -Config $Config -Provider 'steamGridDb' -Field 'apiKey'
    if ([string]::IsNullOrWhiteSpace($key)) { return $null }
    if ([string]::IsNullOrWhiteSpace($AppId)) { return $null }

    Invoke-MetadataThrottle -HostName 'api.steamgriddb.com' -MinDelayMs 400

    $url = 'https://www.steamgriddb.com/api/v2/' + $Type + '/steam/' + $AppId
    try {
        $headers = @{ 'Authorization' = 'Bearer ' + $key }
        $resp = Invoke-WebRequest -Uri $url -Headers $headers -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        $json = $resp.Content | ConvertFrom-Json -ErrorAction Stop
        if ($json.success -and $json.data -and $json.data.Count -gt 0) {
            # Prefer the first 600x900 grid if available.
            foreach ($item in $json.data) {
                if ($item.url) { return [string]$item.url }
            }
        }
    } catch {
        Write-Log "SteamGridDB lookup failed for $AppId`: $($_.Exception.Message)" -Level Debug
    }

    return $null
}

function Get-IgdbAccessToken {
    param($Config)

    $clientId = Get-MetadataCredential -Config $Config -Provider 'igdb' -Field 'clientId'
    $secret = Get-MetadataCredential -Config $Config -Provider 'igdb' -Field 'clientSecret'
    if ([string]::IsNullOrWhiteSpace($clientId) -or [string]::IsNullOrWhiteSpace($secret)) { return $null }

    $cachePath = Join-Path $env:LOCALAPPDATA 'GamesLibraryManager\igdb-token.dat'
    if (Test-Path -LiteralPath $cachePath -PathType Leaf -ErrorAction SilentlyContinue) {
        try {
            $cached = Get-Content -LiteralPath $cachePath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            $expires = [DateTime]::Parse($cached.expires)
            if ($expires -gt [DateTime]::UtcNow.AddMinutes(5)) {
                return @{ ClientId = $clientId; Token = [string]$cached.token }
            }
        } catch { }
    }

    Invoke-MetadataThrottle -HostName 'id.twitch.tv' -MinDelayMs 0

    $tokenUrl = 'https://id.twitch.tv/oauth2/token?client_id=' + $clientId + '&client_secret=' + $secret + '&grant_type=client_credentials'
    try {
        $resp = Invoke-WebRequest -Uri $tokenUrl -Method Post -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        $json = $resp.Content | ConvertFrom-Json -ErrorAction Stop
        $token = [string]$json.access_token
        $expiresIn = [int]$json.expires_in
        if ($token) {
            $expires = [DateTime]::UtcNow.AddSeconds($expiresIn)
            @{ clientId = $clientId; token = $token; expires = $expires.ToString('o') } | ConvertTo-Json | Set-Content -LiteralPath $cachePath -Encoding UTF8 -Force
            return @{ ClientId = $clientId; Token = $token }
        }
    } catch {
        Write-Log "IGDB auth failed: $($_.Exception.Message)" -Level Debug
    }

    return $null
}

function Get-IgdbArtUrl {
    param(
        $Config,
        [string]$Title
    )

    if ([string]::IsNullOrWhiteSpace($Title)) { return $null }
    $auth = Get-IgdbAccessToken -Config $Config
    if ($null -eq $auth) { return $null }

    Invoke-MetadataThrottle -HostName 'api.igdb.com' -MinDelayMs 300

    $clientId = $auth.ClientId
    $token = $auth.Token

    $body = 'search "' + ($Title -replace '"', '') + '"; fields cover.url; limit 1;'
    try {
        $headers = @{
            'Client-ID'     = $clientId
            'Authorization' = 'Bearer ' + $token
        }
        $resp = Invoke-WebRequest -Uri 'https://api.igdb.com/v4/games' -Method Post -Headers $headers -Body $body -ContentType 'text/plain' -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        $json = $resp.Content | ConvertFrom-Json -ErrorAction Stop
        if ($json -and $json.Count -gt 0 -and $json[0].cover -and $json[0].cover.url) {
            $url = [string]$json[0].cover.url
            # IGDB returns //images.igdb.com/... ; make it https.
            if ($url.StartsWith('//')) { $url = 'https:' + $url }
            # Request a larger size.
            $url = $url -replace 't_thumb', 't_cover_big'
            return $url
        }
    } catch {
        Write-Log "IGDB lookup failed for '$Title': $($_.Exception.Message)" -Level Debug
    }

    return $null
}

function Get-VndbArtUrl {
    param([string]$Title)

    if ([string]::IsNullOrWhiteSpace($Title)) { return $null }

    Invoke-MetadataThrottle -HostName 'api.vndb.org' -MinDelayMs 400

    $body = @{ filters = @('search', '=', $Title); fields = 'image.url'; results = 1 } | ConvertTo-Json -Depth 4
    try {
        $resp = Invoke-WebRequest -Uri 'https://api.vndb.org/kana/vn' -Method Post -Body $body -ContentType 'application/json' -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        $json = $resp.Content | ConvertFrom-Json -ErrorAction Stop
        if ($json.results -and $json.results.Count -gt 0) {
            $r = $json.results[0]
            if ($r.image -and $r.image.url) { return [string]$r.image.url }
        }
    } catch {
        Write-Log "VNDB lookup failed for '$Title': $($_.Exception.Message)" -Level Debug
    }

    return $null
}

function Resolve-MetadataArtwork {
    # Returns a cached relative path or $null. Tries providers in priority order.
    param(
        [string]$Root,
        [Parameter(Mandatory = $true)]$Game,
        $Config
    )

    if ($Game.CoverPath) { return $Game.CoverPath }

    if (!(Test-MetadataEnabled -Config $Config)) { return $null }

    $title = [string]$Game.Name
    $providerKey = [string]$Game.ProviderKey
    $id = [string]$Game.Id

    # Negative cache: skip if previously recorded as a miss.
    $index = Read-ArtworkIndex -Root $Root
    $cacheKey = 'meta|' + $providerKey + '|' + $id + '|' + $title
    if ($index.ContainsKey($cacheKey) -and $index[$cacheKey].miss) {
        return $null
    }

    $url = $null
    $source = $null

    # Steam store (keyless) for Steam games.
    if (($providerKey -eq 'steam' -or $Game.Provider -ieq 'Steam') -and (Get-MetadataProviderEnabled -Config $Config -Name 'steamStore')) {
        $url = Get-SteamStoreArtUrl -AppId $id
        if ($url) { $source = 'steam-store' }
    }

    # SteamGridDB (keyed) for Steam games.
    if ([string]::IsNullOrWhiteSpace($url) -and ($providerKey -eq 'steam' -or $Game.Provider -ieq 'Steam') -and (Get-MetadataProviderEnabled -Config $Config -Name 'steamGridDb')) {
        $url = Get-SteamGridDbArtUrl -Config $Config -AppId $id -Type 'grids'
        if ($url) { $source = 'steamgriddb' }
    }

    # IGDB (keyed) for any game.
    if ([string]::IsNullOrWhiteSpace($url) -and (Get-MetadataProviderEnabled -Config $Config -Name 'igdb')) {
        $url = Get-IgdbArtUrl -Config $Config -Title $title
        if ($url) { $source = 'igdb' }
    }

    # VNDB (keyless) for visual novels.
    if ([string]::IsNullOrWhiteSpace($url) -and (Get-MetadataProviderEnabled -Config $Config -Name 'vndb')) {
        $url = Get-VndbArtUrl -Title $title
        if ($url) { $source = 'vndb' }
    }

    if ([string]::IsNullOrWhiteSpace($url)) {
        # Record negative cache.
        $index[$cacheKey] = @{ miss = $true; checkedAt = (Get-Date).ToString('o') }
        try { Write-ArtworkIndex -Root $Root -Index $index } catch { }
        return $null
    }

    $relative = Fetch-ArtworkFromUrl -Root $Root -Provider 'metadata' -Id ($providerKey + '_' + $id) -Url $url
    if ($relative) {
        $Game.CoverPath = $relative
        $index[$cacheKey] = @{ miss = $false; source = $source; file = $relative; fetchedAt = (Get-Date).ToString('o') }
        try { Write-ArtworkIndex -Root $Root -Index $index } catch { }
        Write-Log "Metadata: resolved art for '$title' via $source." -Level Debug
        return $relative
    }

    return $null
}
