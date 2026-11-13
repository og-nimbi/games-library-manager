# Discovery helpers: registry, installed programs, drives, executables, JSON.

$script:InstalledApplicationsCache = $null
$script:FixedDrivesCache = $null

function Get-AllFixedDriveRoots {
    if ($null -ne $script:FixedDrivesCache) { return $script:FixedDrivesCache }

    $roots = New-Object System.Collections.Generic.List[string]
    try {
        foreach ($drive in [System.IO.DriveInfo]::GetDrives()) {
            if ($drive.IsReady -and $drive.DriveType -eq [System.IO.DriveType]::Fixed) {
                $roots.Add($drive.RootDirectory.FullName)
            }
        }
    } catch {
    }

    $script:FixedDrivesCache = @($roots)
    return $script:FixedDrivesCache
}

function Find-FirstExistingPath {
    param(
        [string[]]$Paths,
        [ValidateSet('Leaf', 'Container', 'Any')][string]$PathType = 'Leaf'
    )

    foreach ($candidate in @($Paths)) {
        if (!$candidate) { continue }
        $expanded = Expand-PathValue $candidate
        if (!$expanded) { continue }

        if ($PathType -eq 'Any') {
            if (Test-Path -LiteralPath $expanded -ErrorAction SilentlyContinue) { return $expanded }
        } elseif (Test-Path -LiteralPath $expanded -PathType $PathType -ErrorAction SilentlyContinue) {
            return $expanded
        }
    }

    return $null
}

function Get-StoreInstallCandidates {
    param([string[]]$RelativePaths)

    $results = New-Object System.Collections.Generic.List[string]
    $bases = New-Object System.Collections.Generic.List[string]

    foreach ($root in (Get-AllFixedDriveRoots)) { $bases.Add($root) }
    foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, (Join-Path $env:LOCALAPPDATA 'Programs'))) {
        if ($base) { $bases.Add($base) }
    }

    foreach ($base in $bases) {
        foreach ($relative in $RelativePaths) {
            if (!$relative) { continue }
            $candidate = Join-Path $base $relative
            if (!($results -contains $candidate)) { $results.Add($candidate) }
        }
    }

    return @($results)
}

function Get-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )

    if (!$Path) { return $null }
    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        $value = $item.GetValue($Name)
        if ($null -ne $value) { return $value }
    } catch {
    }

    return $null
}

function Get-RegistrySubKeys {
    param([string]$Path)

    if (!$Path -or !(Test-Path -LiteralPath $Path -ErrorAction SilentlyContinue)) { return @() }
    return @(Get-ChildItem -LiteralPath $Path -ErrorAction SilentlyContinue)
}

function Get-InstalledApplications {
    if ($null -ne $script:InstalledApplicationsCache) { return $script:InstalledApplicationsCache }

    $uninstallKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $apps = New-Object System.Collections.Generic.List[object]

    foreach ($key in $uninstallKeys) {
        foreach ($item in @(Get-ItemProperty -Path $key -ErrorAction SilentlyContinue)) {
            if (!$item.DisplayName) { continue }

            $installLocation = Expand-PathValue $item.InstallLocation
            $displayIcon = [string]$item.DisplayIcon
            if ($displayIcon) {
                $displayIcon = $displayIcon.Trim()
                if ($displayIcon -match '^"([^"]+)"') {
                    $displayIcon = $Matches[1]
                } elseif ($displayIcon -match '^(.+?\.exe)') {
                    $displayIcon = $Matches[1]
                }
                $displayIcon = Expand-PathValue $displayIcon
            }

            $apps.Add([pscustomobject]@{
                DisplayName     = [string]$item.DisplayName
                Publisher       = [string]$item.Publisher
                InstallLocation = $installLocation
                DisplayIcon     = $displayIcon
                UninstallString = [string]$item.UninstallString
                KeyName         = Split-Path -Leaf $item.PSPath
            })
        }
    }

    $script:InstalledApplicationsCache = @(ConvertTo-Array $apps)
    return $script:InstalledApplicationsCache
}

function Get-PropertyValue {
    param(
        $Object,
        [string]$Name
    )

    if ($null -eq $Object -or !$Name) { return $null }

    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $null
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -ne $property) { return $property.Value }
    return $null
}

function Get-EdgeExecutablePath {
    $candidates = @(
        '%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe',
        '%ProgramFiles%\Microsoft\Edge\Application\msedge.exe'
    )

    $found = Find-FirstExistingPath -Paths $candidates -PathType Leaf
    if ($found) { return $found }

    $command = Get-Command 'msedge.exe' -ErrorAction SilentlyContinue |
        Where-Object { $_.Source -and (Test-Path -LiteralPath $_.Source -PathType Leaf -ErrorAction SilentlyContinue) } |
        Select-Object -First 1
    if ($command) { return $command.Source }

    return $null
}

