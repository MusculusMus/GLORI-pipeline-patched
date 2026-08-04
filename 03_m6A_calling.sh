#!/bin/bash
# ==============================================================================
# Script: 03_m6A_calling.sh
# Description: Runs GLORI-tools m6A calling. 
# Includes patches for STAR 2.7.11b attribute bugs and Python 3.13 SciPy updates.
# ==============================================================================

# --- 1. APPLY CUSTOM PATCHES TO ORIGINAL GLORI SOURCE CODE ---
# Fixes the fatal '--outSAMattributes All' bug in newer versions of STAR
echo "Patching GLORI-tools to support STAR 2.7+..."
find ./GLORI-tools-1.0.0/ -type f -name "*.py" -exec sed -i 's/--outSAMattributes All/--outSAMattributes NH HI AS nM NM MD/g' {} +

# Note for users running Python 3.13+:
# You MUST manually change line 120 in ./pipelines/m6A_caller.py
# From: pvalue = scipy.stats.binom_test(A_count_col, n=AG_col, alternative='greater', p=nonCR)
# To:   pvalue = scipy.stats.binomtest(A_count_col, n=AG_col, alternative='greater', p=nonCR).pvalue


# --- 2. SET VARIABLES ---
Thread=12
genomdir=./GRCm39_Reference
genome=${genomdir}/mm39.AG_conversion.fa
genome2=${genomdir}/mm39.fa
rvsgenome=${genomdir}/mm39.rvsCom.fa
TfGenome=${genomdir}/GCF_000001635.27_GRCm39_rna2.fa.AG_conversion.fa

annodir=./GRCm39_Reference
baseanno=${annodir}/GCF_000001635.27_GRCm39_genomic.gtf_change2Ens.tbl2.noredundance.base
anno=${annodir}/GCF_000001635.27_GRCm39_genomic.gtf_change2Ens.tbl2

outputdir=./GLORI_results
tooldir=./GLORI-tools-1.0.0

mkdir -p $outputdir

# --- 3. RUN PIPELINE ---
for file in ./FASTQ_file/cleaned_reads/*_clean.fq; do
    
    base=$(basename $file _clean.fq)
    prx=${base}_mapped
    
    echo "========================================"
    echo "Running GLORI pipeline for $base..."
    echo "========================================"
    
    python ${tooldir}/run_GLORI.py \
        -i $tooldir \
        -q ${file} \
        -T $Thread \
        -f ${genome} \
        -f2 ${genome2} \
        -rvs ${rvsgenome} \
        -Tf ${TfGenome} \
        -a $anno \
        -b $baseanno \
        -pre ${prx} \
        -o $outputdir \
        --combine \
        --rvs_fac
        
    echo "Finished mapping $base!"
done
