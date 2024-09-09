#!/usr/bin/env Rscript

# usage: ./model_input_batch_correct_mmuphin.r --in ${asvtabout} --out_ac ${corrected_asvtabout} --out_mc ${corrected_asvtabout} --out_mu ${corrected_asvtabout} --refasv ${refasvtab_count} --refmeta ${refasvtab_metacovar} --modelasv ${model_asv_table}

# parse input arguments
#	--in input asv read count table file 
#	--out_ac output batch corrected read count table for all ASVs
#	--out_mc output batch corrected read count table only for the ASVs used in the prognostic model
#	--out_mu output uncorrected read count table only for the ASVs used in the prognostic model
#	--refasv model training dataset's ASV read count table
#	--refmeta model training datsaet's sample metadata (including study name and disease state)
#	--modelasv a table containing the list of ASVs used in the prognostic model
# libraries required
library(optparse)
library(MMUPHin)


# parse input arguments
## create a parser
option_list <- list(
    make_option(c("-i", "--in"), type="character", default=NULL, help="input ASV read count table", metavar="character"),
    make_option(c("-a", "--out_ac"), type="character", default=NULL, help="output containing batch effect corrected ASV read count for all ASVs", metavar="character"),
    make_option(c("-c", "--out_mc"), type="character", default=NULL, help="output containing batch effect corrected ASV read count just for the ASVs used in the prognostic model", metavar="character"),
    make_option(c("-u", "--out_mu"), type="character", default=NULL, help="output containing uncorrected ASV read count just for the ASVs used in the prognostic model", metavar="character"),
    make_option(c("-v", "--modelasv"), type="character", default=NULL, help="a table containing the list of ASVs used in the prognostic model, columns are asv_in_model, pbcorr, pval", metavar="character"),
    make_option(c("-r", "--refasv"), type="character", default=NULL, help="input reference dataset ASV read count table", metavar="character"),
    make_option(c("-m", "--refmeta"), type="character", default=NULL, help="input reference dataset metadata table including sample mapping to study and disease information", metavar="character")
)
opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)
if (is.null(opt$in)) {
  print_help(opt_parser)
  stop("Give --in or -i input argument", call.=FALSE)
}
if (is.null(opt$out_ac)) {
  print_help(opt_parser)
  stop("Give --out_ac or -a input argument", call.=FALSE)
}
if (is.null(opt$out_mc)) {
  print_help(opt_parser)
  stop("Give --out_mc or -c input argument", call.=FALSE)
}
if (is.null(opt$out_mu)) {
  print_help(opt_parser)
  stop("Give --out_mu or -u input argument", call.=FALSE)
}
if (is.null(opt$modelasv)) {
  print_help(opt_parser)
  stop("Give --modelasv or -v input argument", call.=FALSE)
}
if (is.null(opt$refasv)) {
  print_help(opt_parser)
  stop("Give --refasv or -r input argument", call.=FALSE)
}
if (is.null(opt$refmeta)) {
  print_help(opt_parser)
  stop("Give --refmeta or -m input argument", call.=FALSE)
}

input_asv_count_tsv <- opt$in
output_asv_corr_count_tsv <- opt$out_ac
output_modelasv_corr_count_tsv <- opt$out_mc
output_modelasv_uncorr_count_tsv <- opt$out_mu
model_asv_list_tsv <- opt$modelasv
ref_dataset_asv_count_tsv <- opt$refasv
ref_dataset_metavar_tsv <- opt$refmeta
# [example] input_asv_count_tsv <- "SRR15702544.GLASV_asv_count.tsv"
# [example] output_asv_corr_count_tsv <- "SRR15702544.all_asv_batch_corrected_count.tsv"
# [example] output_modelasv_uncorr_count_tsv="SRR15702544.model_asv_uncorrected_count.tsv"
# [example] output_modelasv_corr_count_tsv="SRR15702544.model_asv_batch_corrected_count.tsv"
# [example] ref_dataset_asv_count_tsv <- "model_input_dataset.uncorrected_ASV_count_table.tsv"
# [example] ref_dataset_metavar_tsv <- "model_input_dataset.covariate_data_frame.tsv"
# [example] model_asv_list_tsv <- "asv_used_in_prognostic_model.tsv"


