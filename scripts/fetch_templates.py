#!/usr/bin/env python
#
# STATEMENT OF CHANGES: This file is derived from sources licensed under the Apache-2.0 terms,
# and uses the following portion of the original code:
# https://github.com/nipreps/fmriprep/blob/fe7c9ff8731635d7f25749f2afd99eb77d26305d/scripts/
# fetch_templates.py#L10-L136
#
# ORIGINAL WORK'S ATTRIBUTION NOTICE:
#
#     Copyright The NiPreps Developers <nipreps@gmail.com>
#
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.
#
#     We support and encourage derived works from this project, please read
#     about our expectations at
#
#         https://www.nipreps.org/community/licensing/
"""
Standalone script to facilitate caching of required TemplateFlow templates.

To download and view how to use this script, run the following commands inside a terminal:
1. wget https://raw.githubusercontent.com/pennlinc/qsirecon_build/main/scripts/fetch_templates.py
2. python fetch_templates.py -h
"""

import argparse
import os


def fetch_MNI2009():
    """
    Expected templates:

    tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_T1w.nii.gz
    tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_desc-carpet_dseg.nii.gz
    tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-02_desc-brain_mask.nii.gz
    tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_from-MNI152NLin6Asym_mode-image_xfm.h5
    """
    template = "MNI152NLin2009cAsym"

    tf.get(template, resolution=1, desc=None, suffix="T1w")
    tf.get(template, resolution=1, desc="carpet", suffix="dseg")
    tf.get(template, resolution=2, desc="brain", suffix="mask")
    tf.get(template, mode="image", suffix="xfm", extension=".h5", **{"from": "MNI152NLin6Asym"})


def fetch_MNI6():
    """
    Expected templates:

    tpl-MNI152NLin6Asym/tpl-MNI152NLin6Asym_res-01_T1w.nii.gz
    tpl-MNI152NLin6Asym/tpl-MNI152NLin6Asym_from-MNI152NLin2009cAsym_mode-image_xfm.h5
    """
    template = "MNI152NLin6Asym"

    tf.get(template, resolution=1, desc=None, suffix="T1w")
    tf.get(template, mode="image", suffix="xfm", extension=".h5", **{"from": "MNI152NLin2009cAsym"})


def fetch_MNIInfant():
    """
    Expected templates:

    tpl-MNIInfant/tpl-MNIInfant_cohort-1_res-01_T1w.nii.gz
    tpl-MNIInfant/tpl-MNIInfant_cohort-2_res-01_T1w.nii.gz
    tpl-MNIInfant/tpl-MNIInfant_cohort-3_res-01_T1w.nii.gz
    tpl-MNIInfant/tpl-MNIInfant_cohort-4_res-01_T1w.nii.gz
    tpl-MNIInfant/tpl-MNIInfant_cohort-5_res-01_T1w.nii.gz
    tpl-MNIInfant/tpl-MNIInfant_cohort-6_res-01_T1w.nii.gz
    tpl-MNIInfant/tpl-MNIInfant_cohort-7_res-01_T1w.nii.gz
    tpl-MNIInfant/tpl-MNIInfant_cohort-8_res-01_T1w.nii.gz
    tpl-MNIInfant/tpl-MNIInfant_cohort-9_res-01_T1w.nii.gz
    tpl-MNIInfant/tpl-MNIInfant_cohort-10_res-01_T1w.nii.gz
    tpl-MNIInfant/tpl-MNIInfant_cohort-11_res-01_T1w.nii.gz
    """
    template = "MNIInfant"

    tf.get(template, resolution=1, desc=None, suffix="T1w")


def fetch_fsaverage():
    """
    Expected templates:

    tpl-fsaverage/tpl-fsaverage_hemi-L_den-164k_sphere.surf.gii
    tpl-fsaverage/tpl-fsaverage_hemi-L_den-41k_sphere.surf.gii
    tpl-fsaverage/tpl-fsaverage_hemi-R_den-164k_sphere.surf.gii
    tpl-fsaverage/tpl-fsaverage_hemi-R_den-41k_sphere.surf.gii
    """
    template = "fsaverage"

    tf.get(template, density="164k", desc=None, suffix="sphere")
    tf.get(template, density="41k", desc=None, suffix="sphere")


def fetch_fsLR():
    """
    Expected templates:

    tpl-fsLR/tpl-fsLR_hemi-L_den-32k_desc-vaavg_midthickness.shape.gii
    tpl-fsLR/tpl-fsLR_hemi-L_den-32k_midthickness.shape.gii
    tpl-fsLR/tpl-fsLR_hemi-L_den-32k_sphere.surf.gii
    tpl-fsLR/tpl-fsLR_hemi-R_den-32k_desc-vaavg_midthickness.shape.gii
    tpl-fsLR/tpl-fsLR_hemi-R_den-32k_midthickness.shape.gii
    tpl-fsLR/tpl-fsLR_hemi-R_den-32k_sphere.surf.gii
    """
    tf.get("fsLR", density="32k", desc=None, suffix="midthickness")
    tf.get("fsLR", density="32k", desc="vaavg", suffix="midthickness")
    tf.get("fsLR", space=None, density="32k", suffix="sphere")


def fetch_dhcpAsym():
    """
    Expected templates:

    tpl-dhcpAsym/tpl-dhcpAsym_cohort-42_hemi-L_den-32k_sphere.surf.gii
    tpl-dhcpAsym/tpl-dhcpAsym_cohort-42_hemi-R_den-32k_sphere.surf.gii
    tpl-dhcpAsym/tpl-dhcpAsym_cohort-42_space-fsaverage_hemi-L_den-41k_desc-reg_sphere.surf.gii
    tpl-dhcpAsym/tpl-dhcpAsym_cohort-42_space-fsaverage_hemi-R_den-41k_desc-reg_sphere.surf.gii
    """
    template = "dhcpAsym"

    tf.get(template, cohort="42", space="fsaverage", density="41k", desc="reg", suffix="sphere")
    tf.get(template, cohort="42", space=None, density="32k", desc=None, suffix="sphere")


def fetch_all():
    fetch_MNI2009()
    fetch_MNI6()
    fetch_MNIInfant()
    fetch_fsaverage()
    fetch_fsLR()
    fetch_dhcpAsym()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Helper script for pre-caching required templates to run fMRIPrep",
    )
    parser.add_argument(
        "--tf-dir",
        type=os.path.abspath,
        help=(
            "Directory to save templates in. "
            "If not provided, templates will be saved to `${HOME}/.cache/templateflow`."
        ),
    )
    opts = parser.parse_args()

    # set envvar (if necessary) prior to templateflow import
    if opts.tf_dir is not None:
        os.environ["TEMPLATEFLOW_HOME"] = opts.tf_dir

    import templateflow.api as tf

    fetch_all()
