#!/bin/bash

set -e
set -u

ver=$1
tmpdir=$(mktemp -d)

git clone git@github.com:pndni/TNT_pipeline_2012.git $tmpdir
pushd $tmpdir

git checkout $ver
./download_software.sh
docker build -t pndni/tnt_pipeline_2012:$ver .
docker push pndni/tnt_pipeline_2012:$ver

popd
rm -rf $tmpdir
