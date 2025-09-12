Miniforge3-Windows-x86_64.exe /S
call C:\ProgramData\miniforge3\Scripts\activate.bat
mamba create -n esp cmake ninja pyserial gcc git -y 
call conda activate esp
git clone https://github.com/caiohamamura/nodemcu-firmware.git --depth=1 --recurse-submodules --shallow-submodules --branch cmake
pushd nodemcu-firmware
call tools\03_configure_build.bat
