import pandas as pd
import numpy as np
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri
from rpy2.robjects.packages import importr
import matplotlib.pyplot as plt
import seaborn as sns
import os

# Activate the pandas to R interface
pandas2ri.activate()

# Import R libraries
base = importr('base')
stats = importr('stats')
survey = importr('survey')
haven = importr('haven')
dhs_rates = importr('DHS.rates')

# Step 1. Import data
file_path = "/Users/jesslong/Desktop/Datafiles/NN_dhs_2018"
pathways_file = os.path.join(file_path, "North_Nigeria_2018DHS7_1.0.csv")

dhsdata_path = "/Users/jesslong/Desktop/Datafiles/DHS/Nigeria 2018"
br_file = os.path.join(dhsdata_path, "NGBR7BDT/NGBR7BFL.DTA")

if os.path.exists(pathways_file) and os.path.exists(br_file):
    nn = pd.read_csv(pathways_file)
    # Using rpy2 haven to read DTA
    robjects.r(f'BR <- read_dta("{br_file}")')
    br = pandas2ri.rpy2py(robjects.r['BR'])
else:
    print("Files not found. Please update paths.")
    nn = pd.DataFrame()
    br = pd.DataFrame()

if not nn.empty and not br.empty:
    # Step 2 Create U5MR using DHS package and code
    nn_selected = nn[['caseid', 'segment_name', 'strata']]
    
    # Merge
    merged_data = br.merge(nn_selected, on='caseid', how='inner')
    
    # Convert back to R for DHS.rates
    r_merged_data = pandas2ri.py2rpy(merged_data)
    robjects.globalenv['BR'] = r_merged_data
    
    # Execute recoding and chmort in R via rpy2
    robjects.r('''
        library(dplyr)
        library(naniar)
        library(sjlabelled)
        library(DHS.rates)
        
        BR <- BR %>%
          mutate(child_sex = b4) %>%
          mutate(months_age = b3-v011) %>%
          mutate(mo_age_at_birth =
                   case_when(
                     months_age < 20*12   ~ 1 ,
                     months_age >= 20*12 & months_age < 30*12 ~ 2,
                     months_age >= 30*12 & months_age < 40*12 ~ 3,
                     months_age >= 40*12 & months_age < 50*12 ~ 4)) %>%
          mutate(mo_age_at_birth = factor(mo_age_at_birth, levels = c(1,2,3,4), labels = c("< 20", "20-29", "30-39","40-49"))) %>%
          mutate(birth_order =
                   case_when(
                     bord == 1  ~ 1,
                     bord >= 2 & bord <= 3 ~ 2,
                     bord >= 4 & bord <= 6 ~ 3,
                     bord >= 7  ~ 4,
                     bord == NA ~ 99)) %>%
          replace_with_na(replace = list(birth_order = c(99))) %>%
          mutate(birth_order = factor(birth_order, levels = c(1,2,3,4), labels = c("1", "2-3", "4-6","7+"))) %>%
          mutate(prev_bint =
                   case_when(
                     b11 <= 23 ~ 1,
                     b11 >= 24 & b11 <= 35 ~ 2,
                     b11 >= 36 & b11 <= 47 ~ 3,
                     b11 >= 48 ~ 4)) %>%
          mutate(birth_size =
                   case_when(
                     m18 >= 4 & m18 <= 5 ~ 1,
                     m18 <= 3 ~ 2,
                     m18 > 5 ~ 99))
        
        BR$prev_bint[is.na(BR$prev_bint)] <- 999
        BR$birth_size[is.na(BR$birth_size)] <- 999
        
        BR <- BR %>%
          mutate(prev_bint = factor(prev_bint, levels = c(1,2,3,4,999), labels = c("<2 years", "2 years", "3 years","4+ years", "missing"))) %>%
          mutate(birth_size = factor(birth_size, levels = c(1,2,99,999), labels = c("Small/very small","Average or larger", "Don't know/missing", "missing" )))
        
        BR$segment_name <- as.factor(BR$segment_name)
        BR$strata <- as.factor(BR$strata)
        
        BR_CMORT <- BR[, c("v021", "v022","v024", "v025", "v005", "v008","v011", 
                                "b3", "b7", "v106", "v190", "segment_name", "strata")]
        
        # Calculate mortality rates
        NNmort_segment5 <- chmort(BR_CMORT, Class = "segment_name", Period = 60, JK ="Yes")
        
        # Add Indicator labels
        NNmort_segment5 <- NNmort_segment5 %>%
          group_by(Class) %>%
          mutate(Indicator = c("NNMR","PNNMR","IMR","CMR","U5MR")) %>%
          ungroup()
    ''')
    
    nnmort_segment5 = pandas2ri.rpy2py(robjects.r['NNmort_segment5'])
    
    print("Mortality Rates by Segment (5 years, Jackknife SEs):")
    print(nnmort_segment5)
    
    # Filter for U5MR for plotting
    u5mr_segment5 = nnmort_segment5[nnmort_segment5['Indicator'] == "U5MR"].copy()
    
    # Sort for plotting
    u5mr_segment5 = u5mr_segment5.sort_values(by='R')
    
    plt.figure(figsize=(10, 8))
    sns.barplot(x='R', y='Class', data=u5mr_segment5, palette='Blues_d')
    plt.errorbar(u5mr_segment5['R'], np.arange(len(u5mr_segment5)), 
                 xerr=[u5mr_segment5['R'] - u5mr_segment5['LCI'], u5mr_segment5['UCI'] - u5mr_segment5['R']], 
                 fmt='none', ecolor='black', capsize=3)
    
    plt.title("Under-5 Mortality Rate (U5MR) by Segment", fontweight='bold')
    plt.suptitle("Nigeria DHS – Last 5 Years (95% CI)", fontsize=10)
    plt.xlabel("U5MR (per 1,000 live births)")
    plt.ylabel("Segment")
    plt.tight_layout()
    plt.savefig("u5mr_segment_plot.png")
    plt.show()
    
    nnmort_segment5.to_csv("nnmort_segment5.csv", index=False)
