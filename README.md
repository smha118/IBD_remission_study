
# IBD_remission_study
This GitHub page contains all the relevant code for the analysis conducted for the paper "Gut Microbiota-Based Ensemble Model Predicts Prognosis Of Pediatric Inflammatory Bowel Disease". In the study, we trained/tested various machine learning models to predict prognosis of pediatric inflammatory bowel disease with the activate state microbiome (16S rRNA) and clinical metadata.
Under the analaysis_code, there are two jupyter notebooks, hyperparameter_tuning.ipynb and ML_classification.ipynb <br>

Prior to the machine learning training, the data was filtered based on their point-biserial correlation score (|cor| >0.1) and p-value (p-val <0.05)


![Overall Schematic](https://github.com/smha118/IBD_remission_study/blob/main/figures/IBD_ML_Figures.png?raw=true)


# Downloading the repo
```
git clone https://github.com/smha118/IBD_remission_study.git
cd IBD_remission_study
```

# Setting up the enviornment

```
conda env create -f environment.yml
```