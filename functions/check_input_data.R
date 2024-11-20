
# Check Input Data
#
# Check the schools data has the expected structure
#
# df: data frame of schools data

check_input_data <- function (df) {
  
  if (!is.data.frame(df)) stop ('df must be a data frame or tibble')
  
  exp_num_cols <- 30
  exp_col_names <- c("Seed Code", 
                     "School name",
                     "Sector",
                     "School roll",
                     "FSM #",
                     "FSM %",
                     "EAL #",
                     "EAL %",
                     "# SIMD decile 1",  
                     "% SIMD decile 1",  
                     "# SIMD decile 2",  
                     "% SIMD decile 2",  
                     "# SIMD decile 3",  
                     "% SIMD decile 3",  
                     "# SIMD decile 4",  
                     "% SIMD decile 4", 
                     "# SIMD decile 5",  
                     "% SIMD decile 5", 
                     "# SIMD decile 6",  
                     "% SIMD decile 6",  
                     "# SIMD decile 7",  
                     "% SIMD decile 7",  
                     "# SIMD decile 8",  
                     "% SIMD decile 8", 
                     "# SIMD decile 9",
                     "% SIMD decile 9",  
                     "# SIMD decile 10", 
                     "% SIMD decile 10", 
                     "# SIMD not known", 
                     "% SIMD not known", 
                     "Seed Code")  
  
  if (ncol(df) != exp_num_cols) {
    
    stop(paste('df has', ncol(df), 'columns, expected', exp_num_cols))
    
  }
  
  col_names <- colnames(df)
  
  bad_col_names <- col_names[!(col_names %in% exp_col_names)]
  
  if (length(bad_col_names) > 0) {
    
    stop_message <- paste('df has unexpected column names:', 
                          paste(bad_col_names, collapse = ','),
                          '\nexpected:', 
                          paste(col_names, collapse = ','))
    
    stop(stop_message)
    
  }
  
  if (nrow(df) == 0) stop ('df has 0 rows')
  
  return(invisible(df))
  
}