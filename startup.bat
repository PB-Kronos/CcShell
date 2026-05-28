@echo off
set PYTHON="C:\Program Files\WindowsApps\PythonSoftwareFoundation.PythonManager_26.2.240.0_x64__qbz5n2kfra8p0\python.exe"
set ROOT=C:\Users\craftos\AppData\Roaming\CraftOS-PC

if exist "%ROOT%\python\execbridge.py" (
    start "" /min %PYTHON% %ROOT%\python\bridgefs.py
    start "" /min %PYTHON% %ROOT%\python\execbridge.py
) else (
    for /d %%G in ("%ROOT%\computer\*") do (
        if exist "%%~fG\var\.install.py" start "" /min %PYTHON% "%%~fG\var\.install.py"
    )
)
start "" "C:\Program Files\CraftOS-PC\CraftOS-PC.exe"

exit /b
