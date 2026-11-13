# Emulators: detect major emulators, scan ROM roots, and create ROM shortcuts.
# One provider result is produced per emulator so the library gets a separate
# folder (for example "Dolphin" or "RetroArch") plus a launcher shortcut.

function Get-EmulatorDefinitions {
    return @(
        @{
            Key = 'dolphin'; Name = 'Dolphin'; UninstallPattern = '(?i)^Dolphin'
            ExeNames = @('Dolphin.exe')
            ExePaths = @('%ProgramFiles%\Dolphin\Dolphin.exe', '%ProgramFiles%\Dolphin Emulator\Dolphin.exe', '%ProgramFiles(x86)%\Dolphin\Dolphin.exe')
            Extensions = @('.iso', '.gcm', '.gcz', '.rvz', '.wbfs', '.wad', '.dol', '.elf')
            Hints = @('(?i)(^|\\)(gamecube|gc|wii|nintendo\s*wii)(\\|$)')
            ArgPrefix = '-e'
        },
        @{
            Key = 'cemu'; Name = 'Cemu'; UninstallPattern = '(?i)^Cemu'
            ExeNames = @('Cemu.exe')
            ExePaths = @('%ProgramFiles%\Cemu\Cemu.exe', '%ProgramFiles(x86)%\Cemu\Cemu.exe')
            Extensions = @('.wud', '.wux', '.rpx', '.elf')
            Hints = @('(?i)(^|\\)(wiiu|wii\s*u)(\\|$)')
            ArgPrefix = '-g'
        },
        @{
            Key = 'pcsx2'; Name = 'PCSX2'; UninstallPattern = '(?i)^PCSX2'
            ExeNames = @('pcsx2-qt.exe', 'pcsx2.exe')
            ExePaths = @('%ProgramFiles%\PCSX2\pcsx2-qt.exe', '%ProgramFiles(x86)%\PCSX2\pcsx2-qt.exe')
            Extensions = @('.iso', '.bin', '.cue', '.chd', '.mdf', '.nrg', '.img')
            Hints = @('(?i)(^|\\)(ps2|playstation\s*2)(\\|$)')
        },
        @{
            Key = 'rpcs3'; Name = 'RPCS3'; UninstallPattern = '(?i)^RPCS3'
            ExeNames = @('rpcs3.exe')
            ExePaths = @('%ProgramFiles%\RPCS3\rpcs3.exe', '%ProgramFiles(x86)%\RPCS3\rpcs3.exe')
            Extensions = @('.pkg')
            Hints = @('(?i)(^|\\)(ps3|playstation\s*3)(\\|$)')
        },
        @{
            Key = 'duckstation'; Name = 'DuckStation'; UninstallPattern = '(?i)^DuckStation'
            ExeNames = @('duckstation-qt-x64-ReleaseLTCG.exe', 'duckstation-qt.exe', 'duckstation.exe')
            ExePaths = @(
                '%LOCALAPPDATA%\DuckStation\duckstation-qt-x64-ReleaseLTCG.exe',
                '%ProgramFiles%\DuckStation\duckstation-qt-x64-ReleaseLTCG.exe',
                '%ProgramFiles%\DuckStation\duckstation-qt.exe'
            )
            Extensions = @('.bin', '.cue', '.chd', '.pbp', '.ecm', '.mds', '.mdf', '.img')
            Hints = @('(?i)(^|\\)(ps1|psx|psone|playstation(?!\s*[23]))(\\|$)')
        },
        @{
            Key = 'ppsspp'; Name = 'PPSSPP'; UninstallPattern = '(?i)^PPSSPP'
            ExeNames = @('PPSSPPWindows64.exe', 'PPSSPPWindows.exe', 'PPSSPPQt.exe')
            ExePaths = @('%ProgramFiles%\PPSSPP\PPSSPPWindows64.exe', '%ProgramFiles(x86)%\PPSSPP\PPSSPPWindows.exe')
            Extensions = @('.iso', '.cso', '.chd', '.pbp', '.elf')
            Hints = @('(?i)(^|\\)(psp|playstation\s*portable)(\\|$)')
        },
        @{
            Key = 'melonds'; Name = 'melonDS'; UninstallPattern = '(?i)^melonDS'
            ExeNames = @('melonDS.exe')
            ExePaths = @('%ProgramFiles%\melonDS\melonDS.exe', '%LOCALAPPDATA%\melonDS\melonDS.exe')
            Extensions = @('.nds', '.dsi', '.srl')
            Hints = @('(?i)(^|\\)(nds|nintendo\s*ds|ds)(\\|$)')
        },
        @{
            Key = 'desmume'; Name = 'DeSmuME'; UninstallPattern = '(?i)^DeSmuME'
            ExeNames = @('DeSmuME.exe', 'DeSmuME_x64.exe')
            ExePaths = @('%ProgramFiles%\DeSmuME\DeSmuME.exe', '%ProgramFiles(x86)%\DeSmuME\DeSmuME.exe')
            Extensions = @('.nds', '.dsi')
            Hints = @('(?i)(^|\\)(nds|nintendo\s*ds|ds)(\\|$)')
        },
        @{
            Key = 'citra'; Name = 'Citra'; UninstallPattern = '(?i)^Citra'
            ExeNames = @('citra-qt.exe', 'citra.exe')
            ExePaths = @('%ProgramFiles%\Citra\citra-qt.exe', '%LOCALAPPDATA%\Citra\citra-qt.exe')
            Extensions = @('.3ds', '.cci', '.cxi', '.app', '.cia')
            Hints = @('(?i)(^|\\)(3ds|nintendo\s*3ds)(\\|$)')
        },
        @{
            Key = 'yuzu'; Name = 'yuzu'; UninstallPattern = '(?i)^yuzu'
            ExeNames = @('yuzu.exe')
            ExePaths = @('%APPDATA%\yuzu\yuzu.exe', '%LOCALAPPDATA%\yuzu\yuzu.exe', '%ProgramFiles%\yuzu\yuzu.exe')
            Extensions = @('.nsp', '.xci', '.nca', '.nro')
            Hints = @('(?i)(^|\\)(switch|nintendo\s*switch)(\\|$)')
        },
        @{
            Key = 'ryujinx'; Name = 'Ryujinx'; UninstallPattern = '(?i)^Ryujinx'
            ExeNames = @('Ryujinx.exe', 'Ryujinx.Ava.exe')
            ExePaths = @('%APPDATA%\Ryujinx\Ryujinx.exe', '%LOCALAPPDATA%\Ryujinx\Ryujinx.exe', '%ProgramFiles%\Ryujinx\Ryujinx.exe')
            Extensions = @('.nsp', '.xci', '.nro')
            Hints = @('(?i)(^|\\)(switch|nintendo\s*switch)(\\|$)')
        },
        @{
            Key = 'mgba'; Name = 'mGBA'; UninstallPattern = '(?i)^mGBA'
            ExeNames = @('mGBA.exe')
            ExePaths = @('%ProgramFiles%\mGBA\mGBA.exe', '%ProgramFiles(x86)%\mGBA\mGBA.exe')
            Extensions = @('.gba', '.gb', '.gbc', '.srl')
            Hints = @('(?i)(^|\\)(gba|game\s*boy|gb|gbc)(\\|$)')
        },
        @{
            Key = 'snes9x'; Name = 'Snes9x'; UninstallPattern = '(?i)^Snes9x'
            ExeNames = @('snes9x-x64.exe', 'snes9x.exe')
            ExePaths = @('%ProgramFiles%\Snes9x\snes9x-x64.exe', '%ProgramFiles(x86)%\Snes9x\snes9x.exe')
            Extensions = @('.smc', '.sfc', '.fig', '.swc')
            Hints = @('(?i)(^|\\)(snes|super\s*nintendo)(\\|$)')
        },
        @{
            Key = 'project64'; Name = 'Project64'; UninstallPattern = '(?i)^Project64'
            ExeNames = @('Project64.exe')
            ExePaths = @('%ProgramFiles%\Project64\Project64.exe', '%ProgramFiles(x86)%\Project64\Project64.exe')
            Extensions = @('.n64', '.z64', '.v64', '.rom')
            Hints = @('(?i)(^|\\)(n64|nintendo\s*64)(\\|$)')
        },
        @{
            Key = 'mupen64plus'; Name = 'Mupen64Plus'; UninstallPattern = '(?i)^Mupen64'
            ExeNames = @('mupen64plus.exe', 'mupen64plus-ui-console.exe')
            ExePaths = @('%ProgramFiles%\Mupen64Plus\mupen64plus.exe')
            Extensions = @('.n64', '.z64', '.v64', '.rom')
            Hints = @('(?i)(^|\\)(n64|nintendo\s*64)(\\|$)')
        },
        @{
            Key = 'flycast'; Name = 'Flycast'; UninstallPattern = '(?i)^Flycast'
            ExeNames = @('flycast.exe')
            ExePaths = @('%ProgramFiles%\Flycast\flycast.exe', '%ProgramFiles(x86)%\Flycast\flycast.exe')
            Extensions = @('.gdi', '.cdi', '.chd', '.cue', '.bin')
            Hints = @('(?i)(^|\\)(dreamcast|dc|naomi)(\\|$)')
        },
        @{
            Key = 'redream'; Name = 'redream'; UninstallPattern = '(?i)^redream'
            ExeNames = @('redream.exe')
            ExePaths = @('%ProgramFiles%\redream\redream.exe', '%ProgramFiles(x86)%\redream\redream.exe')
            Extensions = @('.gdi', '.cdi', '.chd', '.cue')
            Hints = @('(?i)(^|\\)(dreamcast|dc)(\\|$)')
        },
        @{
            Key = 'xemu'; Name = 'xemu'; UninstallPattern = '(?i)^xemu'
            ExeNames = @('xemu.exe')
            ExePaths = @('%ProgramFiles%\xemu\xemu.exe', '%ProgramFiles(x86)%\xemu\xemu.exe')
            Extensions = @('.iso', '.xiso')
            Hints = @('(?i)(^|\\)(xbox|xemu)(?!\s*360)(\\|$)')
            ArgPrefix = '-dvd_path'
        },
        @{
            Key = 'xenia'; Name = 'Xenia'; UninstallPattern = '(?i)^Xenia'
            ExeNames = @('xenia.exe', 'xenia_canary.exe')
            ExePaths = @('%ProgramFiles%\Xenia\xenia.exe', '%LOCALAPPDATA%\Xenia\xenia.exe')
            Extensions = @('.iso', '.xex')
            Hints = @('(?i)(^|\\)(xbox\s*360|xbox360|xenia)(\\|$)')
        },
        @{
            Key = 'vita3k'; Name = 'Vita3K'; UninstallPattern = '(?i)^Vita3K'
            ExeNames = @('Vita3K.exe')
            ExePaths = @('%ProgramFiles%\Vita3K\Vita3K.exe', '%APPDATA%\Vita3K\Vita3K.exe')
            Extensions = @('.vpk', '.zip')
            Hints = @('(?i)(^|\\)(vita|ps\s*vita)(\\|$)')
        },
        @{
            Key = 'cxbx'; Name = 'Cxbx-Reloaded'; UninstallPattern = '(?i)^Cxbx'
            ExeNames = @('Cxbx.exe', 'cxbx-reloaded.exe')
            ExePaths = @('%ProgramFiles%\Cxbx-Reloaded\Cxbx.exe', '%ProgramFiles(x86)%\Cxbx-Reloaded\Cxbx.exe')
            Extensions = @('.iso', '.xbe')
            Hints = @('(?i)(^|\\)(xbox)(?!\s*360)(\\|$)')
        },
        @{
            Key = 'fceux'; Name = 'FCEUX'; UninstallPattern = '(?i)^FCEUX'
            ExeNames = @('fceux.exe')
            ExePaths = @('%ProgramFiles%\FCEUX\fceux.exe', '%ProgramFiles(x86)%\FCEUX\fceux.exe')
            Extensions = @('.nes', '.fds', '.unf', '.unif')
            Hints = @('(?i)(^|\\)(nes|famicom)(\\|$)')
        },
        @{
            Key = 'mesen'; Name = 'Mesen'; UninstallPattern = '(?i)^Mesen'
            ExeNames = @('Mesen.exe')
            ExePaths = @('%ProgramFiles%\Mesen\Mesen.exe', '%ProgramFiles(x86)%\Mesen\Mesen.exe')
            Extensions = @('.nes', '.fds', '.unf', '.unif', '.sfc', '.smc', '.gb', '.gbc', '.gba', '.pce')
            Hints = @('(?i)(^|\\)(nes|snes|famicom|super\s*nintendo|game\s*boy|gba|gb|gbc|pce|turbografx)(\\|$)')
        },
        @{
            Key = 'nestopia'; Name = 'Nestopia'; UninstallPattern = '(?i)^Nestopia'
            ExeNames = @('nestopia.exe')
            ExePaths = @('%ProgramFiles%\Nestopia\nestopia.exe', '%ProgramFiles(x86)%\Nestopia\nestopia.exe')
            Extensions = @('.nes', '.fds', '.unf', '.unif')
            Hints = @('(?i)(^|\\)(nes|famicom)(\\|$)')
        },
        @{
            Key = 'fusion'; Name = 'Kega Fusion'; UninstallPattern = '(?i)^Kega'
            ExeNames = @('Fusion.exe')
            ExePaths = @('%ProgramFiles%\Kega Fusion\Fusion.exe', '%ProgramFiles(x86)%\Kega Fusion\Fusion.exe')
            Extensions = @('.gen', '.md', '.smd', '.32x', '.sms', '.gg', '.sg')
            Hints = @('(?i)(^|\\)(genesis|megadrive|mega\s*drive|master\s*system|game\s*gear|32x)(\\|$)')
        },
        @{
            Key = 'mednafen'; Name = 'Mednafen'; UninstallPattern = '(?i)^Mednafen'
            ExeNames = @('mednafen.exe')
            ExePaths = @('%ProgramFiles%\Mednafen\mednafen.exe', '%ProgramFiles(x86)%\Mednafen\mednafen.exe')
            Extensions = @('.pce', '.cue', '.bin', '.chd', '.iso', '.nes', '.sfc', '.smc', '.gba', '.gb', '.gbc')
            Hints = @()
        },
        @{
            Key = 'bizhawk'; Name = 'BizHawk'; UninstallPattern = '(?i)^BizHawk'
            ExeNames = @('EmuHawk.exe')
            ExePaths = @('%ProgramFiles%\BizHawk\EmuHawk.exe', '%ProgramFiles(x86)%\BizHawk\EmuHawk.exe')
            Extensions = @('.nes', '.fds', '.sfc', '.smc', '.gb', '.gbc', '.gba', '.n64', '.z64', '.nds', '.gen', '.md', '.sms', '.gg', '.pce', '.cue', '.bin', '.iso')
            Hints = @()
        },
        @{
            Key = 'scummvm'; Name = 'ScummVM'; UninstallPattern = '(?i)^ScummVM'
            ExeNames = @('scummvm.exe')
            ExePaths = @('%ProgramFiles%\ScummVM\scummvm.exe', '%ProgramFiles(x86)%\ScummVM\scummvm.exe')
            Extensions = @('.scummvm')
            Hints = @()
        },
        @{
            Key = 'mame'; Name = 'MAME'; UninstallPattern = '(?i)^MAME'
            ExeNames = @('mame.exe', 'mame64.exe')
            ExePaths = @('%ProgramFiles%\MAME\mame.exe', '%ProgramFiles(x86)%\MAME\mame.exe')
            Extensions = @('.zip')
            Hints = @('(?i)(^|\\)(mame|arcade|mame\s*roms)(\\|$)')
            RequireHint = $true
            ArgumentStyle = 'rom-name'
        },
        @{
            Key = 'retroarch'; Name = 'RetroArch'; UninstallPattern = '(?i)^RetroArch'
            ExeNames = @('retroarch.exe')
            ExePaths = @('%APPDATA%\RetroArch\retroarch.exe', '%ProgramFiles%\RetroArch\retroarch.exe', '%ProgramFiles(x86)%\RetroArch\retroarch.exe')
            Extensions = @(
                '.nes', '.fds', '.unf', '.unif', '.sfc', '.smc', '.fig', '.swc',
                '.n64', '.z64', '.v64', '.gb', '.gbc', '.gba', '.nds', '.dsi',
                '.3ds', '.cci', '.cxi', '.cia', '.iso', '.bin', '.cue', '.chd',
                '.pbp', '.cso', '.gdi', '.cdi', '.gen', '.md', '.smd', '.32x',
                '.sms', '.gg', '.pce', '.wad', '.gcz', '.rvz', '.wbfs', '.nsp',
                '.xci', '.pkg', '.vpk', '.zip'
            )
            Hints = @()
            Fallback = $true
        }
    )
}

