@echo off
setlocal

set "ROOT=C:\Users\craftos\AppData\Roaming\CraftOS-PC"
set "PYTHON_EXE=C:\Program Files\WindowsApps\PythonSoftwareFoundation.PythonManager_26.2.240.0_x64__qbz5n2kfra8p0\python.exe"
set "CCSHELL_PYTHON_PATH=%ROOT%\python"
set "STARTUP_PS1=%ROOT%\startup.ps1"

if exist "%STARTUP_PS1%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%STARTUP_PS1%" ^
        -Root "%ROOT%" ^
        -PythonExe "%PYTHON_EXE%" ^
        -DefaultPythonPath "%CCSHELL_PYTHON_PATH%"
)

start "" "C:\Program Files\CraftOS-PC\CraftOS-PC.exe"

endlocal
exit /b
