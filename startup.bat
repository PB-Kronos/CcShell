@echo off
set PYTHON="C:\Program Files\WindowsApps\PythonSoftwareFoundation.PythonManager_26.2.240.0_x64__qbz5n2kfra8p0\python.exe"
set ROOT=C:\Users\craftos\AppData\Roaming\CraftOS-PC
set "CCSHELL_PYTHON_PATH=%ROOT%\python"

if exist "%ROOT%\computer\0\.settings" (
    for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command ^
        "$settings = Join-Path $env:ROOT 'computer\0\.settings';" ^
        "$value = $null;" ^
        "if (Test-Path $settings) {" ^
        "  $content = Get-Content -Raw $settings;" ^
        "  if ($content -match '(?:\[\s*\"python_path\"\s*\]|python_path)\s*=\s*\"((?:\\.|[^\"])*)\"') {" ^
        "    $value = $matches[1] -replace '\\\\', '\';" ^
        "  }" ^
        "}" ^
        "if ($null -ne $value -and $value -ne '') {" ^
        "  if ($value -match '^[A-Za-z]:') { $value } else { Join-Path $env:ROOT ($value.TrimStart('/').TrimStart('\')) }" ^
        "}"`) do set "CCSHELL_PYTHON_PATH=%%P"
)

if exist "%CCSHELL_PYTHON_PATH%\*.py" (
    for %%F in ("%CCSHELL_PYTHON_PATH%\*.py") do (
        if exist "%%~fF" start "" /min %PYTHON% "%%~fF"
    )
)

start "" "C:\Program Files\CraftOS-PC\CraftOS-PC.exe"
pause
