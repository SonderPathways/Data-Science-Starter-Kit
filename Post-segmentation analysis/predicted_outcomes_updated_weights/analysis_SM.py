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
base = importr('base')
stats = importr('stats')
survey = importr('survey')
ggplot2 = importr('ggplot2')

# LOAD SENEGAL DATA
if not os.path.exists("merged_pathways_dhs.csv"):
    print("Warning: merged_pathways_dhs.csv not found. Please ensure it exists in the folder.")
    # Create a dummy dataframe for structure if needed for testing, 
    # but for the final script we assume it's there.
    df = pd.DataFrame()
else:
    df = pd.read_csv("merged_pathways_dhs.csv")

# filter data to remove NA from outcomes
if not df.empty:
    df_1 = df[df['nofp.mod.now'].notna()].copy()
    
    # Convert to R dataframe
    r_df = pandas2ri.py2rpy(df_1)
    robjects.globalenv['df_1'] = r_df
    
    # DHS survey design in R
    robjects.r('''
        library(survey)
        design <- svydesign(ids = ~v021.x, strata = ~ v023.x, data = df_1, weights = ~wt, nest = TRUE)
        
        # model
        log.model1 <- svyglm(nofp.mod.now ~ segment_name, design = design, family = quasibinomial())
        print(summary(log.model1))
        
        # CALCULATE ACCURACY
        predicted_probs <- predict(log.model1, type = "response")
        predicted_class <- ifelse(predicted_probs >= 0.5, 1, 0)
        
        df_1$correct <- as.numeric(predicted_class == df_1$nofp.mod.now)
        design_updated <- update(design, correct = df_1$correct)
        
        accuracy_obj <- svymean(~correct, design_updated)
        accuracy_val <- as.numeric(accuracy_obj)
        print(accuracy_obj)
        
        # PREDICTIONS FOR PLOTTING
        predicted_link <- predict(log.model1, type = "link", se.fit = TRUE)
        predicted_link_df <- as.data.frame(predicted_link)
        
        df_1$predicted.prob <- plogis(predicted_link_df$link)
        df_1$ci.lower <- plogis(predicted_link_df$link - 1.96 * predicted_link_df$SE)
        df_1$ci.upper <- plogis(predicted_link_df$link + 1.96 * predicted_link_df$SE)
        
        design_with_preds <- update(design, 
                                    predicted.prob = df_1$predicted.prob,
                                    ci.lower = df_1$ci.lower,
                                    ci.upper = df_1$ci.upper)
        
        # Use svyby to get mean predicted probabilities + CIs by class
        # Note: using 'class' as in R script
        seg_probs <- svyby(~predicted.prob + ci.lower + ci.upper, 
                           ~class, 
                           design = design_with_preds, 
                           svymean)
    ''')
    
    seg_probs = pandas2ri.rpy2py(robjects.r['seg_probs'])
    accuracy_val = robjects.r['accuracy_val'][0]
    
    # Clean up for plotting
    seg_probs.rename(columns={'predicted.prob': 'mean_prob', 'ci.lower': 'lower', 'ci.upper': 'upper'}, inplace=True)
    
    seg_order = ["R2-S", "R3.1-S", "R3.2-S", "R4-S", "U1-S", "U2.1-S", "U2.2-S", "U3.1-S"]
    
    # Filter for segments in order and reindex
    seg_probs = seg_probs[seg_probs['class'].isin(seg_order)].copy()
    seg_probs['class'] = pd.Categorical(seg_probs['class'], categories=seg_order, ordered=True)
    seg_probs.sort_values('class', inplace=True)
    
    # Matplotlib Plot
    plt.figure(figsize=(10, 6))
    y_pos = np.arange(len(seg_probs))
    plt.errorbar(seg_probs['mean_prob'], y_pos, 
                 xerr=[seg_probs['mean_prob'] - seg_probs['lower'], seg_probs['upper'] - seg_probs['mean_prob']], 
                 fmt='o', color='steelblue', ecolor='red', capsize=5, markersize=8)
    
    plt.yticks(y_pos, seg_probs['class'])
    
    for i, prob in enumerate(seg_probs['mean_prob']):
        plt.text(prob, i + 0.2, f"{prob:.2f}", va='center', ha='center', fontsize=9)
        
    plt.title("Predicted Probability of No Modern FP Method Use by Segment", fontweight='bold', fontsize=14)
    plt.suptitle(f"Overall Accuracy: {accuracy_val*100:.0f}%", fontsize=12)
    plt.xlabel("Predicted Probability of No Modern FP Method Use")
    plt.ylabel("Segment")
    plt.grid(axis='x', linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.savefig("predicted_probability_plot.png")
    plt.show()
else:
    print("Dataframe is empty. Cannot proceed.")
