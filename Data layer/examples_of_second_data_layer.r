################################################################################
# FINAL LAYER VARIABLES
################################################################################

# LOAD LIBRARIES
library(dplyr)
library(readxl)

################################################################################
# READ IN DATASETS
################################################################################


# LOAD DHS DATA FILES

# COMMENT THIS CODE ACCORDINGLY IF USING DHS OR A DIFFERENT SURVEY
if (file.exists(paste0("data/", "IR.rds"))) {
  IR <- readRDS(file = paste0("data/", "IR.rds"))
  IR <- IR %>% dplyr::filter(v024 %in% c("south west", "south south" , "south east"))
  message("IR file imported.")}

if (file.exists(paste0("data/", "BR.rds"))) {
  BR <- readRDS(file = paste0("data/", "BR.rds"))
  BR <- BR %>% dplyr::filter(v024 %in% c("south west", "south south" , "south east"))
  message("BR file imported.")}

if (file.exists(paste0("data/", "KR.rds"))) {
  KR <- readRDS(file = paste0("data/", "KR.rds"))
  KR <- KR %>% dplyr::filter(v024 %in% c("south west", "south south" , "south east"))
  message("KR file imported.")}

if (file.exists(paste0("data/", "HH.rds"))) {
  HH <- readRDS(file = paste0("data/", "HH.rds"))
  HH <- HH %>% dplyr::filter(hv024 %in% c("south west", "south south" , "south east"))
  message("HH file imported.")}

if (file.exists(paste0("data/", "MR.rds"))) {
  MR <- readRDS(file = paste0("data/", "MR.rds"))
  MR <- MR %>% dplyr::filter(mv024 %in% c("south west", "south south" , "south east"))
  message("MR file imported.")}

if (file.exists(paste0("data/", "PR.rds"))) {
  PR <- readRDS(file = paste0("data/", "PR.rds"))
  PR <- PR %>% dplyr::filter(hv024 %in% c("south west", "south south" , "south east"))
  message("PR file imported.")}


# LOAD SEGMENTATION DATASET, SKIP PATTERN AND DATA INVERSION ANALYSIS FILES

# Load South Nigeria dataset
df_edit <- read.csv("data/Nigeria_South_2024DHS8_1.1.csv")

# Load South Nigeria outcomes and vulnerabilities sheets from WB
wb_outcomes <- read_excel("output/pathways workbook - South_Nigeria_2024DHS8_1.6.xlsx", sheet = "outcomes")
wb_vuln <- read_excel("output/pathways workbook - South_Nigeria_2024DHS8_1.6.xlsx", sheet = "vulnerabilities")

#Load outcomes inversions analysis file
inv_outcomes <- read_excel("data/outcomes_to_flip_recode.xlsx", sheet = "Southern Nigeria")
# Keep only variables flip ==1 and recode == 0
inv_outcomes_vars <- inv_outcomes %>%
  dplyr::filter(flip == 1 & recode == 0) %>%
  pull(outcome_variable)

# Keep only variables to recode
flip_outcomes_vars <- inv_outcomes %>%
  dplyr::filter(flip == 1 & recode != 0) %>%
  pull(outcome_variable)

#Load skip patterns analysis file
skip_patterns <- read.csv("data/skip_patterns_analysis.csv")
# Keep only variables that have skip patterns in South (region = "Both" or "South Nigeria")
# and where skip_category_south is not empty
skip_vars <- skip_patterns %>%
  dplyr::filter(region %in% c("Both", "South Nigeria")) %>%
  dplyr::filter(!is.na(skip_category_south) & skip_category_south != "")

################################################################################
# SKIP PATTERNS HANDLING
################################################################################


