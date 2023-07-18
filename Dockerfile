FROM pennlinc/xcp_d:0.1.3 as build_fsl
FROM pennlinc/atlaspack:0.0.4 as atlaspack
FROM ubuntu:bionic-20220531

COPY docker/files/neurodebian.gpg /usr/local/etc/neurodebian.gpg

# Download atlases from AtlasPack
RUN mkdir /AtlasPack
COPY --from=atlaspack /AtlasPack/tpl-fsLR_*.dlabel.nii /AtlasPack/
COPY --from=atlaspack /AtlasPack/tpl-MNI152NLin6Asym_*.nii.gz /AtlasPack/
COPY --from=atlaspack /AtlasPack/atlas-4S*.tsv /AtlasPack/
COPY --from=atlaspack /AtlasPack/*.json /AtlasPack/

# Install basic libraries
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-utils \
        autoconf \
        build-essential \
        bzip2 \
        ca-certificates \
        curl \
        dc \
        git \
        graphviz \
        libtool \
        locales \
        pandoc \
        pandoc-citeproc \
        pkg-config \
        unzip \
        wget \
        xvfb \
        && \
    curl -sSL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y --no-install-recommends \
        nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV OS="Linux" \
    FIX_VERTEX_AREA=""

RUN echo "Downloading C3D ..." \
    && mkdir /opt/c3d \
    && curl -sSL --retry 5 https://sourceforge.net/projects/c3d/files/c3d/1.0.0/c3d-1.0.0-Linux-x86_64.tar.gz/download \
    | tar -xzC /opt/c3d --strip-components=1
ENV C3DPATH=/opt/c3d/bin \
    PATH=/opt/c3d/bin:$PATH

# Set up NeuroDebian
RUN curl -sSL "http://neuro.debian.net/lists/$( lsb_release -c | cut -f2 ).us-ca.full" >> /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-key add /usr/local/etc/neurodebian.gpg && \
    (apt-key adv --refresh-keys --keyserver hkp://ha.pool.sks-keyservers.net 0xA5D32F012649A5A9 || true)

# Install and set up miniconda
RUN curl -sSLO https://repo.continuum.io/miniconda/Miniconda3-py38_4.9.2-Linux-x86_64.sh && \
    bash Miniconda3-py38_4.9.2-Linux-x86_64.sh -b -p /usr/local/miniconda && \
    rm Miniconda3-py38_4.9.2-Linux-x86_64.sh

# Set CPATH for packages relying on compiled libs (e.g. indexed_gzip)
ENV PATH="/usr/local/miniconda/bin:$PATH" \
    CPATH="/usr/local/miniconda/include:$CPATH" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    PYTHONNOUSERSITE=1

# Install precomputed python packages
RUN conda install -y \
        python=3.8 \
        libxslt=1.1 \
        matplotlib=3.3 \
        mkl=2021.2 \
        mkl-service=2.3 \
        numpy=1.18.1 \
        pandas=1.2 \
        scikit-learn=0.24 \
        scipy=1.6 \
        traits=6.2 \
        zstd=1.4; \
    sync && \
    chmod -R a+rX /usr/local/miniconda; sync && \
    chmod +x /usr/local/miniconda/bin/*; sync && \
    conda clean -y --all; sync && \
    conda clean -tipsy; sync && \
    rm -rf ~/.conda ~/.cache/pip/*; sync

# Install AFNI, Connectome Workbench, and git-annex
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        afni=18.0.05+git24-gb25b21054~dfsg.1-1~nd17.10+1+nd18.04+1 \
        connectome-workbench=1.5.0-1~nd18.04+1 \
        git-annex-standalone && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install SLICER from FSL
COPY --from=build_fsl /usr/lib/fsl/5.0/slicer /opt/fsl/lib/slicer
COPY --from=build_fsl /usr/lib/fsl/5.0/slicesdir /opt/fsl/lib/slicesdir
COPY --from=build_fsl /usr/lib/fsl/5.0/pngappend /opt/fsl/lib/pngappend
COPY --from=build_fsl /usr/lib/fsl/5.0/remove_ext /opt/fsl/lib/remove_ext
# Binaries
COPY --from=build_fsl /usr/bin/fsl5.0-slicer /opt/fsl/bin/fsl-5.0-slicer
COPY --from=build_fsl /usr/bin/fsl5.0-slicesdir /opt/fsl/bin/fsl5.0-slicesdir
COPY --from=build_fsl /usr/bin/fsl5.0-pngappend /opt/fsl/bin/fsl5.0-pngappend
COPY --from=build_fsl /usr/bin/fsl5.0-remove_ext /opt/fsl/bin/fsl5.0-remove_ext
COPY --from=build_fsl /usr/share/fsl/5.0/bin/slicer /opt/fsl/bin/slicer
COPY --from=build_fsl /usr/share/fsl/5.0/bin/slicesdir /opt/fsl/bin/slicesdir
COPY --from=build_fsl /usr/share/fsl/5.0/bin/pngappend /opt/fsl/bin/pngappend
COPY --from=build_fsl /usr/share/fsl/5.0/bin/remove_ext /opt/fsl/bin/remove_ext
# Shared libraries
COPY --from=build_fsl /usr/lib/fsl/5.0/libnewimage.so /opt/fsl/lib/libnewimage.so
COPY --from=build_fsl /usr/lib/fsl/5.0/libmiscmaths.so /opt/fsl/lib/libmiscmaths.so
COPY --from=build_fsl /usr/lib/fsl/5.0/libmiscpic.so /opt/fsl/lib/libmiscpic.so
COPY --from=build_fsl /usr/lib/fsl/5.0/libfslio.so /opt/fsl/lib/libfslio.so
COPY --from=build_fsl /usr/lib/fsl/5.0/libutils.so /opt/fsl/lib/libutils.so
COPY --from=build_fsl /usr/lib/fsl/5.0/libprob.so /opt/fsl/lib/libprob.so
COPY --from=build_fsl /usr/lib/libnewmat.so.10.0.0 /opt/fsl/lib/libnewmat.so.10
ENV FSLDIR="/opt/fsl" \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLMULTIFILEQUIT="TRUE" \
    FSLLOCKDIR="" \
    FSLMACHINELIST="" \
    FSLREMOTECALL="" \
    FSLGECUDAQ="cuda.q" \
    LD_LIBRARY_PATH="/opt/fsl/lib:$LD_LIBRARY_PATH" \
    PATH="/opt/fsl/lib:/opt/fsl/bin:$PATH" \
    FSL_DEPS="libquadmath0;libnewimage.so;libmiscmaths.so"

# Install FreeSurfer
RUN curl -sSL https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.1/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.1.tar.gz | tar zxv --no-same-owner -C /opt \
    --exclude="freesurfer/diffusion" \
    --exclude="freesurfer/docs" \
    --exclude="freesurfer/fsfast" \
    --exclude="freesurfer/lib/cuda" \
    --exclude="freesurfer/lib/qt" \
    --exclude="freesurfer/matlab" \
    --exclude="freesurfer/mni/share/man" \
    --exclude="freesurfer/subjects/fsaverage_sym" \
    --exclude="freesurfer/subjects/fsaverage3" \
    --exclude="freesurfer/subjects/fsaverage4" \
    --exclude="freesurfer/subjects/cvs_avg35" \
    --exclude="freesurfer/subjects/cvs_avg35_inMNI152" \
    --exclude="freesurfer/subjects/bert" \
    --exclude="freesurfer/subjects/lh.EC_average" \
    --exclude="freesurfer/subjects/rh.EC_average" \
    --exclude="freesurfer/subjects/sample-*.mgz" \
    --exclude="freesurfer/subjects/V1_average" \
    --exclude="freesurfer/trctrain"

ENV FREESURFER_HOME="/opt/freesurfer" \
    FSF_OUTPUT_FORMAT="nii.gz"

ENV FUNCTIONALS_DIR="$FREESURFER_HOME/sessions" \
    LOCAL_DIR="$FREESURFER_HOME/local" \
    MINC_BIN_DIR="$FREESURFER_HOME/mni/bin" \
    MINC_LIB_DIR="$FREESURFER_HOME/mni/lib" \
    MNI_DIR="$FREESURFER_HOME/mni" \
    MNI_DATAPATH="$FREESURFER_HOME/mni/data"

ENV MNI_PERL5LIB="$MINC_LIB_DIR/perl5/5.8.5" \
    PERL5LIB="$MINC_LIB_DIR/perl5/5.8.5" \
    SUBJECTS_DIR="$FREESURFER_HOME/subjects" \
    PATH="$FREESURFER_HOME/bin:$FREESURFER_HOME/tktools:$MINC_BIN_DIR:$PATH"

ENV AFNI_MODELPATH="/usr/lib/afni/models" \
    AFNI_IMSAVE_WARNINGS="NO" \
    AFNI_TTATLAS_DATASET="/usr/share/afni/atlases" \
    AFNI_PLUGINPATH="/usr/lib/afni/plugins" \
    PATH="/usr/lib/afni/bin:$PATH"

# Install ANTS
ENV ANTSPATH="/usr/lib/ants"
RUN mkdir -p $ANTSPATH && \
    curl -sSL "https://dl.dropbox.com/s/gwf51ykkk5bifyj/ants-Linux-centos6_x86_64-v2.3.4.tar.gz" \
    | tar -xzC $ANTSPATH --strip-components 1
ENV PATH=$ANTSPATH:$PATH

# Install SVGO
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g svgo

# Install bids-validator
RUN npm install -g bids-validator@1.8.0

# Unless otherwise specified each process should only use one thread - nipype
# will handle parallelization
ENV MKL_NUM_THREADS=1 \
    OMP_NUM_THREADS=1

# Create a shared $HOME directory
RUN useradd -m -s /bin/bash -G users xcp_d
WORKDIR /home/xcp_d
ENV HOME="/home/xcp_d"

# Update pip, which AFNI installs (probably)
RUN pip install --no-cache-dir --upgrade pip

# Precaching fonts, set "Agg" as default backend for matplotlib
RUN python -c "from matplotlib import font_manager" && \
    sed -i 's/\(backend *: \).*$/\1Agg/g' $( python -c "import matplotlib; print(matplotlib.matplotlib_fname())" )

# Precaching atlases: UPDATE TEMPLATEFLOW VERSION TO MATCH XCP_D
RUN pip install --no-cache-dir "templateflow ~= 0.8.1 " && \
    python -c "from templateflow import api as tfapi; \
               tfapi.get('MNI152NLin2009cAsym', resolution=2, suffix='T1w', desc=None); \
                tfapi.get(template='MNI152NLin6Asym',resolution=2, suffix='T1w'); \
                tfapi.get(template='fsLR',density='32k',suffix='sphere'); \
                tfapi.get('MNI152NLin2009cAsym', resolution=1, desc='carpet',suffix='dseg'); \
                tfapi.get(template='MNI152NLin2009cAsym',mode='image',suffix='xfm',extension='.h5'); \
                tfapi.get(template='fsLR',density='32k',desc='vaavg', suffix='midthickness',extension='.gii'); \
                tfapi.get('fsLR', density='32k'); \
                 " && \
    find $HOME/.cache/templateflow -type d -exec chmod go=u {} + && \
    find $HOME/.cache/templateflow -type f -exec chmod go=u {} +

# add pandoc
RUN curl -o pandoc-2.2.2.1-1-amd64.deb -sSL "https://github.com/jgm/pandoc/releases/download/2.2.2.1/pandoc-2.2.2.1-1-amd64.deb" && \
    dpkg -i pandoc-2.2.2.1-1-amd64.deb && \
    rm pandoc-2.2.2.1-1-amd64.deb

ARG VERSION=0.0.1

RUN find $HOME -type d -exec chmod go=u {} + && \
    find $HOME -type f -exec chmod go=u {} + && \
    rm -rf $HOME/.npm $HOME/.conda $HOME/.empty

RUN ldconfig
WORKDIR /tmp/
