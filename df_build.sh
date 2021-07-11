#!/bin/sh

# DOOM 2D: FOREVER BUILDER FOR OS X - v0.01
# k_1nspired, 2021

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
LIBDIR="../../macosx/Doom2DF.app/Contents/MacOS/libs"
TMPDIR="../../macosx/tmp"
OUTDIR="../../macosx/Doom2DF.app/Contents/MacOS"
BUILDFLAGS="-dUSE_SDL2 -dUSE_SDLMIXER"
HEADLESSFLAGS="-dUSE_SOUNDSTUB -dHEADLESS"

cd $SRCDIR/src/game

# clean tmp files

echo "clean tmp files"
rm -rvf $TMPDIR/* $OUTDIR/{link.res,ppas*,Doom2DF*}

# building headless version

echo "building headless version"
fpc -g -gl -gs -O3 $HEADLESSFLAGS -FU"$TMPDIR" -FE"$OUTDIR" -Ff"$LIBDIR" -Fu"$LIBDIR" -Fl"$LIBDIR" -oDoom2DF Doom2DF.lpr
mv $OUTDIR/Doom2DF $OUTDIR/Doom2DF_H

# clean tmp files

echo "clean tmp files"
rm -rvf $TMPDIR/* $OUTDIR/{link.res,ppas*}

# building main version

echo "building main version"
fpc -g -gl -gs -O3 $BUILDFLAGS -FU"$TMPDIR" -FE"$OUTDIR" -Ff"$LIBDIR" -Fu"$LIBDIR" -Fl"$LIBDIR" -oDoom2DF Doom2DF.lpr

# fix library paths
echo "fix library paths for:"

cd $LIBDIR
for LIBNAME in *; do
    echo "  $LIBNAME"
    cd $SRCDIR/src/game
    install_name_tool -change /usr/local/lib/$LIBNAME @executable_path/$LIBNAME $OUTDIR/Doom2DF
    install_name_tool -change /usr/local/lib/$LIBNAME @executable_path/$LIBNAME $OUTDIR/Doom2DF_H
done

#done