# Iterate through each variable with skip patterns
for (i in 1:nrow(skip_vars)) {
  var_name <- skip_vars$variable_name[i]
  skip_category <- skip_vars$skip_category_south[i]
  short_name <- skip_vars$short_name[i]

  # Check if variable exists in the dataset
  if (!var_name %in% colnames(df_edit)) {
    cat(sprintf("  [SKIP] Variable '%s' not found in dataset\n", var_name))
    next
  }

  # Create new variable name
  new_var_name <- paste0(var_name, "_skp_rm")

  tryCatch({
    # Copy the original variable
    df_edit[[new_var_name]] <- df_edit[[var_name]]

    # Handle multiple skip categories separated by semicolon
    skip_categories <- strsplit(skip_category, ";")[[1]]
    skip_categories <- trimws(skip_categories)

    # Replace each skip category with NA
    for (skip_cat in skip_categories) {
      df_edit[[new_var_name]][df_edit[[new_var_name]] == skip_cat] <- NA
    }

  }, error = function(e) {
    cat(sprintf(
      "  [ERROR] Failed to process '%s': %s\n",
      var_name, e$message
    ))
  })
}


# Inspect the new variables
skp_cols <- grep("_skp_rm$", names(df_edit), value = TRUE)
unique_values <- lapply(df_edit[skp_cols], unique)


################################################################################
# SIMPLE OUTCOME INVERSIONS HANDLING
################################################################################

df_edit <- df_edit %>%
  mutate(
    across(
      all_of(inv_outcomes_vars),
      ~ if_else(. == 1, 0L,
                if_else(. == 0, 1L, NA_integer_)),
      .names = "{.col}_inv"
    )
  )

# Inspect the new variables
inv_cols <- grep("_inv$", names(df_edit), value = TRUE)
unique_values <- lapply(df_edit[skp_cols], unique)

# Check tabulations
for (v in inv_cols) {

  orig <- sub("_inv$", "", v)

  cat("\n=== ", v, " vs ", orig, " ===\n")

  print(
    table(
      df_edit[[v]],
      df_edit[[orig]],
      useNA = "ifany"
    )
  )
}


################################################################################
# MORE COMPLEX OUTCOME INVERSIONS LOGIC FIXES HANDLING ON VACCINES
################################################################################
# *** Pentavalent ***
### DPT 1, 2, 3 either source ----
KR <- KR %>%
  mutate(dpt1 = case_when(h3%in%c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h3%in%c("no","don't know") ~ 0  )) %>%
  mutate(dpt2 = case_when(h5%in%c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h5%in%c("no","don't know") ~ 0  )) %>%
  mutate(dpt3 = case_when(h7%in%c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h7%in%c("no","don't know") ~ 0  )) %>%
  mutate(dptsum = dpt1 + dpt2 + dpt3) %>%
  mutate(dpt.all = case_when(is.na(dptsum) ~ NA, dptsum == 3 ~ 1, TRUE ~ 0))
# table(KR$dpt.all, useNA = "ifany")

# *** Measles ***
## Measles either source ----
KR <- KR %>%
  mutate(measles1 = case_when(h9 %in% c("vaccination date on card", "vaccination marked on card", "reported by mother") ~ 1, h9 %in% c("no", "don't know")  ~ 0  )) %>%
  mutate(measles2 = case_when(h9a %in% c("vaccination date on card", "vaccination marked on card", "reported by mother") ~ 1, h9a %in% c("no", "don't know")  ~ 0  )) %>%
  mutate(measlessum = measles1 + measles2) %>%
  mutate(measles.full = case_when(is.na(measlessum) ~ NA, measlessum == 2 ~ 1, TRUE ~ 0))

# *** Polio ***
# Polio 0, 1, 2, 3 either source
KR <- KR %>%
  mutate(polio1 = case_when(h4%in%c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h4%in%c("no","don't know") ~ 0  )) %>%
  mutate(polio2 = case_when(h6%in%c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h6%in%c("no","don't know") ~ 0  )) %>%
  mutate(polio3 = case_when(h8%in%c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h8%in%c("no","don't know") ~ 0  )) %>%
  mutate(poliosum=polio1 + polio2 + polio3) %>%
  mutate(polio.all = case_when(is.na(poliosum) ~ NA, poliosum == 3 ~ 1, TRUE ~ 0))

### BCG ----
KR <- KR %>%
  mutate(bcg1 = case_when(h2 %in% c("vaccination date on card", "vaccination marked on card", "reported by mother") ~ 1, h2 %in% c("no", "don't know")  ~ 0  )) %>%
  mutate(bcg.all = case_when(is.na(bcg1) ~ NA, bcg1 == 1 ~ 1, TRUE ~ 0))
