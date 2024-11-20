
# Calculate Number of Comparisons
#
# Returns the number of schools to compare based on the number of input schools
#
# Args:
#
# num_schools: number of schools overall

calc_num_comparisons <- function (num_schools) {
  
  if (num_schools < 8) {
    
    num_comparisons <- 3
    
  } else if (num_schools < 40) {
    
    num_comparisons <- 5
    
  } else {
    
    num_comparisons <- 10
    
  } 
  
  if (num_schools < num_comparisons) {
    
    num_comparisons <- num_schools
    
  }
  
  
  return (num_comparisons)
  
}