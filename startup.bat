@echo off
set PYTHON="C:\Program Files\WindowsApps\PythonSoftwareFoundation.PythonManager_26.2.240.0_x64__qbz5n2kfra8p0\python.exe"
set ROOT=C:\Users\craftos\AppData\Roaming\CraftOS-PC

if exist "%ROOT%\python" (
    for %%F in ("%ROOT%\python\*.py") do (
        if exist "%%~fF" start "" /min %PYTHON% "%%~fF"
    )
)

for /d %%C in ("%ROOT%\computer\*") do (
    if exist "%%~fC\var\.install.py" (
        start "" /min %PYTHON% "%%~fC\var\.install.py"
    )
)

start "" "C:\Program Files\CraftOS-PC\CraftOS-PC.exe"

exit /b
