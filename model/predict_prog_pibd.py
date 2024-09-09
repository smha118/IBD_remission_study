import os
import numpy as np
import pandas as pd
import pickle
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from scipy import stats


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
def pointbiserialFilter(X,y):
    corr_list = []
    p_val_list=[]
    X_list=[]
    for i in range(len(X.columns)):
        cor=stats.pointbiserialr(X.iloc[:,i], y)
        corr_list.append(cor[0])
        p_val_list.append(cor[1])
        X_list.append(X.columns[i])
    cor_df=pd.DataFrame({"cor":corr_list,"pval":p_val_list,"name":X_list})
    index=((cor_df.iloc[:,0]>0.1) | (cor_df.iloc[:,0]< -0.1)) & (cor_df.iloc[:,1]<0.05) 
    X_transpose=X.T
    X=X_transpose[index.set_axis(X_transpose.index)].T
    return X,index,cor_df
def combine_meta_with_data(X):
    meta=pd.read_csv("metadata.csv",sep=",",header=0)
    columns=["sample","current.disease",
             "current.calprotectin_range.V3","current.severity",
             "current.age","gender","current.antibiotics","Anti-TNFa","5ASA","AZA","Steroids"]
    meta=meta.loc[:,columns]
    mergedX=X.merge(meta,how="inner",on="sample")
    print(mergedX.columns)
    mergedX["current.disease"]=LabelEncoder().fit_transform(mergedX["current.disease"])
    mergedX["current.calprotectin_range.V1"]=LabelEncoder().fit_transform(mergedX["current.calprotectin_range.V1"])
    mergedX["current.calprotectin_range.V2"]=LabelEncoder().fit_transform(mergedX["current.calprotectin_range.V2"])
    mergedX["current.calprotectin_range.V3"]=LabelEncoder().fit_transform(mergedX["current.calprotectin_range.V3"])
    mergedX["current.calprotectin_range.V4"]=LabelEncoder().fit_transform(mergedX["current.calprotectin_range.V4"])
    mergedX["current.severity"]=LabelEncoder().fit_transform(mergedX["current.severity"])
    mergedX["current.age"]=LabelEncoder().fit_transform(mergedX["current.age"])
    mergedX["gender"]=LabelEncoder().fit_transform(mergedX["gender"])
    mergedX["current.antibiotics"]=LabelEncoder().fit_transform(mergedX["current.antibiotics"])
    mergedX["Anti-TNFa"]=LabelEncoder().fit_transform(mergedX["Anti-TNFa"])
    mergedX["5ASA"]=LabelEncoder().fit_transform(mergedX["5ASA"])
    mergedX["AZA"]=LabelEncoder().fit_transform(mergedX["AZA"])
    mergedX["Steroids"]=LabelEncoder().fit_transform(mergedX["Steroids"])
    X=mergedX
    X=X.drop(columns=['current.calprotectin_range.V2', 'current.calprotectin_range.V1','current.calprotectin_range.V4'])
    return X


if __name__ == "__main__":
    model = pickle.load(open("ensembl_model.sav", 'rb'))
    X_test=pd.read_csv("testdata.csv").set_index('sample')
    y_val_pred_prob = model.predict_proba(X_test)
    probability_predictions = y_val_pred_prob[:, 1]
    # Get class predictions (binary classification example)
    class_predictions = (probability_predictions > 0.5).astype("int32")
    label_mapping = {0: 'non-responder', 1: 'responder'}
    # Convert numeric class predictions to string labels
    label_predictions = np.vectorize(label_mapping.get)(class_predictions)
    results_df = pd.DataFrame({
    'sample_id': X_test.index,
    'Prognosis prediction': label_predictions.flatten(),
    'probability': probability_predictions.flatten()
    })

    # Display the DataFrame
    results_df=results_df.set_index("sample_id")
    results_df.to_csv("sample_output.csv")