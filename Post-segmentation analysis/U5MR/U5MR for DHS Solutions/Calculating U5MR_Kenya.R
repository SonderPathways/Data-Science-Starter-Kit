##########################################
#########################################
## Calculating U5MR using DHS rates package

# Code adapted from DHS Github for childhood mortality: 
#https://github.com/DHSProgram/DHS-Indicators-R/blob/main/Chap08_CM/CM_CHILD.R

#Code uses the DHS mortality rates R package:
#https://cran.r-project.org/web/packages/DHS.rates/index.html

#Data needed:
## Pathways segmentation: Kenya 2022 DHS 8: https://app.openhexa.org/workspaces/pathways-global-606430/datasets/kenya-segmentation-data-dhs-survey-v8-0-2022/from/pathways-global-606430/
## DHS data: Kenya 2022 DHS 8 BR file


##Author: Jess Long
## Last updated: 11/20/2025
##########################################
#########################################


rm(list=ls())
library(haven)
library(naniar) 
library(dplyr)
library(tidyr)
library(survey)
library(sjlabelled)
library(data.table)
library(expss)
library(stringr)
#install.packages("DHS.rates")
library(DHS.rates)

##########################################
#########################################
## Step 1. Import data
##########################################
#########################################

#Load Kenya DHS Pathways dataset
file_path <- "/Users/jesslong/Desktop/Datafiles/Kenya_dhs_2024"
kenya <- read.csv(file.path(file_path, "Kenya_2022DHS8_1.2.csv"))

#Add in BR DHS file
dhsdata_path <- "/Users/jesslong/Desktop/Datafiles/DHS/Kenya 2022"
BR <- read_dta(file.path(dhsdata_path, "KEBR8CDT/KEBR8CFL.DTA"))


#########################################
#########################################
# Step 2 Create U5MR using DHS package and code
##########################################
#########################################

#Make a subset of data to merge into the BR dataset
kenya_selected <- kenya %>%
  select(caseid, segment_name, strata) 

#Check that caseids match for merge
head(kenya_selected$caseid, 25)
head(BR$caseid, 25)

#Fix caseid to merge
BR <- BR %>%
  mutate(caseid = gsub(" ", "_", trimws(gsub("\\s+", " ", caseid))))

#BR, the Kenya DHS birth recode, is long form - one row per birth, with multiple
#births per caseid. Merge in Pathways segment so that dataset is limited
#to Pathways caseid, but stays long format and segment populate for each
#row of an applicable caseid. 
merged_data <- BR %>%
  inner_join(kenya_selected, by = "caseid")

BR<- merged_data

### This is code from DHS github used to look at U5MR by particular subsets. Leaving in
BR <- BR %>%
  mutate(child_sex = b4) %>%
  mutate(child_sex = set_label(child_sex, label = "Sex of child"))  %>%
  mutate(months_age = b3-v011) %>%
  mutate(mo_age_at_birth =
           case_when(
             months_age < 20*12   ~ 1 ,
             months_age >= 20*12 & months_age < 30*12 ~ 2,
             months_age >= 30*12 & months_age < 40*12 ~ 3,
             months_age >= 40*12 & months_age < 50*12 ~ 4)) %>%
  mutate(mo_age_at_birth = factor(mo_age_at_birth, levels = c(1,2,3,4), labels = c("Mother's age at birth < 20", "Mother's age at birth 20-29", "Mother's age at birth 30-39","Mother's age at birth 40-49"))) %>%
  mutate(mo_age_at_birth = set_label(mo_age_at_birth, label = "Mother's age at birth")) %>%
  mutate(birth_order =
           case_when(
             bord == 1  ~ 1,
             bord >= 2 & bord <= 3 ~ 2,
             bord >= 4 & bord <= 6 ~ 3,
             bord >= 7  ~ 4,
             bord == NA ~ 99)) %>%
  replace_with_na(replace = list(birth_order = c(99))) %>%
  mutate(birth_order = factor(birth_order, levels = c(1,2,3,4), labels = c("Birth order:1", "Birth order:2-3", "Birth order:4-6","Birth order:7+"))) %>%
  mutate(birth_order = set_label(birth_order, label = "Birth order"))  %>%
  mutate(prev_bint =
           case_when(
             b11 <= 23 ~ 1,
             b11 >= 24 & b11 <= 35 ~ 2,
             b11 >= 36 & b11 <= 47 ~ 3,
             b11 >= 48 ~ 4)) %>%
  mutate(prev_bint = set_label(prev_bint, label = "Preceding birth interval"))  %>%
  mutate(birth_size =
           case_when(
             m18 >= 4 & m18 <= 5 ~ 1,
             m18 <= 3 ~ 2,
             m18 > 5 ~ 99)) %>%
  mutate(birth_size = set_label(birth_size, label = "Birth size")) 

