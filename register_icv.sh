#!/bin/bash

set -e
set -u

moving=models/SYS_808.mnc
fixed=from_niagara_tpaus_home_MODELS/SYS808_icv/FWHM2_STEP2.mnc
mask=from_niagara_tpaus_home_MODELS/SYS808_icv/cranium_mask_Jan9_2012.mnc

/opt/singularity/2.5.2/bin/singularity exec --cleanenv TNT_pipeline_1-98b26b4.simg \
mincmath -gt -const 0 $fixed register_icv_wd/FWHM2_STEP2_mask.mnc

/opt/singularity/2.5.2/bin/singularity exec --cleanenv TNT_pipeline_1-98b26b4.simg \
mincANTS 3 -m PR[$fixed,$moving,1,4] \
--use-Historgram-Matching \
--number-of-affine-iteratons "10000x10000x10000x10000x10000" \
--MI-option "32x16000" \
--affine-gradient-descent-option "0.5x0.95x1.e-4x1.e-4" \
-r "Gauss[3,0]" -t "SyN[0.5]" \
-o icv_space_to_sys_808.xfm -i "20x20x20"

/opt/singularity/2.5.2/bin/singularity exec --cleanenv TNT_pipeline_1-98b26b4.simg \
mincresample \
-transformation icv_space_to_sys_808.xfm \
-like $moving \
-near \
-labels \
$mask models/SYS808_icv.mnc

/opt/singularity/2.5.2/bin/singularity exec --cleanenv TNT_pipeline_1-98b26b4.simg \
mincresample \
-transformation icv_space_to_sys_808.xfm \
-like $moving \
-near \
-labels \
$fixed register_icv_wd/FWHM2_STEP2_tr.mnc
