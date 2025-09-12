call C:\ProgramData\miniforge3\Scripts\activate.bat esp
cmake -B build -GNinja .
cmake --build build
cmake --install build --prefix .
dir bin
