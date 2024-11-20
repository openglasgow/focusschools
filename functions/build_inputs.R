
# Build Inputs
#
# Creates a matrix of the various inputs required for similarity calculations
#
# df: data frame of schools data

build_inputs <- function (df) {
  
  # Extract the simd stats into a matrix
  
  simd_mtx <- df %>% 
    select(contains('simd')) %>% 
    select(contains('percent')) %>% 
    as.matrix()
  
  colnames(simd_mtx) <- 1:10
  rownames(simd_mtx) <- df[['school_id']]
  
  # Some are slightly off summing to 1 due to minor rounding issues, this fixes
  # that
  
  simd_mtx <- simd_mtx / rowSums(simd_mtx)
  
  multiplier <- matrix(1:10, nrow = nrow(simd_mtx), ncol = 10, byrow = TRUE)
  
  schools_simd_mean <- rowSums(simd_mtx * multiplier)
  
  # The original methodology used variance but I think this is not optimal. 
  # Variance tells you the mean square difference in the data points but standard
  # deviation just tells you the mean difference. If you think about it, variance
  # will make larger numbers even larger
  
  schools_simd_sd <- apply(simd_mtx, MARGIN = 1, weighted_sd)
  
  mean_roll <- mean(df[['school_roll']])
  roll_diff_from_mean <- df[['school_roll']] - mean_roll
  roll_percent_diff <- roll_diff_from_mean / mean_roll
  
  stats_mtx <- matrix(NA, ncol = 5, nrow = nrow(simd_mtx))
  colnames(stats_mtx) <- c('simd_mean', 'simd_sd', 'eal', 'fsm', 'roll_count')
  rownames(stats_mtx) <- rownames(simd_mtx)
  
  stats_mtx[,1] <- schools_simd_mean
  stats_mtx[,2] <- schools_simd_sd
  stats_mtx[,3] <- df[['eal_percent']]
  stats_mtx[,4] <- df[['fsm_percent']]
  stats_mtx[,5] <- roll_percent_diff
  
  return (stats_mtx)
  
}

# Weighted Standard Deviation
#
# Calculate a weighted standard deviation. Helper function for 
# build_inputs
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

# Weighted Mean
#
# Calculate a weighted mean based on position. Helper for weighted_sd
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

