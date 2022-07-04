Building Doom 2D: Forever on OS X natively
=====================================

*NOTE: This manual assumes that you're using MacPorts as your package manager. Those who prefer Homebrew should find the appropriate packages themselves.*

1. Install prerequisites with MacPorts:

```$ sudo port install libsdl2 libsdl2_mixer miniupnpc macdylibbundler autoconf```

2. Download `libenet` sources and build them, it would be convenient to choose `/opt/local` as prefix because it's default path where MacPorts places installed packages:

```
$ git clone https://github.com/lsalzman/enet.git && cd enet
$ autoreconf -vfi
$ ./configure --prefix="/opt/local/" && make && make install
```

3. Make sure you installed FPC. It can be installed from MacPorts or manually

4. Vodify `builder.sh` (it is in root of this repo), select `PACKUTIL` (utility to make DMG - `mkisofs` (`cdrtools` package in MacPorts) or `genisoimage`), go through the available options to check them

```https://github.com/fl0atingzero/df_osx_utils.git```

5. Build them with `builder.sh`:

```builder.sh -s path/to/game/sources -r path/to/game/resources -p -y```
