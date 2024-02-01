
# Calculate Comparator Inputs --------------------------------------------------
#
# This function takes schools data, either primary or secondary, and 
# restructures it into a matrix of measurements, suitable for measuring the 
# similarlity between schools.
#
# Args:
#
# df: a data frame of primary or secondary schools data - this is the data from 
#     a supplied Excel file, it is read into R then cleaned up a bit because the 
#     sheet was a bit messy

calc_compartor_inputs <- function (df) {
  
  # Extract the GIMD stats into a matrix
  
  gimd_mtx <- df %>% 
    dplyr::select(dplyr::starts_with('gimd')) %>% 
    select(ends_with('_percent')) %>% 
    as.matrix()
  
  colnames(gimd_mtx) <- 1:10
  rownames(gimd_mtx) <- df[['school_name']]
  
  # Some are slightly off summing to 1 due to minor rounding issues, this fixes
  # that
  
  gimd_mtx <- gimd_mtx / rowSums(gimd_mtx)
  
  multiplier <- matrix(1:10, nrow = nrow(gimd_mtx), ncol = 10, byrow = TRUE)
  
  schools_gimd_mean <- rowSums(gimd_mtx * multiplier)
  
  # The original methodology used variance but I think this is not optimal. 
  # Variance tells you the mean square difference in the data points but standard
  # deviation just tells you the mean difference. If you think about it, variance
  # will make larger numbers even larger
  
  schools_gimd_sd <- apply(gimd_mtx, MARGIN = 1, weighted_sd)
  
  mean_roll <- mean(df[['school_roll_census_2023']])
  roll_diff_from_mean <- df[['school_roll_census_2023']] - mean_roll
  roll_percent_diff <- roll_diff_from_mean / mean_roll
  
  stats_mtx <- matrix(NA, ncol = 5, nrow = nrow(gimd_mtx))
  colnames(stats_mtx) <- c('gimd_mean', 'gimd_sd', 'eal', 'fsm', 'roll_count')
  rownames(stats_mtx) <- rownames(gimd_mtx)
  
  stats_mtx[,1] <- schools_gimd_mean
  stats_mtx[,2] <- schools_gimd_sd
  stats_mtx[,3] <- df[['eal_percent']]
  stats_mtx[,4] <- df[['fsm_percent']]
  stats_mtx[,5] <- roll_percent_diff
  
  return (stats_mtx)
  
}


# Weighted Mean ----------------------------------------------------------------
#
# Calculate a weighted mean based on position
#
# Args:
#
# values: vector of values to produce a weighted mean. Each mean is weighted 
#         based on position

weighted_mean <- function (values) {
  
  weights <- 1:length(values)
  weighted_sum <- sum(weights * values)
  total_values <- sum(values)
  
  # Handle division by zero
  
  if (total_values == 0) {
    
    return(NA)  
    
  }
  
  return (weighted_sum / total_values)
  
}

# Weighted Standard Deviation --------------------------------------------------
#
# Calculate a weighted mean based on position
#
# Args:
#
# values: vector of values to produce a weighted standard deviation. Each mean 
#         is weighted based on position then a standard deviation

weighted_sd <- function (values) {
  
  mean_value <- weighted_mean(values)
  
  # Handle division by zero in weighted mean
  
  if (is.na(mean_value)) {
    
    return(NA)  
    
  }
  
  weights <- 1:length(values)
  weighted_variance <- sum(((weights - mean_value)^2) * values) / sum(values)
  sqrt_weighted_variance <- sqrt(weighted_variance)
  
  return (sqrt_weighted_variance)
}

# Calculate Distances ----------------------------------------------------------
#
# Calculate distances between schools 
#
# Args:
#
# school_inputs:   school inputs matrix
# num_comparators: number of schools to have as comparators (10 for primary
#                  schools, 5 for secondary)

calc_distances <- function (school_inputs, num_comparators) {
  
  num_schools <- nrow(school_inputs)
  
  standard_devs <- apply(school_inputs, 2, sd)
  standard_devs <- matrix(standard_devs, ncol = length(standard_devs), 
                          nrow = num_schools, byrow = TRUE)
  
  store_distances <- vector('list', num_schools)
  
  for (i in 1:num_schools) {
    
    school_name <- rownames(school_inputs)[i]
    
    school_input <- school_inputs[rep(i, num_schools),]
    
    distance_mtx <- abs(school_inputs - school_input) / standard_devs
    
    distances <- sort(rowSums(distance_mtx)[-i])
    distances <- distances[is.finite(distances)]
    
    store_distances[[i]] <- distances
    
  }
  
  comparator_table <- map2_dfr(store_distances, 
                               rownames(school_inputs), 
                               build_comparator_tables,
                               average_distance =  mean(unlist(store_distances)),
                               num_comparators = num_comparators)
  
  return (comparator_table)
  
}

# Build Comparator Tables ------------------------------------------------------
#
# Build a table of school comparators
#
# Args:
#
# distances:        distance matrix
# school:           name of the school to build table for
# average_distance: mean distance between schools for deciding star rating of 
#                   match
# num_comparators:  number of schools to have as comparators (10 for primary
#                   schools, 5 for secondary)

build_comparator_tables <- function (distances, school, average_distance,
                                     num_comparators) {
  
  distances <- distances[1:num_comparators]
  
  half_average_distance <- average_distance * 0.5
  
  comparator_table <- tibble(school,
                             comparison_school = names(distances), 
                             distance = distances) %>% 
    mutate(
      star_rating = case_when(distance <= half_average_distance ~ '***',
                              distance <= average_distance ~ '**',
                              TRUE ~ '*')
    )
  
  return (comparator_table)
  
}

# Compare Previous -------------------------------------------------------------
#
# Compare the previous schools list with new schools
#
# Args:
#
# school_name: name of school to look at
# tables_new:  new output table
# tables_prev: previous output table

compare_prev <- function (school_name, tables_new, tables_prev) {
  
  school_table_new <- tables_new[tables_new[['school']] == school_name,]
  school_table_prev <- tables_prev[tables_prev[['school']] == school_name,]
  
  school_table_new %>% 
    mutate(comparison_status = if_else(
      comparison_school %in% school_table_prev$comparison_school, 'Existing Match', 
      'New Match')
    )
}

