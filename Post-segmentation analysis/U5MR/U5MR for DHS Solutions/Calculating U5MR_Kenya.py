import pandas as pd
import numpy as np
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri
from rpy2.robjects.packages import importr
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
file_path = "/Users/jesslong/Desktop/Datafiles/Kenya_dhs_2024"
pathways_file = os.path.join(file_path, "Kenya_2022DHS8_1.2.csv")

dhsdata_path = "/Users/jesslong/Desktop/Datafiles/DHS/Kenya 2022"
br_file = os.path.join(dhsdata_path, "KEBR8CDT/KEBR8CFL.DTA")

if os.path.exists(pathways_file) and os.path.exists(br_file):
    kenya = pd.read_csv(pathways_file)
    # Using rpy2 haven to read DTA to preserve labels/attributes
    robjects.r(f'BR <- read_dta("{br_file}")')
    br = pandas2ri.rpy2py(robjects.r['BR'])
else:
    print("Files not found. Please update paths.")
    kenya = pd.DataFrame()
    br = pd.DataFrame()

if not kenya.empty and not br.empty:
    # Step 2 Create U5MR using DHS package and code
    kenya_selected = kenya[['caseid', 'segment_name', 'strata']]
    
    # Fix caseid to merge
    br['caseid'] = br['caseid'].str.strip().str.replace(r'\s+', '_', regex=True)
    
    # Merge
    merged_data = br.merge(kenya_selected, on='caseid', how='inner')
    
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
        resn1 <- as.data.frame(chmort(BR_CMORT))
        
        kemort_segment10 <- chmort(BR_CMORT, Class = "segment_name", Period = 120)
        kemort_segment5 <- chmort(BR_CMORT, Class = "segment_name", Period = 60)
    ''')
    
    resn1 = pandas2ri.rpy2py(robjects.r['resn1'])
    kemort_segment10 = pandas2ri.rpy2py(robjects.r['kemort_segment10'])
    kemort_segment5 = pandas2ri.rpy2py(robjects.r['kemort_segment5'])
    
    print("Overall Mortality Rates:")
    print(resn1)
    print("\nMortality Rates by Segment (10 years):")
    print(kemort_segment10)
    print("\nMortality Rates by Segment (5 years):")
    print(kemort_segment5)
    
    kemort_segment5.to_csv("kemort_segment5.csv", index=False)
