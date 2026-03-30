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

# Ensure output directory exists
os.makedirs("health utilization score files", exist_ok=True)

# Read in final data (RDS files)
# Using rpy2 to read RDS
robjects.r('rural <- readRDS("LCA data/Final data named/NN_rural.class.rds")')
robjects.r('urban <- readRDS("LCA data/Final data named/NN_urban.class.rds")')
robjects.r('NN <- readRDS("LCA data/Final data named/NN_all.class.rds")')

rural = pandas2ri.rpy2py(robjects.r['rural'])
urban = pandas2ri.rpy2py(robjects.r['urban'])
nn = pandas2ri.rpy2py(robjects.r['NN'])

# Merge with original data for creating variables needed
# Using rpy2's haven to read SPSS file to preserve labels/structure if needed, 
# but pandas.read_spss is also fine. Let's use rpy2 haven to match R logic.
robjects.r('NN.raw <- read_sav("Pathways_Nigeria_merged.sav")')
nn_raw_r = robjects.r['NN.raw']
nn_raw = pandas2ri.rpy2py(nn_raw_r)

# Filter for ITYP == 1
nn_raw = nn_raw[nn_raw['ITYP'] == 1].copy()

# Create caseid
# Trim whitespace and replace empty strings with NaN
nn_raw = nn_raw.apply(lambda x: x.str.strip().replace('', np.nan) if x.dtype == "object" else x)

# Build caseid: PSUclean + HHIDclean + ITYP + SbjNum
# Note: Ensure these columns are strings for concatenation
cols_to_concat = ['PSUclean', 'HHIDclean', 'ITYP', 'SbjNum']
for col in cols_to_concat:
    nn_raw[col] = nn_raw[col].astype(str).str.replace('\.0$', '', regex=True)

nn_raw['caseid'] = nn_raw['PSUclean'] + nn_raw['HHIDclean'] + nn_raw['ITYP'] + nn_raw['SbjNum']

# Select necessary columns
nn_select = nn_raw[['caseid', 'A05', 'T_A06_1']].copy()

# Merge back to NN objects
nn = nn.merge(nn_select, on='caseid', how='left')
rural = rural.merge(nn_raw[nn_raw['URBAN_RURA'] == 'R'][['caseid', 'A05', 'T_A06_1']], on='caseid', how='left')
urban = urban.merge(nn_raw[nn_raw['URBAN_RURA'] == 'U'][['caseid', 'A05', 'T_A06_1']], on='caseid', how='left')

# Variable Coding
# ANC
anc_mean = int(nn[nn['C17'] != 97]['C17'].mean())
nn['anc_num'] = np.where(nn['C17'] == 97, anc_mean, nn['C17'])
nn['anyanc'] = np.where(nn['anc_num'] >= 1, 1, 0)
nn['anc_4plus'] = np.where(nn['anc_num'] >= 4, 1, 0)

# FP
nn['fp_mod_ever'] = ((nn['fp.current.modern'] == 1) | (nn['fp.previous.modern'] == 1)).astype(int)
nn['fp_ever'] = ((nn['fp.current.any'] == 1) | (nn['fp.previous.any'] == 1)).astype(int)

# CHW proxy
nn['hc_area'] = (nn['A05'] == 1).astype(int)

# Home birth (ever) - hb.yn is already in nn from LCA data

# Fever & Diarrhea
nn['kid_fever'] = ((nn['kid.ill.1'] == 1) | (nn['kid.ill.2'] == 1) | (nn['kid.ill.5'] == 1)).astype(int)
nn['fever'] = ((nn['kid_fever'] == 1) & (nn['kid.ill.doctor'] == 1)).astype(int)

nn['kid_diarr'] = (nn['kid.ill.4'] == 1).astype(int)
nn['diarr'] = ((nn['kid_diarr'] == 1) & (nn['kid.ill.doctor'] == 1)).astype(int)

# Woman care seeking
nn['her_ill_doctor'] = nn['her.ill.doctor'] # Should be in LCA data or merged

# Score by segment
nn['HC_score4'] = nn['anyanc'] + nn['hc_area'] + nn['fp_mod_ever'] + nn['diarr'] + nn['fever'] + nn['her_ill_doctor']
nn.loc[nn['hb.yn'] == 0, 'HC_score4'] += 1
nn.loc[nn['hb.yn'].isna(), 'HC_score4'] = np.nan

# Prepare for survey weighted analysis
# Replace NAs with "NA" string for factor-like behavior in R if needed by logic
for col in ['anyanc', 'hc_area', 'fp_mod_ever', 'diarr', 'fever', 'her_ill_doctor', 'hb.yn']:
    nn[col] = nn[col].fillna("NA")

nn['hf_deliv'] = np.where(nn['hb.yn'] == 0, 1, np.where(nn['hb.yn'] == 1, 0, "NA"))

# Profile mapping
profile_map = {
    "U1-NN": "Worried Potentials", "U2-NN": "Worried Potentials",
    "R2-NN": "Intending Support Seekers",
    "U3-NN": "Aware Reactives", "U4-NN": "Aware Reactives",
    "R3.1-NN": "Unreached Fatalists", "R3.2-NN": "Unreached Fatalists", "R4-NN": "Unreached Fatalists"
}
nn['profile'] = nn['class'].map(profile_map)

