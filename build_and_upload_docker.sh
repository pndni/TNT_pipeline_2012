#!/bin/bash

set -e
set -u

ver=$1
tmpdir=$(mktemp -d)

git clone --branch $ver git@github.com:pndni/TNT_pipeline_2012.git $tmpdir
pushd $tmpdir

./download_software.sh
docker build -t pndni/tnt_pipeline_2012:$ver .
docker push pndni/tnt_pipeline_2012:$ver
