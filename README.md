# GLORI-pipeline-patched
Outdated Python/SciPy bugs and STAR attribute crashes have been fixed.

## Session 1: Space-Saving Preprocessing
This script takes the raw .fastq.gz files and streams them through memory to prevent massive temporary files from filling up the hard drive.
01_preprocess.sh

## Session 2: Generate Reference Indices
This script uses the specific GRCm39 files you provided and includes the memory cap (--limitGenomeGenerateRAM) to ensure STAR does not crash standard workstations when building the A-to-G converted index.
02_build_reference.sh

## Session 3: Customized m6A Calling
This script contains the automated patch to fix the STAR bug, a prompt to remind users about the scipy fix, and the finalized bash loop to execute the tool.
03_m6A_calling.sh
