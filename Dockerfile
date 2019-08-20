FROM centos:5.11

WORKDIR /root
RUN > update_repo.sed echo -e 's/^mirrorlist=.*/#&/\n\
/^#baseurl/{\n\
s/^#//\n\
s/mirror/vault/\n\
s/centos\/\$releasever/5.11/\n\
s/\$basearch/x86_64/\n\
}'
RUN sed -f update_repo.sed -i /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/libselinux.repo
RUN yum clean all && \
yum update -y && \
yum install -y epel-release && \
yum install -y file bc tar gzip libquadmath which bzip2 tcsh perl zlib zlib-devel zlib-static hostname time glibc.i686 libX11-devel perl-ExtUtils-MakeMaker perl-IO-Socket-SSL perl-CPAN && \
yum groupinstall -y "Development Tools"

COPY hdf5-1.6.10.tar.gz /root/
RUN tar -xf hdf5-1.6.10.tar.gz
RUN cd /root/hdf5-1.6.10 && ./configure --prefix=/opt/hdf5 --enable-static=yes --disable-shared && make && make check && make install
RUN rm -rf /root/hdf5-1.6.10{,.tar.gz}

COPY netcdf-4.0.1.tar.gz /root/
RUN tar -xf netcdf-4.0.1.tar.gz
RUN cd /root/netcdf-4.0.1 && ./configure --prefix=/opt/netcdf && make && make check && make install
RUN rm -rf /root/netcdf-4.0.1{,.tar.gz}

