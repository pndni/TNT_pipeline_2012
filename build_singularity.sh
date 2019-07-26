#!/bin/bash

set -e

if ! ver=$(git describe --tags --exact-match 2> /dev/null)
then
    ver=$(git rev-parse HEAD)
    ver=${ver:0:10}
fi
if ! git diff --quiet
then
    ver=${ver}-dirty
fi

outimage=TNT_pipeline_v1-$ver.simg
if [ -e "$outimg" ]
then
    >&2 echo "output image exists"
    exit 1
fi

TMPDIR=$(mktemp -d -p /tmp_disk)
export TMPDIR

dockerimg=localhost:5000/tnt_pipeline_v1:$ver
docker build -t $dockerimg .
docker push $dockerimg

SINGULARITY_TMPDIR=$(mktemp -d -p /tmp_disk)
export SINGULARITY_TMPDIR

export SINGULARITY_NOHTTPS=1
/opt/singularity/2.5.2/bin/singularity build $outimage docker://$dockerimg
rm -rf $TMPDIR
rm -rf $SINGULARITY_TMPDIR