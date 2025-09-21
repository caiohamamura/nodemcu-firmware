# Run this with $ProgressPreference = 'SilentlyContinue';Invoke-Expression ((Invoke-WebRequest -Uri https://raw.githubusercontent.com/caiohamamura/nodemcu-firmware/refs/heads/cmake/tools/01_install.ps1 -UseBasicParsing).Content);$ProgressPreference = 'Continue'
mkdir nodemcu_build
cd nodemcu_build
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri https://raw.githubusercontent.com/caiohamamura/nodemcu-firmware/refs/heads/cmake/tools/02_setup_environment.bat -UseBasicParsing -OutFile 02_setup_environment.bat
Invoke-WebRequest -OutFile Miniforge3-Windows-x86_64.exe -Uri "https://github.com/conda-forge/miniforge/releases/download/25.3.1-0/Miniforge3-Windows-x86_64.exe"
$ProgressPreference = 'Continue'
cmd /c "02_setup_environment.bat"
cd nodemcu-firmware
