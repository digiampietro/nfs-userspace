#!/bin/bash
# MYDIR is the directory where this script is
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $MYDIR
docker build -t="digiampietro/nfs-userspace" .
