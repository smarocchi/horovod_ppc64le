FROM nvidia/cuda-ppc64le:10.1-devel-centos7

# Set default shell to run the command at /bin/bash
CMD ["/bin/bash"]

#  C.UTF-8 means it is for computers, it is POSIX compliant, option strongly suggested

#ENV LANG=C.UTF-8 

ENV LANG=en_US.UTF-8

RUN yum -y groupinstall "Development tools" 

RUN yum -y install epel-release \
                   bzip2 \ 
                   gzip \
                   tar \
                   zip \
                   unzip \
                   xz \
                   curl \
                   wget \
                   vim \
                   patch \
                   make \
                   cmake \
                   file \
                   git \
                   which \
                   gcc-c++ \
                   perl-Data-Dumper \
                   perl-Thread-Queue \
                   boost-devel \
                   openssl

RUN  yum  -y install libibverbs-dev \
                     libibverbs-devel \
                                                  rdma-core-devel \
                                                  openssl-devel \
                                                  libssl-dev \
                                                  libopenssl-devel \
                                                  binutils \
                                                  dapl \
                                                  dapl-utils \
                                                  ibacm \
                                                  infiniband-diags \
                                                  libibverbs \ 
                                                  libibverbs-utils \
                                                  libmlx4 \
                                                  librdmacm \
                                                  librdmacm-utils \
                                                  mstflint \
                                                  opensm-libs \
                                                  perftest \
                                                  qperf \
                                                  rdma \
                                                  libjpeg-turbo-devel \
                                                  libpng-devel \
                                                  openssh-clients \ 
                                                  openssh-server \
                                                  subversion \ 
                                                  libffi \
                                                  libffi-devel \
                                                  scl-utils \
                                                  libpsm2 \
                                                  libpsm2-devel \
                                                  pmix \
                                                  pmix-devel

RUN yum -y install centos-release-scl

RUN yum -y install devtoolset-7-gcc devtoolset-7-gcc-c++ 

# LOAD GNU 7.3.1

# General environment variables
ENV PATH=/opt/rh/devtoolset-7/root/usr/bin${PATH:+:${PATH}}
ENV MANPATH=/opt/rh/devtoolset-7/root/usr/share/man:${MANPATH}
ENV INFOPATH=/opt/rh/devtoolset-7/root/usr/share/info${INFOPATH:+:${INFOPATH}}
ENV PCP_DIR=/opt/rh/devtoolset-7/root
# Some perl Ext::MakeMaker versions install things under /usr/lib/perl5
# even though the system otherwise would go to /usr/lib64/perl5.
ENV PERL5LIB=/opt/rh/devtoolset-7/root//usr/lib64/perl5/vendor_perl:/opt/rh/devtoolset-7/root/usr/lib/perl5:/opt/rh/devtoolset-7/root//usr/share/perl5/vendor_perl${PERL5LIB:+:${PERL5LIB}}
# bz847911 workaround:
# we need to evaluate rpm's installed run-time % { _libdir }, not rpmbuild time
# or else /etc/ld.so.conf.d files?
#RUN rpmlibdir=$(rpm --eval "%{_libdir}")
# bz1017604: On 64-bit hosts, we should include also the 32-bit library path.

