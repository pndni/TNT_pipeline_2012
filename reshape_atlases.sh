#!/bin/bash

set -e
set -u

echo "Singularity name:" > models/reshape_log.txt
echo "$SINGULARITY_NAME" >> models/reshape_log.txt
echo "mincreshape version:" >> models/reshape_log.txt
mincreshape -version >> models/reshape_log.txt
mincreshape -normalize -unsigned -byte -image_range 0 255 -valid_range 0 255 models/SYS808_atlas_labels_nomiddle{,_rs}.mnc
mincreshape -normalize -unsigned -byte -image_range 0 255 -valid_range 0 255 models/mask_left_oncolinnl_7{,_rs}.mnc
mincreshape -normalize -unsigned -byte -image_range 0 255 -valid_range 0 255 models/mask_right_oncolinnl_7{,_rs}.mnc

