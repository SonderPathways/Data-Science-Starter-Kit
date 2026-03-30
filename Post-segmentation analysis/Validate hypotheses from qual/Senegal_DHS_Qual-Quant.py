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
nnet = importr('nnet')

# Data Preparation Blocks (Matching the Rmd structure)

def prepare_data():
    # Chunks from Senegal_DHS_Qual-Quant.Rmd
    # Load RDS files
    robjects.r('''
        # rural <- readRDS("SEN.rural.all.class.rds")
        # urban <- readRDS("SEN.urban.all.class.rds")
        # senegal <- readRDS("Senegal.all.class.rds")
    ''')
    
    # Load DHS DTA files and merge
    # This part is complex in the Rmd, we replicate the logic:
    robjects.r('''
        # Example for HH
        # HH1 <- read_dta("SNHR81FL.DTA")
        # HH2 <- read_dta("SNHR8BFL.DTA")
        # HH <- rbind(HH1, HH2)
        # ... and so on for IR and KR
    ''')
    
    # After merging, we assume 'senegal' dataframe is ready
    # For the purpose of this script, we'll use 'Senegal_merged.rds' if it exists
    if os.path.exists("Senegal_merged.rds"):
        robjects.r('senegal <- readRDS("Senegal_merged.rds")')
    else:
        print("Senegal_merged.rds not found. Please ensure data preparation is complete.")
        return None
    
    senegal = pandas2ri.rpy2py(robjects.r['senegal'])
    return senegal

def recode_variables(df):
    if df is None: return None
    
    # Remove U3.2-S
    df = df[df['class'] != "U3.2-S"].copy()
    
    # 0. New Variables Coding
    # Current FP use
    df['fp.mod.now'] = np.where(df['nofp.mod.now'] == 0, 1, 0)
    df['fp.any.now'] = np.where(df['v313'] == "no method", 0, 1) # v313 might be numeric or label
    
    # Age brackets
    df['age.adj'] = pd.cut(df['v012'], bins=[0, 19, 24, 29, 34, 100], 
                           labels=["15-19", "20-24", "25-29", "30-34", "35-49"])
    
    # Number of living children
    df['live.child'] = pd.cut(df['v219'], bins=[-1, 2, 4, 100], labels=["[0, 2]", "[3, 4]", "5+"])
    
    # Contact with FP providers
    # Assuming v394, v395, v393a labels are mapped or using their numeric values
    df['disc.fp.hw'] = np.where(((df['v394'] == "yes") & (df['v395'] == "yes")) | (df['v393a'] == "yes"), 1, 0)
    
    # Exposure to FP messages
    df['fp.radio'] = np.where(df['v384a'] == "yes", 1, 0)
    df['fp.tv'] = np.where(df['v384b'] == "yes", 1, 0)
    
    # FP relevance (Binary indicator from section 0.2)
    # Simplified logic for demonstration based on Rmd:
    # relevance is 1 if (Current using OR To use later OR Current need relevant)
    # v364: 1 is using, 2 intends to use later, etc.
    df['fp.relevance'] = np.where(df['v364'].isin(["using modern method", "non-user - intends to use later"]), 1, 0)
    
    # Marriage type and agriculture
    df['work.agri'] = np.where((df['occupation.cat'] == "agricultural") | (df['partner.occupation.cat'] == "agricultural"), 1, 0)
    
    return df

def run_analyses(df):
    if df is None: return
    
    # Convert to R for survey package
    r_df = pandas2ri.py2rpy(df)
    robjects.globalenv['senegal'] = r_df
    
    robjects.r('''
        library(survey)
        library(nnet)
        
        # Survey design
        design <- svydesign(id=~v001, strata=~v024, weights=~wt, data=senegal, nest=TRUE)
        
        # 1.1.1. Age category and relevance
        model_relevance_age <- svyglm(fp.relevance ~ age.adj, design = design, family = quasibinomial())
        
        # 1.1.2. Interaction with segment
        model_interaction <- svyglm(fp.relevance ~ age.adj * class, design = design, family = quasibinomial())
        
        # 3.4.2. Agriculture and ideal children (Multinomial)
        # Using nnet::multinom on weighted data
        model_agri_ideal <- multinom(ideal.n.child.cat.new ~ work.agri + v025, data = senegal, weights = wt)
    ''')
    
    print("Summary of FP Relevance vs Age:")
    print(robjects.r('summary(model_relevance_age)'))
    
    # Plotting example: FP Relevance by Age and Segment
    plt.figure(figsize=(12, 8))
    sns.barplot(x='age.adj', y='fp.relevance', hue='class', data=df)
    plt.title("FP Relevance by Age and Segment")
    plt.ylabel("Proportion Finding FP Relevant")
    plt.xlabel("Age Group")
    plt.legend(title='Segment', bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.tight_layout()
    plt.savefig("fp_relevance_by_age_segment.png")
    plt.show()

# Main execution
if __name__ == "__main__":
    senegal_df = prepare_data()
    if senegal_df is not None:
        senegal_df = recode_variables(senegal_df)
        run_analyses(senegal_df)
