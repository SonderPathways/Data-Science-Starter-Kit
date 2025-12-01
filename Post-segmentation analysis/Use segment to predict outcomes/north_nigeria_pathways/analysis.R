
# LOAD PACKAGES
library(survey)
library(dplyr)
library(ggplot2)

# LOAD SENEGAL DATA
df <- read.csv("Nigeria_North_2022Pathways1_1.3.csv")

df_1 <- df %>% dplyr::filter(!is.na(hb.sum.yn))

# HOME BIRTH

# filter data to remove NA from outcomes

# pathways survey design
design <- svydesign(ids = ~PSUclean, data = df_1, weights = ~weight)

# DHS survey design call
# design <- svydesign(ids = ~ v021, strata = ~ v023, data = df_1, weights = ~wt, nest = TRUE)


log.model1 <- svyglm(hb.sum.yn ~ class, design = design, family = quasibinomial())
summary(log.model1)

# CALCULATE ACCURACY

# Get predicted probabilities
predicted_probs <- predict(log.model1, type = "response")

# Convert probabilities to predicted class (0 or 1), using a 0.5 threshold
predicted_class <- ifelse(predicted_probs >= 0.5, 1, 0)

# Get the actual outcome variable
actual_class <- df_1$hb.sum.yn  # Make sure this is numeric 0/1, not a factor

# Calculate accuracy
accuracy <- mean(predicted_class == actual_class, na.rm = TRUE)
print(paste("Accuracy:", round(accuracy, 4)))


# PLOTTING

# Step 1: Get predicted link and standard errors from svyglm model
predicted.probs <- predict(log.model1, type = "link", se.fit = TRUE)

# Step 2: Convert to probabilities and compute confidence intervals
predicted.probs_1 <- as.data.frame(predicted.probs)

link.fit <- predicted.probs_1$link
link.se <- predicted.probs_1$SE

# Step 3: Add predictions back to your original data frame
df_1$predicted.prob <- plogis(link.fit)
df_1$ci.lower <- plogis(link.fit - 1.96 * link.se)
df_1$ci.upper <- plogis(link.fit + 1.96 * link.se)

# Step 4: Summarize predicted probabilities by segment (weighted!)
design_with_preds <- update(design, 
                            predicted.prob = df_1$predicted.prob,
                            ci.lower = df_1$ci.lower,
                            ci.upper = df_1$ci.upper)

# Use svyby to get mean predicted probabilities + CIs by segment_name
seg.probs <- svyby(~predicted.prob + ci.lower + ci.upper, 
                   ~class, 
                   design = design_with_preds, 
                   svymean)

# Clean up for plotting
seg.probs <- seg.probs %>%
  rename(mean.prob = predicted.prob, 
         lower = ci.lower, 
         upper = ci.upper)

# Step 5: Plot
ggplot(seg.probs, aes(x = reorder(class, mean.prob), y = mean.prob)) +
  geom_point(color = "steelblue", size = 3) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2, color = "red") +
  geom_text(aes(label = round(mean.prob, 2)), vjust = -1, size = 3.5) +
  coord_flip() +
  labs(title = "Predicted Probability of Home Birth by Segment",
       subtitle = paste0("Overall Accuracy: ",round(100*accuracy,0),"%"),
       x = "Segment",
       y = "Predicted Probability of Home Birth") +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"),
        axis.text.x = element_text(angle = 0, hjust = 1, size = 9),
        legend.text = element_text(size = 6))



# ANC

# filter data to remove NA from outcomes
df_1 <- df %>% dplyr::filter(!is.na(anc.4plus)) 

design <- svydesign(ids = ~PSUclean, data = df_1, weights = ~weight)
log.model1 <- svyglm(anc.4plus ~ class, design = design, family = quasibinomial())
summary(log.model1)

# CALCULATE ACCURACY

# Get predicted probabilities
predicted_probs <- predict(log.model1, type = "response")

# Convert probabilities to predicted class (0 or 1), using a 0.5 threshold
predicted_class <- ifelse(predicted_probs >= 0.5, 1, 0)

# Get the actual outcome variable
actual_class <- df_1$anc.4plus  # Make sure this is numeric 0/1, not a factor

# Calculate accuracy
accuracy <- mean(predicted_class == actual_class, na.rm = TRUE)
print(paste("Accuracy:", round(accuracy, 4)))


# PLOTTING

# Step 1: Get predicted link and standard errors from svyglm model
predicted.probs <- predict(log.model1, type = "link", se.fit = TRUE)

# Step 2: Convert to probabilities and compute confidence intervals
predicted.probs_1 <- as.data.frame(predicted.probs)

link.fit <- predicted.probs_1$link
link.se <- predicted.probs_1$SE

# Step 3: Add predictions back to your original data frame
df_1$predicted.prob <- plogis(link.fit)
df_1$ci.lower <- plogis(link.fit - 1.96 * link.se)
df_1$ci.upper <- plogis(link.fit + 1.96 * link.se)

