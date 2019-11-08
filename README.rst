Overview
========

This is a recreation of the Toronto pipeline as it existed in
about 2012. It should *only* be used when compatibility with previous
runs is required. Even then, this does not produce pixel-perfect
results as compared to older runs. This is because mincANTS was
previously compiled with an intel compiler, which is not open source
and therefore hard to replicate. (If anybody knows how to get their
hands on an old version of icc, please open an issue so we can assess
feasibility.)

This pipeline has also been modified to include features that either
appear in later pipeliens are were often calculated in tandom,
specifically ICV and intensity calculation.

The other major change between this pipeline and the real 2012 version
is the patches to minc tools to fix discrete operations. See the
Dockerfile for specifics, but a rough idea can be found by looking at
these commits
`1 <https://github.com/BIC-MNI/libminc/commit/6ef58fe96d1505b5d21b7f9b165d89f957e57cd2>`_
`2 <https://github.com/BIC-MNI/minc-tools/commit/9e7058ef0bf78f4a5794a9fff459d9168a225aba>`_
`3 <https://github.com/BIC-MNI/minc-tools/commit/cc03c467df866a76f8a7eb0115ddc0fa10651fa1>`_
`4 <https://github.com/BIC-MNI/minc-tools/commit/d3b91663b16a23ff9097adda24a4fe48cc4039c6>`_.
Without these changes, labeled images often had non-integer
values. Although this didn't seem to affect the derived volume
measures, it was too unsettling not to fix.

Installation
============

The best way to install this pipeline is to build a singularity container:

1. Clone repository
2. ``./download_software.sh``
3. ``sudo ./build_singularity.sh`` (requires docker and singularity)

(For those wondering why software isn't downloaded in the Dockerfile:
the version of wget available in CentOS 5 does not support modern ssl
or something like that.)

Running
=======

``singularity run --cleanenv TNT_pipeline_2012-${ver}.simg [options] t1image.mnc out_directory``

NB. Only the mincANTS version of the pipeline is implemented. Therefore, certain "optional"
options are required, and others are not allowed. The calling convention has been preserved
for backwards compatibility, even though it doesn't make much sense anymore.

Model Options:

-modeldir      set the directory to search for model files (default: /data/MODELS)
-model         set the basename of the fit model files (default: SYS_808)
-atlaslabels   set the file for the segmentation masks (default: /data/MODELS/SYS808_atlas_labels_nomiddle_rs.mnc)
-brainmask     set the brain mask name for estimating brain volume (default: /data/MODELS/SYS808_brainmask.mnc)

ICV options

-icv           Calculate intensity and volume in ICV
-icvmask       set the brain mask name for estimating ICV (default: /data/MODELS/SYS808_icv.mnc)

BET Options:

-bet_f         BET fractional intesity threshold (0->1); smaller values give larger brain outline (default: 0.5)
-bet_g         BET vertical gradient in fractional intensity threshold (-1->1); positive values give larger
               brain outline at bottom and smaller at top (default: 0)

Classification Options:

-tagfiledir    set the directory for the tagfile (default: /data/CLASSIFY)
-tagfile       set the tagfile name for classification priors (default: ntags_1000_prob_90_nobg_sys808.tag)

Subcortical Options

-subcortical                 do a subcortical segmentation (binary flag, default: False)
-colindir                    set directory to search for colin27 models required for subcortical segmentation (default: /data/MODELS)
-colin_global                set filename for global colin27 model required for subcortical segmentation
                             (default: colin27_t1_tal_lin, note, this is slightly different than the colin
			     available `here <http://nist.mni.mcgill.ca/?p=947>`_)
-sub_cortical_labels_left    set filename for left subcortical labels required for subcortical segmentation
                             (default: /data/MODELS/mask_left_oncolinnl_7_rs.mnc)
-sub_cortical_labels_right   set filename for right subcortical labels required for subcortical segmentation
                             (default: /data/MODELS/mask_right_oncolinnl_7_rs.mnc)

Registration options:

-mincANTS       REQUIRED. use mincANTS symmetric nonlinear registration with greedy optimization for global nonlinear
                registration (binary flag, default: False)
-mni_autoreg    FORBIDDEN. use mni_autoreg software to do nonlinear registration (binary flag, default: False)
-mritotal       FORBIDDEN. use mritotal for lsq9 linear registration - can only be used in -mni_autoreg mode (binary flag, default: False)
-bestlinreg     FORBIDDEN. use bestlinreg for lsq9 linear registration - can only be used in -mni_autoreg mode (binary flag, default: False)

Subcortical registration options:

-subcortical_mincANTS      REQUIRED if ``-subcortical``. use mincANTS for subcortical registration to colin27
                           (binary flag, default: False)