# (1) load reference dataset's ASV read count matrix 
ref_asv_count <- read.table(ref_dataset_asv_count_tsv, sep="\t", header=TRUE, row.names=1, check.names=FALSE)
ref_covar_meta <- read.table(ref_dataset_metavar_tsv, sep="\t", header=TRUE)


# (2) load new sample asv read count
input_sample_uncorrected_count <- read.table(input_asv_count_tsv, sep="\t", header=TRUE, row.names=1, check.names=FALSE, comment.char="")
n_asv_ref <- ncol(ref_asv_count)
n_asv_input <- nrow(input_sample_uncorrected_count)
n_asv_sync <- sum(colnames(ref_asv_count) == row.names(input_sample_uncorrected_count))
if(n_asv_ref != n_asv_input){
	print("the number of ASVs in the input and the reference dataset are not same")
	#stop("the number of ASVs in the input and the reference dataset are not same", call.=FALSE)
}
if(n_asv_ref != n_asv_sync){
	print("the ASV feature order in the input and the reference dataset are not synchronized")
	#stop("the ASV feature order in the input and the reference dataset are not synchronized", call.=FALSE)
}
n_sample_ref <- nrow(ref_asv_count)
n_sample_meta <- nrow(ref_covar_meta)
n_sample_sync <- sum(row.names(ref_asv_count) == ref_covar_meta$key)
if(n_sample_ref != n_sample_meta){
	print("the number of reference dataset samples in the asv count and the metadata are not same")
	#stop("the number of reference dataset samples in the asv count and the metadata are not same", call.=FALSE)
}
if(n_sample_ref != n_sample_sync){
	print("the sample order in the reference asv count and the metadata table are not synchronized")
	#stop("the sample order in the reference asv count and the metadata table are not synchronized", call.=FALSE)
}


# (3) append the new sample to exising model input sample ASV count matrix and the covariate metadata data frame
combined_uncorrected_count <- rbind(ref_asv_count, input_sample_uncorrected_count[,1])
row.names(combined_uncorrected_count)[nrow(combined_uncorrected_count)] <- "user_input_sample"
combined_covar_meta <- rbind(ref_covar_meta, c("user_input_sample", 1, "user_study"))
row.names(combined_covar_meta) <- combined_covar_meta$key
combined_covar_meta$cohort <- as.factor(combined_covar_meta$cohort)

mmuphin_out <- adjust_batch(feature_abd = t(combined_uncorrected_count), batch="cohort", covariates="disease", data=combined_covar_meta, control = list(verbose = FALSE))
user_input_col_index <- match("user_input_sample", colnames(mmuphin_out$feature_abd_adj))
user_sample_corrected_count_df <- data.frame(asv = row.names(mmuphin_out$feature_abd_adj), batch_corr_count = as.numeric(mmuphin_out$feature_abd_adj[,user_input_col_index]))


# (4) just the ASVs used in the prognostic model 
model_asv_list_df <- read.table(model_asv_list_tsv, sep="\t", header=TRUE)
user_sample_uncorrected_count_df <- data.frame(asv = row.names(input_sample_uncorrected_count), uncorr_count = as.numeric(input_sample_uncorrected_count[,1]))
user_sample_uncorrected_count_model_asv <- user_sample_uncorrected_count_df[user_sample_uncorrected_count_df$asv %in% model_asv_list_df$asv_in_model,]
user_sample_corrected_count_model_asv <- user_sample_corrected_count_df[user_sample_corrected_count_df$asv %in% model_asv_list_df$asv_in_model,]


# (5) write all three output files 
write.table(user_sample_corrected_count_df, file=output_asv_corr_count_tsv, sep="\t", quote=FALSE, row.names=FALSE)
write.table(user_sample_uncorrected_count_model_asv, file=output_modelasv_uncorr_count_tsv, sep="\t", quote=FALSE, row.names=FALSE)
write.table(user_sample_corrected_count_model_asv, file=output_modelasv_corr_count_tsv, sep="\t", quote=FALSE, row.names=FALSE)
