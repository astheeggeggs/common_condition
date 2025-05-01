#!/bin/bash

# Input and output variables
PLINKFILE="${1}"  # base name of .bed/.bim/.fam (no extension)
OUT="${2}"
MIN_MAC="$3"
MODELFILE="$4"
VARIANCERATIO="$5"
SPARSEGRM="$6"
SPARSEGRMID="${SPARSEGRM}.sampleIDs.txt"
GROUPFILE="$7"
ANNOTATIONS="$8"
CONDITION_RAW=$(cat "${9}")

echo -e "PLINKFILE=$PLINKFILE\nOUT=$OUT\nMIN_MAC=$MIN_MAC\nMODELFILE=$MODELFILE\nVARIANCERATIO=$VARIANCERATIO\nSPARSEGRM=$SPARSEGRM\nSPARSEGRMID=$SPARSEGRMID\nGROUPFILE=$GROUPFILE\nANNOTATIONS=$ANNOTATIONS\nCONDITION=$CONDITION_RAW"

# Strip 'chr' from chromosome names in GROUPFILE for PLINK format
GROUPFILE_TMP=$(mktemp)
sed 's/chr//g' "$GROUPFILE" > "$GROUPFILE_TMP"

# Remove 'chr' from CONDITION string if not empty
if [[ -n "$CONDITION_RAW" ]]; then
    CONDITION=$(echo "$CONDITION_RAW" | sed 's/chr//g')
else
    CONDITION=""
fi

# Temp file for output
TMPFILE=$(mktemp)

# Run the step2_SPAtests.R using PLINK input
step2_SPAtests.R \
        --bedFile=${PLINKFILE}.bed \
        --bimFile=${PLINKFILE}.bim \
        --famFile=${PLINKFILE}.fam \
        --minMAF=0 \
        --minMAC=${MIN_MAC} \
        --GMMATmodelFile=${MODELFILE} \
        --varianceRatioFile=${VARIANCERATIO} \
        --sparseGRMFile=${SPARSEGRM} \
        --sparseGRMSampleIDFile=${SPARSEGRMID} \
        --LOCO=FALSE \
        --is_Firth_beta=TRUE \
        --pCutoffforFirth=0.10 \
        --is_output_moreDetails=TRUE \
        --is_fastTest=TRUE \
        --SAIGEOutputFile=${TMPFILE} \
        --groupFile=$GROUPFILE_TMP \
        --annotation_in_groupTest=$ANNOTATIONS \
        --is_output_markerList_in_groupTest=TRUE \
        --is_single_in_groupTest=TRUE \
        --maxMAF_in_groupTest=0.0001,0.001,0.01 \
        --condition="$CONDITION"

# Append TMPFILE to OUT (header and all)
[[ -s "${TMPFILE}" ]] && cat "${TMPFILE}" >> "${OUT}"

# Also copy over single assoc files to verify case/control numbers
[[ -s "${TMPFILE}.singleAssoc.txt" ]] && cat "${TMPFILE}.singleAssoc.txt" >> "${OUT}.singleAssoc.txt"

# Ensure output exists for Snakemake
touch "${OUT}"

# Clean up
rm -f "${TMPFILE}" "$GROUPFILE_TMP"