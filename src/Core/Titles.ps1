# Game title normalization: common metadata regex plus curated manual overrides.

function Get-CuratedTitleOverride {
    param(
        [string]$Title,
        [string]$Source = '',
        [string]$Id = '',
        [string]$InstallDir = ''
    )

    # Titles that must stay exactly as published. The general regex below would
    # otherwise treat descriptive words such as "A free to play Visual Novel"
    # as removable metadata.
    $preserved = @{
        'steam-appmanifest|1577420' = 'Love Sucks: Night One'
        'steam-appmanifest|1719310' = 'Love Sucks: Night Two'
        'steam-appmanifest|421670'  = 'CUPID - A free to play Visual Novel'
    }

    if ($Source -and $Id) {
        $key = ('{0}|{1}' -f $Source.ToLowerInvariant(), $Id)
        if ($preserved.ContainsKey($key)) { return $preserved[$key] }
    }

    # Exact-title fallbacks keep the same games safe if their source or id is
    # unavailable (for example a manually registered install).
    foreach ($exact in $preserved.Values) {
        if ($Title -ieq $exact) { return $exact }
    }

    $folder = ''
    if ($InstallDir) {
        try { $folder = Split-Path -Leaf ([IO.Path]::GetFullPath($InstallDir)) } catch { $folder = '' }
    }

    # itch.io: Relicts of Aeson (id 1185708). The receipt title is a marketing
    # block: "[18+, NO AI ART!] Relicts of Aeson v0.28.1, Oct. 2026. Over 600 animations!"
    if ($Source -ieq 'itch-app' -and $Id -eq '1185708') { return 'Relicts of Aeson' }
    if ($folder -ieq 'relicts-auf-aeson') { return 'Relicts of Aeson' }
    if ($Title -match '(?i)^\s*\[[^\]]*\]\s*Relicts of Aeson\b') { return 'Relicts of Aeson' }

    return $null
}

function Get-NormalizedGameTitle {
    param(
        [string]$Title,
        [string]$Source = '',
        [string]$Id = '',
        [string]$InstallDir = ''
    )

    if ([string]::IsNullOrWhiteSpace($Title)) { return $Title }

    $override = Get-CuratedTitleOverride -Title $Title -Source $Source -Id $Id -InstallDir $InstallDir
    if ($override) { return $override }

    $t = $Title.Trim()

    # Some storefront titles use a locale-specific accent or curly quote where a
    # plain apostrophe belongs (for example itch.io's "Sarada´s Rise"). Windows
    # accepts any of them, but the ASCII apostrophe is the conventional form.
    $t = $t -replace "[\u00B4\u2018\u2019\u02BC]", "'"

    # Remove leading metadata tags such as [18+, NO AI ART!], [Demo], or [v1.2].
    $tagPattern = '^\s*\[([^\]]*)\]\s*'
    while ($t -match $tagPattern) {
        $tag = $Matches[0]
        $tagText = $Matches[1]
        if ($tagText -notmatch '(?i)(18\+|nsfw|adult|uncensored|no\s+ai|ai\s+art|free|demo|patreon|early\s+access|release|version|update|repack|^v?\d)') { break }
        $t = $t.Substring($tag.Length)
    }

    # Version and build markers (v0.28.1, v0281, Version 1.2, Build 1234).
    # A bare "V3" is part of some real titles (for example Danganronpa V3), so
    # only strip single-letter markers that carry a dot or a long build number.
    $t = $t -replace '(?i)\bv\.\d+(?:\.\d+)*[a-z]?\b', ' '
    $t = $t -replace '(?i)\bv\d{3,}[a-z]?\b', ' '
    $t = $t -replace '(?i)\b(ver|version)\.?\s*\d+(?:\.\d+)*[a-z]?\b', ' '
    $t = $t -replace '(?i)\b(build|rev|revision)\s*\d+\b', ' '

    # Release dates such as ", Oct. 2026." Plain years are left alone because
    # titles such as "Cyberpunk 2077" and "Battlefield 2042" are legitimate.
    $t = $t -replace '(?i)[,;]?\s*\b(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?\s+(19|20)\d{2}\b\.?', ' '

    # Marketing noise that developers append to itch.io titles.
    $t = $t -replace '(?i)\bover\s+\d+\s+(?:animations?|images?|scenes?|hours?)\b!?', ' '
    $t = $t -replace '(?i)\b\d+\+?\s+(?:animations?|images?|scenes?)\b!?', ' '
    $t = $t -replace '(?i)\b(?:windows\s+)?free\s+version\b', ' '
    $t = $t -replace '(?i)\b(?:full|final|complete)\s+(?:game|version|release)\b', ' '
    $t = $t -replace '(?i)\s*[-:]\s*a\s+free[- ]to[- ]play\s+(?:visual\s+novel|game)\s*$', ' '
    $t = $t -replace '(?i)\s*[-:]\s*(?:early\s+access|uncensored\s+patch|repack)\s*$', ' '

    # Parenthetical or bracketed metadata groups, for example "(NSFW 18+)".
    $t = $t -replace '(?i)\s*[\(\[]([^\)\]]*(?:18\+|nsfw|adult|uncensored|patched|repack|update|version|windows|free|demo|early\s+access|patreon|release)[^\)\]]*)[\)\]]', ' '

    # Tidy whitespace and the separators left behind by removed segments.
    # Trailing hyphens are kept because some published titles really end in one
    # (for example "LoveKami -Divinity Stage-"); metadata suffixes were already
    # removed by the targeted rules above.
    $t = $t -replace '\s*,\s*(?=,|$)', ''
    $t = $t -replace '^\s*[,;:|\-\u2013\u2014]+\s*', ''
    $t = $t -replace '\s*[,;:|]+\s*$', ''
    $t = $t -replace '\s{2,}', ' '
    $t = $t.Trim().TrimEnd('.', ',', ';', ':', '!', '?').Trim()

    if ([string]::IsNullOrWhiteSpace($t)) { $t = $Title.Trim() }

    return (Remove-Emoji $t)
}
