#!/bin/bash

# DOOM 2D: FOREVER AUTOBUILDER FOR OS X - v0.11
# (c) fl0atingzero, 2021
#
# USAGE: df_autobuild_osx.sh <SRCDIR> <DLIBDIR> <RESPATH>
#     <SRCDIR> - directory where source files are placed
#     <DLIBDIR> - directory where dynamic libs are placed
#     <RESPATH> - path to resources (usually win3d-d2df-latest.zip unpacked), directory containing "data", "maps" and "wads" dirs
#     -p (optional) - pack to DMG using mkisofs/genisoimage (if present)
#     -y (optional) - do not ask for pressing any key after finishing build process
#
# ATTENTION! PLEASE MODIFY BEFORE USING!
# warning: this version doensn't perform source dir checks
#

TMPDIR="macosx/tmp"
# directory for temporary files relative to srcdir
OUTDIR="macosx/Doom2DF.app/Contents/MacOS"
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
PACKUTIL=mkisofs
# utility for creating DMG file (mkisofs or genisoimage)

# ----------------------------------------------------------------------------------------- #

echo "Doom 2D: Forever autobuild script for OS X - v0.11 (c) fl0atingzero, 2021"
echo ""

# check for command line arguments count - should be not less than 3

if [ "$#" -lt 3 ]; #if_args
then
    echo "Not enough arguments"
    echo ""
    echo "USAGE: df_autobuild_osx.sh <SRCDIR> <DLIBDIR> <RESPATH> [-p] [-y]"
    echo "    <SRCDIR> - directory where source files are placed"
    echo "    <DLIBDIR> - directory where dynamic libs are placed"
    echo "    <RESPATH> - path to resources (usually win3d-d2df-latest.zip unpacked), directory containing "data", "maps" and "wads" dirs"
    echo "-p (optional) - pack to DMG using mkisofs/genisoimage (if present)"
    echo "-y (optional) - do not ask for pressing any key after finishing build process"
else

# now set variables' values
SRCDIR=$(echo $1 | sed 's:/*$::')
DLIBDIR=$(echo $2 | sed 's:/*$::')
RESPATH=$(echo $3 | sed 's:/*$::')

# check for libs directory

echo "Checking libs directory for integrity" 
echo "  libs directory: $DLIBDIR"

if [ -d $DLIBDIR ]; #if_dlibdir
then
    echo "Ok, directory exists"
    echo ""

# check for resource directory

echo "Checking resources path" 
echo "  resources directory: $RESPATH"

RESPATH_OK=1 # flag for checking resources path

for RESNAME in "$RESPATH/data" "$RESPATH/maps" "$RESPATH/wads"; do
    if [ -d $RESNAME ];
    then
        echo " + $RESNAME"
    else
        RESPATH_OK=0
        echo "ERROR: $RESNAME not found!"
    fi
done

if [ $RESPATH_OK -eq "1" ]; #if_respath
then

#main_part

echo ""

# checking for Doom2DF.app - if present we delete it

if [ -d $SRCDIR/macosx/Doom2DF.app ]; then
    echo "Cleaning founded Doom2DF.app..."
    rm -rv $SRCDIR/macosx/Doom2DF.app
fi

# creating new Doom2DF.app

echo ""
echo "Creating new Doom2DF.app"
cp -rv $SRCDIR/macosx/Doom2DF.app.base $SRCDIR/macosx/Doom2DF.app

# checking for tmp - if present we delete it

if [ -d $SRCDIR/$TMPDIR ]; then
    echo "Cleaning founded $TMPDIR..."
    rm -rv $SRCDIR/$TMPDIR
fi

# creating new tmpdir

echo ""
echo "Creating new $TMPDIR"
mkdir -v $SRCDIR/$TMPDIR

# creating libs directory

echo ""
echo "Creating libs directory"
mkdir -v $SRCDIR/$LIBDIR

# copying libs to directory

echo ""
echo "Copying libs:"
cp -v $DLIBDIR/* $SRCDIR/$LIBDIR

# copying resources

echo ""
echo "Copying resources:"
cp -rv $RESPATH/data $RESPATH/maps $RESPATH/wads $SRCDIR/$OUTDIR/../Resources/

# building from source

cd $SRCDIR/src/game

# clean tmp files

echo ""
echo "Cleaning temporary files:"
echo ""
rm -rvf $SRCDIR/$TMPDIR/* $SRCDIR/$OUTDIR/{link.res,ppas*,Doom2DF*}

# building headless version

echo ""
echo "Building headless version:"
echo ""
fpc -g -gl -gs -O3 $HEADLESSFLAGS -FU"$SRCDIR/$TMPDIR" -FE"$SRCDIR/$OUTDIR" -Ff"$SRCDIR/$LIBDIR" -Fu"$SRCDIR/$LIBDIR" -Fl"$SRCDIR/$LIBDIR" -oDoom2DF_H Doom2DF.lpr

# clean tmp files

echo ""
echo "Cleaning temporary files:"
echo ""
rm -rvf $SRCDIR/$TMPDIR/* $SRCDIR/$OUTDIR/{link.res,ppas*}

# building main version

echo ""
echo "Building main version:"
echo ""
fpc -g -gl -gs -O3 $BUILDFLAGS -FU"$SRCDIR/$TMPDIR" -FE"$SRCDIR/$OUTDIR" -Ff"$SRCDIR/$LIBDIR" -Fu"$SRCDIR/$LIBDIR" -Fl"$SRCDIR/$LIBDIR" -oDoom2DF Doom2DF.lpr

# fix library paths
echo ""
echo "Fixing library paths for:"

cd $SRCDIR/$LIBDIR
for LIBNAME in *; do
    echo "  $LIBNAME"
    cd $SRCDIR/src/game
    install_name_tool -change $DLIBPATHMAIN/$LIBNAME @executable_path/$LIBS/$LIBNAME $SRCDIR/$OUTDIR/Doom2DF
    install_name_tool -change $DLIBPATHMAIN/$LIBNAME @executable_path/$LIBS/$LIBNAME $SRCDIR/$OUTDIR/Doom2DF_H
done

#done main operations

# checking for "-p" parameter

if [ "$4" == "-p" -o "$5" == "-p" ]; then

# trying packing utility

if hash $PACKUTIL 2>/dev/null; then
        
        echo ""
        echo "Creating $SRCDIR/macosx/Doom2DF.dmg"
        echo ""
        
        cd $SRCDIR/macosx
        mkdir -p Doom2DF.root
        echo ""
        cp -rv Doom2DF.app  Doom2DF.root
        
        $PACKUTIL -D -V "Doom 2D Forever" -no-pad -r -apple -file-mode 0555 -o Doom2DF.dmg Doom2DF.root
        
    else
        echo "ERROR: $PACKUTIL not found!"
fi
fi

# checking for "-y" parameter

if [ "$4" == "-y" -o "$5" == "-y" ]; then
    echo "Building complete!"
else
    echo "Building complete! Press any key to exit builder..."
    read -n 1 -s -r
fi

else
    echo "Error with resources path!"
fi #fi_respath

else
    echo "ERROR: Directory $DLIBDIR not found!"
fi #fi_dlibdir

fi #fi_args

#done
