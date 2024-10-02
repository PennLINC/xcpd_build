"""Convert the AtlasPack folder into a BIDS dataset."""

import json
import os
import re
import shutil

if __name__ == "__main__":
    # Where all the files are located
    in_dir = "/AtlasPack"

    with open(os.path.join(in_dir, "dataset_description.json"), "w") as fo:
        json.dump(
            {"Name": "AtlasPack", "BIDSVersion": "1.9.0", "DatasetType": "atlas"},
            fo,
        )

    # Define patterns and corresponding target formats
    patterns = [
        (r"atlas-([a-zA-Z0-9+]+)_dseg.tsv", r"atlas-\1/atlas-\1_dseg.tsv"),
        (
            r"tpl-MNI152NLin6Asym_atlas-([a-zA-Z0-9+]+)_res-01_dseg.nii.gz",
            r"atlas-\1/atlas-\1_space-MNI152NLin6Asym_res-01_dseg.nii.gz",
        ),
        (
            r"tpl-fsLR_atlas-([a-zA-Z0-9+]+)_den-91k_dseg.dlabel.nii",
            r"atlas-\1/atlas-\1_space-fsLR_den-91k_dseg.dlabel.nii",
        ),
        (
            r"tpl-MNI152NLin6Asym_atlas-([a-zA-Z0-9+]+)_dseg.json",
            r"atlas-\1/atlas-\1_space-MNI152NLin6Asym_res-01_dseg.json",
        ),
        (
            r"tpl-fsLR_atlas-([a-zA-Z0-9+]+)_dseg.json",
            r"atlas-\1/atlas-\1_space-fsLR_den-91k_dseg.json",
        ),
    ]

    for pattern, target_format in patterns:
        files = [f for f in os.listdir(in_dir) if re.search(pattern, f)]
        for filename in files:
            atlas_name = re.findall(pattern, filename)[0]
            target_dir = os.path.join(in_dir, f"atlas-{atlas_name}")
            target_path = os.path.join(in_dir, target_format.replace(r"\1", atlas_name))

            # Create target directory if it doesn't exist
            os.makedirs(target_dir, exist_ok=True)

            # Move and rename the file
            shutil.move(os.path.join(in_dir, filename), target_path)
            print(f"Moved {filename} to {target_path}")
