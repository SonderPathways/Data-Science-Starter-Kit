
library(randomForest)
library(caret)
library(ggplot2)
library(dplyr)

# Prepare the data
df <- readRDS("NN_all.class.rds")
 
vars_df <- read.csv("vars.csv")
vars <- vars_df$varnames
df <- df %>% dplyr::select(c(hb.sum.yn, vars))


# Ensure all categorical predictors are factors
df[] <- lapply(df, as.factor)


# check missing data
na_percentage <- sapply(df, function(x) sum(is.na(x)) / length(x) * 100)
df <- df[complete.cases(df), ]


# Split the data into training and testing sets
set.seed(123)  # For reproducibility
train_index <- createDataPartition(df$hb.sum.yn, p = 0.8, list = FALSE)
train_data <- df[train_index, ]
test_data <- df[-train_index, ]

# Train the random forest model
set.seed(123)
rf_model <- randomForest(hb.sum.yn ~ ., data = train_data, importance = TRUE, ntree = 500)

# Evaluate the model
predictions <- predict(rf_model, test_data)
confusionMatrix(predictions, test_data$hb.sum.yn)

# Plot variable importance
# Extract variable importance
importance <- importance(rf_model)
var_importance <- data.frame(Variable = row.names(importance), Importance = importance[, "MeanDecreaseGini"])

# Plot variable importance
ggplot(var_importance, aes(x = reorder(Variable, Importance), y = Importance)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Variable Importance (GINI Index)", x = "Variable", y = "Importance")