function Get-RomRoots {
    param($Config)

    $scan = Get-PropertyValue $Config 'scan'
    $roots = @(Get-PropertyValue $scan 'romRoots' | Where-Object { $_ })
    if ($roots.Count -eq 0) {
        # Probe conventional names on every fixed drive rather than assuming a
        # particular drive letter, so the default works on any machine.
        $roots = @('%USERPROFILE%\ROMs', '%USERPROFILE%\Documents\ROMs')
        foreach ($drive in @(Get-AllFixedDriveRoots)) {
            $roots += (Join-Path $drive 'ROMs')
            $roots += (Join-Path $drive 'Emulation\roms')
            $roots += (Join-Path $drive 'Emulators\roms')
        }
    }

    $result = New-Object System.Collections.Generic.List[string]
    foreach ($root in $roots) {
        $expanded = Expand-PathValue $root
        if (!$expanded) { continue }
        if (!(Test-Path -LiteralPath $expanded -PathType Container -ErrorAction SilentlyContinue)) { continue }
        if (!($result -contains $expanded)) { $result.Add($expanded) }
    }

    return @(ConvertTo-Array $result)
}

function Get-EmulatorRoots {
    param($Config)

    $scan = Get-PropertyValue $Config 'scan'
    $roots = @(Get-PropertyValue $scan 'emulatorRoots' | Where-Object { $_ })
    if ($roots.Count -eq 0) {
        $roots = @('%LOCALAPPDATA%\Programs', '%ProgramFiles%')
        foreach ($drive in @(Get-AllFixedDriveRoots)) {
            $roots += (Join-Path $drive 'Emulators')
            $roots += (Join-Path $drive 'Emulation')
        }
    }

    return $roots
}

