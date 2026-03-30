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
foreign = importr('foreign')

# Set working directory to the script's location
# os.chdir(os.path.dirname(os.path.abspath(__file__)))

############## Load Nigeria 2013 DHS data
# Using pandas to read Stata files (DTA)
nghh = pd.read_stata("data/NGHR6ADT/NGHR6AFL.DTA", convert_categoricals=False)
ngir = pd.read_stata("data/NGIR6ADT/NGIR6AFL.DTA", convert_categoricals=False)

############## Read Pathways Rdat file
# We use rpy2 to load the RData file and bring it to pandas
robjects.r['load']("clean_data_files/DHS Pathways interim segments & factors.RDat")
dhs_seg_r = robjects.r['dhs.seg']
dhs_seg = pandas2ri.rpy2py(dhs_seg_r)

# Select out only the Nigeria segments
ng_seg = dhs_seg[dhs_seg['cv.regX5'] == "Nigeria.South"].copy()

# Re-create caseid
ng_seg['ID'] = ng_seg['IDHSPID'].astype(str)
ng_seg['cluster'] = ng_seg['ID'].str[9:17]
ng_seg['hhid'] = ng_seg['ID'].str[17:20].str.rjust(3)
ng_seg['lineno'] = ng_seg['ID'].str[20:23].str.rjust(2)
ng_seg['caseid'] = (ng_seg['cluster'] + ng_seg['hhid'] + ng_seg['lineno']).str.strip()

ng_seg = ng_seg[['caseid', 'segX4']]

################################################### Define zero dose child
ngbr = pd.read_stata("data/NGBR6ADT/NGBR6AFL.DTA", convert_categoricals=False)

def get_dpt(val):
    if pd.isna(val):
        return np.nan
    return 1 if val in [1, 2, 3] else 0

ngbr['dpt1'] = ngbr['h3'].apply(get_dpt)
ngbr['dpt2'] = ngbr['h5'].apply(get_dpt)
ngbr['dpt3'] = ngbr['h7'].apply(get_dpt)

ngbr['dpt0'] = ((ngbr['dpt1'] + ngbr['dpt2'] + ngbr['dpt3']) == 0).astype(int)
ngbr['ChildAge'] = ngbr['v008'] - ngbr['b3']
ngbr = ngbr[ngbr['b5'] == 1].copy() # b5 == 1 is "Yes" usually in DHS DTA

# dpt0 is for 10-23 months
ngbr['dpt0'] = np.where((ngbr['ChildAge'] > 9) & (ngbr['ChildAge'] < 24), ngbr['dpt0'], np.nan)

################################################### Seek care for diarrhea and fever
ngbr['diarr'] = ngbr['h12z'].replace(9, np.nan)
ngbr['fever'] = ngbr['h32z'].replace(9, np.nan)

diar_fev = ngbr.groupby('caseid').agg({
    'diarr': lambda x: x.max() if x.notna().any() else np.nan,
    'fever': lambda x: x.max() if x.notna().any() else np.nan
}).reset_index()

################################################### Link back
merg = ng_seg.merge(ngbr, on='caseid', how='left')
merg = merg.merge(diar_fev, on='caseid', how='left')

# Segment renaming
segment_map = pd.DataFrame({
    'segX4': ["RF1","RF2","RF3","RF4","RM1","RM2","RM3","UF1","UF2","UF3","UM1","UM2","UM3","UM4","UM5"],
    'new_seg': ["RF4.2","RF3","RF4.1","RF1","RM2.1","RM4","RM2.2","UF3.1","UF3.2","UF1","UM4","UM2","UM1.1","UM3","UM1.2"],
    'comb_seg': ["RF4","RF3","RF4","RF1","RM2","RM4","RM3","UF3","UF3","UF1","UM4","UM2","UM1","UM3","UM1"]
})

merg = merg.merge(segment_map, on='segX4', how='left')
merg = merg[merg['new_seg'].isin(["UM1.1","UM1.2","UF1","UM3","UF3.1","UM4"])].copy()

nigeria = merg.copy()
nigeria['segm1'] = nigeria['new_seg']
nigeria['wt'] = nigeria['v005'] / 1000000

## SCORING
nigeria['anyanc'] = np.where(nigeria['m14'] == 99, np.nan, np.where(nigeria['m14'] == 0, 0, 1))
# anc.num2 and anc.4plus2 are calculated but not used in final score calculation in R script except for HC.score4
# But HC.score4 is not used in the final summary.

# PNC
nigeria['B_PNC'] = np.where(nigeria['m70'] == 9, np.nan, np.where(nigeria['m70'] == 1, 1, 0))

