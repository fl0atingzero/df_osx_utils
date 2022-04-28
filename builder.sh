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
# warning: this version doensn't perform source dir checks
#

BUILDFLAGS="-dUSE_SDL2 -dUSE_SDLMIXER -dUSE_HOLMES -Fu/opt/local/lib -Fu/usr/local/lib"
# default binary build flags
HEADLESSFLAGS="-dUSE_SDLMIXER -dHEADLESS -Fu/opt/local/lib -Fu/usr/local/lib"
# headless server build flags
DYLIBBUNDLER="dylibbundler -ns -b -od -of"
# command for running dylibbundler
PACKUTIL=mkisofs
# utility for creating DMG file (mkisofs or genisoimage)

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

# ----------------------------------------------------------------------------------------- #

# check for source directory presence

if ! [ -e $SRCDIR/src/game/Doom2DF.lpr ];
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

# building from source

cd $SRCDIR/src/game

export D2DF_BUILD_HASH="$(git rev-parse HEAD)"

# building headless version

echo ""
echo "Building headless version:"
echo ""
fpc -g -gl -gs $HEADLESSFLAGS -FU"$TMPDIR" -FE"$OUTDIR/Contents/MacOS" -oDoom2DF_H Doom2DF.lpr

# clean tmp files

echo ""
echo "Cleaning temporary files:"
echo ""
rm -rvf $TMPDIR/* $OUTDIR/Contents/MacOS/{link.res,ppas*}

# building main version

echo ""
echo "Building main version:"
echo ""
fpc -g -gl -gs $BUILDFLAGS -FU"$TMPDIR" -FE"$OUTDIR/Contents/MacOS" -oDoom2DF Doom2DF.lpr

# copying resources:

echo ""
echo "Copying resources:"
cp -rv $RESPATH/data $RESPATH/maps $RESPATH/wads $OUTDIR/Contents/Resources/

# checking for "-l" parameter
# fix binary dependencies

if [ "$FLAG_L" == "0" ]; then

	# fix library paths
	echo ""
	echo "Fixing library paths"
	
	cd $OUTDIR/Contents/MacOS
	
	$DYLIBBUNDLER -d $OUTDIR/Contents/libs -x Doom2DF
	$DYLIBBUNDLER -d $OUTDIR/Contents/libs -x Doom2DF_H

fi

#done main operations

# checking for "-p" parameter

if [ "$FLAG_P" == "1" ]; then

# trying packing utility

	if hash $PACKUTIL 2>/dev/null; then
   
        cd $OUTDIR/..
        
        echo ""
        echo "Creating $(pwd)/Doom2DF.dmg"
        echo ""
        
        if [ -e $OUTDIR/../Doom2DF.root ]; then
        	echo "Doom2DF.root found, trying to delete"
        	rm -rv $OUTDIR/../Doom2DF.root
        	echo ""
        fi
        
        echo "creating new Doom2DF.root"
        mkdir -p Doom2DF.root
        echo ""
        cp -rv $OUTDIR  Doom2DF.root
        echo ""
        
        $PACKUTIL -D -V "Doom 2D Forever" -no-pad -r -apple -file-mode 0555 -o Doom2DF.dmg Doom2DF.root
        echo ""
        
        echo "trying to delete unnecessary Doom2DF.root"
        rm -rv $OUTDIR/../Doom2DF.root
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

