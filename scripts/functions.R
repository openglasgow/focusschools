
calc_compartor_inputs <- function (schools_data) {
  
  # Extract the GIMD stats into a matrix
  
  gimd_mtx <- schools_data %>% 
    dplyr::select(dplyr::starts_with('gimd')) %>% 
    select(ends_with('_percent')) %>% 
    as.matrix()
  
  colnames(gimd_mtx) <- 1:10
  rownames(gimd_mtx) <- schools_data[['school_name']]
  
  # Some are slightly off summing to 1 due to minor rounding issues, this fixes
  # that
  
  gimd_mtx <- gimd_mtx / rowSums(gimd_mtx)
  
  schools_gimd_mean <- rowSums(gimd_mtx * 1:10)
  
  # The original methodology used variance but I think this is not optimal. 
  # Variance tells you the mean square difference in the data points but standard
  # deviation just tells you the mean difference. If you think about it, variance
  # will make larger numbers even larger
  
  schools_gimd_sd <- apply(gimd_mtx, MARGIN = 1, sd)
  
  mean_roll <- mean(schools_data[['school_roll_census_2023']])
  roll_diff_from_mean <- schools_data[['school_roll_census_2023']] - mean_roll
  roll_percent_diff <- roll_diff_from_mean / mean_roll
  
  stats_mtx <- matrix(NA, ncol = 5, nrow = nrow(gimd_mtx))
  colnames(stats_mtx) <- c('gimd_mean', 'gimd_sd', 'eal', 'fsm', 'roll_count')
  rownames(stats_mtx) <- rownames(gimd_mtx)
  
  stats_mtx[,1] <- schools_gimd_mean
  stats_mtx[,2] <- schools_gimd_sd
  stats_mtx[,3] <- schools_data[['eal_percent']]
  stats_mtx[,4] <- schools_data[['fsm_percent']]
  stats_mtx[,5] <- roll_percent_diff
  
  return (stats_mtx)
  
}
