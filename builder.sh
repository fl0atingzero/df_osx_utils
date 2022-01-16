!/bin/bash

# DOOM 2D: FOREVER BUILDER AND PACKER FOR OS X - v0.9
# (c) fl0atingzero, 2022
#
# USAGE: df_autobuild_osx.sh [SRCDIR] [RESPATH] [flags]
#     <SRCDIR> - directory where source files are placed
#     <RESPATH> - path to resources (usually win3d-d2df-latest.zip unpacked), directory containing "data", "maps" and "wads" dirs
#     -p (optional) - pack to DMG using mkisofs/genisoimage (if present)
#     -y (optional) - do NOT ask for pressing any key after finishing build process
#	  -l (optional) - do NOT resolve binary dependecies
#     
# Python 3 is REQUIRED for libs packing (for mackpack), so it's supposed that it is in path
# ATTENTION! PLEASE MODIFY BEFORE USING!
# warning: this version doensn't perform source dir checks
#

TMPDIR="$SRCDIR/macosx/tmp"
# directory for temporary files relative to srcdir
OUTDIR="$SRCDIR/macosx/Doom2DF.app"
# directory where bundle will be placed
BUILDFLAGS="-dUSE_SDL2 -dUSE_SDLMIXER -dUSE_HOLMES"
# default binary build flags
HEADLESSFLAGS="-dUSE_SOUNDSTUB -dHEADLESS"
# headless server build flags
MACPACK="macpack" #python3 $SRCDIR/macpack/patcher.py"
# command for running macpack (Python 3 is required)
PACKUTIL=mkisofs
# utility for creating DMG file (mkisofs or genisoimage)

#TODO: CLI, 110, 127, 141, 148


# ----------------------------------------------------------------------------------------- #

echo "Doom 2D: Forever autobuild script for OS X - v0.9 (c) fl0atingzero, 2022"
echo ""

# check for command line arguments count - should be not less than 3

if [ "$#" -lt 3 ]; #if_args
then
    echo "Not enough arguments"
    echo ""
    echo "USAGE: df_autobuild_osx.sh [SRCDIR] [RESPATH] [flags]"
    echo "    <SRCDIR> - directory where source files are placed"
    echo "    <RESPATH> - path to resources (usually win3d-d2df-latest.zip unpacked), directory containing "data", "maps" and "wads" dirs"
    echo "    -p (optional) - pack to DMG using mkisofs/genisoimage (if present)"
    echo "    -y (optional) - do not ask for pressing any key after finishing build process"
    echo "	  -l (optional) - do NOT resolve binary dependecies"
else

# now set variables' values

#SRCDIR="."
SRCDIR=$(echo $1 | sed 's:/*$::')
RESPATH=$(echo $2 | sed 's:/*$::')


# check for source directory presence

if not [ -e $SRCDIR/src/game/Doom2DF.lpr ];
then
    echo "ERROR with sourcedir $SRCDIR"
    exit -1
fi

# check for resource directory

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

#main_part

echo ""

# checking for Doom2DF.app - if present we delete it

if [ -d $OUTDIR ]; then
    echo "$OUTDIR found - trying to delete it"
    rm -rv $OUTDIR
fi

# creating new Doom2DF.app

echo ""
echo "Creating new $OUTDIR"
cp -rv $SRCDIR/macosx/Doom2DF.app.base $OUTDIR

# checking for tmp - if present we clean it, if not - create

if [ -d $TMPDIR ];
then
    echo "tempdir $TMPDIR found - trying to clean"
    rm -rv $TMPDIR/*
else
	echo "tempdir $TMPDIR not found - creating"
	mkdir -v $TMPDIR
fi

# copying resources: FIXME - should be performed after compiling

echo ""
echo "Copying resources:"
cp -rv $RESPATH/data $RESPATH/maps $RESPATH/wads $OUTDIR/Contents/Resources/

# building from source

cd $SRCDIR/src/game

# clean tmp files - UNNECESSARY AT FIRST ATTEMPT

echo ""
echo "Cleaning temporary files:"
echo ""
rm -rvf $SRCDIR/$TMPDIR/* $SRCDIR/$OUTDIR/{link.res,ppas*,Doom2DF*}

# building headless version FIXME - some arguments are unnecessary or wrong

echo ""
echo "Building headless version:"
echo ""
fpc -g -gl -gs -O3 $HEADLESSFLAGS -FU"$SRCDIR/$TMPDIR" -FE"$SRCDIR/$OUTDIR" -Ff"$SRCDIR/$LIBDIR" -Fu"$SRCDIR/$LIBDIR" -Fl"$SRCDIR/$LIBDIR" -oDoom2DF_H Doom2DF.lpr

# clean tmp files

echo ""
echo "Cleaning temporary files:"
echo ""
rm -rvf $SRCDIR/$TMPDIR/* $SRCDIR/$OUTDIR/{link.res,ppas*}

# building main version FIXME - some arguments are unnecessary or wrong

echo ""
echo "Building main version:"
echo ""
fpc -g -gl -gs -O3 $BUILDFLAGS -FU"$SRCDIR/$TMPDIR" -FE"$SRCDIR/$OUTDIR" -Ff"$SRCDIR/$LIBDIR" -Fu"$SRCDIR/$LIBDIR" -Fl"$SRCDIR/$LIBDIR" -oDoom2DF Doom2DF.lpr

# fix library paths FIXME - should be reimplemented with macpack
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

