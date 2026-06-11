param(
    [Parameter(Mandatory = $true)]
    [string]$Root,
    [Parameter(Mandatory = $true)]
    [string]$PythonExe,
    [Parameter(Mandatory = $true)]
    [string]$DefaultPythonPath
)

$settingsPath = Join-Path $Root 'computer\0\.settings'
$pythonPath = $DefaultPythonPath
$log = Join-Path $Root 'python-startup.log'

if (Test-Path $settingsPath) {
    $content = Get-Content -Raw $settingsPath
    if ($content -match '(?:\[\s*\"python_path\"\s*\]|python_path)\s*=\s*\"((?:\\.|[^\"])*)\"') {
        $value = $matches[1] -replace '\\\\', '\'
        if ($value -and $value.Trim()) {
            if ($value -match '^[A-Za-z]:') {
                $pythonPath = $value
            } else {
                $pythonPath = Join-Path $Root ($value.TrimStart('/').TrimStart('\'))
            }
        }
    }
}

Set-Content -Path $log -Value "[startup] python executable: $PythonExe"
Add-Content -Path $log -Value "[startup] python root: $pythonPath"

if (Test-Path $pythonPath) {
    Get-ChildItem -Path $pythonPath -Filter '*.py' -File | Sort-Object Name | ForEach-Object {
        Add-Content -Path $log -Value "[startup] launching $($_.FullName)"
        Start-Process -FilePath $PythonExe -ArgumentList ('"' + $_.FullName + '"') -WorkingDirectory $pythonPath -WindowStyle Minimized
    }
} else {
    Add-Content -Path $log -Value "[startup] python root missing"
}
