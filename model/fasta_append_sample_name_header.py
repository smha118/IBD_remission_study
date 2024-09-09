import argparse
import os


parser = argparse.ArgumentParser(description = "Input specifications ")
parser.add_argument("--in", dest="input_fasta", required=True, type=str, help="input fasta file, without sample tags in header lines")
parser.add_argument("--out", dest="output_fasta", required=True, type=str, help="output fasta file, with header lines >~~~;sample=SAMPLE;")
parser.add_argument("--sample", dest="sample_name", required=True, type=str, help="sample name")
args = parser.parse_args()
input_fasta = args.input_fasta
output_fasta = args.output_fasta
sample_name = args.sample_name



fw = open(output_fasta, 'w')
fr = open(input_fasta, 'r')
for line in fr:
    if line.strip().startswith('>'):
        fw.write(line.strip() + ";sample=" + sample_name + ";\n")
    else:
        fw.write(line.strip() + "\n")
fr.close()
fw.close()

