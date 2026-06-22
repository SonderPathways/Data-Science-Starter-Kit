################################################################################

# Dealing with Logical dead ends in CART Output

################################################################################

library(tidyverse)
library(rpart)

# load additional functions to work with rpart tree
source("extra_rpart_functions.R")


  #1. Extracting the required objects from rpart

build_c_split_df <- function(tree) {
  xlevels <- attr(tree, "xlevels")
  
  # Convert rownames of the frame to a column for easier manipulation
  frame <- tibble::rownames_to_column(tree$frame, var = "node") %>%
    tibble::as_tibble()
  
  # Convert tree splits and categorical split matrices to tibbles
  splits <- tibble::as_tibble(tree$splits)
  csplit <- tree$csplit %>%
    tibble::as_tibble() %>%
    tibble::rownames_to_column(var = "index")
  
  # Identify the type of each split: main, primary, or surrogate
  n  <- nrow(splits)
  nn <- frame$ncompete + frame$nsurrogate + !(frame$var == "<leaf>")
  ix <- cumsum(c(1L, nn))
  ix_prim <- unlist(mapply(ix, ix + c(frame$ncompete, 0), FUN = seq, SIMPLIFY = FALSE))
  
  # Tag each split with its type
  split_type <- rep.int("surrogate", n)
  split_type[ix_prim[ix_prim <= n]] <- "primary"
  split_type[ix[ix <= n]] <- "main"
  splits <- dplyr::mutate(splits, type = split_type)
  
  # Extract main splits and align with frame object 
  main_splits  <- dplyr::filter(splits, type == "main")
  main_csplits <- csplit %>% slice(main_splits$index)
  
  # Add ncat and index columns to frame only for non-leaf nodes
  not_leaf <- frame$var != "<leaf>"
  ncat  <- rep.int(0, nrow(frame)); ncat[not_leaf]  <- main_splits$ncat
  index <- rep.int(0, nrow(frame)); index[not_leaf] <- main_splits$index
  frame <- dplyr::mutate(frame, ncat = ncat, index = as.character(index)) %>%
    select("node", "var", "n", "yval", "ncat", "index", "yval2")
  
  # Keep only the main decision nodes where a split occurs
  main_frame <- frame %>% filter(var != "<leaf>")
  
  # Dynamically include all V* columns present (V1..Vn)
  v_cols <- grep("^V\\d+$", names(main_csplits), value = TRUE)
  # Ensure numeric ordering: V1, V2, ..., V10 (not lexicographic)
  v_cols <- v_cols[order(as.integer(sub("^V", "", v_cols)))]
  
  # Join the categorical split info with the main frame by using the splitting index
  c_split_df <- inner_join(main_frame, main_csplits, by = "index") %>%
    select(node, var, dplyr::all_of(v_cols), ncat, index)
  
  c_split_df
}



  #2. Identify problematic split due to the absence of an expected level




valid_row_2_split <- function(row, x_cols) {
  
  # The function validate_row check for '2' in first m columns in csplit, 
  # where m is the number of levels for the splitting variable at that node 
  
  # Pull the csplit values for this row
  values <- suppressWarnings(as.numeric(row[x_cols]))
  # How many categories does this split expect?
  ncat <- suppressWarnings(as.numeric(row[["ncat"]]))
  if (is.na(ncat)) return(NA)
  
  # Use only the non-NA V* entries 
  non_na_idx <- which(!is.na(values))
  values <- values[non_na_idx]
  len <- length(values)
  
  # In rpart csplit: the first `ncat` positions correspond to the levels seen at the node.
  # Any '2' is only allowed *after* those, i.e., positions (ncat+1):len.
  allowed_2_positions <- if (ncat < len) seq.int(ncat + 1L, len) else integer(0)
  
  # If any '2' appears in a disallowed position, the row is invalid
  twos <- which(values == 2)
  disallowed_2 <- setdiff(twos, allowed_2_positions)
  length(disallowed_2) == 0
}


