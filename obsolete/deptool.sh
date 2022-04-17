#!/bin/bash

# DepTool - bash-written utility to recursively parse dependencies of Mach-O binaries
# It is not full-fledged tool, but it could be helpful with compiling Doom 2D: Forever binaries and baking bundles for OS X
#
# USAGE:
#
# deptool.sh <target binary> <additional mask for otool output> <path where to look for dependent libs>

OTOOL="otool"
TARGETBINARY=$1
MASK=$2
BINPATH=$3


function GetDependencies

{
    $OTOOL -L "$1" | tail -n +2 | sed -e 's/^[ \t]*//' | sed -e 's/(compatibility.*//' | grep ".dylib"  | grep -e $2 | rev | cut -d/ -f1 | rev
    # DEPLIST=($($OTOOL etc blah-blah))
}

function RecursiveSearch
{
    local currentbin=$1
    local currentpath=$2
    local DEPLIST=()
    local otoolout=""
    if [ ! -d $currentpath ]; then
        echo "error: $currentpath is not found or it isn't directory"
        return 1
    fi

    cd $currentpath

    otoolout=$($OTOOL -L "$currentbin" 2>&1 > /dev/null)

    if [ ! "$otoolout" == "" ]; then
        echo "$otoolout"
        return 1
    fi

    DEPLIST=($( GetDependencies $currentbin $MASK))
    echo "$currentbin:"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    for i in ${!DEPLIST[@]}
    do
        echo "${DEPLIST[$i]}"
    done
    echo ""

    for i in ${!DEPLIST[@]}
    do
        if [ ! "${DEPLIST[$i]}" = "$currentbin" ]; then
            RecursiveSearch ${DEPLIST[$i]} $BINPATH
        fi
    done
}

# main part
echo "deptool (c) fl0atingzero, 2022"
echo "USAGE: deptool.sh <target binary> <additional mask for otool output> <path where to look for dependent libs>"
echo ""

RecursiveSearch $TARGETBINARY $BINPATH
