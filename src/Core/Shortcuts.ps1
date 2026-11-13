# Shortcut creation: .url for protocols, .lnk for executables, folder icons.

function Resolve-ShortcutIcon {
    param(
        $Entry,
        [string]$FallbackIcon = ''
    )

    $candidates = @($Entry.IconPath, $Entry.Target, $FallbackIcon)
    foreach ($candidate in $candidates) {
        if (!$candidate) { continue }
        if (Test-UrlTarget $candidate) { continue }
        if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) {
            return $candidate
        }
    }

    return $null
}

function New-UrlShortcut {
    param(
        [string]$Path,
        [string]$Url,
        [string]$IconPath = ''
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('[{000214A0-0000-0000-C000-000000000046}]')
    $lines.Add('Prop3=19,2')
    $lines.Add('[InternetShortcut]')
    $lines.Add('URL=' + $Url)
    if ($IconPath -and (Test-Path -LiteralPath $IconPath -PathType Leaf -ErrorAction SilentlyContinue)) {
        $lines.Add('IconFile=' + $IconPath)
        $lines.Add('IconIndex=0')
    }

    $content = ($lines -join "`r`n") + "`r`n"
    [IO.File]::WriteAllText($Path, $content, [Text.Encoding]::Default)
    return $Path
}

function New-LnkShortcut {
    param(
        [string]$Path,
        $Entry,
        [string]$IconPath = ''
    )

    $targetPath = $Entry.Target
    if (!(Test-Path -LiteralPath $targetPath -PathType Leaf -ErrorAction SilentlyContinue)) {
        $command = Get-Command $targetPath -ErrorAction SilentlyContinue
        if ($command) { $targetPath = $command.Source }
    }

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    $shortcut.TargetPath = $targetPath

    if ($Entry.Arguments) { $shortcut.Arguments = $Entry.Arguments }

    $workingDirectory = $Entry.WorkingDirectory
    if (!$workingDirectory -and (Test-Path -LiteralPath $targetPath -PathType Leaf -ErrorAction SilentlyContinue)) {
        $workingDirectory = Split-Path -Parent $targetPath
    }
    if ($workingDirectory) { $shortcut.WorkingDirectory = $workingDirectory }

    if ($IconPath) { $shortcut.IconLocation = $IconPath + ',0' }
    if ($Entry.Description) { $shortcut.Description = $Entry.Description }

    $shortcut.Save()
    return $Path
}

function New-ShortcutFile {
    param(
        [string]$Directory,
        [string]$BaseName,
        $Entry,
        [string]$FallbackIcon = ''
    )

    if (!(Test-Path -LiteralPath $Directory -PathType Container -ErrorAction SilentlyContinue)) {
        if ($script:DryRun) {
            Write-Log "Would create folder: $Directory" -Level Debug
        } else {
            New-Item -ItemType Directory -Path $Directory -Force | Out-Null
        }
    }

    $safeName = Get-SafeFileName -Name $BaseName
    $isUrl = [bool]$Entry.IsUrl
    $extension = if ($isUrl) { '.url' } else { '.lnk' }
    $path = Join-Path $Directory ($safeName + $extension)

    if ($script:DryRun) {
        Write-Log "Would create shortcut: $path -> $($Entry.Target)" -Level Debug
        return $path
    }

    $icon = Resolve-ShortcutIcon -Entry $Entry -FallbackIcon $FallbackIcon

    try {
        if ($isUrl) {
            return New-UrlShortcut -Path $path -Url $Entry.Target -IconPath $icon
        }
        return New-LnkShortcut -Path $path -Entry $Entry -IconPath $icon
    } catch {
        Write-Log "Could not create shortcut '$path': $($_.Exception.Message)" -Level Warn
        return $null
    }
}

function Set-FolderIcon {
    param(
        [string]$Folder,
        [string]$IconPath,
        [string]$IniPath
    )

    if (!$IconPath -or !(Test-Path -LiteralPath $IconPath -PathType Leaf -ErrorAction SilentlyContinue)) { return $false }
    if (!(Test-Path -LiteralPath $Folder -PathType Container -ErrorAction SilentlyContinue)) { return $false }

    $content = "[.ShellClassInfo]`r`nIconResource=$IconPath,0`r`n"

    if ($script:DryRun) {
        Write-Log "Would set folder icon: $Folder -> $IconPath" -Level Debug
        return $true
    }

    try {
        Set-Content -LiteralPath $IniPath -Value $content -Encoding Unicode -Force

        $iniItem = Get-Item -LiteralPath $IniPath -Force
        $iniItem.Attributes = $iniItem.Attributes -bor [IO.FileAttributes]::Hidden -bor [IO.FileAttributes]::System

        $folderItem = Get-Item -LiteralPath $Folder -Force
        $folderItem.Attributes = $folderItem.Attributes -bor [IO.FileAttributes]::System

        return $true
    } catch {
        Write-Log "Could not set folder icon for '$Folder': $($_.Exception.Message)" -Level Debug
        return $false
    }
}