function Get-ExecutableVersionInfo {
    param([string]$Path)

    if (!$Path) { return $null }

    if ($null -eq $script:ExecutableInfoCache) { $script:ExecutableInfoCache = @{} }
    if ($script:ExecutableInfoCache.ContainsKey($Path)) { return $script:ExecutableInfoCache[$Path] }

    $info = $null
    try { $info = [Diagnostics.FileVersionInfo]::GetVersionInfo($Path) } catch { $info = $null }

    $script:ExecutableInfoCache[$Path] = $info
    return $info
}

function Get-ExecutableBitness {
    param([string]$Path)

    if (!$Path) { return 0 }

    if ($null -eq $script:ExecutableBitnessCache) { $script:ExecutableBitnessCache = @{} }
    if ($script:ExecutableBitnessCache.ContainsKey($Path)) { return $script:ExecutableBitnessCache[$Path] }

    $bits = 0
    $stream = $null
    try {
        $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        $reader = New-Object IO.BinaryReader($stream)
        try {
            if ($reader.ReadUInt16() -eq 0x5A4D -and $stream.Length -gt 0x40) {
                $stream.Position = 0x3C
                $peOffset = $reader.ReadInt32()
                if ($peOffset -gt 0 -and $peOffset -lt ($stream.Length - 6)) {
                    $stream.Position = $peOffset
                    if ($reader.ReadUInt32() -eq 0x00004550) {
                        switch ($reader.ReadUInt16()) {
                            0x014C { $bits = 32 }
                            0x8664 { $bits = 64 }
                            0xAA64 { $bits = 64 }
                        }
                    }
                }
            }
        } finally {
            $reader.Dispose()
        }
    } catch {
        $bits = 0
    } finally {
        if ($stream) { $stream.Dispose() }
    }

    $script:ExecutableBitnessCache[$Path] = $bits
    return $bits
}

function Test-EngineOrRuntimeExecutable {
    param([IO.FileInfo]$File)

    if (!$File) { return $false }

    # Names that are almost always engines, runtimes, installers, crash handlers,
    # or prerequisite installers rather than the playable game.
    $blockedName = '(?i)^(' +
        'unins[^\\]*|uninstall[^\\]*|setup[^\\]*|install(er)?|' +
        'vc_?redist[^\\]*|vcredist[^\\]*|dxsetup[^\\]*|dxwebsetup[^\\]*|directx[^\\]*|' +
        'dotnet[^\\]*|oalinst[^\\]*|openal[^\\]*|physx[^\\]*|cleanup[^\\]*|touchup[^\\]*|' +
        'register|config(uration)?|settings|crash[^\\]*|crashhandler[^\\]*|crashreport[^\\]*|' +
        'report[^\\]*|notification_helper|steamerrorreporter|steam_api[^\\]*|steamservice|' +
        'steamcmd[^\\]*|zsync[^\\]*|chardetect[^\\]*|' +
        'python[0-9.]*(w)?|pyw?|node[^\\]*|nw[^\\]*|electron[^\\]*|javaw?|' +
        'ffmpeg[^\\]*|ffplay[^\\]*|ffprobe[^\\]*|qtwebkit[^\\]*|cef[^\\]*|chrome[^\\]*|msedge[^\\]*|' +
        'unitycrashhandler[^\\]*|unityplayer|server|dedicated[^\\]*|' +
        'ue[45]prereqsetup[^\\]*|epicwebhelper|unrealversionselector|bootstrap(packaged)?game|' +
        'godot[^\\]*_console|' +
        'helper|tool|editor' +
        ')\.exe$'

    if ($File.Name -match $blockedName) { return $true }

    # Engine and runtime folders. The UE game binary itself lives in
    # "<Game>\Binaries\Win64", so that path is deliberately not blocked.
    $relative = $File.FullName
    if ($relative -match '(?i)(^|\\)(engine\\binaries|engine\\extras|_commonredist|commonredist|' +
        'redist|redistributables?|prerequisites|installers?|jre|jvm|node_modules|nwjs|cef|' +
        'python[^\\]*)(\\|$)') {
        return $true
    }

    $version = Get-ExecutableVersionInfo $File.FullName
    if ($version) {
        $identity = ('{0} {1} {2} {3}' -f $version.OriginalFilename, $version.InternalName, $version.ProductName, $version.FileDescription)
        if ($identity -match '(?i)(python interpreter|python\.exe|pythonw\.exe|node\.js|nw\.js|nwjs|' +
            'electron|unity crash handler|crash report client|unreal engine prerequisites|' +
            'epic web helper|unreal version selector|visual c\+\+ redistributable|directx setup)') {
            return $true
        }

        if ($version.CompanyName -match '(?i)^(python software foundation|node\.js|nw\.js|electron)$') {
            return $true
        }
    }

    return $false
}

