#!/bin/bash

# DOOM 2D: FOREVER BUILDER AND PACKER FOR OS X - v1.0
# (c) fl0atingzero, 2022
#
# This version is modified for using as cross-compilation tool so you shouldn't pass arguments to it
# ATTENTION! PLEASE MODIFY BEFORE USING! THIS VERSION DOENSN'T PERFORM SOURCE DIR CHECKS!
# dylibbundler is required
#
# NOTE for bundling: dependent libraries should be placed to /opt/local/lib (if you downloaded them from MacPorts)
# That is required because dylibbundler don't work properly if libs aren't placed at their dependecy paths
# NOTE 2: if you used macportsutil to obtain libaries and if you specified a different for them,
# then macdylibbundler will probably parse dependencies since macportsutil can fix dependency paths

# cross-compiler
FPC=ppcrossx64
# build flags used both for main and headless
COMMONFLAGS="-g -gl -gs -TDarwin -XPx86_64-apple-darwin12- -XR/usr/local/osxcross/SDK/MacOSX10.8.sdk -Xd -Fl/opt/local/lib -Fu/usr/local/osxcross/SDK/MacOSX10.8.sdk/usr/lib"
# default binary build flags
MAINFLAGS="-dUSE_SDL2 -dUSE_SDLMIXER -dUSE_NINIUPNPC -dENABLE_HOLMES -oDoom2DF Doom2DF.lpr"
# headless server build flags
HEADLESSFLAGS="-dUSE_SYSSTUB -dUSE_GLSTUB -dHEADLESS -dUSE_SDLMIXER -oDoom2DF_H Doom2DF.lpr"
# command for running dylibbundler
DYLIBBUNDLER="dylibbundler -ns -b -od -of"
# utility for creating DMG file (mkisofs or genisoimage)
PACKUTIL=mkisofs
# path to project files
SRCDIR=/home/vlad/projects/d2df-sdl
# path to game resources
RESPATH=/home/vlad/windf
# directory for temporary files relative
TMPDIR="/home/vlad/dfbuilddir/tmp"
# directory where bundle will be placed
OUTDIR="/home/vlad/dfbuilddir/Doom2DF.app"

# ----------------------------------------------------------------------------------------- #

#flags
# if set to 1, script will fix libraries' dependecy paths
FLAG_L=1
# if set to 1, script will pack bundle to DMG
FLAG_P=1

# ----------------------------------------------------------------------------------------- #

echo ""
echo "Doom 2D: Forever autobuild script for OS X - v1.0 (c) fl0atingzero, 2022"
echo ""


if [ -z "$SRCDIR" ]; then
	echo "ERROR: source dir $SRCDIR is required, but not provided or empty"
	exit -1
fi

if [ -z "$RESPATH" ]; then
	echo "ERROR: resources path $RESPATH is required, but not provided or empty"
	exit -1
fi

# ----------------------------------------------------------------------------------------- #

# uncomment for debugging

#echo "SRCDIR: $SRCDIR"
#echo "OUTDIR: $OUTDIR"
#echo "TMPDIR: $TMPDIR"
#echo "RESPATH: $RESPATH"
#echo "FLAG_P: $FLAG_P"
#echo "FLAG_L: $FLAG_L"
#read

echo "# ----------------------------------------------------------------------------------------- #"

echo "check for source directory presence"

if ! [ -e $SRCDIR/src/game/Doom2DF.lpr ];
then
    echo "ERROR with sourcedir $SRCDIR"
    exit -1
fi

echo ""
echo "check for resource directory"
echo ""
echo "Checking resources path: $RESPATH"

for RESNAME in "$RESPATH/data" "$RESPATH/maps" "$RESPATH/wads"; do
    if [ -d $RESNAME ];
    then
        echo " $RESNAME ok"
    else
        echo "ERROR: $RESNAME not found!"
        exit -1
    fi
done
echo "# ----------------------------------------------------------------------------------------- #"
# main part
echo ""
echo "main_part" 

