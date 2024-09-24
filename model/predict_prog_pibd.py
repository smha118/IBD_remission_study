import os
import numpy as np
import pandas as pd
import pickle
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from scipy import stats
import click
import sys
import warnings
warnings.filterwarnings("ignore")



def create_baseline(hidden_layer=1, units=10,l1_value=0.01, l2_value=0.01, dropout_rate=0.5):
    model = Sequential()
    model.add(Input(shape=(X.shape[1],)))
    model.add(Dense(units, activation='relu',kernel_regularizer=l1_l2(l1=l1_value, l2=l2_value)))
    model.add(Dropout(dropout_rate))
    for i in range(hidden_layer):
        model.add(Dense(units, activation='relu',kernel_regularizer=l1_l2(l1=l1_value, l2=l2_value)))
        model.add(Dropout(dropout_rate))
    model.add(Dense(1, activation='sigmoid'))
    model.compile(loss='binary_crossentropy', optimizer='adam', metrics=['accuracy'])
    return model

def combine_asv_metadata(asv_df,metadata):
    with open('resources/encoders.pkl', 'rb') as f:
        encoders = pickle.load(f)
    for col in metadata.columns:
            try:
                # Try to encode if the column exists in new_data
                le = encoders[col]  # Retrieve the encoder for the column
                metadata[col] = le.transform(metadata[col])
            except KeyError:
                # Column not found in new_data
                continue
            except Exception as e:
                # Handle any other errors
                print(f"An error occurred while encoding column '{col}': {e}")
                sys.exit()
    mergedX=asv_df.merge(metadata,how="inner",on="sample")

    asv_df=mergedX
    return asv_df

@click.command()
@click.option('--input', prompt="Input ASV count table in tsv", help='Input ASV count table in tsv format')
@click.option('--sample', prompt="Sample Name", help='Sample name for given ASV count table and metadata')
@click.option('--metadata', prompt='Metadata', help='Metadata')
@click.option('--output', default='output.tsv', prompt='Output file in tsv', help='Output file name')
def model_prediction(input,sample,metadata,output):
    """This python code predicts prognosis of Pediatric Inflammatory Bowel Disease using ensemble model presented in https://dx.doi.org/10.2139/ssrn.4512923."""
    model = pickle.load(open("resources/ensembl_model.pkl", 'rb'))
    X=pd.read_csv(input,sep="\t").set_index("asv")
    X=X.T
    X.index=[sample]
    X=np.log(X+1)
    metadata=pd.read_csv(metadata,sep="\t",header=0).set_index("sample")
    X.index.name='sample'
    X=combine_asv_metadata(X,metadata)
    dummy_row = pd.DataFrame([[0] * X.shape[1]], columns=X.columns)
    X=pd.concat([X, dummy_row], ignore_index=False)
    #X.to_csv("test.csv")
    #X_test=pd.read_csv("testdata.csv").set_index("sample")
    y_val_pred_prob = model.predict_proba(X)
    probability_predictions = y_val_pred_prob[:, 1]
    # Get class predictions (binary classification example)
    class_predictions = (probability_predictions > 0.5).astype("int32")
    label_mapping = {0: 'non-responder', 1: 'responder'}
    # Convert numeric class predictions to string labels
    label_predictions = np.vectorize(label_mapping.get)(class_predictions)
    results_df = pd.DataFrame({
    'sample_id': X.index,
    'Prognosis prediction': label_predictions.flatten(),
    'probability': probability_predictions.flatten()
    })
    # Display the DataFrame
    results_df=results_df.set_index("sample_id")
    results_df.iloc[0:1,:].to_csv(output,sep="\t")



if __name__ == "__main__":
    model_prediction()