function Find-GameExecutable {
    param(
        [string]$Directory,
        [int]$Depth = 3,
        [string]$PreferName = ''
    )

    if (!$Directory) { return $null }
    $dir = Expand-PathValue $Directory
    if (!$dir -or !(Test-Path -LiteralPath $dir -PathType Container -ErrorAction SilentlyContinue)) { return $null }

    $exclude = '(?i)(^unins|uninstall|^setup|^install(er)?\.exe$|^vc_?redist|^vcredist|^dxsetup|^dxwebsetup|^directx|^dotnet|^oalinst|^openal|^physx|^cleanup|^touchup|^register|^config(uration)?\.exe$|^settings\.exe$|^crash|crashhandler|crashreport|^helper|^report|^notification_helper|^steamerrorreporter|^steam_api|^steamservice|^python|^pythonw|^py\.exe$|^pyw\.exe$|^node\.exe$|^nw\.exe$|^nwjs\.exe$|^electron\.exe$|^javaw?\.exe$|^ffmpeg|^ffplay|^ffprobe|^qtwebkit|^cef|^chrome|^msedge|^unitycrashhandler|^unityplayer|^server\.exe$|^dedicated|^ue[45]prereqsetup|^epicwebhelper|^unrealversionselector|^bootstrap(packaged)?game|godot[^\\]*_console\.exe$)'

    $files = @()
    try {
        $files = @(
            Get-ChildItem -LiteralPath $dir -Filter '*.exe' -File -Recurse -Depth $Depth -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notmatch $exclude }
        )
    } catch {
        try {
            $files = @(
                Get-ChildItem -LiteralPath $dir -Filter '*.exe' -File -Force -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -notmatch $exclude }
            )
        } catch {
            $files = @()
        }
    }

    $files = @($files | Where-Object { !(Test-EngineOrRuntimeExecutable $_) })
    if ($files.Count -eq 0) { return $null }

    $preferred = ''
    if ($PreferName) {
        $preferred = ($PreferName -replace '[^a-zA-Z0-9]', '').ToLowerInvariant()
    }

    $scored = foreach ($file in $files) {
        $score = 0.0
        $base = $file.BaseName
        $normalized = ($base -replace '[^a-zA-Z0-9]', '').ToLowerInvariant()

        if ($preferred) {
            if ($normalized -eq $preferred) {
                $score += 1000
            } elseif ($normalized.Contains($preferred) -or $preferred.Contains($normalized)) {
                $score += 500
            }
        }

        if ($base -match '(?i)(game|client)') { $score += 200 }
        if ($base -match '(?i)launcher') { $score += 50 }

        # Prefer the actual UE shipping binary over bootstrappers, and 64-bit
        # builds over the alternate 32-bit build when both are installed.
        if ($base -match '(?i)shipping$') { $score += 350 }
        if ($base -match '(?i)(win64|x64|64-?bit)') { $score += 60 }
        if ($base -match '(?i)(win32|x86|32-?bit)') { $score -= 30 }

        $bits = Get-ExecutableBitness $file.FullName
        if ($bits -eq 64) { $score += 80 }
        elseif ($bits -eq 32) { $score -= 40 }

        if ($base -match '(?i)(console|debug|test)$') { $score -= 200 }

        $score -= ($file.FullName.Split([IO.Path]::DirectorySeparatorChar).Count * 5)
        $score += [math]::Min(($file.Length / 1MB), 400)

        [pscustomobject]@{ File = $file; Score = $score }
    }

    return ($scored | Sort-Object Score -Descending | Select-Object -First 1).File.FullName
}

function Read-ItchReceipt {
    param([string]$AppDirectory)

    $receiptPath = Join-Path $AppDirectory '.itch\receipt.json.gz'
    if (!(Test-Path -LiteralPath $receiptPath -PathType Leaf -ErrorAction SilentlyContinue)) { return $null }

    try {
        $stream = [IO.File]::OpenRead($receiptPath)
        try {
            $gzip = New-Object IO.Compression.GZipStream($stream, [IO.Compression.CompressionMode]::Decompress)
            try {
                $reader = New-Object IO.StreamReader($gzip)
                try {
                    $json = $reader.ReadToEnd()
                } finally {
                    $reader.Dispose()
                }
            } finally {
                $gzip.Dispose()
            }
        } finally {
            $stream.Dispose()
        }

        return ($json | ConvertFrom-Json -ErrorAction Stop)
    } catch {
        return $null
    }
}

function Get-JsonFiles {
    param(
        [string]$Directory,
        [int]$Depth = 2,
        [int]$MaxBytes = 1048576
    )

    if (!$Directory -or !(Test-Path -LiteralPath $Directory -PathType Container -ErrorAction SilentlyContinue)) { return @() }

    return @(
        Get-ChildItem -LiteralPath $Directory -Filter '*.json' -File -Recurse -Depth $Depth -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -le $MaxBytes }
    )
}
