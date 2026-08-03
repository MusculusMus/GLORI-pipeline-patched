import sys, os, argparse, time, subprocess, pysam
import numpy as np

parser = argparse.ArgumentParser(description="building index")
parser.add_argument("-r", "--reads", nargs="?", type=str, default='read2')
parser.add_argument("-f", "--reference", nargs="?", type=str, default=sys.stdin)
parser.add_argument("-p", "--Threads", nargs="?", type=str, default='1')
parser.add_argument("-t", "--tools", nargs="?", type=str, default='STAR')
parser.add_argument("-mate_length", "--mate_length", nargs="?", type=int, default=100)
parser.add_argument("-pre", "--outname_prefix", nargs="?", type=str, default='default')
parser.add_argument("-o", "--outputdir", nargs="?", type=str, default='./')

args = parser.parse_args()
reads, reference, Threads, tools, outputdir, outname_prx = args.reads, args.reference, args.Threads, args.tools, args.outputdir, args.outname_prefix

def change_reference(reads, reference, outputdir, outname_prx):
    refer_name = outname_prx if outname_prx != 'default' else "_".join(os.path.basename(reference).split(".")[:-1])
    os.makedirs(outputdir, exist_ok=True)
        
    if reads == "read1":
        changed_refer = os.path.join(outputdir, refer_name + ".TC_conversion.fa")
        f_char, t_char, suffix = 'T', 'C', '_TC_converted'
    else:
        changed_refer = os.path.join(outputdir, outname_prx + ".AG_conversion.fa")
        f_char, t_char, suffix = 'A', 'G', '_AG_converted'
        
    subprocess.call(f"rm -f {changed_refer} 2>/dev/null", shell=True)
    
    with open(reference, 'r') as fin, open(changed_refer, 'w') as fout:
        for line in fin:
            if line.startswith('>'):
                print('Genome', line.strip()[1:])
                fout.write(line.strip() + suffix + '\n')
            else:
                fout.write(line.strip().upper().replace(f_char, t_char) + '\n')
    return changed_refer

def get_reversecom(filename, output):
    changed_refer = output + ".rvsCom.fa"
    subprocess.call(f"rm -f {changed_refer} 2>/dev/null", shell=True)
    
    with open(filename, 'r') as fin, open(changed_refer, 'w') as fout:
        for line in fin:
            if line.startswith('>'):
                print('reversecomplement Genome', line.strip()[1:])
                fout.write(line.strip() + '_AG_converted\n')
            else:
                fout.write(line.strip().upper().replace('T', 'C') + '\n')
    return changed_refer

def build_index(changed_refer, tool, Threads):
    if tool == "STAR":
        filedir_STAR = changed_refer[:-3]
        if os.path.exists(filedir_STAR):
            subprocess.call(f"rm -rf {filedir_STAR}", shell=True)
        os.makedirs(filedir_STAR, exist_ok=True)
        fh = pysam.FastaFile(changed_refer)
        genomesize = sum(fh.lengths)
        Nbases = int(round(min(14, np.log2(genomesize)/2 - 1)))
        
        # Here is the 32GB limit (34359738368 bytes) and optimized sparse index (2)
        cmd = f"STAR --runMode genomeGenerate -runThreadN {Threads} --genomeDir {filedir_STAR} --genomeFastaFiles {changed_refer} --genomeSAindexNbases {Nbases} --genomeSAsparseD 2 --limitGenomeGenerateRAM 34359738368"
        
        print(cmd)
        subprocess.call(cmd, shell=True)
    else:
        cmd = f"{tool}-build -q {changed_refer} {changed_refer}"
        subprocess.call(cmd, shell=True)

if __name__ == "__main__":
    print("**********changing genome ************")
    changed_refer = change_reference(reads, reference, outputdir, outname_prx)
    print("**********reverse complementary genome ************")
    rvs_refer = get_reversecom(reference, os.path.join(outputdir, outname_prx))
    print(f"**********Building genome index for {changed_refer} with {tools}************")
    build_index(changed_refer, tools, Threads)
    print(f"**********Building reverse complementary genome index for {rvs_refer} with {tools}************")
    build_index(rvs_refer, tools, Threads)
    print(f"**********Results will be found in {outputdir} ************")
