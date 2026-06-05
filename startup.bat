@echo off
set PYTHON="C:\ProgramFiles\WindowsApps\PythonSoftwareFoundation.PythonManager_26.2.240.0_x64__qbz5n2kfra8p0\python.exe"
set ROOT=C:\Users\craftos\AppData\Roaming\CraftOS-PC

start "%PYTHON%" "%ROOT%\python\execbridge.py"
start "%PYTHON%" "%ROOT%\python\bridgefs.py"
start "" "C:\Program Files\CraftOS-PC\CraftOS-PC.exe"

exit /b
