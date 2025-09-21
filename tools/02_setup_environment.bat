Miniforge3-Windows-x86_64.exe /S
call C:\ProgramData\miniforge3\Scripts\activate.bat
mamba create -n esp cmake ninja pyserial gcc -y 
call conda activate esp
pushd nodemcu-firmware
call tools\03_configure_build.bat