function Get-EmulatorExecutableIndex {
    param([string[]]$Roots)

    if ($null -ne $script:EmulatorExecutableIndex) { return $script:EmulatorExecutableIndex }

    $index = @{}
    foreach ($root in @($Roots)) {
        $expanded = Expand-PathValue $root
        if (!$expanded -or !(Test-Path -LiteralPath $expanded -PathType Container -ErrorAction SilentlyContinue)) { continue }

        foreach ($file in @(Get-ChildItem -LiteralPath $expanded -Filter '*.exe' -File -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue)) {
            $key = $file.Name.ToLowerInvariant()
            if (!$index.ContainsKey($key)) { $index[$key] = $file.FullName }
        }
    }

    $script:EmulatorExecutableIndex = $index
    return $index
}

function Find-EmulatorExecutable {
    param(
        $Definition,
        [string[]]$Roots
    )

    if (!$Definition) { return $null }

    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($value in @($Definition.ExePaths)) { if ($value) { $paths.Add($value) } }

    $relativePaths = New-Object System.Collections.Generic.List[string]
    foreach ($name in @($Definition.ExeNames)) {
        if ($name) {
            $relativePaths.Add((Join-Path $Definition.Name $name))
            $relativePaths.Add((Join-Path (Join-Path 'Emulators' $Definition.Name) $name))
        }
    }
    foreach ($value in (Get-StoreInstallCandidates -RelativePaths @(ConvertTo-Array $relativePaths))) {
        $paths.Add($value)
    }

    if ($Definition.UninstallPattern) {
        foreach ($app in @(Get-InstalledApplications)) {
            if ($app.DisplayName -notmatch $Definition.UninstallPattern) { continue }

            if ($app.DisplayIcon -and [IO.Path]::GetExtension($app.DisplayIcon) -ieq '.exe') {
                $paths.Add($app.DisplayIcon)
            }
            if ($app.InstallLocation) {
                foreach ($name in @($Definition.ExeNames)) {
                    if ($name) { $paths.Add((Join-Path $app.InstallLocation $name)) }
                }
            }
        }
    }

    $found = Find-FirstExistingPath -Paths @(ConvertTo-Array $paths) -PathType Leaf
    if ($found) { return $found }

    $index = Get-EmulatorExecutableIndex -Roots $Roots
    foreach ($name in @($Definition.ExeNames)) {
        if (!$name) { continue }
        $key = $name.ToLowerInvariant()
        if ($index.ContainsKey($key)) { return $index[$key] }
    }

    return $null
}