# table(KR$bcg.all, useNA = "ifany")

### Yellow fever ----
KR <- KR %>%
  mutate(yellowfever1 = case_when(syf %in% c("vaccination date on card", "vaccination marked on card", "reported by mother") ~ 1, syf %in% c("no", "don't know")  ~ 0  )) %>%
  mutate(yellowfever.all = case_when(is.na(yellowfever1) ~ NA, yellowfever1 == 1 ~ 1, TRUE ~ 0))

table(KR$yellowfever.all, useNA = "ifany")

### Pneumococcal ----
# 0, 1, 2, 3
KR <- KR %>%
  mutate(pneumo1 = case_when(h54%in%c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h54%in%c("no","don't know") ~ 0  )) %>%
  mutate(pneumo2 = case_when(h55%in%c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h55%in%c("no","don't know") ~ 0  )) %>%
  mutate(pneumo3 = case_when(h56%in%c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h56%in%c("no","don't know") ~ 0  )) %>%
  mutate(pneumosum=pneumo1 + pneumo2 + pneumo3) %>%
  mutate(pneumo.all = case_when(is.na(pneumosum) ~ NA, pneumosum == 3 ~ 1, TRUE ~ 0))

### Polio ----
# Polio 0, 1, 2, 3 either source
KR <- KR %>%
  mutate(polio1 = case_when(h4%in%c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h4%in%c("no","don't know") ~ 0  )) %>%
  mutate(polio2 = case_when(h6%in%c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h6%in%c("no","don't know") ~ 0  )) %>%
  mutate(polio3 = case_when(h8%in%c("vaccination date on card","vaccination marked on card","reported by mother") ~ 1, h8%in%c("no","don't know") ~ 0  )) %>%
  mutate(poliosum=polio1 + polio2 + polio3) %>%
  mutate(polio.all = case_when(is.na(poliosum) ~ NA, poliosum == 3 ~ 1, TRUE ~ 0))
# table(KR$polio.all, useNA = "ifany")

### Meningitis ----
#1 Due to an error in the Woman’s Questionnaire, information on yellow fever and meningitis vaccinations is missing
#for 337 children age 12–23 months.
KR <- KR %>%
  mutate(meningitis1 = case_when(smg %in% c("vaccination date on card", "vaccination marked on card", "reported by mother") ~ 1, smg %in% c("no", "don't know")  ~ 0  )) %>%
  mutate(meningitis.all = case_when(is.na(meningitis1) ~ NA, meningitis1 == 1 ~ 1, TRUE ~ 0))

table(KR$meningitis.all, useNA = "ifany")


# CHANGES START HERE
# Basic antigen full 12m+ yn
KR <- KR %>%
  mutate(
    basic.antigen.full.12m = case_when(
      b19 < 12 ~ NA_real_,
      b19 >= 12 &  bcg.all == 1 & dpt.all == 1 & polio.all == 1 & measles1 == 1 ~ 1,
      b19 >= 12 ~ 0
    )
  )

table(KR$basic.antigen.full.12m, useNA = "ifany")

