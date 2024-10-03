FROM pennlinc/xcp_d:0.1.3 as build_fsl
FROM pennlinc/atlaspack:0.1.0 as atlaspack
FROM ubuntu:jammy-20240911.1

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
        lsb-release \
        pandoc \
        pandoc-citeproc \
        pkg-config \
        unzip \
        wget \
        xvfb \
        && \
    curl -sSL https://deb.nodesource.com/setup_21.x | bash - && \
    apt-get install -y --no-install-recommends \
        nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV OS="Linux" \
    FIX_VERTEX_AREA=""

# Install and set up miniconda
RUN curl -sSLO https://repo.continuum.io/miniconda/Miniconda3-py310_23.10.0-1-Linux-x86_64.sh && \
    bash Miniconda3-py310_23.10.0-1-Linux-x86_64.sh -b -p /usr/local/miniconda && \
    rm Miniconda3-py310_23.10.0-1-Linux-x86_64.sh

# Set CPATH for packages relying on compiled libs (e.g. indexed_gzip)
ENV PATH="/usr/local/miniconda/bin:$PATH" \
    CPATH="/usr/local/miniconda/include:$CPATH" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    PYTHONNOUSERSITE=1

# Install precomputed python packages
RUN conda install -y \
        python=3.10 \
        libxslt=1.1 \
        mkl=2021.2 \
        mkl-service=2.3 \
        numpy=1.18.1 \
        pandas=1.2 \
        scikit-learn=0.24 \
        scipy=1.6 \
        traits=6.2 \
        zstd=1.4; \
    sync && \
    pip install \
        matplotlib \
        requests \
        templateflow ; \
    sync && \
    chmod -R a+rX /usr/local/miniconda; sync && \
    chmod +x /usr/local/miniconda/bin/*; sync && \
    conda clean --all; sync

# Set up NeuroDebian
RUN curl -sSL "http://neuro.debian.net/lists/$( lsb_release -c | cut -f2 ).us-ca.full" >> /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-key add /usr/local/etc/neurodebian.gpg && \
    (apt-key adv --refresh-keys --keyserver hkp://ha.pool.sks-keyservers.net 0xA5D32F012649A5A9 || true)

# Install Connectome Workbench and git-annex
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        connectome-workbench \
        git-annex-standalone && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install AFNI latest (neurodocker build)
# Need to symlink libXpm.so.4.11.0 to libXp.so.6 because AFNI expects libXp.so.6.
RUN apt-get update -qq \
&& apt-get install -y -q --no-install-recommends \
       apt-utils \
       ed \
       gsl-bin \
       curl \
       libglib2.0-0 \
       libglu1-mesa-dev \
       libglw1-mesa \
       libgomp1 \
       libjpeg62 \
       libxm4 \
       libxpm4 \
       netpbm \
       tcsh \
       xfonts-base \
       xvfb \
&& ln -s /usr/lib/x86_64-linux-gnu/libXpm.so.4.11.0 /usr/lib/x86_64-linux-gnu/libXp.so.6 \
&& echo "Downloading AFNI ..." \
&& mkdir -p /opt/afni-latest \
&& curl -fsSL --retry 5 https://afni.nimh.nih.gov/pub/dist/tgz/linux_openmp_64.tgz \
| tar -xz -C /opt/afni-latest --strip-components 1

# Configure AFNI
ENV PATH="$PATH:/opt/afni-latest" \
    AFNI_INSTALLDIR=/opt/afni-latest \
    AFNI_IMSAVE_WARNINGS=NO

RUN echo "Downloading C3D ..." \
    && mkdir /opt/c3d \
    && curl -sSL --retry 5 https://sourceforge.net/projects/c3d/files/c3d/1.0.0/c3d-1.0.0-Linux-x86_64.tar.gz/download \
    | tar -xzC /opt/c3d --strip-components=1
ENV C3DPATH=/opt/c3d/bin \
    PATH=/opt/c3d/bin:$PATH

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
COPY --from=build_fsl /usr/lib/libniftiio.so.2 /opt/fsl/lib/libniftiio.so.2
COPY --from=build_fsl /usr/lib/libznz.so.2 /opt/fsl/lib/libznz.so.2
# Install applywarp from FSL for UK Biobank data
COPY --from=build_fsl /usr/lib/fsl/5.0/applywarp /opt/fsl/lib/applywarp

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

# Install ANTS
ENV ANTSPATH="/usr/lib/ants"
RUN mkdir -p $ANTSPATH && \
    curl -sSL "https://github.com/ANTsX/ANTs/releases/download/v2.5.3/ants-2.5.3-ubuntu-22.04-X64-gcc.zip" -o /tmp/ants.zip && \
    unzip /tmp/ants.zip -d $ANTSPATH && \
    rm /tmp/ants.zip
ENV PATH=/usr/lib/ants/ants-2.5.3/bin:$PATH

# Install SVGO
RUN npm install -g svgo

# Install bids-validator
RUN npm install -g bids-validator@1.8.4

# Unless otherwise specified each process should only use one thread - nipype
# will handle parallelization
ENV MKL_NUM_THREADS=1 \
    OMP_NUM_THREADS=1

# Create a shared $HOME directory
RUN useradd -m -s /bin/bash -G users xcp_d
WORKDIR /home/xcp_d
ENV HOME="/home/xcp_d"

# Must do this after setting up home directory
# Precaching fonts, set "Agg" as default backend for matplotlib
RUN python -c "from matplotlib import font_manager" && \
    sed -i 's/\(backend *: \).*$/\1Agg/g' $( python -c "import matplotlib; print(matplotlib.matplotlib_fname())" )

# Precaching templates
COPY scripts/fetch_templates.py fetch_templates.py
RUN python fetch_templates.py && \
    rm fetch_templates.py && \
    find $HOME/.cache/templateflow -type d -exec chmod go=u {} + && \
    find $HOME/.cache/templateflow -type f -exec chmod go=u {} +

# Reformat AtlasPack into a BIDS dataset
COPY scripts/fix_atlaspack.py fix_atlaspack.py
RUN python fix_atlaspack.py && rm fix_atlaspack.py

# Install pandoc (for HTML/LaTeX reports)
RUN curl -o pandoc-2.2.2.1-1-amd64.deb -sSL "https://github.com/jgm/pandoc/releases/download/2.2.2.1/pandoc-2.2.2.1-1-amd64.deb" && \
    dpkg -i pandoc-2.2.2.1-1-amd64.deb && \
    rm pandoc-2.2.2.1-1-amd64.deb

RUN find $HOME -type d -exec chmod go=u {} + && \
    find $HOME -type f -exec chmod go=u {} + && \
    rm -rf $HOME/.npm $HOME/.conda $HOME/.empty

RUN ldconfig
WORKDIR /tmp/