BR[["prev_bint"]] <- ifelse(is.na(BR[["prev_bint"]]), 999, BR[["prev_bint"]])
BR[["birth_size"]] <- ifelse(is.na(BR[["birth_size"]]), 999, BR[["birth_size"]])

BR <- BR %>%
  mutate(prev_bint = factor(prev_bint, levels = c(1,2,3,4,999), labels = c("Previous birth interval <2 years", "Previous birth interval 2 years", "Previous birth interval 3 years","Previous birth interval 4+ years", "missing"))) %>%
  mutate(birth_size = factor(birth_size, levels = c(1,2,99,999), labels = c("Birth size: Small/very small","Birth size: Average or larger", "Birth size: Don't know/missing", "missing" )))

#Make our variables of interest factor variables
class(BR$segment_name)
BR$segment_name <- as.factor(BR$segment_name)
table(BR$segment_name,useNA="always")

class(BR$strata)
BR$strata <- as.factor(BR$strata)
table(BR$strata,useNA="always")

####
# Calculate mortality rates
####

BR_CMORT <- (BR[, c("v021", "v022","v024", "v025", "v005", "v008","v011", 
                        "b3", "b7", "v106", "v190", "segment_name", "strata")])

# Create NNMR, PNNMR, IMR, CMR & U5MR for whole population; default period 0-4 years
resn1 <- as.data.frame(chmort(BR_CMORT))
resn1$period <- "0-4"

#create alternate periods of time
# Different datasets for different period ends: 5-9 years and 10-14 years
BR_CMORT1 <- BR_CMORT
BR_CMORT2 <- BR_CMORT
BR_CMORT1$v008 <- BR_CMORT$v008 - 12 * (5)
BR_CMORT2$v008 <- BR_CMORT$v008 - 12 * (10)

resn2 <- as.data.frame(chmort(BR_CMORT1))
resn2$period <- "5-9"
resn3 <- as.data.frame(chmort(BR_CMORT2))
resn3$period <- "10-14"


#Get the results by variables of interest, over 10 years. Output is:
# R - estimated mortality rate (per 1,000 live births)
# N - unweighted number of cases (births) used to calculate the rate
# WN - weighted number of cases (births) after applying DHS sample weights (v005)
#By region
kemort_region10 <- chmort(BR_CMORT, Class = "v024", Period = 120)
#By segment
kemort_segment10 <- chmort(BR_CMORT, Class = "segment_name", Period = 120)
#By rural/urban
kemort_strata5 <- chmort(BR_CMORT, Class = "strata", Period = 120)


#now repeat, over a 5 year span
#By region
kemort_region5 <- chmort(BR_CMORT, Class = "v024", Period = 60)
#By segment
kemort_segment5 <- chmort(BR_CMORT, Class = "segment_name", Period = 60)
#By strata
kemort_strata5 <- chmort(BR_CMORT, Class = "strata", Period = 60)

#If we want to add in SE and CIs, add "JK = "Yes" to the code. NOTE: it increases run time substantially. 
#By segment
Kemort_segment5 <- chmort(BR_CMORT, Class = "segment_name", Period = 60, JK ="Yes")