function Test-RomPartFile {
    param([IO.FileInfo]$File)

    # Multi-file disc images list .cue/.mds/.ccd/.gdi as the entry point. The
    # accompanying .bin/.mdf/.img track should not become a second shortcut.
    $partPairs = @{
        '.bin' = @('.cue', '.gdi')
        '.mdf' = @('.mds')
        '.img' = @('.ccd', '.cue')
    }

    $extension = $File.Extension.ToLowerInvariant()
    if (!$partPairs.ContainsKey($extension)) { return $false }

    $base = [IO.Path]::GetFileNameWithoutExtension($File.Name)
    foreach ($siblingExtension in $partPairs[$extension]) {
        $sibling = Join-Path $File.DirectoryName ($base + $siblingExtension)
        if (Test-Path -LiteralPath $sibling -PathType Leaf -ErrorAction SilentlyContinue) { return $true }
    }

    return $false
}

function Test-EmulatorPathHint {
    param(
        [string]$Path,
        [string[]]$Hints
    )

    if (!$Path -or !$Hints -or @($Hints).Count -eq 0) { return $false }

    foreach ($hint in @($Hints)) {
        if ($hint -and $Path -match $hint) { return $true }
    }

    return $false
}

function Get-EmulatorArguments {
    param(
        $Definition,
        [string]$RomPath
    )

    if (!$Definition -or !$RomPath) { return '' }

    if ($Definition.ArgumentStyle -eq 'rom-name') {
        return [IO.Path]::GetFileNameWithoutExtension($RomPath)
    }

    $quoted = '"' + $RomPath + '"'
    if ($Definition.ArgPrefix) { return $Definition.ArgPrefix + ' ' + $quoted }
    return $quoted
}

