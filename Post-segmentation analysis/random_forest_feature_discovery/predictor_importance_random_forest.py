import pandas as pd
import numpy as np
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import confusion_matrix, classification_report
import matplotlib.pyplot as plt
import seaborn as sns
import os

# Activate the pandas to R interface
pandas2ri.activate()

# Set working directory if needed
# os.chdir(os.path.dirname(os.path.abspath(__file__)))

# Prepare the data
if not os.path.exists("NN_all.class.rds"):
    print("Warning: NN_all.class.rds not found.")
    df = pd.DataFrame()
else:
    # Use rpy2 to read RDS
    robjects.r('df <- readRDS("NN_all.class.rds")')
    df = pandas2ri.rpy2py(robjects.r['df'])

if not df.empty and os.path.exists("vars.csv"):
    vars_df = pd.read_csv("vars.csv")
    vars_list = vars_df['varnames'].tolist()
    
    # Select target and predictors
    # target: hb.sum.yn
    target_col = 'hb.sum.yn'
    if target_col not in df.columns:
        # Check if it has a different name or if we need to adjust
        # For now assume it's there as per R script
        pass
    
    selected_cols = [target_col] + [v for v in vars_list if v in df.columns]
    df_model = df[selected_cols].copy()
    
    # check missing data
    na_percentage = df_model.isna().mean() * 100
    print("NA Percentage per column:\n", na_percentage)
    
    # Drop rows with any missing values as in R script (complete.cases)
    df_model.dropna(inplace=True)
    
    # In R, all are converted to factors. 
    # In scikit-learn, we need to encode categorical variables.
    # We'll use one-hot encoding for predictors and label encoding for target.
    
    X = df_model.drop(columns=[target_col])
    y = df_model[target_col]
    
    # Convert all columns to categorical if they aren't already, then dummy encode
    X_encoded = pd.get_dummies(X, drop_first=True)
    
    # Encode target
    from sklearn.preprocessing import LabelEncoder
    le = LabelEncoder()
    y_encoded = le.fit_transform(y.astype(str))
    
    # Split the data into training and testing sets (80/20 stratified)
    X_train, X_test, y_train, y_test = train_test_split(
        X_encoded, y_encoded, test_size=0.2, random_state=123, stratify=y_encoded
    )
    
    # Train the random forest model
    rf_model = RandomForestClassifier(n_estimators=500, random_state=123, oob_score=True)
    rf_model.fit(X_train, y_train)
    
    # Evaluate the model
    y_pred = rf_model.predict(X_test)
    print("Confusion Matrix:\n", confusion_matrix(y_test, y_pred))
    print("\nClassification Report:\n", classification_report(y_test, y_pred))
    
    # Plot variable importance
    importances = rf_model.feature_importances_
    feature_names = X_encoded.columns
    var_importance = pd.DataFrame({'Variable': feature_names, 'Importance': importances})
    var_importance = var_importance.sort_values(by='Importance', ascending=False).head(20) # Top 20
    
    plt.figure(figsize=(10, 8))
    sns.barplot(x='Importance', y='Variable', data=var_importance, palette='viridis')
    plt.title("Variable Importance (Gini Importance) - Top 20")
    plt.xlabel("Importance")
    plt.ylabel("Variable")
    plt.tight_layout()
    plt.savefig("variable_importance_rf.png")
    plt.show()
else:
    print("Data or vars.csv missing.")
