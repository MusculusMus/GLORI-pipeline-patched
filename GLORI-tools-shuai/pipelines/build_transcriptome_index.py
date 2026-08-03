import sys, os, argparse, subprocess

parser = argparse.ArgumentParser(description="building index for reference")
parser.add_argument("-r", "--reads", nargs="?", type=str, default='read2')
parser.add_argument("-f", "--reference", nargs="?", type=str, default=sys.stdin)
parser.add_argument("-p", "--Threads", nargs="?", type=str, default='1')
parser.add_argument("-t", "--tools", nargs="?", type=str, default='bowtie2')
parser.add_argument("-mate_length", "--mate_length", nargs="?", type=int, default=100)
parser.add_argument("-pre", "--outname_prefix", nargs="?", type=str, default='default')
parser.add_argument("-o", "--outputdir", nargs="?", type=str, default='./')

args = parser.parse_args()

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
    
    # Pure Python replacement to avoid the Biopython bug
    with open(reference, 'r') as fin, open(changed_refer, 'w') as fout:
        for line in fin:
            if line.startswith('>'):
                # Intentionally not printing names here; transcriptomes have thousands 
                # of entries and printing them all would crash/slow down the terminal.
                fout.write(line.strip() + suffix + '\n')
            else:
                fout.write(line.strip().upper().replace(f_char, t_char) + '\n')
    return changed_refer

def build_index(changed_refer, tool, Threads):
    # Enforce bowtie2 and apply the Threads argument
    cmd = f"bowtie2-build --threads {Threads} -q {changed_refer} {changed_refer}"
    print(cmd)
    subprocess.call(cmd, shell=True)

if __name__ == "__main__":
    print("**********changing transcriptome ************")
    changed_refer = change_reference(args.reads, args.reference, args.outputdir, args.outname_prefix)
    print(f"**********Building transcriptome index for {changed_refer} with bowtie2************")
    build_index(changed_refer, 'bowtie2', args.Threads)
    print(f"**********Results will be found in {args.outputdir} ************")
