#!/bin/bash

#this script is for getting URL links to download specific links from MacPorts for specific OS X

URL="https://packages.macports.org"
LIBS=("libsdl2"
      "libsdl2_mixer"
      "libmodplug"
      "libvorbis"
      "libogg"
      "flac"
      "mpg123"
      "opusfile"
      "libopus")
DARWINVER="12"
ARCH="x86_64"

PATTERN="darwin_$DARWINVER\.$ARCH"

LIBURL=""

for LIBNAME in ${LIBS[*]}
do
    # this horrifying thing actually parses macports' download page and find required link

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
    LIBURL+="$URL/$LIBNAME/$ANSWER "
    echo $LIBNAME: $URL/$LIBNAME/$ANSWER
done