# FP
nigeria['fp_ever'] = np.where(nigeria['v361'] == 0, 0, 1) # Assuming 0 is "Never used"

# Health services
nigeria['hc_chw'] = np.where(nigeria['v393'] == 9, np.nan, np.where(nigeria['v393'] == 1, 1, 0))
nigeria['hc_hfac'] = np.where(nigeria['v394'] == 9, np.nan, np.where(nigeria['v394'] == 1, 1, 0))

# Home births in ngir
for i in range(1, 6):
    col = f'm15_{i}'
    hb_col = f'hb_{i}'
    ngir[hb_col] = np.where(ngir[col].isin([10, 11, 12, 96]), 1, 0)
    ngir[hb_col] = np.where(ngir[col] == 99, np.nan, ngir[hb_col])

ngir['hb_ever'] = ngir[[f'hb_{i}' for i in range(1, 6)]].max(axis=1)
ngir['caseid'] = ngir['caseid'].str.strip()

nigeria = nigeria.merge(ngir[['caseid', 'hb_ever']], on='caseid', how='left')

# final indicators for summary
nigeria['hf_deliv'] = np.where(nigeria['hb_ever'] == 0, 1, np.where(nigeria['hb_ever'] == 1, 0, np.nan))

# Deduplicate by caseid for survey analysis as in R script
nigeria2 = nigeria.drop_duplicates(subset='caseid').copy()
nigeria2 = nigeria2[nigeria2['v021'].notna()]

# Convert to R data frame for survey package
r_nigeria2 = pandas2ri.py2rpy(nigeria2)
robjects.globalenv['nigeria2'] = r_nigeria2

# Execute survey design and tables in R via rpy2
robjects.r('''
    library(survey)
    library(reshape2)
    library(dplyr)
    
    Pathdesign <- svydesign(id=~v021, weights=~wt, data=nigeria2)
    
    tot <- as.data.frame(svytable(~segm1, Pathdesign))
    colnames(tot) <- c("segm1", "value.y")
    
    summarize_service <- function(var_name, service_label) {
        formula_str <- paste0("~segm1 + ", var_name)
        seg <- as.data.frame(svytable(as.formula(formula_str), Pathdesign))
        colnames(seg) <- c("segm1", "health.service.status", "value.x")
        
        # Merge with totals
        m <- merge(seg, tot, by="segm1")
        
        # Subtract NAs if present
        na_rows <- m[is.na(m$health.service.status), ]
        if (nrow(na_rows) > 0) {
            for (s in unique(m$segm1)) {
                na_val <- na_rows$value.x[na_rows$segm1 == s]
                if (length(na_val) > 0) {
                    m$value.y[m$segm1 == s] <- m$value.y[m$segm1 == s] - na_val
                }
            }
        }
        
        m <- m[!is.na(m$health.service.status), ]
        m$perct <- 100 * m$value.x / m$value.y
        m$health.service <- service_label
        return(m)
    }
    
    anc <- summarize_service("anyanc", "anc")
    hc_hfac <- summarize_service("hc_hfac", "hc_hfac")
    B_PNC <- summarize_service("B_PNC", "B.PNC")
    fp_ever <- summarize_service("fp_ever", "fp.ever")
    diarr <- summarize_service("diarr", "diarr")
    fever <- summarize_service("fever", "fever")
    hf_deliv <- summarize_service("hf_deliv", "hf_deliv")
    
    health_service_lagos <- rbind(anc, hc_hfac, B_PNC, fp_ever, diarr, fever, hf_deliv)
    colnames(health_service_lagos)[colnames(health_service_lagos) == "value.x"] <- "number"
    colnames(health_service_lagos)[colnames(health_service_lagos) == "value.y"] <- "total_in_segment"
    colnames(health_service_lagos)[colnames(health_service_lagos) == "perct"] <- "percentage"
''')

health_service_lagos = pandas2ri.rpy2py(robjects.r['health_service_lagos'])

# Calculate averages as in R script
health_service_lagos_ave = health_service_lagos[health_service_lagos['health.service.status'] == "1"].copy()
health_service_lagos_ave['percentage'] = pd.to_numeric(health_service_lagos_ave['percentage'])
health_service_lagos_ave = health_service_lagos_ave.groupby(['segm1', 'health.service.status'])['percentage'].mean().reset_index()
health_service_lagos_ave.rename(columns={'percentage': 'average.utilization'}, inplace=True)

# Write outputs
health_service_lagos.to_csv("heath_utilization_by_service_lagos.csv", index=False)
health_service_lagos_ave.to_csv("heath_utilization_average_lagos.csv", index=False)
