#!/bin/bash
#
# Preprocess data for the spinal MS lesion segmentation training pipeline.
#
# Usage: individual subject
#   ./process_data.sh <SUBJECT>
#
# Usage: parallel processing across subjects
#   sct_run_batch -script process_data.sh -path-data <PATHDATA>
#
# Manual segmentations or labels should be located under:
# PATH_DATA/derivatives/labels/SUBJECT/<CONTRAST>/
#
# Authors: Julien Cohen-Adad

# The following global variables are retrieved from the caller sct_run_batch
# but could be overwritten by uncommenting the lines below:
# PATH_DATA_PROCESSED="~/data_processed"
# PATH_RESULTS="~/results"
# PATH_LOG="~/log"
# PATH_QC="~/qc"

# Uncomment for full verbose
set -x

# Immediately exit if error
set -e -o pipefail

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Retrieve input params
SUBJECT=$1

# get starting time:
start=`date +%s`


# FUNCTIONS
# ==============================================================================

# Check if manual segmentation already exists. If it does, copy it locally. If
# it does not, perform seg.
segment_if_does_not_exist(){
  local file="$1"
  local contrast="$2"
  # Find contrast
  if [[ $contrast == "dwi" ]]; then
    folder_contrast="dwi"
  else
    folder_contrast="anat"
  fi
  # Update global variable with segmentation file name
  FILESEG="${file}_seg"
  FILESEGMANUAL="${PATH_DATA}/derivatives/labels/${SUBJECT}/${folder_contrast}/${FILESEG}-manual.nii.gz"
  echo
  echo "Looking for manual segmentation: $FILESEGMANUAL"
  if [[ -e $FILESEGMANUAL ]]; then
    echo "Found! Using manual segmentation."
    rsync -avzh $FILESEGMANUAL ${FILESEG}.nii.gz
    sct_qc -i ${file}.nii.gz -s ${FILESEG}.nii.gz -p sct_deepseg_sc -qc ${PATH_QC} -qc-subject ${SUBJECT}
  else
    echo "Not found. Proceeding with automatic segmentation."
    # Segment spinal cord
    sct_deepseg_sc -i ${file}.nii.gz -c $contrast -qc ${PATH_QC} -qc-subject ${SUBJECT}
  fi
}

register_data(){
  local file_src="$1"
  if [[ -e $file_src ]]; then
    sct_register_multimodal -i ${file_src} -d ${file_t2}$ext -dseg ${file_t2_seg}$ext -m mask_T2w.nii.gz -param step=1,type=im,algo=rigid,metric=CC,deformation=1x1x1,shrink=4,iter=10:step=2,type=im,algo=rigid,metric=CC,deformation=1x1x1,shrink=2,iter=10:step=3,type=im,algo=rigid,metric=CC,deformation=1x1x1,shrink=1,iter=5,smooth=1 -z 0 -qc ${PATH_QC} -qc-subject ${SUBJECT}
  else
    echo "Not found: $file_src"
  fi
}

# SCRIPT STARTS HERE
# ==============================================================================
# Display useful info for the log, such as SCT version, RAM and CPU cores available
sct_check_dependencies -short

# Go to folder where data will be copied and processed
cd $PATH_DATA_PROCESSED
# Copy list of participants in processed data folder
if [[ ! -f "participants.tsv" ]]; then
  rsync -avzh $PATH_DATA/participants.tsv .
fi
# Copy list of participants in results folder (used by spine-generic scripts)
if [[ ! -f $PATH_RESULTS/"participants.tsv" ]]; then
  rsync -avzh $PATH_DATA/participants.tsv $PATH_RESULTS/"participants.tsv"
fi
# Copy source images
rsync -avzh $PATH_DATA/$SUBJECT .
# Go to anat folder where all structural data are located
cd ${SUBJECT}/anat/

# Reorient to RPI
file_t2="${SUBJECT}_acq-sag_T2w"
ext=".nii.gz"
sct_image -i ${file_t2}.nii.gz -setorient RPI -o ${file_t2}_RPI.nii.gz
# Resample to 0.5mm iso
# TODO: resample to 0.5mm iso when https://github.com/neuropoly/spinalcordtoolbox/issues/3269 is fixed.
sct_resample -i ${file_t2}_RPI.nii.gz -mm 0.5x0.5x0.5 -o ${file_t2}_RPI_r.nii.gz
file_t2="${file_t2}_RPI_r"
# Segment spinal cord (only if it does not exist)
segment_if_does_not_exist $file_t2 "t2"
file_t2_seg=$FILESEG
# Create mask (used for registration)
sct_create_mask -i ${file_t2}$ext -p centerline,${file_t2_seg}$ext -o mask_T2w.nii.gz -size 30mm -f cylinder
# Crop image for faster computing
sct_crop_image -i ${file_t2}$ext -m mask_T2w.nii.gz -o ${file_t2}_crop$ext
file_t2="${file_t2}_crop"
# Register axial image to T2w sag
register_data ${SUBJECT}_acq-ax_T2w.nii.gz
register_data ${SUBJECT}_T2star.nii.gz

# Verify presence of output files and write log file if error
# ------------------------------------------------------------------------------
FILES_TO_CHECK=(
)

for file in ${FILES_TO_CHECK[@]}; do
  if [[ ! -e $file ]]; then
    echo "${SUBJECT}/${file} does not exist" >> $PATH_LOG/_error_check_output_files.log
  fi
done

# Display useful info for the log
end=`date +%s`
runtime=$((end-start))
echo
echo "~~~"
echo "SCT version: `sct_version`"
echo "Ran on:      `uname -nsr`"
echo "Duration:    $(($runtime / 3600))hrs $((($runtime / 60) % 60))min $(($runtime % 60))sec"
echo "~~~"
