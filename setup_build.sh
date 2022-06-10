#!/bin/bash

# Set up the environment for the main build
BUILD_TAG=latest
if [[ -n "${CIRCLE_TAG}" ]]; then
    BUILD_TAG="${CIRCLE_TAG}"
fi
export BUILD_TAG

# # Versions of the components
# export TAG_FSL=22.2.0
# export TAG_FREESURFER=22.2.0
# export TAG_ANTS=22.2.6
# export TAG_MRTRIX3=22.1.0
# export TAG_3TISSUE=22.1.0
# export TAG_DSISTUDIO=22.2.10
# export TAG_MINICONDA=22.4.1
# export TAG_AFNI=22.2.0


# echo "Settings:"
# echo "----------"
# echo ""
# echo "BUILD_TAG=${BUILD_TAG}"
# echo "TAG_FSL=${TAG_FSL}"
# echo "TAG_FREESURFER=${TAG_FREESURFER}"
# echo "TAG_ANTS=${TAG_ANTS}"
# echo "TAG_MRTRIX3=${TAG_MRTRIX3}"
# echo "TAG_3TISSUE=${TAG_3TISSUE}"
# echo "TAG_DSISTUDIO=${TAG_DSISTUDIO}"
# echo "TAG_MINICONDA=${TAG_MINICONDA}"
# echo "TAG_AFNI=${TAG_AFNI}"


do_build() {

    DOCKER_BUILDKIT=1 \
    BUILDKIT_PROGRESS=plain \
    docker build -t \
        pennbbl/xcpd_build:${BUILD_TAG} \
        .

}