function Get-RomFormatRank {
    param([string]$Extension)

    switch ($Extension.ToLowerInvariant()) {
        '.chd'  { return 100 }
        '.rvz'  { return 96 }
        '.gcz'  { return 94 }
        '.wbfs' { return 92 }
        '.cso'  { return 90 }
        '.iso'  { return 88 }
        '.nsp'  { return 86 }
        '.xci'  { return 84 }
        '.gdi'  { return 82 }
        '.ccd'  { return 80 }
        '.cue'  { return 78 }
        '.mds'  { return 76 }
        '.pbp'  { return 74 }
        '.3ds'  { return 72 }
        '.cci'  { return 70 }
        '.vpk'  { return 68 }
        '.pkg'  { return 66 }
        '.bin'  { return 20 }
        '.mdf'  { return 18 }
        '.img'  { return 16 }
        default { return 50 }
    }
}

function Get-RomFolderNames {
    # Short, canonical names so the emulator path hints match without extra
    # configuration. Keep these in sync with the Hints regexes above.
    return @(
        'NES',
        'SNES',
        'N64',
        'GameCube',
        'Wii',
        'Wii U',
        'Switch',
        'Game Boy',
        'Game Boy Color',
        'GBA',
        'NDS',
        '3DS',
        'PS1',
        'PS2',
        'PS3',
        'PSP',
        'PS Vita',
        'Dreamcast',
        'Saturn',
        'Genesis',
        'Master System',
        'Game Gear',
        '32X',
        'Xbox',
        'Xbox 360',
        'Arcade',
        'ScummVM'
    )
}

