#!/bin/bash
# ==============================================================================
# Script: 02_build_reference.sh
# Description: Generates STAR and Bowtie indices and base annotations for mm39.
# Adapted from original hg38 GLORI-tools guidelines.
# ==============================================================================

THREADS=4
REF_DIR="./GRCm39_Reference"
TOOL_DIR="./GLORI-tools-1.0.0"

# Input files provided
REPORT="GCF_000001635.27_GRCm39_assembly_report.txt"
GTF="GCF_000001635.27_GRCm39_genomic.gtf"
GENOME="mm39.fa"
RNA="GCF_000001635.27_GRCm39_rna.fna"

# Move into the reference directory so all generated files stay organized
cd $REF_DIR

echo "========================================"
echo "1. Generating Annotation Files"
echo "========================================"
# 1.3 Unify chromosome naming in GTF file and genome file
python ../${TOOL_DIR}/get_anno/change_UCSCgtf.py \
    -i $GTF \
    -j $REPORT \
    -o ${GTF}_change2Ens

echo "========================================"
echo "2. Getting Reference for Reads Alignment"
echo "========================================"

# Patch STAR memory limit into the python script to prevent workstation crashes
sed -i 's/--runMode genomeGenerate/--runMode genomeGenerate --limitGenomeGenerateRAM 34359738368/g' ../${TOOL_DIR}/pipelines/build_genome_index.py

# 2.1 Build genome index using STAR (includes A-to-G conversion)
python ../${TOOL_DIR}/pipelines/build_genome_index.py \
    -f $GENOME \
    -p $THREADS \
    -pre mm39

# 2.2 Build transcriptome index using bowtie (v1)
# 2.2.1 Get the longest transcript for genes
python ../${TOOL_DIR}/get_anno/gtf2anno.py \
    -i ${GTF}_change2Ens \
    -o ${GTF}_change2Ens.tbl

awk '$3!~/_/&&$3!="na"' ${GTF}_change2Ens.tbl | sed '/unknown_transcript/d' > ${GTF}_change2Ens.tbl2

python ../${TOOL_DIR}/get_anno/selected_longest_transcrpts_fa.py \
    -anno ${GTF}_change2Ens.tbl2 \
    -fafile $RNA \
    --outname_prx GCF_000001635.27_GRCm39_rna2.fa

# 2.2.2 Build reference with bowtie
python ../${TOOL_DIR}/pipelines/build_transcriptome_index.py \
    -f GCF_000001635.27_GRCm39_rna2.fa \
    -pre GCF_000001635.27_GRCm39_rna2.fa

echo "========================================"
echo "3. Getting Base Annotation"
echo "========================================"
# 3.1 Get annotation at single-base resolution
python ../${TOOL_DIR}/get_anno/anno_to_base.py \
    -i ${GTF}_change2Ens.tbl2 \
    -threads $THREADS \
    -o ${GTF}_change2Ens.tbl2.baseanno

# 3.2 Get required annotation file for further removal of duplicated loci
python ../${TOOL_DIR}/get_anno/gtf2genelist.py \
    -i ${GTF}_change2Ens \
    -f $RNA \
    -o ${GTF}_change2Ens.genelist > output2

awk '$6!~/_/&&$6!="na"' ${GTF}_change2Ens.genelist > ${GTF}_change2Ens.genelist2

# 3.3 Removal of duplicated loci in the annotation file
python ../${TOOL_DIR}/get_anno/anno_to_base_remove_redundance_v1.0.py \
    -i ${GTF}_change2Ens.tbl2.baseanno \
    -o ${GTF}_change2Ens.tbl2.noredundance.base \
    -g ${GTF}_change2Ens.genelist2

cd ..
echo "Reference building complete! Indices are ready for m6A calling."
