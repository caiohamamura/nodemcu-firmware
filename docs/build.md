There are essentially three ways to build your NodeMCU firmware: cloud build service, Docker image, dedicated Linux environment (possibly VM).

## Tools

### Cloud Build Service
NodeMCU "application developers" just need a ready-made firmware. There's a [cloud build service](http://nodemcu-build.com/) with a nice UI and configuration options for them.

### Docker Image
Occasional NodeMCU firmware hackers don't need full control over the complete tool chain. They might not want to setup a Linux VM with the build environment. Docker to the rescue. Give [Docker NodeMCU build](https://hub.docker.com/r/marcelstoer/nodemcu-build/) a try.

### Linux Build Environment
NodeMCU firmware developers commit or contribute to the project on GitHub and might want to build their own full fledged build environment with the complete tool chain. The NodeMCU project embeds a [ready-made tool chain](https://github.com/nodemcu/nodemcu-firmware/blob/401fa56b863873c4cbf0b6581eb36fc61046ff6c/Makefile#L225) for Linux/x86-64 by default. After working through the [Build Options](#build-options) below, simply start the build process with
```
make
```

The default build setup reduces output verbosity to a minimum. The verbosity level can be increased by setting the `V` environment variable to 1, as below.  See the root `Makefile` for other available options.
```
V=1 make
```

!!! note

    Building the tool chain from scratch is out of NodeMCU's scope. Refer to [ESP toolchains](https://github.com/jmattsson/esp-toolchains) for related information.

### CMake Build (Linux and Windows)
As an alternative to the `make` build above, the firmware can also be built with [CMake](https://cmake.org/) (3.24 or newer). The CMake build downloads and prunes the required toolchain, SDK and `esptool.py` automatically, and additionally supports building on Windows with the MSVC compiler (`cl`).

Configure and build from the repository root:
```
cmake -B build -DLUA=53 .
cmake --build build
```

The resulting firmware image is written to the `bin/` directory, the same as the `make` build.

The most relevant CMake cache options are:

| Option | Values | Description |
|---|---|---|
| `LUA` | `51` (default), `53` | Lua version to build. |
| `LUA_NUMBER_INTEGRAL` | `ON`/`OFF` | Integer numbers, Lua 5.1 only. Mutually exclusive with `LUA_NUMBER_64BITS`. |
| `LUA_NUMBER_64BITS` | `ON`/`OFF` | 64-bit numbers, Lua 5.3 only. |
| `CMAKE_BUILD_TYPE` | `Release` (default), `Debug` | Build configuration. |
| `BUILD_HOST_TOOLS` | `AUTO` (default), `ON`, `OFF` | Build the host tools (`luac.cross`, `spiffsimg`); requires a host C compiler. |

For example, a Lua 5.3 integer (64-bit) build:
```
cmake -B build -DLUA=53 -DLUA_NUMBER_64BITS=ON .
cmake --build build
```

Or a Lua 5.1 integer build:
```
cmake -B build -DLUA=51 -DLUA_NUMBER_INTEGRAL=ON .
cmake --build build
```

Pass `--verbose` to `cmake --build` (or configure with `-DCMAKE_VERBOSE_MAKEFILE=ON`) to increase output verbosity.

The set of compiled modules is taken from `app/include/user_modules.h`, exactly as with the `make` build (see [Select Modules](#select-modules) below).

### Git
If you decide to build with either the Docker image or the native environment then use Git to clone the firmware sources instead of downloading the ZIP file from GitHub. Only cloning with Git will retrieve the referenced submodules:
```
git clone --recurse-submodules -b <branch> https://github.com/nodemcu/nodemcu-firmware.git
```
Omitting the optional `-b <branch>` will clone release.

## Build Options

The following sections explain some of the options you have if you want to build your own NodeMCU firmware.

### Select Modules
Disable modules you won't be using to reduce firmware size and free up some RAM. The ESP8266 is quite limited in available RAM and running out of memory can cause a system panic. The *default configuration* is designed to run on all ESP modules including the 512 KB modules like ESP-01 and only includes general purpose interface modules which require at most two GPIO pins.

Edit `app/include/user_modules.h` and comment-out the `#define` statement for modules you don't need. Example:

```c
...
#define LUA_USE_MODULES_MQTT
// #define LUA_USE_MODULES_COAP
...
```

### TLS/SSL Support
To enable TLS support edit `app/include/user_config.h` and uncomment the following flag:

```c
//#define CLIENT_SSL_ENABLE
```

The complete configuration is stored in `app/include/user_mbedtls.h`. This is the file to edit if you build your own firmware and want to change mbed TLS behavior. See the [`tls` documentation](modules/tls.md) for details.

### Debugging
To enable runtime debug messages to serial console edit `app/include/user_config.h`

```c
#define DEVELOP_VERSION
```

### LFS
LFS is turned off by default. See the [LFS documentation](./lfs.md) for supported config options (e.g. how to enable it).

### Set UART Bit Rate
The initial baud rate at boot time is 115200bps. You can change this by
editing `BIT_RATE_DEFAULT` in `app/include/user_config.h`:

```c
#define BIT_RATE_DEFAULT BIT_RATE_115200
```

Note that, by default, the firmware runs an auto-baudrate detection algorithm so that typing a few characters at boot time will cause
the firmware to lock onto that baud rate (between 1200 and 230400).

### Double build (Lua 5.3 only)
By default a build will be generated supporting floating point variables (floats) and integers.
To increase the precision of the floating point variables, a double build can be created. This
is also the default in the Lua 5.1 builds. The downside is that more memory is consumed when
storing variables.
You can change this
either by uncommenting `LUA_NUMBER_64BITS` in `app/include/user_config.h`:

```c
//#define LUA_NUMBER_64BITS
```

OR by overriding this with the `make` command 

```
make EXTRA_CCFLAGS="-DLUA_NUMBER_64BITS ....
```

### Integer build (Lua 5.1 only)
By default a build will be generated supporting floating-point variables (doubles).
To reduce memory size an integer build can be created.  You can change this
either by uncommenting `LUA_NUMBER_INTEGRAL` in `app/include/user_config.h`:

```c
//#define LUA_NUMBER_INTEGRAL
```

OR by overriding this with the `make` command as it's [done during the CI
build](https://github.com/nodemcu/nodemcu-firmware/blob/release/.travis.yml#L30):

```
make EXTRA_CCFLAGS="-DLUA_NUMBER_INTEGRAL ....
```

### Tag Your Build
Identify your firmware builds by setting the environment variable `USER_PROLOG`.
You may also edit `app/include/user_version.h`. The variable `USER_PROLOG` will be included in `NODE_VERSION_LONG`.

```c
#define NODE_VERSION    "NodeMCU " ESP_SDK_VERSION_STRING "." NODE_VERSION_XSTR(NODE_VERSION_INTERNAL) " " NODE_VERSION_LONG

#ifndef BUILD_DATE
#define BUILD_DATE      "unspecified"
#endif
```

### u8g2 Module Configuration
Display drivers and embedded fonts are compiled into the firmware image based on the settings in `app/include/u8g2_displays.h` and `app/include/u8g2_fonts.h`. See the [`u8g2` documentation](modules/u8g2.md#displays) for details.

### ucg Module Configuration
Display drivers and embedded fonts are compiled into the firmware image based on the settings in `app/include/ucg_config.h`. See the [`ucg` documentation](modules/ucg.md#displays) for details.