function Initialize-RomFolderStructure {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [switch]$DryRun
    )

    $expanded = Expand-PathValue $Root
    if (!$expanded) { throw 'A ROM root path is required.' }

    $created = 0
    $existing = 0
    $rootExisted = Test-Path -LiteralPath $expanded -PathType Container -ErrorAction SilentlyContinue

    if (!$rootExisted) {
        if ($DryRun) {
            Write-Log "Would create ROM root: $expanded" -Level Info
        } else {
            New-Item -ItemType Directory -Path $expanded -Force | Out-Null
            Write-Log "Created ROM root: $expanded" -Level Ok
        }
    } else {
        Write-Log "ROM root already exists: $expanded" -Level Info
    }

    foreach ($name in @(Get-RomFolderNames)) {
        $path = Join-Path $expanded $name
        if (Test-Path -LiteralPath $path -PathType Container -ErrorAction SilentlyContinue) {
            $existing++
            continue
        }

        if ($DryRun) {
            Write-Log "Would create ROM folder: $path" -Level Debug
        } else {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
        $created++
    }

    if ($DryRun) {
        Write-Log ("Dry run: {0} console folder(s) would be created, {1} already exist." -f $created, $existing) -Level Ok
    } else {
        Write-Log ("ROM folder scaffold ready: {0} created, {1} already existed." -f $created, $existing) -Level Ok
    }

    return [pscustomobject]@{
        Root     = $expanded
        Created  = $created
        Existing = $existing
        DryRun   = [bool]$DryRun
    }
}

