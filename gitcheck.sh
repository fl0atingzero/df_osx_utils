#!/bin/bash
REPODIR="d2df-sdl"
cd $REPODIR

OUTPUT=$( LC_ALL=en_US git pull origin master 2>&1 | grep 'fatal\|error\|Already up to date' )
if [ "${#OUTPUT}" -ne "0" ]; then
    echo $OUTPUT | grep 'fatal\|error';
    if [ -n "$(echo $OUTPUT | grep 'fatal\|error')" ]; then
        echo "An error occurred when fetching updates:"
        echo $OUTPUT
        exit -1
    else
        echo "There are no updates on remote"
    fi
else
    echo "There are updates on remote, performing actions"
    #do something here
    # for example:
    # /bin/bash -e ./crossbuilder.sh 2>&1 | tee /home/vlad/dfcross/buildlogs/build_$(date +%F_%H-%M-%S).log
fi
