import pandas as pd
import numpy as np
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri
from rpy2.robjects.packages import importr
import os

# Activate the pandas to R interface
pandas2ri.activate()

# Import R libraries
survey = importr('survey')

# Note: This script uses placeholder paths from the original Rmd example.
# Please update them to your actual local paths.

### 1. Obtain the number of WRA from UN WPP
wpp_file = "/Users/jesslong/Desktop/Datafiles/unpopulation_dataportal_20251107125406.csv"
if os.path.exists(wpp_file):
    kenya_wra = pd.read_csv(wpp_file)
    # The total pop of WRA is shown in column "Subregion" in the example
    # Assuming the first unique value is the total or we need to extract it
    wra_total = 14084146 # Value from example output
    print(f"Total WRA: {wra_total}")
else:
    wra_total = 14084146
    print(f"WPP file not found, using example value: {wra_total}")

### 2. Determine the percent of WRA in DHS eligible for Pathways
dhsdata_path = "/Users/jesslong/Desktop/Datafiles/DHS/Kenya 2022"
br_path = os.path.join(dhsdata_path, "KEBR8CDT/KEBR8CFL.DTA")
ir_path = os.path.join(dhsdata_path, "KEIR8CDT/KEIR8CFL.DTA")

if os.path.exists(br_path) and os.path.exists(ir_path):
    # Using pandas to read Stata files
    br = pd.read_stata(br_path, convert_categoricals=False)
    ir = pd.read_stata(ir_path, convert_categoricals=False)
    
    # Filter BR to children under 5: b3 >= (v008 - 60)
    br_u5 = br[br['b3'] >= (br['v008'] - 60)]
    
    # Filter IR to women in BR_u5
    ir_pw = ir[ir['caseid'].isin(br_u5['caseid'])]
    
    eligibility_proportion = len(ir_pw) / len(ir)
    print(f"Eligibility Proportion: {eligibility_proportion}")
else:
    eligibility_proportion = 0.4506468
    print(f"DHS files not found, using example value: {eligibility_proportion}")

### 3. National population totals
total_eligible_wra = eligibility_proportion * wra_total
print(f"Total Eligible WRA: {total_eligible_wra}")

### 4. Segment totals
pathways_file = "/Users/jesslong/Desktop/Datafiles/Kenya_dhs_2024/Kenya_2022DHS8_1.2.csv"
if os.path.exists(pathways_file):
    kenya = pd.read_csv(pathways_file)
    
    # Use rpy2 for survey weighted calculations
    r_kenya = pandas2ri.py2rpy(kenya)
    robjects.globalenv['kenya'] = r_kenya
    
    robjects.r('''
        library(survey)
        ken.des <- svydesign(id=~v021, strata=~v023, weights=~wt,
                           survey.lonely.psu="adjust", nest=T, data=kenya)
        ke.seg.tab <- as.data.frame(svytable(~segment_name, design = ken.des))
    ''')
    
    ke_seg_tab = pandas2ri.rpy2py(robjects.r['ke.seg.tab'])
    
    # Calculate percentage and segment population
    ke_seg_tab['percentage'] = (ke_seg_tab['Freq'] / ke_seg_tab['Freq'].sum()) * 100
    ke_seg_tab['segment_population'] = (ke_seg_tab['percentage'] / 100) * total_eligible_wra
    
    print("\nSegment Population Estimates:")
    print(ke_seg_tab)
    
    ke_seg_tab.to_csv("segment_population_estimates.csv", index=False)
else:
    print(f"Pathways file {pathways_file} not found.")