# Step 4: Summarize predicted probabilities by segment (weighted!)
design_with_preds <- update(design, 
                            predicted.prob = df_1$predicted.prob,
                            ci.lower = df_1$ci.lower,
                            ci.upper = df_1$ci.upper)

# Use svyby to get mean predicted probabilities + CIs by segment_name
seg.probs <- svyby(~predicted.prob + ci.lower + ci.upper, 
                   ~class, 
                   design = design_with_preds, 
                   svymean)

# Clean up for plotting
seg.probs <- seg.probs %>%
  rename(mean.prob = predicted.prob, 
         lower = ci.lower, 
         upper = ci.upper)

# Step 5: Plot
ggplot(seg.probs, aes(x = reorder(class, mean.prob), y = mean.prob)) +
  geom_point(color = "steelblue", size = 3) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2, color = "red") +
  geom_text(aes(label = round(mean.prob, 2)), vjust = -1, size = 3.5) +
  coord_flip() +
  labs(title = "Predicted Probability of Less than 4 ANC by Segment",
       subtitle = paste0("Overall Accuracy: ",round(100*accuracy,0),"%"),
       x = "Segment",
       y = "Predicted Probability of Less than 4 ANC") +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"),
        axis.text.x = element_text(angle = 0, hjust = 1, size = 9),
        legend.text = element_text(size = 6))


# mCP

# filter data to remove NA from outcomes
df_1 <- df %>% dplyr::filter(!is.na(fp.current.any)) 

design <- svydesign(ids = ~ PSUclean, data = df_1, weights = ~weight)
log.model1 <- svyglm(fp.current.any ~ class, design = design, family = quasibinomial())
summary(log.model1)

# CALCULATE ACCURACY

# Get predicted probabilities
predicted_probs <- predict(log.model1, type = "response")

# Convert probabilities to predicted class (0 or 1), using a 0.5 threshold
predicted_class <- ifelse(predicted_probs >= 0.5, 1, 0)

# Get the actual outcome variable
actual_class <- df_1$fp.current.any  # Make sure this is numeric 0/1, not a factor

# Calculate accuracy
accuracy <- mean(predicted_class == actual_class, na.rm = TRUE)
print(paste("Accuracy:", round(accuracy, 4)))


# PLOTTING

# Step 1: Get predicted link and standard errors from svyglm model
predicted.probs <- predict(log.model1, type = "link", se.fit = TRUE)

# Step 2: Convert to probabilities and compute confidence intervals
predicted.probs_1 <- as.data.frame(predicted.probs)

link.fit <- predicted.probs_1$link
link.se <- predicted.probs_1$SE

# Step 3: Add predictions back to your original data frame
df_1$predicted.prob <- plogis(link.fit)
df_1$ci.lower <- plogis(link.fit - 1.96 * link.se)
df_1$ci.upper <- plogis(link.fit + 1.96 * link.se)

# Step 4: Summarize predicted probabilities by segment (weighted!)
design_with_preds <- update(design, 
                            predicted.prob = df_1$predicted.prob,
                            ci.lower = df_1$ci.lower,
                            ci.upper = df_1$ci.upper)

# Use svyby to get mean predicted probabilities + CIs by segment_name
seg.probs <- svyby(~predicted.prob + ci.lower + ci.upper, 
                   ~class, 
                   design = design_with_preds, 
                   svymean)

# Clean up for plotting
seg.probs <- seg.probs %>%
  rename(mean.prob = predicted.prob, 
         lower = ci.lower, 
         upper = ci.upper)

# Step 5: Plot
ggplot(seg.probs, aes(x = reorder(class, mean.prob), y = mean.prob)) +
  geom_point(color = "steelblue", size = 3) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2, color = "red") +
  geom_text(aes(label = round(mean.prob, 2)), vjust = -1, size = 3.5) +
  coord_flip() +
  labs(title = "Predicted Probability of no mCP by Segment",
       subtitle = paste0("Overall Accuracy: ",round(100*accuracy,0),"%"),
       x = "Segment",
       y = "Predicted Probability of no mCP") +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"),
        axis.text.x = element_text(angle = 0, hjust = 1, size = 9),
        legend.text = element_text(size = 6))


# Wasting 

# filter data to remove NA from outcomes
df_1 <- df %>% dplyr::filter(!is.na(her.wasting)) 

design <- svydesign(ids = ~ PSUclean, data = df_1, weights = ~weight)
log.model1 <- svyglm(her.wasting ~ class, design = design, family = quasibinomial())
summary(log.model1)

# CALCULATE ACCURACY

# Get predicted probabilities
predicted_probs <- predict(log.model1, type = "response")

# Convert probabilities to predicted class (0 or 1), using a 0.5 threshold
predicted_class <- ifelse(predicted_probs >= 0.5, 1, 0)

# Get the actual outcome variable
actual_class <- df_1$her.wasting  # Make sure this is numeric 0/1, not a factor

