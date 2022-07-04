Cross-compiling Doom 2D: Forever from Linux to OS X
===================================================

*NOTE: this manual is written for Arch Linux and pacman. Those who prefer other distros and package manager should find the appropriate packages themselves*

1. First of all we need to install cross-toolchain `osxcross`. Clone it's repo and put Mac OS X SDK tarball to `tarballs` directory inside the repo. You can download it from [here](https://github.com/phracker/MacOSX-SDKs/releases). I'm using SDK for Mac OS X 10.8 (`x86_64-apple-darwin12`):

```git clone https://github.com/tpoechtrager/osxcross```

2. Install prerequisites with pacman:

```# pacman -S base-devel fpc clang cmake libxml2 openssl cpio curl```

3. Export `TARGET_DIR` - path where toolchain should be installed and build it, then add `$TARGET_DIR` to `PATH`:

```# TARGET_DIR=/usr/local/osxcross ./build.sh```

4. Download FPC sources and build cross-compiler. `CROSSBINDIR` - path to cross-toolchain, `CPU_TARGET` and `BINUTILSPREFIX` depends on the selected SDK version, installation prefix - path where cross-fpc should be installed (`/opt/cross` for me):

```
$ curl -O ftp://ftp.hu.freepascal.org/pub/fpc/dist/3.2.2/source/fpc-3.2.2.source.tar.gz
$ tar -xzvf fpc-3.2.2.source.tar.gz
$ cd fpc-3.2.2
# make distclean && FPC=ppcx64 make crossall crossinstall \
CPU_TARGET=x86_64 OS_TARGET=darwin \
CROSSBINDIR=/usr/local/osxcross/bin/ BINUTILSPREFIX=x86_64-apple-darwin12- \
INSTALL_PREFIX=/opt/cross \
OPT="-gl -gw -godwarfsets -XX -CX -Xd -Fl/usr/local/osxcross/SDK/MacOSX10.8.sdk/usr/lib"
```

Then add `/opt/cross/lib/fpc/3.2.2/` to `PATH`

5. Modify `macportsutil.sh` (it is in root of this repo - script that will download libs from MacPorts, puts them in the specified directory and fixes their dependency paths) to specify `OUTDIR` - directory where libs will be placed (for me it's `~/dfcross/libs`) and set `FLAG_D` to 1:

```
$ git clone https://github.com/fl0atingzero/df_osx_utils.git
./macportsutil
```

6. Clone `macdylibbundler` repo and build it, then make symbolic links for `otool` and `install_name_tool` for dylibbundler to work properly:

```
$ git clone https://github.com/auriamg/macdylibbundler.git
$ cd macdylibbundler
$ make
$ sudo cp dylibbundler /usr/local/bin
$ ln -s /usr/local/osxcross/bin/{x86_64-apple-darwin12-otool,otool}
$ ln -s /usr/local/osxcross/bin/{x86_64-apple-darwin12-install_name_tool,install_name_tool}
```

7. Download sources of `libenet` and build them, it would be convenient to choose the same `OUTDIR` as you used with macportsutil as prefix:

```
$ git clone https://github.com/lsalzman/enet/commits/master
# pacman -S autoconf
$ cd enet
$ autoreconf -vfi
$ ./configure \
    --host="x86_64-apple-darwin12" \
    --target="x86_64-apple-darwin12" \
    --prefix="/home/vlad/dfcross/libs" \
    --with-sysroot="/usr/local/osxcross/SDK/MacOSX10.8.sdk/" \
    CC=x86_64-apple-darwin12-clang
```

8. Modify `crossbuilder.sh` in `df_osx_utils` repo to specify paths to sources, game resources (usually unpacked win32-d2df-latest.zip), temporary files, output directory and utility to make DMG - `mkisofs` (`cdrtools` package in Arch repo) or `genisoimage`, go through the available options to check them, then build game with `crossbuilder.sh`

```./crossbuilder.sh```