#RUN if [ "$rpmlibdir" != "${rpmlibdir/lib64/}" ]; then rpmlibdir32=":/opt/rh/devtoolset-7/root${rpmlibdir/lib64/lib}" fi

ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-7/root$rpmlibdir$rpmlibdir32${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
ENV LD_LIBRARY_PATH=/opt/rh/devtoolset-7/root$rpmlibdir$rpmlibdir32:/opt/rh/devtoolset-7/root$rpmlibdir/dyninst$rpmlibdir32/dyninst${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
# duplicate python site.py logic for sitepackages
#ENV pythonvers=3.6
#ENV PYTHONPATH=/opt/rh/devtoolset-7/root/usr/lib64/python$pythonvers/site-packages:/opt/rh/devtoolset-7/root/usr/lib/python$pythonvers/site-packages${PYTHONPATH:+:${PYTHONPATH}}

RUN gcc --version

# INSTALL MINICONDA

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py37_4.8.3-Linux-ppc64le.sh && \
    bash Miniconda3-py37_4.8.3-Linux-ppc64le.sh -bfp /home/miniconda483 && \
    rm -rf Miniconda3-py37_4.8.3-Linux-ppc64le.sh

# ACTIVATE CONDA VIRTUALENV BASE

ENV CONDA_SHLVL=1
ENV CONDA_PROMPT_MODIFIER=(base) 
ENV CONDA_EXE=/home/miniconda483/bin/conda
ENV _CE_CONDA=
ENV PATH=/home/miniconda483/bin:/home/miniconda483/condabin:${PATH}
ENV CONDA_PREFIX=/home/miniconda483
ENV CONDA_PYTHON_EXE=/home/miniconda483/bin/python
ENV CONDA_DEFAULT_ENV=base

RUN conda --version
RUN python --version 

# INSTALL POWERAI

ENV IBM_POWERAI_LICENSE_ACCEPT=yes

RUN conda install -y conda && conda clean --all --yes

#&& \
#    conda install -y gxx_linux-ppc64le=7

RUN conda config --prepend channels https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/

RUN conda install -y pytorch powerai-release=1.6.2

# IMPORTANT: correct CUDA linking for torch ###############

ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs:$LD_LIBRARY_PATH
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 && ln -s /home/miniconda483/lib/libffi.so /home/miniconda483/lib/libffi.so.7

# UP TO HERE OK ! TORCH WORKING
###########################################################

RUN conda install -y tensorflow-gpu powerai-release=1.6.2

################### INSTALL HOROVOD ##############################

# UP TO HERE OK ! TENSORFLOW WORKING

RUN conda install -y gxx_linux-ppc64le=7 cffi cudatoolkit-dev=10.1

ENV HOROVOD_VERSION=0.19.1

RUN HOROVOD_CUDA_HOME=/usr/local/cuda HOROVOD_GPU_OPERATIONS=NCCL HOROVOD_WITH_TENSORFLOW=1 HOROVOD_WITH_PYTORCH=1 \
         pip install --no-cache-dir horovod==${HOROVOD_VERSION}

# UP TO HERE OK ! HOROVOD WORKING

# MPI-SPECTRUM 10.3 ALREADY INSTALLED BY CONDA

#remove all __pycache__

#RUN find /home/miniconda483 | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rf

################### INSTALL UCX ###############################

# install alternative libraries

RUN yum install -y systemd-devel numactl-libs numactl-devel

# install gdrcopy

#RUN yum install -y rpm-build make check check-devel subunit subunit-devel && \
#    cd /home && \
#    wget https://github.com/NVIDIA/gdrcopy/archive/master.zip && \
#    unzip master.zip && \
#    rm -rf master.zip && \
#    cd gdrcopy-master && \
#    make PREFIX=/opt/gdrcopy CUDA=/usr/local/cuda all install && \
#    ./insmod.sh

RUN wget https://github.com/openucx/ucx/releases/download/v1.7.0/ucx-1.7.0.tar.gz && \
    tar zxvf ucx-1.7.0.tar.gz && \
    cd ucx-1.7.0 && \
    ./configure --prefix=/opt/ucx-cuda --with-cuda=/usr/local/cuda && \
    make && \
    make install

# Now I will avoid to use --with-gdrcopy because it needs the cuda drivers and I do not know the correct version for M100

################### INSTALL OPENMPI ###############################

# RUN wget https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.3.tar.gz

#${PKG_SOURCE_DIR}/configure 
#CFLAGS="-I/opt/pmix/3.1.4rc2/include" 
#CPPFLAGS="-I/opt/pmix/3.1.4rc2/include" 
#LDFLAGS="-L/opt/pmix/3.1.4rc2/lib -L/opt/pmix/3.1.4rc2/lib/pmix -L/m100/prod/build/compilers/openmpi/4.0.3/gnu--8.4.0/BA_WORK/libudev/usr/lib64" 

# --with-hcoll=/opt/mellanox/hcoll --with-mxm=/opt/mellanox/mxm --with-memory-manager=none  --enable-static=yes --enable-shared --with-pmix="/opt/pmix/3.1.4rc2" --with-pmi="/opt/pmix/3.1.4rc2" --with-libevent=/usr  --with-hwloc=/usr --with-ucx=$PKG_INSTALL_DIR/ucx-cuda/1.7.0 --with-verbs -with-cuda=/cineca/prod/opt/compilers/cuda/10.1/none --enable-mpirun-prefix-by-default  --with-platform=/cineca/prod/build/compilers/openmpi/4.0.3/gnu--8.4.0/BA_WORK/openmpi-4.0.3/contrib/platform/mellanox/optimized --with-slurm

# Install Open MPI
RUN cd /home && \
    wget https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.3.tar.gz && \
    tar zxf openmpi-4.0.3.tar.gz

RUN cd /home/openmpi-4.0.3 && \
    ./configure --prefix=/opt/openmpi --with-memory-manager=none  --enable-static=yes --enable-shared --with-pmix --with-libevent  --with-hwloc --with-ucx=/opt/ucx-cuda --with-verbs -with-cuda=/usr/local/cuda --enable-mpirun-prefix-by-default --with-slurm && \ 
    make -j $(nproc) all && \
    make install && \ 
    cd /tmp && \
    rm -rf /tmp/openmpi

ENV PATH=/opt/openmpi/bin:${PATH}
ENV LD_LIBRARY_PATH=/opt/openmpi/lib:${LD_LIBRARY_PATH}

# SKIPPED OPTIONS

# --with-platform=/path_to_file
# --with-pmi
#--with-hcoll 
#--with-mxm
