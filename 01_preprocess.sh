#!/bin/bash
# ==============================================================================
# Script: 01_preprocess.sh
# Description: Trims adapters, removes duplicates, and trims UMI sequences.
# Optimized to stream data directly through RAM to save hard drive space.
# ==============================================================================

THREADS=12
UMI_LEN=9
MIN_LEN=$((UMI_LEN + 25))
TRIM_START=$((UMI_LEN + 1))
OUTPUT_DIR="./FASTQ_file/cleaned_reads"

mkdir -p $OUTPUT_DIR

for file in ./FASTQ_file/*.fastq.gz; do
    
    # Extract the base name (e.g., cuts "SRR31477255" from "SRR31477255.fastq.gz")
    filename=$(basename "$file")
    base="${filename%%.*}"
    
    echo "========================================"
    echo "Starting space-saving preprocessing for $base..."
    echo "========================================"
    
    # Step 1: Trim adapters and low-quality bases (Outputs compressed .gz)
    trim_galore -q 20 --stringency 1 -e 0.3 --length $MIN_LEN -o $OUTPUT_DIR $file
    
    # Step 2 & 3: Piped Execution (Streams directly in RAM)
    seqkit rmdup -j $THREADS -s -D ${OUTPUT_DIR}/${base}_duplicate_names.txt ${OUTPUT_DIR}/${base}_trimmed.fq.gz | \
    fastx_trimmer -Q 33 -f $TRIM_START -o ${OUTPUT_DIR}/${base}_clean.fq
    
    # Cleanup compressed intermediate
    rm ${OUTPUT_DIR}/${base}_trimmed.fq.gz
    
    echo "Finished $base! Final file is ${OUTPUT_DIR}/${base}_clean.fq"
done
