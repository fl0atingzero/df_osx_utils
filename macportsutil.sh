#!/bin/bash

# this script gets URL links for specific packages from MacPorts (for specific version of OS X), downloads and extracts them

OUTDIR="/opt/local"
URL="https://packages.macports.org"
LIBS=("libsdl2"
      "libsdl2_mixer"
      "libmodplug"
      "libvorbis"
      "libogg"
      "flac"
      "mpg123"
      "opusfile"
      "libopus"
      "miniupnpc")
DARWINVER="12"
ARCH="x86_64"

# ----------------------------------------------------------------------------- #
# FLAG_D = 1 - script will parse all *.dylib files in $OUTDIR/lib with
# install_name_tool to change paths from /opt/local/lib to $OUTDIR/lib
# useful for cross-compilation to put libs somewhere other than /opt/local/lib

FLAG_D=0
OTOOL="otool -L"
INSTALLNAMETOOL="install_name_tool"

# ----------------------------------------------------------------------------- #

PATTERN="darwin_$DARWINVER\.$ARCH"

LIBFNAMES=()

echo "This script will help you to obtain specific libs from MacPorts' repository"

echo "Getting links"
echo ""

for LIBNAME in ${LIBS[*]}
do
    # this horrible thing parses macports' download page and find required link

    ANSWER=$( curl -s "$URL/$LIBNAME/" | grep -Eo "$LIBNAME[^>]+\.$PATTERN\.tbz2" | grep -v "universal" | tr " " "\n" | sort | uniq | tail -n 1 )

    # there is another way to get required library name which seems to be more complicated

    #ANSWER=$( curl -s "$URL" | grep -Eo "(href=\")[^>]+($PATTERN.tbz2\")>" | grep -v "universal" | tr " " "\n" | sort | uniq | tail -n 1 | cut -c 7- | rev | cut -c 3- | rev )
    # curl -s "$URL" - we'll get page where links are listed
    # grep -Eo '(href=\")[^>]+($PATTERN.tbz2\")>' - then we'll parse links that meets our pattern
    # grep -v "universal" - we'll also exclude universal binaries because we don't need them
    # tr " " "\n" - replace whitespace with newline characters
    # sort - sort strings
    # uniq - remove duplicate strings
    # tail -n 1 - remove all but last string
    # cut -c 7- | rev - cut first 7 characters then reverse string
    # cut -c 3- | rev - cut first (actually last) 3 characters then reverse string to get final answer
    LIBFNAMES+=("$ANSWER")
    echo $LIBNAME: $URL/$LIBNAME/$ANSWER
done

echo ""
if [ -d "$OUTDIR/libs" ]; then
    echo "$OUTDIR/libs directory already exists, trying to delete it"
    rm -rv $OUTDIR/libs
fi

mkdir $OUTDIR

echo ""
echo "Now downloading and extracting libs..."
cd $OUTDIR

for i in ${!LIBS[@]}
do
    echo ""
    echo "-->${LIBS[$i]}"
    curl -O $URL/${LIBS[$i]}/${LIBFNAMES[$i]}
    echo ""
    echo "extracting ${LIBS[$i]}..."
    tar --strip-components=3 -xjvf ${LIBFNAMES[$i]} ./opt/local/lib
done

# parsing dylibs

if [ "$FLAG_D" = 1 ]; then
    echo "Now we'll parse dylibs in $OUTDIR"

    cd $OUTDIR
    echo ""
    echo "List of dylibs:"
    find . -type f -name "*.dylib" | cut -c 3-
    echo ""
    for DNAME in $(find . -type f -name "*.dylib" | cut -c 3-)
    do
        echo "processing $DNAME:"
        LNAME=$OUTDIR/
        LNAME+=$($OTOOL $DNAME |  grep -Eo -e '.*\.dylib' | grep "/opt/local/" | head -n 1 | tr -d "\t" | cut -c 12-)
        echo "$INSTALLNAMETOOL -id $LNAME $DNAME"
        $INSTALLNAMETOOL -id $LNAME $DNAME
        for DEPNAME in $($OTOOL $DNAME |  grep -Eo -e '.*\.dylib' | grep "/opt/local/" | tail +1 | tr -d "\t")
        do      
            FIXNAME=$OUTDIR/
            FIXNAME+=$(echo $DEPNAME | cut -c 12-)

            echo "$INSTALLNAMETOOL -change $DEPNAME $FIXNAME $DNAME"
            $INSTALLNAMETOOL -change $DEPNAME $FIXNAME $DNAME
        done
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    done

fi
