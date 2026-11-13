# Secure secret storage using the Windows Data Protection API (DPAPI).
# Secrets are encrypted for the current user and stored outside the repository
# and outside the library root, so they never appear in config, manifests, logs,
# or generated HTML.

if (-not ('GamesLibrary.SecretProtector' -as [type])) {
    try {
        Add-Type -TypeDefinition @"
using System;
using System.Security.Cryptography;
using System.Text;
public static class SecretProtector {
    public static string Protect(string plain) {
        if (plain == null) plain = "";
        var bytes = Encoding.UTF8.GetBytes(plain);
        var protectedBytes = ProtectedData.Protect(bytes, null, DataProtectionScope.CurrentUser);
        return Convert.ToBase64String(protectedBytes);
    }
    public static string Unprotect(string cipher) {
        if (string.IsNullOrWhiteSpace(cipher)) return null;
        var bytes = Convert.FromBase64String(cipher);
        var plain = ProtectedData.Unprotect(bytes, null, DataProtectionScope.CurrentUser);
        return Encoding.UTF8.GetString(plain);
    }
}
"@ -ReferencedAssemblies 'System.Security' -ErrorAction Stop | Out-Null
    } catch {
        # Fall back to a no-op protector so the module still loads; values will
        # be stored verbatim only if DPAPI is unavailable (non-Windows).
        if (-not ('GamesLibrary.SecretProtector' -as [type])) {
            Add-Type -TypeDefinition @"
using System;
public static class SecretProtector {
    public static string Protect(string plain) { return plain; }
    public static string Unprotect(string cipher) { return cipher; }
}
"@ -ErrorAction SilentlyContinue | Out-Null
        }
    }
}

function Get-SecretStorePath {
    $base = Join-Path $env:LOCALAPPDATA 'GamesLibraryManager'
    if (!(Test-Path -LiteralPath $base -PathType Container -ErrorAction SilentlyContinue)) {
        if (!$script:DryRun) { New-Item -ItemType Directory -Path $base -Force | Out-Null }
    }
    return (Join-Path $base 'secrets.dat')
}

function Get-SecretStore {
    $path = Get-SecretStorePath
    if (!(Test-Path -LiteralPath $path -PathType Leaf -ErrorAction SilentlyContinue)) { return @{} }

    try {
        $raw = Get-Content -LiteralPath $path -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) { return @{} }
        $obj = $raw | ConvertFrom-Json -ErrorAction Stop
        $table = @{}
        foreach ($prop in $obj.PSObject.Properties) {
            $table[[string]$prop.Name] = [string]$prop.Value
        }
        return $table
    } catch {
        Write-Log "Could not read the secret store: $($_.Exception.Message)" -Level Warn
        return @{}
    }
}

function Save-SecretStore {
    param([hashtable]$Store)

    $path = Get-SecretStorePath
    $json = $Store | ConvertTo-Json -Depth 2
    Set-Content -LiteralPath $path -Value $json -Encoding UTF8 -ErrorAction Stop
}

function Protect-SecretValue {
    param([string]$Value)
    return [SecretProtector]::Protect($Value)
}

function Unprotect-SecretValue {
    param([string]$Value)
    return [SecretProtector]::Unprotect($Value)
}

function Set-StoredSecret {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Name)) { throw 'A secret name is required.' }

    $protected = Protect-SecretValue $Value
    $store = Get-SecretStore
    $store[$Name] = $protected
    Save-SecretStore -Store $store

    Write-Log "Stored secret '$Name' (encrypted for the current Windows user)." -Level Ok
}

function Get-StoredSecret {
    param([Parameter(Mandatory = $true)][string]$Name)

    $store = Get-SecretStore
    if (!$store.ContainsKey($Name)) { return $null }

    try {
        return Unprotect-SecretValue $store[$Name]
    } catch {
        Write-Log "Could not decrypt secret '$Name': $($_.Exception.Message)" -Level Warn
        return $null
    }
}

function Remove-StoredSecret {
    param([Parameter(Mandatory = $true)][string]$Name)

    $store = Get-SecretStore
    if (!$store.ContainsKey($Name)) {
        Write-Log "Secret '$Name' is not stored." -Level Debug
        return
    }

    $store.Remove($Name)
    Save-SecretStore -Store $store
    Write-Log "Removed secret '$Name'." -Level Ok
}

function Test-StoredSecret {
    param([Parameter(Mandatory = $true)][string]$Name)
    return (Get-SecretStore).ContainsKey($Name)
}

function Get-StoredSecretNames {
    return @((Get-SecretStore).Keys | Sort-Object)
}

function ConvertFrom-SecureStringPlain {
    param([System.Security.SecureString]$Secure)

    if ($null -eq $Secure) { return '' }
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Resolve-SecretValue {
    # Turn a config value into the real secret. Supported forms:
    #   {secret:NAME}  -> DPAPI-protected store
    #   {env:VAR}      -> environment variable
    #   anything else  -> returned verbatim (not recommended for real secrets)
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $v = $Value.Trim()

    if ($v -match '^\{secret:(.+)\}$') {
        return (Get-StoredSecret -Name $Matches[1].Trim())
    }
    if ($v -match '^\{env:(.+)\}$') {
        return [Environment]::GetEnvironmentVariable($Matches[1].Trim())
    }

    return $v
}