function Get-EmulatorProvider {
    param($Config)

    $definitions = @(Get-EmulatorDefinitions)
    $emulatorRoots = @(Get-EmulatorRoots -Config $Config)
    $romRoots = @(Get-RomRoots -Config $Config)

    if ($romRoots.Count -eq 0) {
        Write-Log 'Emulators: no ROM roots exist; set scan.romRoots in the config.' -Level Debug
        return $null
    }

    $installed = @{}
    foreach ($definition in $definitions) {
        $exe = Find-EmulatorExecutable -Definition $definition -Roots $emulatorRoots
        if ($exe) { $installed[$definition.Key] = $exe }
    }

    if ($installed.Count -eq 0) {
        Write-Log 'Emulators: no supported emulators are installed.' -Level Debug
        return $null
    }

    $scan = Get-PropertyValue $Config 'scan'
    $depth = 5
    $depthValue = Get-PropertyValue $scan 'romDepth'
    if ($null -ne $depthValue -and [int]$depthValue -gt 0) { $depth = [int]$depthValue }

    # Map each supported extension to the installed emulators that accept it.
    $extensionMap = @{}
    foreach ($definition in $definitions) {
        if (!$installed.ContainsKey($definition.Key)) { continue }
        foreach ($extension in @($definition.Extensions)) {
            if (!$extension) { continue }
            $key = $extension.ToLowerInvariant()
            if (!$extensionMap.ContainsKey($key)) { $extensionMap[$key] = New-Object System.Collections.Generic.List[object] }
            $extensionMap[$key].Add($definition)
        }
    }

    $ambiguous = @{
        '.iso' = $true; '.bin' = $true; '.cue' = $true; '.chd' = $true; '.cso' = $true
        '.mdf' = $true; '.nrg' = $true; '.img' = $true; '.pbp' = $true; '.elf' = $true
        '.zip' = $true; '.7z' = $true; '.rom' = $true
    }

    $entriesByKey = @{}
    $seenRoms = @{}
    $romEntryIndex = @{}

    foreach ($root in $romRoots) {
        $files = @(Get-ChildItem -LiteralPath $root -File -Recurse -Depth $depth -Force -ErrorAction SilentlyContinue)
        foreach ($file in $files) {
            $extension = $file.Extension.ToLowerInvariant()
            if (!$extension -or !$extensionMap.ContainsKey($extension)) { continue }
            if (Test-RomPartFile -File $file) { continue }

            $pathKey = $file.FullName.ToLowerInvariant()
            if ($seenRoms.ContainsKey($pathKey)) { continue }

            $candidates = New-Object System.Collections.Generic.List[object]
            foreach ($definition in $extensionMap[$extension]) {
                if ($definition.RequireHint -and !(Test-EmulatorPathHint -Path $file.FullName -Hints $definition.Hints)) { continue }
                $candidates.Add($definition)
            }

            if ($candidates.Count -eq 0) { continue }

            $choice = $null
            $hinted = New-Object System.Collections.Generic.List[object]
            foreach ($definition in $candidates) {
                if (Test-EmulatorPathHint -Path $file.FullName -Hints $definition.Hints) { $hinted.Add($definition) }
            }

            if ($hinted.Count -gt 0) {
                $choice = $hinted[0]
            } elseif ($candidates.Count -eq 1) {
                $choice = $candidates[0]
            } elseif (!$ambiguous.ContainsKey($extension)) {
                $choice = $candidates[0]
            } else {
                # A catch-all emulator (RetroArch) can run anything, so use it
                # rather than dropping a ROM that has no system-folder hint.
                foreach ($definition in $candidates) {
                    if ($definition.Fallback) { $choice = $definition; break }
                }
                if (!$choice) {
                    Write-Log ("Emulators: ambiguous '{0}'; add a system folder name or install only one matching emulator." -f $file.FullName) -Level Debug
                }
            }

            if (!$choice) { continue }

            $seenRoms[$pathKey] = $true
            if (!$entriesByKey.ContainsKey($choice.Key)) { $entriesByKey[$choice.Key] = New-Object System.Collections.Generic.List[object] }

            # The same game can be present as .chd and .cue/.bin at once. Keep
            # the single best dump instead of emitting duplicate shortcuts.
            $entryKey = $choice.Key + '|' + $file.BaseName.ToLowerInvariant()
            if ($romEntryIndex.ContainsKey($entryKey)) {
                if ((Get-RomFormatRank $extension) -le $romEntryIndex[$entryKey].Rank) { continue }
                $entriesByKey[$choice.Key].Remove($romEntryIndex[$entryKey].Entry)
            }

            $exe = $installed[$choice.Key]
            $entry = New-GameEntry -Name $file.BaseName -Provider $choice.Name -ProviderKey ('emu-' + $choice.Key) -Kind 'Rom' `
                -Target $exe -Arguments (Get-EmulatorArguments -Definition $choice -RomPath $file.FullName) `
                -WorkingDirectory (Split-Path -Parent $exe) -IconPath $exe -Source 'emulator-rom'
            $entriesByKey[$choice.Key].Add($entry)
            $romEntryIndex[$entryKey] = [pscustomobject]@{ Entry = $entry; Rank = (Get-RomFormatRank $extension) }
        }

        # Folder-based games: PS3 (PS3_GAME) and Xbox 360 (default.xex).
        if ($installed.ContainsKey('rpcs3') -or $installed.ContainsKey('xenia')) {
            $directories = @(Get-ChildItem -LiteralPath $root -Directory -Recurse -Depth $depth -Force -ErrorAction SilentlyContinue)
            foreach ($directory in $directories) {
                if ($installed.ContainsKey('rpcs3')) {
                    $ps3Game = Join-Path $directory.FullName 'PS3_GAME'
                    if (Test-Path -LiteralPath $ps3Game -PathType Container -ErrorAction SilentlyContinue) {
                        $pathKey = ('ps3|' + $directory.FullName).ToLowerInvariant()
                        if (!$seenRoms.ContainsKey($pathKey)) {
                            $seenRoms[$pathKey] = $true
                            if (!$entriesByKey.ContainsKey('rpcs3')) { $entriesByKey['rpcs3'] = New-Object System.Collections.Generic.List[object] }
                            $exe = $installed['rpcs3']
                            $entriesByKey['rpcs3'].Add((New-GameEntry -Name $directory.Name -Provider 'RPCS3' -ProviderKey 'emu-rpcs3' -Kind 'Rom' `
                                -Target $exe -Arguments (Get-EmulatorArguments -Definition (Get-EmulatorDefinitionByKey $definitions 'rpcs3') -RomPath $ps3Game) `
                                -WorkingDirectory (Split-Path -Parent $exe) -IconPath $exe -Source 'emulator-folder'))
                        }
                    }
                }

                if ($installed.ContainsKey('xenia')) {
                    $xex = Join-Path $directory.FullName 'default.xex'
                    if (Test-Path -LiteralPath $xex -PathType Leaf -ErrorAction SilentlyContinue) {
                        $pathKey = ('xenia|' + $directory.FullName).ToLowerInvariant()
                        if (!$seenRoms.ContainsKey($pathKey)) {
                            $seenRoms[$pathKey] = $true
                            if (!$entriesByKey.ContainsKey('xenia')) { $entriesByKey['xenia'] = New-Object System.Collections.Generic.List[object] }
                            $exe = $installed['xenia']
                            $entriesByKey['xenia'].Add((New-GameEntry -Name $directory.Name -Provider 'Xenia' -ProviderKey 'emu-xenia' -Kind 'Rom' `
                                -Target $exe -Arguments (Get-EmulatorArguments -Definition (Get-EmulatorDefinitionByKey $definitions 'xenia') -RomPath $xex) `
                                -WorkingDirectory (Split-Path -Parent $exe) -IconPath $exe -Source 'emulator-folder'))
                        }
                    }
                }
            }
        }
    }

    $results = New-Object System.Collections.Generic.List[object]
    foreach ($definition in $definitions) {
        if (!$entriesByKey.ContainsKey($definition.Key)) { continue }
        $entries = $entriesByKey[$definition.Key]
        if ($entries.Count -eq 0) { continue }

        $exe = $installed[$definition.Key]
        $launcher = New-GameEntry -Name $definition.Name -Provider 'Providers' -ProviderKey 'provider' -Kind 'Provider' `
            -Target $exe -IconPath $exe -Source 'emulator-launcher'

        $results.Add((New-ProviderResult -Key ('emu-' + $definition.Key) -DisplayName $definition.Name -Launcher $launcher -Games $entries -IconPath $exe))
    }

    if ($results.Count -eq 0) { return $null }
    return @(ConvertTo-Array $results)
}

function Get-EmulatorDefinitionByKey {
    param($Definitions, [string]$Key)

    foreach ($definition in @($Definitions)) {
        if ($definition.Key -eq $Key) { return $definition }
    }

    return $null
}