echo ""
echo "checking for Doom2DF.app - if present we delete it"

if [ -d $OUTDIR ]; then
    echo "$OUTDIR found - trying to delete it"
    rm -rf $OUTDIR
fi

# creating new Doom2DF.app

echo ""
echo "Creating new $OUTDIR"
cp -rv $SRCDIR/macosx/Doom2DF.app.base $OUTDIR

echo ""
echo "checking for tmp - if present we clean it, if not - create"

if [ -d $TMPDIR ];
then
    echo "tempdir $TMPDIR found - trying to clean"
    find $TMPDIR -mindepth 1 -delete
else
	echo "tempdir $TMPDIR not found - creating"
	mkdir -v $TMPDIR
fi

# create build-metadata file
echo ""
echo $(grep "NET_PROTOCOL_VER =" $SRCDIR/src/game/g_net.pas | grep -Eo '[[:digit:]]*' && date +%d/%m/%Y\ %T) > $OUTDIR/../osx-x86_64-d2df-latest-version.txt

echo "# ----------------------------------------------------------------------------------------- #"

echo "building from source"

cd $SRCDIR/src/game

export D2DF_BUILD_HASH="$(git rev-parse HEAD)"

# building headless

echo ""
echo "Building headless:"
echo ""
$FPC $COMMONFLAGS -FU$TMPDIR -FE$OUTDIR/Contents/MacOS $HEADLESSFLAGS 
# clean tmp files

echo ""
echo "Cleaning temporary files:"
echo ""
#rm -rf $TMPDIR/* $OUTDIR/Contents/MacOS/{link.res,ppas*}
find $TMPDIR -mindepth 1 -delete
find $OUTDIR/Contents/MacOS/ \( -name "link.res" -o -name "ppas*"\) -delete
echo "# ----------------------------------------------------------------------------------------- #"

# building main

echo ""
echo "Building main:"
echo ""
$FPC $COMMONFLAGS -FU$TMPDIR -FE$OUTDIR/Contents/MacOS $MAINFLAGS
echo "# ----------------------------------------------------------------------------------------- #"
echo ""

# copying resources:
echo "Copying resources:"
cp -rv $RESPATH/data $RESPATH/maps $RESPATH/wads $OUTDIR/Contents/Resources/
echo "# ----------------------------------------------------------------------------------------- #"

# checking for "-l" flag
if [ "$FLAG_L" == "1" ]; then

    # fix library dependencies paths
    echo ""
    echo "Fixing library dependencies paths"

    cd $OUTDIR/Contents/MacOS
    echo ""
    $DYLIBBUNDLER -d $OUTDIR/Contents/libs -x Doom2DF
    echo "# ----------------------------------------------------------------------------------------- #"
    echo ""
    $DYLIBBUNDLER -d $OUTDIR/Contents/libs -x Doom2DF_H
echo "# ----------------------------------------------------------------------------------------- #"

fi
echo ""
echo "main actions are done"

# checking for "-p" parameter

if [ "$FLAG_P" == "1" ]; then

    # packing bundle to DMG

    cd $OUTDIR/..

    echo ""
    echo "Creating $(pwd)/Doom2DF.dmg"
    echo ""

    if [ -e $OUTDIR/../Doom2DF.root ]; then
        echo "Doom2DF.root found, trying to delete"
        rm -rf $OUTDIR/../Doom2DF.root
        echo ""
    fi

    echo "creating new Doom2DF.root"
    mkdir -p Doom2DF.root
    echo ""
    cp -rf $OUTDIR  Doom2DF.root
    echo ""

    $PACKUTIL -D -V "Doom 2D Forever" -no-pad -r -apple -file-mode 0555 -o Doom2DF.dmg Doom2DF.root
    echo ""

    echo "trying to delete unnecessary Doom2DF.root"
    find $OUTDIR/../Doom2DF.root -delete

fi

echo ""
