# Private data bridge used only by _common.bat :load. Never emits CMD code.
# Windows PowerShell 5.1; stdout is all-or-nothing validated KEY=VALUE data.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
try {
    . (Join-Path $PSScriptRoot '000-config.ps1')
    if ([string]::IsNullOrWhiteSpace($env:AIJAIL_CONFIG_FILE)) { throw 'CONFIG_PATH_REQUIRED' }
    $config = Read-AijConfig -Path $env:AIJAIL_CONFIG_FILE
    $keys = @('TARGET_DRIVE','DISTRO','BASE_DISTRO','LINUX_USER','MIN_WSL_VERSION','MIN_FREE_GB',
        'ALLOW_HOSTS_OPENCODE','ALLOW_HOSTS_COMFYUI','ALLOW_HOSTS_INSTALL',
        'INSTALL_COMFYUI','INSTALL_OPENCODE','INSTALL_VSCODE','ENABLE_NONO')
    if ($config.Count -ne $keys.Count) { throw 'CONFIG_SCHEMA_MISMATCH' }
    $lines = New-Object 'System.Collections.Generic.List[string]'
    foreach ($key in $keys) {
        if (-not $config.ContainsKey($key)) { throw 'CONFIG_KEY_MISSING' }
        $value = [string]$config[$key]
        # Defense in depth at the CMD boundary, independent of future changes
        # to the strict parser. In particular reject %, !, &, |, quotes, CR/LF.
        if ($value -cnotmatch '^[A-Za-z0-9_.:;\-]*$') { throw 'CONFIG_CMD_ENCODING_REJECTED' }
        $lines.Add($key + '=' + $value)
    }
    $lines.Add('AIJAIL_CONFIG_OK=1')
    [Console]::Out.Write(($lines -join [Environment]::NewLine) + [Environment]::NewLine)
    exit 0
} catch {
    # No input value or exception content is copied to diagnostics.
    [Console]::Error.WriteLine('AIJAIL_CONFIG_REJECTED')
    exit 1
}
