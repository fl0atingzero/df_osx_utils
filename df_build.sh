#!/bin/sh

# DOOM 2D: FOREVER BUILDER FOR OS X - v0.02
# k_1nspired, 2021
#
# ATTENTION! PLEASE MODIFY BEFORE USING!
#
# warning - this version doesn't perform soucre dir checks for necessary files - you should prepare it by yourself
# please be assured that there is macosx/tmp dir and Doom2DF.app dir, also there should be Contents/MacOS/libs with these files:
# 
# libSDL2-2.0.0.dylib
# libSDL2.dylib
# libSDL2_mixer-2.0.0.dylib
# libSDL2_mixer.dylib
# libenet.7.dylib
# libenet.dylib
# libenet.la
# libmodplug.1.dylib
# libmodplug.dylib
# libmpg123.0.dylib
# libmpg123.dylib 
# libogg.0.dylib
# libogg.dylib
# libopus.0.dylib
# libopus.dylib
# libopusfile.0.dylib
# libopusfile.dylib
# libvorbis.0.dylib
# libvorbis.dylib

SRCDIR="/Users/vlad/d2df-sdl"
# directory where source files are placed
TMPDIR="../../macosx/tmp"
# directory for temporary files relative to srcdir
OUTDIR="../../macosx/Doom2DF.app/Contents/MacOS"
# directory for out binary relative to srcdir
LIBS="libs"
# workaround, libs directory relative to outdir
LIBDIR="$OUTDIR/$LIBS"
# resulting libs directory relative to srcdir
BUILDFLAGS="-dUSE_SDL2 -dUSE_SDLMIXER"
# default binary build flags
HEADLESSFLAGS="-dUSE_SOUNDSTUB -dHEADLESS"
# headless server build flags
DLIBPATHMAIN="/opt/local/lib"
# deafult path for installed libraries, e.g. if using MacPorts, libs are installed to /opt/local/lib

#~~~~~~~~~~~~~~
echo "Doom 2D: Forever build script for OS X - v0.02 @ k_1nspired"
echo ""

cd $SRCDIR/src/game

# clean tmp files

echo "cleaning temporary files:"
echo ""
rm -rvf $TMPDIR/* $OUTDIR/{link.res,ppas*,Doom2DF*}

# building headless version

echo ""
echo "building headless version:"
echo ""
fpc -g -gl -gs -O3 $HEADLESSFLAGS -FU"$TMPDIR" -FE"$OUTDIR" -Ff"$LIBDIR" -Fu"$LIBDIR" -Fl"$LIBDIR" -oDoom2DF Doom2DF.lpr
mv $OUTDIR/Doom2DF $OUTDIR/Doom2DF_H

# clean tmp files

echo ""
echo "clean temporary files:"
echo ""
rm -rvf $TMPDIR/* $OUTDIR/{link.res,ppas*}

# building main version

echo ""
echo "building main version:"
echo ""
fpc -g -gl -gs -O3 $BUILDFLAGS -FU"$TMPDIR" -FE"$OUTDIR" -Ff"$LIBDIR" -Fu"$LIBDIR" -Fl"$LIBDIR" -oDoom2DF Doom2DF.lpr

# fix library paths
echo ""
echo "fix library paths for:"

cd $LIBDIR
for LIBNAME in *; do
    echo "  $LIBNAME"
    cd $SRCDIR/src/game
    install_name_tool -change $DLIBPATHMAIN/$LIBNAME @executable_path/$LIBS/$LIBNAME $OUTDIR/Doom2DF
    install_name_tool -change $DLIBPATHMAIN/$LIBNAME @executable_path/$LIBS/$LIBNAME $OUTDIR/Doom2DF_H
done

#done
