
# LOAD PACKAGES
library(survey)
library(dplyr)
library(ggplot2)

# LOAD SENEGAL DATA
df <- read.csv("merged_pathways_dhs.csv")

# filter data to remove NA from outcomes
df_1 <- df %>% dplyr::filter(!is.na(nofp.mod.now))

# DHS survey design
design <- svydesign(ids = ~v021.x, strata = ~ v023.x, data = df_1, weights = ~wt, nest = TRUE)

# model
log.model1 <- svyglm(nofp.mod.now ~ segment_name, design = design, family = quasibinomial())
summary(log.model1)

# CALCULATE ACCURACY

# Get predicted probabilities
predicted_probs <- predict(log.model1, type = "response")

# Convert probabilities to predicted class (0 or 1), using a 0.5 threshold
predicted_class <- ifelse(predicted_probs >= 0.5, 1, 0)

# update the design object

df_1$correct <- as.numeric(predicted_class == df_1$nofp.mod.now)

design_updated <- update(design, 
                         predicted_class = predicted_class,
                         correct = df_1$correct)

accuracy <- svymean(~correct, design_updated)
accuracy 

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

# Use svyby to get mean predicted probabilities + CIs by class
seg.probs <- svyby(~predicted.prob + ci.lower + ci.upper, 
                   ~class, 
                   design = design_with_preds, 
                   svymean)

# Clean up for plotting
seg.probs <- seg.probs %>%
  rename(mean.prob = predicted.prob, 
         lower = ci.lower, 
         upper = ci.upper)


seg_order <- c("R2-S", "R3.1-S", "R3.2-S", "R4-S",
               "U1-S", "U2.1-S", "U2.2-S", "U3.1-S")

seg.probs <- seg.probs %>%
  mutate(seg.name = factor(seg.name, levels = seg_order))

ggplot(seg.probs, aes(x = seg.name, y = mean.prob)) +
  geom_point(color = "steelblue", size = 3) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2, color = "red") +
  geom_text(aes(label = round(mean.prob, 2)), vjust = -1, size = 3.5) +
  coord_flip() +
  labs(
    title = "Predicted Probability of No Modern FP Method Use by Segment",
    subtitle = paste0("Overall Accuracy: ", round(100 * accuracy, 0), "%"),
    x = "Segment",
    y = "Predicted Probability of No Modern FP Method Use"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"),
        axis.text.x = element_text(angle = 0, hjust = 1, size = 9),
        legend.text = element_text(size = 6))