# Other immunizations
KR <- KR %>%
  mutate(
    dpt.all_12m= if_else(b19 >= 12, dpt.all, NA_real_), # DPT fully vaccinated 12+ months (similar to DHS)
    dpt.all_4m = if_else(b19 > 4, dpt.all, NA_real_), # DPT fully vaccinated 4+ months per schedule
    measles.full_24m = if_else(b19 >= 24, measles.full, NA_real_), # Measles full 2 doses  24+ months (similar to DHS)
    measles.full_15m = if_else(b19 > 15, measles.full, NA_real_), # Measles full 2 doses  15+ months per schedule
    measles1_12m = if_else(b19 >= 12, measles1, NA_real_), # Measles at least one 12+ months (similar to DHS)
    measles1_9m = if_else(b19 > 9, measles1, NA_real_), # Measles at least one 9+ months per schedule
    meningitis_12m = if_else(b19 >= 12, meningitis.all, NA_real_), # Meningitis 12+ months (similar to DHS)
    meningitis_9m = if_else(b19 > 9, meningitis.all, NA_real_), # Meningitis 9+ months per schedule
    yellowfever_12m = if_else(b19 >= 12,yellowfever.all, NA_real_), # Yellow fever 12+ months (similar to DHS)
    yellowfever_9m = if_else(b19 > 9,yellowfever.all, NA_real_), # Yellow fever 9+ months per schedule
    dpt1_12m = if_else(b19 >= 12, dpt1, NA_real_), # Pentavalent 12+ months (similar to DHS)
    dpt1_2m = if_else(b19 > 2, dpt1, NA_real_), # Pentavalent first dose 2+ months per schedule
    pneumo1_12m = if_else(b19 >= 12, pneumo1, NA_real_), # Pneumococcal first dose 12+ months (similar to DHS)
    pneumo1_2m = if_else(b19 > 2, pneumo1, NA_real_), # Pneumo 2+ months per schedule
    polio.all_12m = if_else(b19 >= 12, polio.all, NA_real_), # Polio 12+ months (similar to DHS)
    polio.all_4m = if_else(b19 > 4, polio.all, NA_real_) # Polio all 3 4+ months (16 weeks) per schedule
  )

# Home birth any child
BR <- BR %>%
  mutate(
    facility.birth = case_when(
      is.na(m15) | m15 == "" ~ NA_real_,
      m15 %in% c("faith-based hospital",
                 "faith-based clinic",
                 "other ngo medical sector",
                 "other",
                 "her home",
                 "home",
                 "other home") ~ 0,
      TRUE ~ 1
    )
  )

# Home birth last - converted to facility birth
IR <- IR %>%
  mutate(
    home.birth.last_inv = case_when(
      is.na(m15_1) | m15_1 == "" ~ NA_real_,
      m15_1 %in% c("faith-based hospital",
                   "faith-based clinic",
                   "other ngo medical sector",
                   "other") ~ 0,
      TRUE ~ 1
    )
  )



# Convert variables to woman-level measures
ir.out <- IR %>%
  dplyr::select(caseid, home.birth.last_inv)


br.out <- BR %>%
  group_by(caseid) %>%
  summarize(
    # All facility birth
    n_eligible_fac = sum(!is.na(facility.birth)),
    home.birth.yn_inv = dplyr::case_when(
      n_eligible_fac == 0 ~ NA_real_,  # no eligible births in BR
      all(facility.birth[!is.na(facility.birth)] == 1) ~ 1,
      TRUE ~ 0
    ),
    .groups = "drop"
  )

