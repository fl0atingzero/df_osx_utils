#!/bin/bash

# DOOM 2D: FOREVER BUILDER AND PACKER FOR OS X - v0.9
# (c) fl0atingzero, 2022
#
# USAGE: builder.sh [options]
#     -s <SRCDIR> (REQUIRED)- directory where source files are placed
#     -r <RESPATH> (REQUIRED) - path to resources (usually win3d-d2df-latest.zip unpacked), directory containing "data", "maps" and "wads" dirs
#     -p (optional) - pack to DMG using mkisofs/genisoimage (if present)
#     -y (optional) - do NOT ask for pressing any key after finishing build process
#     -l (optional) - do NOT resolve binary dependecies
#     -h (optional) - show help
# dylibbundler is required
# ATTENTION! PLEASE MODIFY BEFORE USING!
# WARNING: THIS VERSION DOENSN'T PERFORM SOURCE DIR CHECKS
#
# build flags used both for main and headless
COMMONFLAGS="-g -gl -gs -Fu/opt/local/lib"
# default binary build flags
MAINFLAGS="-dUSE_SDL2 -dUSE_SDLMIXER -dUSE_HOLMES -oDoom2DF Doom2DF.lpr"
# headless server build flags
HEADLESSFLAGS="-dUSE_GLSTUB -dUSE_SDLMIXER -dHEADLESS -oDoom2DF_H Doom2DF.lpr"
# command for running dylibbundler
DYLIBBUNDLER="dylibbundler -ns -b -od -of"
# utility for creating DMG file (mkisofs or genisoimage)
PACKUTIL=mkisofs


# ----------------------------------------------------------------------------------------- #

#flags
FLAG_P=0
FLAG_Y=0
FLAG_L=0

# ----------------------------------------------------------------------------------------- #

printhelp ()
{
	echo "USAGE: builder.sh [options]"
    echo "    -s <SRCDIR> - directory where source files are placed"
    echo "    -r <RESPATH> - path to resources (usually win3d-d2df-latest.zip unpacked), directory containing data, maps and wads dirs"
    echo "    -p (optional) - pack to DMG using mkisofs/genisoimage (if present)"
    echo "    -y (optional) - do not ask for pressing any key after finishing build process"
    echo "    -l (optional) - do not resolve binary dependencies"
    echo "    -h or no args - show this help"
    echo ""
    exit 0	
}

# ----------------------------------------------------------------------------------------- #

echo ""
echo "Doom 2D: Forever autobuild script for OS X - v0.9 (c) fl0atingzero, 2022"
echo ""

# check for command line arguments count - should be not less than 1

if [ "$#" -lt 1 ]; then
    echo "Not enough arguments"
    echo ""
	printhelp
fi

# CLI

while getopts "hs:r:pyl" flag
do
	case $flag in
		h) printhelp;;
		s) SRCDIR=$(echo $OPTARG | sed 's:/*$::');;
		r) RESPATH=$(echo $OPTARG | sed 's:/*$::');;
		p) FLAG_P=1;;
		y) FLAG_Y=1;;
		l) FLAG_L=1;;
	esac
done

# checking for presence of required params

if [ -z "$SRCDIR" ]; then
	echo "ERROR: source dir $SRCDIR is required, but not provided or empty"
	exit -1
fi

if [ -z "$RESPATH" ]; then
	echo "ERROR: resources path $RESPATH is required, but not provided or empty"
	exit -1
fi

# ----------------------------------------------------------------------------------------- #

TMPDIR="$SRCDIR/macosx/tmp"
# directory for temporary files relative to srcdir
OUTDIR="$SRCDIR/macosx/Doom2DF.app"
# directory where bundle will be placed

# uncomment for debugging

#echo "SRCDIR: $SRCDIR"
#echo "OUTDIR: $OUTDIR"
#echo "TMPDIR: $TMPDIR"
#echo "RESPATH: $RESPATH"
#echo "FLAG_P: $FLAG_P"
#echo "FLAG_L: $FLAG_L"
#echo "FLAG_Y: $FLAG_Y"
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
#main_part
echo ""
echo "main_part"

echo ""
echo "checking for Doom2DF.app - if present we delete it"

if [ -d $OUTDIR ]; then
    echo "$OUTDIR found - trying to delete it"
    rm -rvf $OUTDIR
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

echo ""
echo "# ----------------------------------------------------------------------------------------- #"

echo "building from source"

cd $SRCDIR/src/game

export D2DF_BUILD_HASH="$(git rev-parse HEAD)"

# building headless

echo ""
echo "Building headless:"
echo ""
fpc $COMMONFLAGS -FU$TMPDIR -FE$OUTDIR/Contents/MacOS $HEADLESSFLAGS

# clean tmp files

echo ""
echo "Cleaning temporary files:"
echo ""
find $TMPDIR -mindepth 1 -delete && $OUTDIR/Contents/MacOS/{link.res,ppas*}
echo "# ----------------------------------------------------------------------------------------- #"

# building main

echo ""
echo "Building main:"
echo ""
fpc $COMMONFLAGS -FU$TMPDIR -FE$OUTDIR/Contents/MacOS $MAINFLAGS
echo "# ----------------------------------------------------------------------------------------- #"
echo ""

# copying resources:
echo ""
echo "Copying resources:"
cp -rv $RESPATH/data $RESPATH/maps $RESPATH/wads $OUTDIR/Contents/Resources/
echo "# ----------------------------------------------------------------------------------------- #"

# checking for "-l" parameter
# fix binary dependencies

if [ "$FLAG_L" == "0" ]; then

	# fix library paths
	echo ""
	echo "Fixing library dependecies paths"
	
	cd $OUTDIR/Contents/MacOS
	echo ""

	$DYLIBBUNDLER -d $OUTDIR/Contents/libs -x Doom2DF
    echo "# ----------------------------------------------------------------------------------------- #"
    echo ""
	$DYLIBBUNDLER -d $OUTDIR/Contents/libs -x Doom2DF_H
    echo "# ----------------------------------------------------------------------------------------- #"
    echo ""
fi

# main actions are done
echo "main actions are done"

# checking for "-p" parameter

if [ "$FLAG_P" == "1" ]; then

# trying packing utility

	if hash $PACKUTIL 2>/dev/null; then

        # packing bundle to DMG

        cd $OUTDIR/..
        
        echo ""
        echo "Creating $(pwd)/Doom2DF.dmg"
        echo ""
        
        if [ -e $OUTDIR/../Doom2DF.root ]; then
        	echo "Doom2DF.root found, trying to delete"
        	rm -rvf $OUTDIR/../Doom2DF.root
        	echo ""
        fi
        
        echo "creating new Doom2DF.root"
        mkdir -p Doom2DF.root
        echo ""
        cp -rvf $OUTDIR Doom2DF.root
        echo ""
        
        $PACKUTIL -D -V "Doom 2D Forever" -no-pad -r -apple -file-mode 0555 -o Doom2DF.dmg Doom2DF.root
        echo ""
        
        echo "trying to delete unnecessary Doom2DF.root"
        find $OUTDIR/../Doom2DF.root -delete
        echo ""       
        
    else
 		echo "ERROR: $PACKUTIL not found!"
	fi
fi

# checking for "-y" parameter

if [ "$FLAG_Y" = "1" ]; then
    echo "Building complete!"
else
    echo "Building complete! Press any key to exit builder..."
    read -n 1 -s -r
fi

