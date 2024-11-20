
# Calculate Distances
#
# Calculate distances between schools 
#
# Args:
#
# school_inputs:   school inputs matrix
# num_to_compare: number of schools to have for comparison

calc_distances <- function (school_inputs, num_to_compare) {
  
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
  
  comparison_table <- map2_dfr(store_distances, 
                               rownames(school_inputs), 
                               build_comparison_tables,
                               average_distance =  mean(unlist(store_distances)),
                               num_to_compare = num_to_compare)
  
  return (comparison_table)
  
}

# Build Comparison Tables
#
# Build a comparison table for schools - helper for calc_distances
#
# Args:
#
# distances:        distance matrix
# school:           name of the school to build table for
# average_distance: mean distance between schools for deciding star rating of 
#                   match
# num_to_compare:  number of schools to compare

build_comparison_tables <- function (distances, school, average_distance,
                                     num_to_compare) {
  
  distances <- distances[1:num_to_compare]
  
  half_average_distance <- average_distance * 0.5
  
  comparison_table <- tibble(school_id = school,
                             comparison_school_id = names(distances), 
                             distance = distances) %>% 
    mutate(
      star_rating = case_when(distance <= half_average_distance ~ '***',
                              distance <= average_distance ~ '**',
                              TRUE ~ '*')
    )
  
  return (comparison_table)
  
}