-subcortical_mni_autoreg   FORBIDDEN. use mni_autoreg tool for subcortical registration to colin27 (binary flag, default: False)
-subcortical_mritotal      FORBIDDEN. use mritotal for initial linear registration to colin27 - can only be used in
                           -sub_cortical_mni_autoreg mode (binary flag, default: False)
-subcortical_bestlinreg    FORBIDDEN. use bestlinreg for initial linear registration to colin27 - can only be used in
                           -sub_cortical_mni_autoreg mode (binary flag, default: False)

Other options:

-debug                     Reduce mincANTS iterations to quickly test that the pipeline runs without errors.


Example methods write-up
========================

Adapted from [Paus2010]_


Volumes of grey matter (GM) and white matter (WM) of the frontal,
parietal, occipital and temporal lobes were automatically extracted
using the following procedures. T1-weighted images were first
corrected for non-uniformities and the intensity normalised using
nu_correct and inormalize from the MINC tools ([Sled1998]_;
[MINC]_). The images where then non-linearly registered
to a template brain using mincANTS ([mincANTS]_), a modified version
of ANTS version 1.9 ([Avants2008]_; [ANTS]_).  The template brain
employed here is the average brain computed from our population
(SYS808). Next, a brain mask was calculated using BET from the FSL
package ([Smith2002]_; [FSL]_). This brain mask was applied to the
non-uniformity corrected image. The voxels in this masked image were
automatically classified as GM, WM, or cerebrospinal fluid (CSF) using
a minimum-distance classifier (using the MINC classify command). This
classifier was trained by transforming points labeled as GM, WM or CSF
in template space into native space for each individual (using the
previous non-linear transformation), and extracting the non-uniformity
corrected intensity values at these points. Tissue-classified voxels
were further labeled as belonging to one of the four lobes. This was
achieved by transforming a “lobar” atlas from template space to native
space ([Collins1994]_; [Collins1995]_; [Collins1999]_). Absolute
(native-space) volumes of lobar GM and WM were defined as the sum of
the GM and WM voxels in eight lobes (four lobes per hemisphere)
multiplied by voxel size (e.g., 1 mm3).  The relative volumes of GM
and WM were calculated by dividing the absolute volumes by the
individual’s brain volume; the brain volume was the volume of a brain
mask (defined in the template space) transformed to the native space.

.. [Paus2010] Paus, T., Nawaz-Khan, I., Leonard, G., Perron, M., Pike, G. B., Pitiot, A., … Pausova, Z. (2010). Sexual dimorphism in the adolescent brain: Role of testosterone and androgen receptor in global and local volumes of grey and white matter. Hormones and Behavior, 57(1), 63–75. https://doi.org/10.1016/j.yhbeh.2009.08.004

.. [Sled1998] Sled, J. G., Zijdenbos, A. P., & Evans, A. C. (1998). A nonparametric method for automatic correction of intensity nonuniformity in MRI data. IEEE Transactions on Medical Imaging, 17(1), 87–97. https://doi.org/10.1109/42.668698

.. [MINC] http://bic.mni.mcgill.ca/ServicesSoftware

.. [mincANTS] http://www.bic.mni.mcgill.ca/~vfonov/software/mincANTS_1p9.tar.gz

.. [Avants2008] Avants, B. B., Epstein, C. L., Grossman, M., & Gee, J. C. (2008). Symmetric diffeomorphic image registration with cross-correlation: Evaluating automated labeling of elderly and neurodegenerative brain. Medical Image Analysis, 12(1), 26–41. https://doi.org/10.1016/j.media.2007.06.004

.. [ANTS] https://sourceforge.net/projects/advants/files/ANTS/

.. [Smith2002] Smith, S. M. (2002). Fast robust automated brain extraction. Human Brain Mapping, 17(3), 143–155. https://doi.org/10.1002/hbm.10062

.. [FSL] http://fsl.oxford.ac.uk

.. [Collins1994] Collins, D. L., Neelin, P., Peters, T. M., & Evans, A. C. (1994). Automatic 3D intersubject registration of MR volumetric data in standardized Talairach space. Journal of Computer Assisted Tomography, 18(2), 192–205.
.. [Collins1995] Collins, D. Louis, Holmes, C. J., Peters, T. M., & Evans, A. C. (1995). Automatic 3-D model-based neuroanatomical segmentation. Human Brain Mapping, 3(3), 190–208. https://doi.org/10.1002/hbm.460030304
.. [Collins1999] Collins, D. Louis, Zijdenbos, A. P., Baaré, W. F. C., & Evans, A. C. (1999). ANIMAL+INSECT: Improved Cortical Structure Segmentation. In A. Kuba, M. Šáamal, & A. Todd-Pokropek (Eds.), Information Processing in Medical Imaging (pp. 210–223). Springer Berlin Heidelberg.

