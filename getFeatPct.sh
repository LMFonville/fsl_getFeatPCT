#!/bin/sh

# Alternative to featquery if you just want signal percentage change from an ROI without all the bells and whistles
# Uses robust mean and standard deviation options from fslstats to ignore empty voxels.

# For a better understanding of how it works check the guide to calculating percentage signal change:
# http://mumford.fmripower.org/perchange_guide.pdf
# update: now found at https://jeanettemumford.org/assets/files/perchange_guide.pdf
# update2: featquery code at http://ftp.nmr.mgh.harvard.edu/pub/dist/freesurfer/tutorial_packages/centos6/fsl_507/bin/featquery

# Can work with first-level outputs as well as fixed-effects mid-level outputs
# just adjust the path to the stats folder accordingly!
# For now input arguments are fixed in position
# Provide input and output folder and ROI mask path as well as cope number if needed

Usage() {
  echo ""
  echo "Extract percentage signal change from cope images found within FSL's feat folders."
  echo "Usage: getFeatPct.sh <feat folder> <working directory> <roi image> <contrast index>"
  echo "If used with higher level analysis, do not use .gfeat folder but select relevant .feat folder inside."
  exit
}

[ "$1" = "" ] && Usage

# Make sure FSL is available
if [ -z $FSLDIR ]; then
  echo "Make sure FSL is available in your environment"
  exit
fi

inputpath=$1
outputpath=$2
maskimage=$3
# check if cope number is specified
if [ -z $4 ]; then cope=1; else cope=$4; fi
cd ${inputpath}

cope_idx=$(bc <<< 1+${cope}) # get the appropriate column index for PP heights, column 2 is cope 1 etc.

# get images and scaling factor
statsimage=stats/cope${cope}.nii.gz
scale_hl=`grep PPheights design.con | awk '{ print $'${cope_idx}'}'`
# convert from scientific notation to integer
scale_hl=`echo $scale_hl | awk '{printf "%.6f\n", $1}'`
scale_ll=1

if [ -f design.lcon ]; then
    scale_ll=`cat design.lcon`
fi

scaling_factor=$(bc <<< "100.0*${scale_ll}*${scale_hl}")

meanimage=mean_func.nii.gz

# produce temporary PCT output image
fslmaths ${statsimage} -mul ${scaling_factor} -div ${meanimage} -mul ${maskimage} ${outputpath}/pct_tmp
# get percentage signal change
pct=`fslstats ${outputpath}/pct_tmp -M -S`
# remove temporary file
rm ${outputpath}/pct_tmp.nii.gz
# return percentage signal change
echo ${pct}
