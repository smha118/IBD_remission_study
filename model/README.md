
# PLEASE BE ADVISED THAT THIS MODEL IS FOR RESEARCH USE ONLY.
## Docker
For convenience, a Docker image is available to run the model with your own data. The DockerHub page can be found [here](https://hub.docker.com/repository/docker/danha118/pibd_model).

## Pull docker image
```
docker pull danha118/pibd_model:arm
```

## Run model with your own data
Assuming that you are using data from this GitHub page.

```
cd data;
docker run -v ./:/data danha118/pibd_model:arm amplicon_read_preproc_ASV_count_and_batch_correct.sh SRR15702544 metadata_SRR15702544.tsv
```

## Files needed
For the input, you need two parameters: the sample name and the metadata file name. 

You also need raw fastq files named after your sample name. 

For example, SRR15702544_1.fastq.gz and SRR15702544_2.fastq.gz. 

The script only works with paired-end data.


The metadata should consist of following columns
| sample | current.disease | current.calprotectin_range.V3 | current.severity | current.age | gender | current.antibiotics | Anti-TNFa | 5ASA | AZA | Steroids |
|---|---|---|---|---|---|---|---|---|---|---|


Here are desriptions for each columns

| Column Name                    | Description                                                                                               |
|---------------------------------|-----------------------------------------------------------------------------------------------------------|
| **sample**                      | Sample ID; this should match the prefix used in your FASTQ files.                                          |
| **current.disease**             | Patient's disease status: either "CD" (Crohn's Disease) or "UC" (Ulcerative Colitis).                      |
| **current.calprotectin_range.V3**| Calprotectin levels, categorized as: "1_below250", "2_250to500", "3_500to2000", "4_over2000", or "nan".     |
| **current.severity**            | Severity of disease: "inactive", "mild", "moderate", "severe", or "nan".                                   |
| **current.age**                 | Patient's age; use "nan" if unknown.                                                                       |
| **gender**                      | Patient's gender: "F" for female, "M" for male, or "nan" if unknown.                                       |
| **current.antibiotics**         | Whether the patient took antibiotics: "Yes", "No", or "nan" if unknown.                                    |
| **Anti-TNFa**                   | Whether any Anti-TNFa treatment was given: "Yes", "No", or "nan" if unknown.                               |
| **5ASA**                        | Whether any 5-Aminosalicylic acid treatment was given: "Yes", "No", or "nan" if unknown.                   |
| **AZA**                         | Whether any azathioprine (AZA) treatment was given: "Yes", "No", or "nan" if unknown.                      |
| **Steroids**                    | Whether any steroids were given: "Yes", "No", or "nan" if unknown.                                         |




## Output format
Your output will be generated under the file name <file_name>_modelprediction_out.tsv.

This output file will have the following format:

| Column Name                    | Description                                                                                               |
|---------------------------------|-----------------------------------------------------------------------------------------------------------|
| **sample_id**                      | The sample ID provided.                                      |
| **Prognosis prediction**             | The final prediction of future prognosis (e.g., responder vs. non-responder).                     |
| **probability**| The probability used to make the final prediction. Values close to 1 indicate a responder.      |


