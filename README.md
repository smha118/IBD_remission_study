
# IBD_remission_study
This GitHub page contains all the relevant code for the analysis conducted for the paper "Gut Microbiota-Based Ensemble Model Predicts Prognosis of Pediatric Inflammatory Bowel Disease."<br> In this study, we trained and tested various machine learning models to predict the prognosis of pediatric inflammatory bowel disease using the active state microbiome (16S rRNA) and clinical metadata. <br> Under the analysis_code folder, there are two Jupyter notebooks: hyperparameter_tuning.ipynb and ML_classification.ipynb.

Prior to training the machine learning models, the data was filtered based on their point-biserial correlation score (|cor| > 0.1) and p-value (p < 0.05).


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

# Runnig the ensemble model
The final ensemble model is provided under the model directory.<br> Please be advised that the model is for research use only and should never be used for any clinical purposes.