COPY minc-2.0.18.tar.gz /root/
RUN tar -xf minc-2.0.18.tar.gz
# https://mailman.bic.mni.mcgill.ca/pipermail/minc-development/2009-May.txt
# apply https://github.com/BIC-MNI/libminc/commit/6ef58fe96d1505b5d21b7f9b165d89f957e57cd2
# apply some of https://github.com/BIC-MNI/minc-tools/commit/9e7058ef0bf78f4a5794a9fff459d9168a225aba
# apply https://github.com/BIC-MNI/minc-tools/commit/cc03c467df866a76f8a7eb0115ddc0fa10651fa1
RUN cd /root/minc-2.0.18 && \
sed -i '147i#define MAX_NC_OPEN 32' libsrc/minc.h && \
echo -e '\
206a207\n\
>    int is_labels;\n\
1062,1065c1063,1074\n\
<    maxid = micreate_std_variable(outmincid, MIimagemax, NC_DOUBLE, \n\
<                                  out_ndims-out_nimgdims, outdim);\n\
<    minid = micreate_std_variable(outmincid, MIimagemin, NC_DOUBLE, \n\
<                                  out_ndims-out_nimgdims, outdim);\n\
---\n\
>    if( loop_options->is_labels )\n\
>    {\n\
>       maxid = micreate_std_variable(outmincid, MIimagemax, NC_DOUBLE, \n\
>                                     0, NULL);\n\
>       minid = micreate_std_variable(outmincid, MIimagemin, NC_DOUBLE, \n\
>                                     0, NULL);\n\
>    } else {\n\
>       maxid = micreate_std_variable(outmincid, MIimagemax, NC_DOUBLE, \n\
>                                     out_ndims-out_nimgdims, outdim);\n\
>       minid = micreate_std_variable(outmincid, MIimagemin, NC_DOUBLE, \n\
>                                     out_ndims-out_nimgdims, outdim);\n\
>    }\n\
1218,1219c1227,1235\n\
<       (void) miicv_setint(icvid, MI_ICV_DO_NORM, TRUE);\n\
<       (void) miicv_setint(icvid, MI_ICV_USER_NORM, TRUE);\n\
---\n\
>       if ( loop_options->is_labels )\n\
>       {\n\
> 	(void) miicv_setint(icvid, MI_ICV_DO_NORM, FALSE);\n\
> 	(void) miicv_setint(icvid, MI_ICV_USER_NORM, FALSE);\n\
> 	(void) miicv_setint(icvid, MI_ICV_DO_RANGE, FALSE);\n\
>       } else {\n\
> 	(void) miicv_setint(icvid, MI_ICV_DO_NORM, TRUE);\n\
> 	(void) miicv_setint(icvid, MI_ICV_USER_NORM, TRUE);\n\
>       }\n\
1588,1591c1604,1610\n\
<             (void) mivarput1(outmincid, maxid, block_cur, \n\
<                              NC_DOUBLE, NULL, &maximum);\n\
<             (void) mivarput1(outmincid, minid, block_cur, \n\
<                              NC_DOUBLE, NULL, &minimum);\n\
---\n\
> 	    if ( ! loop_options->is_labels )\n\
> 	    {\n\
>               (void) mivarput1(outmincid, maxid, block_cur, \n\
>                                NC_DOUBLE, NULL, &maximum);\n\
>               (void) mivarput1(outmincid, minid, block_cur, \n\
>                                NC_DOUBLE, NULL, &minimum);\n\
> 	    }\n\
1630a1650,1663\n\
>       if ( loop_options->is_labels )\n\
>       {\n\
> 	 /*Have to write out global valid range and global image range*/\n\
> 	 if ((global_minimum[ofile] == DBL_MAX) &&\n\
> 	     (global_maximum[ofile] == -DBL_MAX)) {\n\
> 	    global_minimum[ofile] = 0.0;\n\
> 	    global_maximum[ofile] = 0.0;\n\
> 	 }\n\
> 	 valid_range[0] = global_minimum[ofile];\n\
> 	 valid_range[1] = global_maximum[ofile];\n\
> 	 (void) mivarput1(outmincid, minid, 0, NC_DOUBLE, NULL, &valid_range[0]);\n\
> 	 (void) mivarput1(outmincid, maxid, 0, NC_DOUBLE, NULL, &valid_range[1]);\n\
> 	 (void) miset_valid_range(outmincid, imgid, valid_range);\n\
>       }\n\
2695a2729\n\
>    loop_options->is_labels = FALSE; /* for backward compatibility*/\n\
2702a2737,2747\n\
> }\n\
> \n\
> MNCAPI void set_loop_labels(Loop_Options *loop_options,\n\
> 			    int labels)\n\
> {\n\
>   loop_options->is_labels = labels;\n\
> }\n\
> \n\
> MNCAPI int get_loop_labels(Loop_Options *loop_options)\n\
> {\n\
>   return loop_options->is_labels;\n' > patch_voxel_loop.c.txt && \
patch -i patch_voxel_loop.c.txt libsrc/voxel_loop.c && \
echo -e '\
296a297,299\n\
> MNCAPI void set_loop_labels(Loop_Options *loop_options,\n\
> 			    int labels);\n\
>   \n\
304a308\n\
> MNCAPI int get_loop_labels(Loop_Options *loop_options);\n' > patch_voxel_loop.h.txt && \
patch -i patch_voxel_loop.h.txt libsrc/voxel_loop.h && \
echo -e '\
241a242\n\
> static int is_labels = FALSE;\n\
289a291,292\n\
>    {"-labels", ARGV_CONSTANT, (char *) TRUE, (char *) &is_labels,\n\
>        "integer operation on labels"},\n\
535a539\n\
>    set_loop_labels(loop_options, is_labels);\n' > patch_mincmath.c.txt && \
patch -i patch_mincmath.c.txt progs/mincmath/mincmath.c && \
echo -e '\
225a226\n\
> static int is_labels = FALSE;\n\
263a265,266\n\
>     {"-labels", ARGV_CONSTANT, (char *) TRUE, (char *) &is_labels,\n\
>        "integer operation on labels"},\n\
362a366\n\
>    set_loop_labels(loop_options, is_labels || discrete_lookup);\n' > patch_minclookup.c.txt && \
patch -i patch_minclookup.c.txt progs/minclookup/minclookup.c && \
chmod +x progs/mincdiff/mincdiff && \
./configure --prefix=/opt/minc --with-build-path=/opt/hdf5:/opt/netcdf && \
make && \
make check && \
make install
ENV PATH=/opt/minc/bin:$PATH
RUN rm -rf /root/minc-2.0.18{,.tar.gz}