# Calculate accuracy
accuracy <- mean(predicted_class == actual_class, na.rm = TRUE)
print(paste("Accuracy:", round(accuracy, 4)))


# PLOTTING

# Step 1: Get predicted link and standard errors from svyglm model
predicted.probs <- predict(log.model1, type = "link", se.fit = TRUE)

# Step 2: Convert to probabilities and compute confidence intervals
predicted.probs_1 <- as.data.frame(predicted.probs)

link.fit <- predicted.probs_1$link
link.se <- predicted.probs_1$SE

# Step 3: Add predictions back to your original data frame
df_1$predicted.prob <- plogis(link.fit)
df_1$ci.lower <- plogis(link.fit - 1.96 * link.se)
df_1$ci.upper <- plogis(link.fit + 1.96 * link.se)

# Step 4: Summarize predicted probabilities by segment (weighted!)
design_with_preds <- update(design, 
                            predicted.prob = df_1$predicted.prob,
                            ci.lower = df_1$ci.lower,
                            ci.upper = df_1$ci.upper)

# Use svyby to get mean predicted probabilities + CIs by segment_name
seg.probs <- svyby(~predicted.prob + ci.lower + ci.upper, 
                   ~class, 
                   design = design_with_preds, 
                   svymean)

# Clean up for plotting
seg.probs <- seg.probs %>%
  rename(mean.prob = predicted.prob, 
         lower = ci.lower, 
         upper = ci.upper)

# Step 5: Plot
ggplot(seg.probs, aes(x = reorder(class, mean.prob), y = mean.prob)) +
  geom_point(color = "steelblue", size = 3) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2, color = "red") +
  geom_text(aes(label = round(mean.prob, 2)), vjust = -1, size = 3.5) +
  coord_flip() +
  labs(title = "Predicted Probability of any Child Wasting by Segment",
       subtitle = paste0("Overall Accuracy: ",round(100*accuracy,0),"%"),
       x = "Segment",
       y = "Predicted Probability of any Child Wasting") +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"),
        axis.text.x = element_text(angle = 0, hjust = 1, size = 9),
        legend.text = element_text(size = 6))



# Under 5 mortality 

# filter data to remove NA from outcomes
df_1 <- df %>% dplyr::filter(!is.na(death.u5)) 

design <- svydesign(ids = ~ PSUclean, data = df_1, weights = ~weight)
log.model1 <- svyglm(death.u5 ~ class, design = design, family = quasibinomial())
summary(log.model1)

# CALCULATE ACCURACY

# Get predicted probabilities
predicted_probs <- predict(log.model1, type = "response")

# Convert probabilities to predicted class (0 or 1), using a 0.5 threshold
predicted_class <- ifelse(predicted_probs >= 0.5, 1, 0)

# Get the actual outcome variable
actual_class <- df_1$death.u5  # Make sure this is numeric 0/1, not a factor

# Calculate accuracy
accuracy <- mean(predicted_class == actual_class, na.rm = TRUE)
print(paste("Accuracy:", round(accuracy, 4)))


# PLOTTING

# Step 1: Get predicted link and standard errors from svyglm model
predicted.probs <- predict(log.model1, type = "link", se.fit = TRUE)

# Step 2: Convert to probabilities and compute confidence intervals
predicted.probs_1 <- as.data.frame(predicted.probs)

link.fit <- predicted.probs_1$link
link.se <- predicted.probs_1$SE

# Step 3: Add predictions back to your original data frame
df_1$predicted.prob <- plogis(link.fit)
df_1$ci.lower <- plogis(link.fit - 1.96 * link.se)
df_1$ci.upper <- plogis(link.fit + 1.96 * link.se)

# Step 4: Summarize predicted probabilities by segment (weighted!)
design_with_preds <- update(design, 
                            predicted.prob = df_1$predicted.prob,
                            ci.lower = df_1$ci.lower,
                            ci.upper = df_1$ci.upper)

# Use svyby to get mean predicted probabilities + CIs by segment_name
seg.probs <- svyby(~predicted.prob + ci.lower + ci.upper, 
                   ~class, 
                   design = design_with_preds, 
                   svymean)

# Clean up for plotting
seg.probs <- seg.probs %>%
  rename(mean.prob = predicted.prob, 
         lower = ci.lower, 
         upper = ci.upper)

# Step 5: Plot
ggplot(seg.probs, aes(x = reorder(class, mean.prob), y = mean.prob)) +
  geom_point(color = "steelblue", size = 3) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2, color = "red") +
  geom_text(aes(label = round(mean.prob, 2)), vjust = -1, size = 3.5) +
  coord_flip() +
  labs(title = "Predicted Probability of Under 5 Mortality by Segment",
       subtitle = paste0("Overall Accuracy: ",round(100*accuracy,0),"%"),
       x = "Segment",
       y = "Predicted Probability of Under 5 Mortality") +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"),
        axis.text.x = element_text(angle = 0, hjust = 1, size = 9),
        legend.text = element_text(size = 6))