kr.out <- KR %>%
  group_by(caseid) %>%
  summarize(
    # All basic antigen 12+m
    n_eligible_basic = sum(!is.na(basic.antigen.full.12m)),
    basic.antigen.full.12m.yn_inv = dplyr::case_when(
      n_eligible_basic == 0 ~ NA_real_,
      all(basic.antigen.full.12m[!is.na(basic.antigen.full.12m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # All dpt doses 12+
    n_eligible_dpt = sum(!is.na(dpt.all_12m)),
    dpt.full.yn_inv = dplyr::case_when(
      n_eligible_dpt == 0 ~ NA_real_,
      all(dpt.all_12m[!is.na(dpt.all_12m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # All dpt doses 4+
    n_eligible_dpt = sum(!is.na(dpt.all_4m)),
    dpt.full.yn.sched_inv = dplyr::case_when(
      n_eligible_dpt == 0 ~ NA_real_,
      all(dpt.all_4m[!is.na(dpt.all_4m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # 2 measles doses 24+
    n_eligible_meas2 = sum(!is.na(measles.full_24m)),
    meas.full.yn_inv = dplyr::case_when(
      n_eligible_meas2 == 0 ~ NA_real_,
      all(measles.full_24m[!is.na(measles.full_24m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # 2 measles doses 15+
    n_eligible_meas2 = sum(!is.na(measles.full_15m)),
    meas.full.yn.sched_inv = dplyr::case_when(
      n_eligible_meas2 == 0 ~ NA_real_,
      all(measles.full_15m[!is.na(measles.full_15m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # measles at least 1 12+
    n_eligible_meas1 = sum(!is.na(measles1_12m)),
    measles.none.yn_inv = dplyr::case_when(
      n_eligible_meas1 == 0 ~ NA_real_,
      all(measles1_12m[!is.na(measles1_12m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # measles at least 1 9+
    n_eligible_meas1 = sum(!is.na(measles1_9m)),
    measles.none.yn.sched_inv = dplyr::case_when(
      n_eligible_meas1 == 0 ~ NA_real_,
      all(measles1_9m[!is.na(measles1_9m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # meningitis 12+
    n_eligible_meningitis = sum(!is.na(meningitis_12m)),
    meningitis.none.yn_inv = dplyr::case_when(
      n_eligible_meningitis == 0 ~ NA_real_,
      all(meningitis_12m[!is.na(meningitis_12m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # meningitis 9+
    n_eligible_meningitis = sum(!is.na(meningitis_9m)),
    meningitis.none.yn.sched_inv = dplyr::case_when(
      n_eligible_meningitis == 0 ~ NA_real_,
      all(meningitis_9m[!is.na(meningitis_9m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # pentavalent 12+
    n_eligible_penta = sum(!is.na(dpt1_12m)),
    pentavalent.none.yn_inv = dplyr::case_when(
      n_eligible_penta == 0 ~ NA_real_,
      all(dpt1_12m[!is.na(dpt1_12m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # pentavalent 2+
    n_eligible_penta = sum(!is.na(dpt1_2m)),
    pentavalent.none.yn.sched_inv = dplyr::case_when(
      n_eligible_penta == 0 ~ NA_real_,
      all(dpt1_2m[!is.na(dpt1_2m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # pneumo 12+
    n_eligible_pneumo = sum(!is.na(pneumo1_12m)),
    pneumo.none.yn_inv = dplyr::case_when(
      n_eligible_pneumo == 0 ~ NA_real_,
      all(pneumo1_12m[!is.na(pneumo1_12m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # pneumo 2+
    n_eligible_pneumo = sum(!is.na(pneumo1_2m)),
    pneumo.none.yn.sched_inv = dplyr::case_when(
      n_eligible_pneumo == 0 ~ NA_real_,
      all(pneumo1_2m[!is.na(pneumo1_2m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # polio 12+
    n_eligible_polio = sum(!is.na(polio.all_12m)),
    polio.full.yn_inv = dplyr::case_when(
      n_eligible_polio == 0 ~ NA_real_,
      all(polio.all_12m[!is.na(polio.all_12m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # polio 4+
    n_eligible_polio = sum(!is.na(polio.all_4m)),
    polio.full.yn.sched_inv = dplyr::case_when(
      n_eligible_polio == 0 ~ NA_real_,
      all(polio.all_4m[!is.na(polio.all_4m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # yellow fever 12+
    n_eligible_yellow = sum(!is.na(yellowfever_12m)),
    yellowfever.none.yn_inv = dplyr::case_when(
      n_eligible_yellow == 0 ~ NA_real_,
      all(yellowfever_12m[!is.na(yellowfever_12m)] == 1) ~ 1,
      TRUE ~ 0
    ),
    # yellow fever 9+
    n_eligible_yellow = sum(!is.na(yellowfever_9m)),
    yellowfever.none.yn.sched_inv = dplyr::case_when(
      n_eligible_yellow == 0 ~ NA_real_,
      all(yellowfever_9m[!is.na(yellowfever_9m)] == 1) ~ 1,
      TRUE ~ 0
    ),

    .groups = "drop"
  )

# filter only new vars
ir.out <- ir.out %>%
  dplyr::select(caseid, ends_with("_inv"))

kr.out <- kr.out %>%
  dplyr::select(caseid, ends_with("_inv"))

br.out <- br.out %>%
  dplyr::select(caseid, ends_with("_inv"))

# JOIN TOGETHER
outcomes_inv <- ir.out %>%
  base::merge(kr.out, by="caseid", all.x=TRUE) %>%
  base::merge(br.out, by="caseid", all.x=TRUE)

outcomes_inv

# merge into df_edit
df_edit <- df_edit %>%
  dplyr::left_join(outcomes_inv, by="caseid")



################################################################################
# SAVE NEW COLUMNS TO ORIGINAL DATASET
################################################################################











