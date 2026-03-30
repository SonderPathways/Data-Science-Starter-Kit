import pandas as pd
import numpy as np
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri
from rpy2.robjects.packages import importr
import matplotlib.pyplot as plt
import os

# Activate the pandas to R interface
pandas2ri.activate()

# Import R libraries
survey = importr('survey')

# LOAD DATA
csv_file = "Nigeria_North_2022Pathways1_1.3.csv"
if os.path.exists(csv_file):
    df = pd.read_csv(csv_file)
else:
    print(f"Warning: {csv_file} not found.")
    df = pd.DataFrame()

def run_analysis(df, outcome_col, title, filename):
    if df.empty or outcome_col not in df.columns:
        print(f"Skipping {outcome_col}: Data or column missing.")
        return
    
    df_1 = df[df[outcome_col].notna()].copy()
    r_df = pandas2ri.py2rpy(df_1)
    robjects.globalenv['df_1'] = r_df
    robjects.globalenv['outcome_col'] = outcome_col
    
    robjects.r('''
        library(survey)
        design <- svydesign(ids = ~PSUclean, data = df_1, weights = ~weight)
        
        formula_str <- paste0(outcome_col, " ~ class")
        log.model <- svyglm(as.formula(formula_str), design = design, family = quasibinomial())
        
        # Accuracy
        predicted_probs <- predict(log.model, type = "response")
        predicted_class <- ifelse(predicted_probs >= 0.5, 1, 0)
        accuracy <- mean(predicted_class == df_1[[outcome_col]], na.rm = TRUE)
        
        # Predictions for plotting
        predicted_link <- predict(log.model, type = "link", se.fit = TRUE)
        predicted_link_df <- as.data.frame(predicted_link)
        
        df_1$predicted.prob <- plogis(predicted_link_df$link)
        df_1$ci.lower <- plogis(predicted_link_df$link - 1.96 * predicted_link_df$SE)
        df_1$ci.upper <- plogis(predicted_link_df$link + 1.96 * predicted_link_df$SE)
        
        design_with_preds <- update(design, 
                                    predicted.prob = df_1$predicted.prob,
                                    ci.lower = df_1$ci.lower,
                                    ci.upper = df_1$ci.upper)
        
        seg_probs <- svyby(~predicted.prob + ci.lower + ci.upper, 
                           ~class, 
                           design = design_with_preds, 
                           svymean)
    ''')
    
    seg_probs = pandas2ri.rpy2py(robjects.r['seg_probs'])
    accuracy = robjects.r['accuracy'][0]
    
    # Clean up for plotting
    seg_probs.rename(columns={'predicted.prob': 'mean_prob', 'ci.lower': 'lower', 'ci.upper': 'upper'}, inplace=True)
    seg_probs = seg_probs.sort_values(by='mean_prob')
    
    # Matplotlib Plot
    plt.figure(figsize=(10, 6))
    y_pos = np.arange(len(seg_probs))
    plt.errorbar(seg_probs['mean_prob'], y_pos, 
                 xerr=[seg_probs['mean_prob'] - seg_probs['lower'], seg_probs['upper'] - seg_probs['mean_prob']], 
                 fmt='o', color='steelblue', ecolor='red', capsize=5)
    
    plt.yticks(y_pos, seg_probs['class'])
    
    for i, prob in enumerate(seg_probs['mean_prob']):
        plt.text(prob, i + 0.2, f"{prob:.2f}", va='center', ha='center', fontsize=9)
        
    plt.title(title, fontweight='bold', fontsize=14)
    plt.suptitle(f"Overall Accuracy: {accuracy*100:.0f}%", fontsize=12)
    plt.xlabel("Predicted Probability")
    plt.ylabel("Segment")
    plt.grid(axis='x', linestyle='--', alpha=0.7)
    plt.tight_layout()
    
    os.makedirs("pathways_NN_plots", exist_ok=True)
    plt.savefig(f"pathways_NN_plots/{filename}.png")
    plt.show()

# Run for all outcomes
outcomes = [
    ('hb.sum.yn', 'Predicted Probability of Home Birth by Segment', 'home_birth'),
    ('anc.4plus', 'Predicted Probability of Less than 4 ANC by Segment', 'ANC'),
    ('fp.current.any', 'Predicted Probability of no mCP by Segment', 'mCP'),
    ('her.wasting', 'Predicted Probability of any Child Wasting by Segment', 'wasting'),
    ('death.u5', 'Predicted Probability of Under 5 Mortality by Segment', 'under5_mort')
]

for outcome, title, filename in outcomes:
    run_analysis(df, outcome, title, filename)
