Invoke-Expression ((Invoke-WebRequest -Uri https://micro.mamba.pm/install.ps1 -UseBasicParsing).Content)
micromamba create -n esp
micromamba activate esp
micromamba install cmake ninja pyserial gcc -y
cmake -B build -GNinja .
cmake --build build --config Release
cmake --install build --prefix .