COPY ebtks-1.6.3.tar.gz /root/
# for some reason if shared is enabled N3 configure fails
RUN tar -xf ebtks-1.6.3.tar.gz && \
cd ebtks-1.6.3 && \
./configure --prefix=/opt/ebtks && \
make && \
make install
RUN rm -rf /root/ebtks-1.6.3{,.tar.gz}

COPY mni_perllib-0.08.tar.gz /root/
RUN echo no | cpan Getopt::Tabular && \
tar -xf mni_perllib-0.08.tar.gz && \
cd /root/mni_perllib-0.08 && \
mkdir /opt/mni && \
mkdir /opt/mni/data && \
echo "/opt/mni/data" | perl Makefile.PL && \
make && \
make install
RUN rm -rf /root/mni_perllib-0.08{,.tar.gz}

COPY N3-1.11.0.tar.gz /root/
RUN tar -xf N3-1.11.0.tar.gz && \
cd /root/N3-1.11.0 && \
sed -i '1s#/usr/local/bin/perl#/usr/bin/perl#' testing/rms_diff testing/do_test && \
./configure --with-minc2 --prefix=/opt/N3 --with-build-path=/opt/hdf5:/opt/netcdf:/opt/minc:/opt/ebtks && \
make && \
make install
ENV PATH=/opt/N3/bin:$PATH
RUN cd /root/N3-1.11.0 && make check
RUN rm -rf /root/N3-1.11.0{,.tar.gz}

COPY inormalize-1.0.2.tar.gz /root/
RUN tar -xf inormalize-1.0.2.tar.gz && \
cd /root/inormalize-1.0.2 && \
./configure --with-minc2 --prefix=/opt/inormalize --with-build-path=/opt/hdf5:/opt/netcdf:/opt/minc:/opt/ebtks && \
make && \
make check && \
make install
ENV PATH=/opt/inormalize/bin:$PATH
RUN rm -rf /root/inormalize-1.0.2{,.tar.gz}

COPY classify-1.0.08.tar.gz /root/
RUN tar -xf classify-1.0.08.tar.gz && \
cd /root/classify-1.0.08 && \
./configure --with-minc2 --prefix=/opt/classify --with-build-path=/opt/hdf5:/opt/netcdf:/opt/minc:/opt/ebtks && \
make && \
make check && \
make install
ENV PATH=/opt/classify/bin:$PATH
RUN rm -rf /root/classify-1.0.08{,.tar.gz}

COPY fsl-4.1.9-sources.tar.gz /root/
ENV FSLMACHTYPE=linux_64-gcc4.1
RUN cd /opt && \
tar -xf /root/fsl-4.1.9-sources.tar.gz && \
cd /opt/fsl && \
sed -i '/  echo "   $error\(install\)\|\(projs\)" ;/a\ \ exit 1' ./config/common/buildproj && \
sed -i '/elif \[ -d $FSLDIR\/src\/$projname \] ; then/a\ \ \ \ \ \ \ \ MAKEOPTIONS="${MAKEOPTIONS} FSLEXTLIB=${FSLDIR}/extras/lib FSLEXTINC=${FSLDIR}/extras/include" ;' config/common/buildproj  && \
./config/common/buildproj extras && \
./config/common/buildproj utils && \
./config/common/buildproj znzlib && \
./config/common/buildproj niftiio && \
./config/common/buildproj fslio && \
./config/common/buildproj miscmaths && \
./config/common/buildproj newimage && \
./config/common/buildproj meshclass && \
./config/common/buildproj bet2
ENV FSLDIR=/opt/fsl
ENV FSLOUTPUTTYPE=NIFTI_GZ \
FSLMULTIFILEQUIT=TRUE \
FSLTCLSH=${FSLDIR}/bin/fsltclsh \
FSLWISH=${FSLDIR}/bin/fslwish \
FSLLOCKDIR="" \
FSLMACHINELIST="" \
FSLREMOTECALL="" \
FSLCONFDIR=${FSLDIR}/config \
PATH=${FSLDIR}/bin:$PATH

