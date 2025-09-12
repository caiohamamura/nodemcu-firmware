Invoke-WebRequest -Uri "https://github.com/conda-forge/miniforge/releases/download/25.3.1-0/Miniforge3-Windows-x86_64.exe"
Miniforge3-Windows-x86_64.exe /S
cmd
ProgramData\miniforge3\Scripts\activate.bat
conda create -n esp
conda activate esp
conda install cmake ninja pyserial gcc -y
rmdir /S /Q build
cmake -B build -GNinja .
cmake --build build
cmake --install build --prefix .
dir bin