# Survey analysis helper function
def get_survey_summaries(df, group_col):
    r_df = pandas2ri.py2rpy(df)
    robjects.globalenv['tmp_df'] = r_df
    robjects.globalenv['group_col'] = group_col
    
    robjects.r('''
        library(survey)
        library(reshape2)
        library(dplyr)
        
        design <- svydesign(id=~PSUclean, strata=~URBAN_RURA, weights=~weight, data=tmp_df, survey.lonely.psu="adjust", nest=T)
        
        get_totals <- function(grp) {
            formula_str <- paste0("~", grp)
            tot <- as.data.frame(svytable(as.formula(formula_str), design))
            colnames(tot) <- c(grp, "value.y")
            return(tot)
        }
        
        tot <- get_totals(group_col)
        
        summarize_service <- function(var_name, service_label, grp, tot_df) {
            formula_str <- paste0("~", grp, " + ", var_name)
            seg <- as.data.frame(svytable(as.formula(formula_str), design))
            colnames(seg) <- c(grp, "health.service.status", "value.x")
            
            m <- merge(seg, tot_df, by=grp)
            
            # Subtract NAs
            na_rows <- m[m$health.service.status == "NA", ]
            if (nrow(na_rows) > 0) {
                for (val in unique(m[[grp]])) {
                    na_val <- na_rows$value.x[na_rows[[grp]] == val]
                    if (length(na_val) > 0) {
                        m$value.y[m[[grp]] == val] <- m$value.y[m[[grp]] == val] - na_val
                    }
                }
            }
            
            m <- m[m$health.service.status != "NA", ]
            m$perct <- 100 * m$value.x / m$value.y
            m$health.service <- service_label
            return(m)
        }
        
        # List of services
        services <- list(
            list("anyanc", "Any ANC"),
            list("hc_area", "Has health worker in the area"),
            list("fp_mod_ever", "Ever used mCP"),
            list("diarr", "Medical treatment on diarrhea"),
            list("fever", "Medical treatment on fever"),
            list("her_ill_doctor", "Woman goes to health facility when ill"),
            list("hf_deliv", "Health facility delivery")
        )
        
        results <- list()
        for (s in services) {
            results[[length(results)+1]] <- summarize_service(s[[1]], s[[2]], group_col, tot)
        }
        
        combined <- do.call(rbind, results)
        colnames(combined)[colnames(combined) == "value.x"] <- "number"
        colnames(combined)[colnames(combined) == "value.y"] <- paste0("total_in_", group_col)
        colnames(combined)[colnames(combined) == "perct"] <- "percentage"
        
        combined_no_chw <- do.call(rbind, results[c(1, 3:7)])
        colnames(combined_no_chw)[colnames(combined_no_chw) == "value.x"] <- "number"
        colnames(combined_no_chw)[colnames(combined_no_chw) == "value.y"] <- paste0("total_in_", group_col)
        colnames(combined_no_chw)[colnames(combined_no_chw) == "perct"] <- "percentage"
    ''')
    
    combined = pandas2ri.rpy2py(robjects.r['combined'])
    combined_no_chw = pandas2ri.rpy2py(robjects.r['combined_no_chw'])
    
    # Calculate averages
    def calculate_ave(df, grp):
        ave = df[df['health.service.status'] == "1"].copy()
        ave['percentage'] = pd.to_numeric(ave['percentage'])
        ave = ave.groupby([grp, 'health.service.status'])['percentage'].mean().reset_index()
        ave.rename(columns={'percentage': 'average.utilization'}, inplace=True)
        return ave

    ave = calculate_ave(combined, group_col)
    ave_no_chw = calculate_ave(combined_no_chw, group_col)
    
    return combined, combined_no_chw, ave, ave_no_chw

# Summaries by Segment (class)
nn_clean = nn[nn['PSUclean'].notna()].copy()
seg_status, seg_status_no_chw, seg_ave, seg_ave_no_chw = get_survey_summaries(nn_clean, "class")

# Summaries by Profile
prof_status, prof_status_no_chw, prof_ave, prof_ave_no_chw = get_survey_summaries(nn_clean, "profile")

# Save to Excel
with pd.ExcelWriter("health utilization score files/[Segment]health_utilization_score.xlsx") as writer:
    seg_status.to_excel(writer, sheet_name="Status with CHW", index=False)
    seg_status_no_chw.to_excel(writer, sheet_name="Status without CHW", index=False)
    seg_ave.to_excel(writer, sheet_name="Average score with CHW", index=False)
    seg_ave_no_chw.to_excel(writer, sheet_name="Average score without CHW", index=False)

with pd.ExcelWriter("health utilization score files/[Profile]health_utilization_score.xlsx") as writer:
    prof_status.to_excel(writer, sheet_name="Status with CHW", index=False)
    prof_status_no_chw.to_excel(writer, sheet_name="Status without CHW", index=False)
    prof_ave.to_excel(writer, sheet_name="Average score with CHW", index=False)
    prof_ave_no_chw.to_excel(writer, sheet_name="Average score without CHW", index=False)
