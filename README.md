# Customized GLORI-tools Pipeline for m6A Calling

A customized and fully patched pipeline for the absolute quantification of m6A RNA modifications (GLORI). 

This repository is a customized fork of the original [GLORI-tools](https://github.com/liucongcas/GLORI-tools). It has been specifically updated to resolve fatal runtime errors in newer environments (like Python 3.13+ and STAR 2.7+).

## Key Optimizations & Patches

1. **STAR 2.7+ Compatibility Patch:** Newer versions of STAR crash when encountering the `--outSAMattributes All` flag due to conflicts with the `ch` tag. This repository includes an automated patch that recursively replaces this with the safe standard `--outSAMattributes NH HI AS nM NM MD`, preventing the pipeline from crashing during mapping.
2. **SciPy 1.12.0+ Compatibility Fix:** The original Python scripts rely on `scipy.stats.binom_test`, which was permanently removed in SciPy v1.12.0. This updated workflow includes instructions and patches to transition to the modern `scipy.stats.binomtest().pvalue` function, allowing the pipeline to run smoothly on modern Python distributions (e.g., Python 3.13).

---

## Pipeline Workflow

The pipeline is structured into three sequential sessions for easy, step-by-step reproduction.

### Session 1: Space-Saving Preprocessing (`01_preprocess.sh`)
This script handles the raw `.fastq.gz` inputs. It utilizes Trim Galore to remove adapters and low-quality bases, then pipes the output through SeqKit (for deduplication) and FASTX-Toolkit (for UMI trimming) in memory.
* **Input:** Raw `.fastq.gz` files.
* **Output:** Cleaned, uncompressed `.fq` files ready for the GLORI Python tool.

### Session 2: Reference Index Generation (`02_build_reference.sh`)
This script builds the necessary mapping indices for both STAR and Bowtie. It is pre-configured for the GRCm39 mouse reference genome and transcriptome. This step only needs to be performed once; the generated indices can be reused repeatedly for all future samples aligned to this reference.
* **Note:** Building the A-to-G converted genome index is highly memory-intensive. This script includes a strict RAM cap (`--limitGenomeGenerateRAM 51539607552`) to prevent crashes on standard 64GB/128GB workstations. 
* **Dependency:** You *must* use Bowtie version 1 (not Bowtie 2) for the transcriptome indices, as the downstream Python scripts hardcode `bowtie` (v1) parameters.
* Four files for mouse genome and transcriptome from [Genome assembly GRCm39](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000001635.27/) and [UCSC GRCm39/mm39](https://hgdownload.soe.ucsc.edu/goldenPath/mm39/bigZips/).
  `GCF_000001635.27_GRCm39_assembly_report.txt`,`GCF_000001635.27_GRCm39_genomic.gtf`, `GCF_000001635.27_GRCm39_rna.fna` and `mm39.fa`.

### Session 3: m6A Calling (`03_m6A_calling.sh`)
The core wrapper script that triggers the `run_GLORI.py` pipeline. 
* **Note on Python 3.13:** Before running this session on a new environment, ensure you apply the SciPy patch to the `m6A_caller.py` script as documented in the code comments, or install an older version of SciPy (`pip install "scipy<1.12.0"`).

---

## Dependencies
Ensure the following tools are available in your `$PATH` before running:
* **STAR** (v2.7+)
* **Bowtie** (v1.x - *Crucial: Bowtie2 will not work*)
* **Trim Galore** (v2.0+)
* **SeqKit**
* **FASTX-Toolkit** (`fastx_trimmer`)
* **Python** (v3.x) with `scipy`, `numpy`, and `pandas`

## License & Attribution
This software is released under the [MIT License](LICENSE). 
* Customized and optimized by Shuai Wang.
* Original `GLORI-tools` framework developed by Cong Liu (Copyright (c) 2022).