identify_missing_level <- function(c_split_df) {
  # Select columns starting by V to detect '2' and create function to detect unvalid '2'
  
  # All V* columns present (V1..Vn)
  x_cols <- grep("^V\\d+$", names(c_split_df), value = TRUE)
  x_cols <- x_cols[order(as.integer(sub("^V", "", x_cols)))]
  
  # Apply the validation function row-wise to identify missing levels 
  c_split_df <- c_split_df %>%
    rowwise() %>%
    mutate(check_valid = valid_row_2_split(cur_data(), x_cols)) %>%
    ungroup()
  
  # Flag splits with invalid '2's
  flagged_c_split <- c_split_df %>% filter(check_valid == FALSE)
  
  # ---- Build xlevel lookup (unchanged, but dynamic width) ----
  max_levels <- max(lengths(xlevels))
  col_names <- c("var", paste0("V", seq_len(max_levels)))
  
  xlevel_df <- lapply(names(xlevels), function(var) {
    levels <- xlevels[[var]]
    padded <- c(var, levels, rep(NA, max_levels - length(levels)))
    names(padded) <- col_names
    padded
  }) %>%
    do.call(rbind, .) %>%
    as.data.frame(stringsAsFactors = FALSE)
  
   # Join level names with the flagged splits and node numbers
  join_levels <- left_join(flagged_c_split, xlevel_df, by = "var") %>%
    rename(parent_node = node) %>%
    rowwise() %>%
    mutate(child_nodes = list(get_child_nodes(as.numeric(parent_node)))) %>%
    ungroup()
  
  # Find all V*.x (csplit) and matching V*.y (labels), ordered numerically
  v_x <- grep("^V\\d+\\.x$", names(join_levels), value = TRUE)
  v_x <- v_x[order(as.integer(sub("^V(\\d+)\\.x$", "\\1", v_x)))]
  v_y <- sub("\\.x$", ".y", v_x)
  
  final_output <- join_levels %>%
    rowwise() %>%
    mutate(
      not_present_levels = {
        vs <- suppressWarnings(as.numeric(c_across(all_of(v_x))))
        ls <- as.character(c_across(all_of(v_y)))
        keep <- !is.na(vs) & !is.na(ls)
        paste(ls[keep & vs == 2], collapse = ", ")
      }
    ) %>%
    ungroup() %>%
    select(variable = var, parent_node, child_nodes, not_present_levels) %>%
    arrange(parent_node)
  
  final_output
}


  #3. Exclude nodes where a level isn't expected to be present

# This situation occurs when a variable is repeated twice along a path.
# At the first occurrence, some level(s) of the variable are excluded from one path based on the split at that node.
# At the second occurrence, csplit doesn't carry this exclusion information and still flags the level as missing.
#
# Pseudocode:
# - For each row in the c-split data frame:
#     - Pull the first value in the child nodes and the variable.
#     - If the variable appears twice in the path:
#         - Store the position of the variable in the path.
#         - Get the node number and find the sibling node.
#         - If the sibling's level is in the missing-level list:
#             - Remove it from the list: there are no dead-ends for this level
#     - If the missing-level list is empty, remove the row.
#
# Helper function to normalize spacing around commas and trim whitespace

remove_false_levels <- function(final_output) {
  output_level_df <- data.frame()
  
  for (i in seq_len(nrow(final_output))) {
    row <- final_output[i, ]
    var <- row$variable
    parent_node <- row$parent_node
    child_nodes <- row$child_nodes
    missing_level <- row$not_present_levels
    
    # Split and trim levels
    missing_level_list <- trimws(strsplit(missing_level, ",", fixed = TRUE)[[1]])
    
    first_child <- child_nodes[[1]][1]
    child_path_var <- get_path_variables(first_child)
    
    if (sum(child_path_var == var, na.rm = TRUE) > 1) {
      var_first_position <- which(child_path_var == var)[1]
      var_first_node <- get_path_nodes(first_child)[var_first_position + 1]
      var_first_sibling <- get_sibling_node(var_first_node)
      
      var_first_sibling_level <- trimws(strsplit(
        tail(get_path_levels(var_first_sibling), 1), ","
      )[[1]])
      
      # Filter out any missing levels that are found in the sibling
      for (missing in missing_level_list) {
        if (missing %in% var_first_sibling_level) {
          
          missing_level_list <- setdiff(missing_level_list, missing)
        }
      }
    }
    
    # Save the result for this row, including parent and child info
    output_level_df <- rbind(
      output_level_df,
      data.frame(
        row_index = i,
        variable = var,
        parent_node = parent_node,
        first_child = first_child,
        second_child = get_sibling_node(first_child),
        missing_levels = paste(missing_level_list, collapse = ",")
      )
    )
  }
  
  output_level_df <- output_level_df %>%
    filter(missing_levels != "")
  
  output_level_df 
  
}

################################################################################

# ALGORITHM IMPLEMENTATION

# !Requirement : load tree and xlevels
# On tree, run: build_c_split_df() > identify_missing_level() > remove_false_levels()

# Urban North Nigeria Typing Tool DHS7
library(rpart)
library(rpart.plot)

tree <- readRDS('data/urban_tree_prune_model.rds')  
xlevels <- attr(tree, "xlevels")

df_u <- readRDS("data/urban_typing_tool.rds")

prp(tree, type=4, varlen=0, cex=.4)


tree %>% 
  build_c_split_df() %>%
  identify_missing_level() %>%
  remove_false_levels()


# Rural North Nigeria Typing Tool DHS7

tree <- readRDS('data/rural_tree_prune_model.rds')  
xlevels <- attr(tree, "xlevels")

df_r <- readRDS("data/rural_typing_tool.rds")

tree %>%
  build_c_split_df() %>%
  identify_missing_level() %>% 
  remove_false_levels()

prp(tree, type=4, varlen=0, cex=.4)
