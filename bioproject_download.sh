#!/usr/bin/bash
#---|
# id			tools.download/bioproject_download.sh
# creation		2019.01.11
# author 		Sean Aller | seandavid.a@gmail.com
# description 	Script for downloading all samples from a supplied bioproject
#---|
# Bash Settings
set -o errexit   			# Abort on nonzero exitstatus
set -o nounset   			# Abort on unbound variable
set -o pipefail  			# Don't hide errors within pipes
#---| START
# Input Arguments
BIOPRO=$1
#---|

#---|
# Obtain the download information file and parse out download links
RUNFILE=SraRunInfo.csv
DOWNFILE=SraRunDownload.txt
wget 'http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&rettype=runinfo&db=sra&term='${BIOPRO}'' -O - | tee ${RUNFILE}
awk -F "\"*,\"*" '{print $10}' ${RUNFILE} > ${DOWNFILE}
tail -n +2 ${DOWNFILE} > tmp.txt && mv tmp.txt ${DOWNFILE}
SAMPLENUM=$(wc -l < ${DOWNFILE})
echo "Downloading ${SAMPLENUM} samples in BioProject ${BIOPRO}"
#---|
# Begin download of sample files
OUTDIR=${PWD}/samples
mkdir ${PWD}/samples
while read SAMPLE; do wget ${SAMPLE} -P ${OUTDIR}; done < ${DOWNFILE}
#---|
# Completed
echo "Completed downloads for ${BIOPRO}"
#---| END