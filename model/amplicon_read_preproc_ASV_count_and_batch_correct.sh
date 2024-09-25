# input = the only command line input is the sample name
# usage: ./amplicon_read_preproc_ASV_count_and_batch_correct_v2.sh SRR15702544
## Importantly, you must have input paired-end raw read fastq files as SAMPLE_1.fastq.gz and SAMPLE_2.fastq.gz in the current path!!
## The input raw reads must be from stool sample 16S amplicon sequencing.
## The 16S amplicon must be targeted at either bacterial V3-V4 or bacterial V4 region.

# output = three output files
## [1] SAMPLE.all_asv_batch_corrected_count.tsv: batch-corrected read count of all ASVs (a two column tsv file with header row; column 1 = 'asv' = ASV name, column 2 = 'batch_corr_count' = read count after batch effect correction)
## [2] SAMPLE.model_asv_uncorrected_count.tsv: uncorrected read count of the ASVs used in prognostic model (a two column tsv file with header row; column 1 = 'asv' = ASV name, column 2 = 'uncorr_count' = read count as is provided in the input)
## [3] SAMPLE.model_asv_batch_corrected_count.tsv: batch-corrected read count of the ASVs used in prognostic model (a two column tsv file with header row; column 1 = 'asv' = ASV name, column 2 = 'batch_corr_count' = read count after batch effect correction)
SAMPLE=$1
METADATA=$2

# dependencies
## a) executable commands
### a.1) fastp
#### --> conda install -c bioconda fastp
### a.2) usearch11.0.667_i86linux32
#### --> wget https://drive5.com/downloads/usearch11.0.667_i86linux32.gz; gzip -d usearch11.0.667_i86linux32.gz; chmod +x usearch11.0.667_i86linux32
### a.3) vsearch
#### --> conda install bioconda::vsearch
## b) python script file at place
### b.1) fasta_append_sample_name_header.py
## c) R script file at place
### c.1) model_input_batch_correct_mmuphin.r
## d) R libraries pre-installed
### d.1) MMUPHin
#### if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
#### --> BiocManager::install("MMUPHin")
### d.2) optparse
#### --> install.packages("optparse")
## e) reference data files 
### e.1) pan_study_pooled_asv.ACHIKNS_ver.clu_id100_cov90s_rep_seq.fasta
### e.2) model_input_dataset.uncorrected_ASV_count_table.tsv
### e.3) model_input_dataset.covariate_data_frame.tsv
### e.4) asv_used_in_prognostic_model.tsv


# (1) file paths
echo "Start on sample ${SAMPLE}"
# files for the input samples
raw_pe_1="${SAMPLE}_1.fastq.gz"
raw_pe_2="${SAMPLE}_2.fastq.gz"
merged_fq="${SAMPLE}.merged.fastq"
trimmed_fq="${SAMPLE}.trimmed.fastq"
filtered_fa="${SAMPLE}.filtered.fasta"
modified_header_fa="${SAMPLE}.count_input.fasta"
asvtabout="${SAMPLE}.GLASV_asv_count.tsv"
all_asv_corrected_tabout="${SAMPLE}.all_asv_batch_corrected_count.tsv"
model_asv_uncorrected_tabout="${SAMPLE}.model_asv_uncorrected_count.tsv"
model_asv_corrected_tabout="${SAMPLE}.model_asv_batch_corrected_count.tsv"
# files supplied from beginning
refasv_seqdb="pan_study_pooled_asv.ACHIKNS_ver.clu_id100_cov90s_rep_seq.fasta"
refasvtab_count="model_input_dataset.uncorrected_ASV_count_table.tsv"
refasvtab_metacovar="model_input_dataset.covariate_data_frame.tsv"
model_asv_table="asv_used_in_prognostic_model.tsv"
# if there is a missing file, quit
if [ ! -f ${refasv_seqdb} ]; then
	echo "Missing a necessary reference file: ${refasv_seqdb}"
	exit 0
fi
if [ ! -f ${refasvtab_count} ]; then
	echo "Missing a necessary reference file: ${refasvtab_count}"
	exit 0
fi
if [ ! -f ${refasvtab_metacovar} ]; then
	echo "Missing a necessary reference file: ${refasvtab_metacovar}"
	exit 0
fi
if [ ! -f ${model_asv_table} ]; then
	echo "Missing a necessary reference file: ${model_asv_table}"
	exit 0
fi


# (2) merge paired ends
echo "Merge paired-end reads into joined full amplicon sequences"
fastp -i ${raw_pe_1} -I ${raw_pe_2} --merge --merged_out ${merged_fq} --html ${merged_fq%.fastq}.QC_merge.html --report_title ${SAMPLE}


# (3) trim the reads (primers assumed to be < 20 bp)
echo "Trim terminal 20 bases to remove primer parts, approximately"
usearch -fastx_truncate ${merged_fq} -stripleft 20 -stripright 20 -relabel ${SAMPLE} -fastqout ${trimmed_fq}


# (4) filter low quality reads 
echo "Filter out low quality reads"
usearch -fastq_filter ${trimmed_fq} -fastq_maxee 5.0 -fastq_minlen 180 -fastaout ${filtered_fa}


# (5) add sample name field to the header lines of the fasta file 
echo "Append sample names in fasta header"
echo python fasta_append_sample_name_header.py --in ${filtered_fa} --out ${modified_header_fa} --sample ${SAMPLE}
python fasta_append_sample_name_header.py --in ${filtered_fa} --out ${modified_header_fa} --sample ${SAMPLE}


# (6) create ASV read count table from reads, by aligning the reads to the ASVs defined from the training dataset
echo "Map reads to pre-defined ASV reference sequences, create ASV count table"
vsearch --usearch_global ${modified_header_fa} --db ${refasv_seqdb} --id 0.95 --otutabout ${asvtabout} --strand both --threads 4


# (7) batch correct and produce a new asv table
Rscript model_input_batch_correct_mmuphin.r --in ${asvtabout} --out_ac ${all_asv_corrected_tabout} --out_mc ${model_asv_corrected_tabout} --out_mu ${model_asv_uncorrected_tabout} --refasv ${refasvtab_count} --refmeta ${refasvtab_metacovar} --modelasv ${model_asv_table}

# (8) run prediction model with batch corrected reads
python predict_prog_pibd.py --input ${model_asv_corrected_tabout} --sample ${SAMPLE} --output ${SAMPLE}_modelprediction_out.tsv --metadata ${METADATA} 