COPY cmake-2.8.12.2-Linux-i386.tar.gz /root
RUN tar -xf cmake-2.8.12.2-Linux-i386.tar.gz && \
mkdir /opt/cmake && \
cp -r /root/cmake-2.8.12.2-Linux-i386/* /opt/cmake/ && \
rm -rf /root/cmake-2.8.12.2-Linux-i386{,.tar.gz}

COPY InsightToolkit-3.20.0.tar.gz /root/
RUN tar -xf InsightToolkit-3.20.0.tar.gz && \
mkdir /root/build_itk && \
cd /root/build_itk && \
/opt/cmake/bin/cmake -DCMAKE_BUILD_TYPE=RELEASE -DBUILD_EXAMPLES=OFF -DCMAKE_INSTALL_PREFIX=/opt/itk ../InsightToolkit-3.20.0 && \
make -j 8 && \
make test && \
make install

COPY gsl-1.14.tar.gz /root/
RUN tar -xf gsl-1.14.tar.gz && \
cd /root/gsl-1.14 && \
./configure --prefix=/opt/gsl --disable-shared && \
make && \
make check && \
make install && \
rm -rf /root/gsl-1.14{,.tar.gz}

COPY ezminc-r60.tar.gz /root/
# not sure how to actually run the tests
# RUN make test
RUN tar -xf ezminc-r60.tar.gz && \
sed -i 's#/usr/local/bic#/opt/minc#' ezminc/CMakeLists.txt && \
sed -i '17a/opt/hdf5/include\n/opt/netcdf/include' ezminc/CMakeLists.txt && \
sed -i '14a/opt/hdf5/lib\n/opt/netcdf/lib' ezminc/CMakeLists.txt && \
mkdir /root/build_ezminc && \
cd /root/build_ezminc && \
/opt/cmake/bin/cmake -DCMAKE_BUILD_TYPE=RELEASE -DITK_DIR=/root/build_itk -DBUILD_TESTS=OFF -DBUILD_ITK_PLUGIN=ON -DUSE_MINC2=ON -DCMAKE_INSTALL_PREFIX=/opt/ezminc -DBUILD_TOOLS=ON -DGSL_ROOT=/opt/gsl ../ezminc && \
make && \
make install && \
rm -rf /root/ezminc{,-r60.tar.gz}

COPY mincANTS_1p9.tar.gz /root/
RUN tar -xf mincANTS_1p9.tar.gz && \
sed -i 's#/usr/local/bic#/opt/ezminc#' mincANTS_1p9/Examples/CMakeLists.txt && \
sed -i '/^INCLUDE_DIRECTORIES($/a/opt/hdf5/include\n/opt/netcdf/include\n/opt/minc/include' mincANTS_1p9/Examples/CMakeLists.txt && \
sed -i '/^LINK_DIRECTORIES($/a/opt/hdf5/lib\n/opt/netcdf/lib\n/opt/minc/lib' mincANTS_1p9/Examples/CMakeLists.txt && \
echo -e '\
100c100\n\
< #ifdef USE_EZMINC      \n\
---\n\
> #ifdef USE_EZMINC\n\
103,105c103,120\n\
<         minc::write_linear_xfm(this->m_NamingConvention.c_str(), \n\
<                                this->m_AffineTransform->GetMatrix(),\n\
<                                this->m_AffineTransform->GetOffset());\n\
---\n\
>         if(! this->m_DeformationField )\n\
>         {\n\
>           minc::write_linear_xfm(this->m_NamingConvention.c_str(), \n\
>                                 this->m_AffineTransform->GetMatrix(),\n\
>                                 this->m_AffineTransform->GetOffset());\n\
>           // lets create an inverse to be consistent\n\
>           \n\
>           std::string inv_xfm = filePrefix + std::string( "_inverse.xfm" );\n\
>           \n\
>           AffineTransformPointer tmp=AffineTransformType::New();\n\
>           //tmp->SetCenter(this->m_AffineTransform->GetCenter());\n\
>           this->m_AffineTransform->GetInverse(tmp);\n\
>           minc::write_linear_xfm(inv_xfm.c_str(), \n\
>                                  tmp->GetMatrix(),\n\
>                                  tmp->GetOffset());\n\
>           \n\
>           //delete tmp;\n\
>         }\n\
127,128d141\n\
<             //update the .xfm file\n\
<           std::ofstream xfm(this->m_NamingConvention.c_str(),std::ios_base::app|std::ios_base::out);\n\
130,138d142\n\
<           if(!this->m_AffineTransform)\n\
<             xfm<<"MNI Transform File"<<std::endl<<std::endl\n\
<                 <<"Transform_Type = Linear;"<<std::endl\n\
<                 <<"Linear_Transform ="<<std::endl\n\
<                 <<" 1 0 0 0"<<std::endl\n\
<                 <<" 0 1 0 0"<<std::endl\n\
<                 <<" 0 0 1 0"<<std::endl;\n\
<             \n\
<           xfm<<"Transform_Type = Grid_Transform;"<<std::endl;\n\
143c147,155\n\
<           xfm<<"Displacement_Volume = "<<basename<<";"<<std::endl;\n\
---\n\
>           \n\
>           if(this->m_AffineTransform)\n\
>             minc::write_combined_xfm(this->m_NamingConvention.c_str(),\n\
>                                      basename.c_str(),\n\
>                                      this->m_AffineTransform->GetMatrix(),\n\
>                                      this->m_AffineTransform->GetOffset());\n\
>           else\n\
>             minc::write_nonlinear_xfm(this->m_NamingConvention.c_str(),basename.c_str());\n\
>           \n\
168c180\n\
<     }         \n\
---\n\
>     }\n\
182a195,215\n\
>         \n\
>         std::string inv_xfm = filePrefix + std::string( "_inverse.xfm" );\n\
>         \n\
>         std::string::size_type pos = filename.rfind( "/" );\n\
>         if(pos==std::string::npos) pos=0;\n\
>         else pos++;\n\
>         std::string basename(filename,pos,filename.length());\n\
>           \n\
>         if(this->m_AffineTransform)\n\
>         {\n\
>           AffineTransformPointer tmp=AffineTransformType::New();\n\
>           this->m_AffineTransform->GetInverse(tmp);\n\
>           \n\
>           minc::write_combined_xfm(inv_xfm.c_str(),\n\
>                                    tmp->GetMatrix(),\n\
>                                    tmp->GetOffset(),\n\
>                                     basename.c_str());\n\
>         } else {\n\
>           minc::write_nonlinear_xfm(inv_xfm.c_str(),basename.c_str());\n\
>         } \n\
> ' > mincANTS.patch && \    
patch -i mincANTS.patch mincANTS_1p9/ImageRegistration/itkANTSImageTransformation.cxx && \
mkdir /root/build_mincANTS && \
cd /root/build_mincANTS && \
/opt/cmake/bin/cmake -DCMAKE_BUILD_TYPE=RELEASE -DITK_DIR=/root/build_itk -DCMAKE_INSTALL_PREFIX=/opt/mincANTS -DBUILD_TESTING=OFF ../mincANTS_1p9/Examples && \
make -j 8 && \
make install
RUN rm -rf /root/build_mincANTS mincAnts_1p9{,.tar.gz} && \
rm -rf /root/build_itk InsightToolkit-3.20.0{,.tar.gz}
# For some reason some of these tests fail
#RUN make test
ENV PATH=/opt/mincANTS/bin:$PATH
# failed tests:
# ANTS_CC_3_WARP_METRIC_0 (Failed)
# ANTS_MSQ_WARP_METRIC_0 (Failed)
# ANTS_GSYN_WARP_METRIC_0 (Failed)
# ANTS_GSYN_INVERSEWARP_METRIC_0 (Failed)
# ANTS_PSE_MSQ_IMG_WARP_METRIC_1 (Failed)
# ANTS_PSE_MSQ_IMG_INVERSEWARP_METRIC_1 (Failed)
# ANTS_ROT_GSYN_INVERSEWARP_METRIC_0 (Failed)
# These tests also seem to fail with the old build (found by copying MeasureImageSimilarity over and using some old hdf5 lib)


# prevent minc from caching any volumes. Otherwise can cause errors
ENV VOLUME_CACHE_THRESHOLD=-1

COPY models /data/MODELS
COPY classify /data/CLASSIFY
COPY standardPipeline_201907_v1.pl /opt/
COPY pipeline_wrapper.sh /opt/
ENTRYPOINT ["/opt/pipeline_wrapper.sh"]