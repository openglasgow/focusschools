
# Setup ------------------------------------------------------------------------

# Load packages - you may need to install first, run scripts/install-packages.R
# first if that is the case. You will only need to run that script once per 
# machine.

library(here)       # To find what folder your project lives in
library(openxlsx)   # For working with excel docs
library(dplyr)      # To manipulate data frames
library(tidyr)      # Handy tidying functions
library(stringr)    # For working with strings
library(purrr)      # Mapping
library(readr)      # Reading and writing data
library(stringdist) # String distance calcs for fuzzy matching

# Setup paths for easy access (working directory = wd)

wd <- list() 

wd$wd <- here()
wd$data <- file.path(wd$wd, 'data')
wd$scripts <- file.path(wd$wd, 'scripts')
wd$output <- file.path(wd$wd, 'output')

# Read in custom functions

source(file.path(wd$scripts, 'functions.R'))

# Data prep --------------------------------------------------------------------

file_schools_data <- file.path(wd$data, 'FOCUS comparator data Nov 2023.xlsx')

# The format of the column names in the data is not ideal for coding but great 
# for a human - its over 2 lines. Let's sort them first.

schools_data <- read.xlsx(file_schools_data, colNames = FALSE)

cols1 <- unname(unlist(schools_data[1, ]))
cols2 <- unname(unlist(schools_data[2, ]))

col_names <- tidyr::fill(tibble(cols1, cols2), cols1) %>% 
  dplyr::mutate(col_name = paste(cols1, cols2)) %>% 
  pull(col_name) %>% 
  str_replace('NA ', '') %>% 
  str_replace_all('\\(|\\)', '') %>% 
  str_replace_all(' ', '_') %>% 
  str_replace_all('#', 'count') %>% 
  str_replace_all('%', 'percent') %>% 
  tolower()
  
# Now read back in, convert to a tibble and set the well formatted column names

schools_data <- file_schools_data %>% 
  read.xlsx(colNames = FALSE, startRow = 3) %>% 
  as_tibble() 

colnames(schools_data) <- col_names

schools_data <- select(schools_data, -contains('not_known'))

primary_data <- filter(schools_data, sector == 'Primary')
secondary_data <- filter(schools_data, sector == 'Secondary')

# Calculations -----------------------------------------------------------------

primary_comparator_inputs <- calc_compartor_inputs(primary_data)
primary_tables <- calc_distances(primary_comparator_inputs, 10)

secondary_comparator_inputs <- calc_compartor_inputs(secondary_data)
secondary_tables <- calc_distances(secondary_comparator_inputs, 5)

# Primary schools - bring in previous data -------------------------------------

file_schools_data_prev <- file.path(wd$data, 'Primary Schools Previous.xlsx')

# The format of the column names in the data is not ideal for coding but great 
# for a human - its over 2 lines. Let's sort them first.

primary_tables_prev <- read.xlsx(file_schools_data_prev, colNames = FALSE, 
                               sheet = 'Ten Comparators') %>% 
  as_tibble() %>% 
  fill('X1', .direction = 'down') %>% 
  filter(!is.na(X2), !is.na(X4), X4 != 'Level') %>% 
  mutate(across(everything(), .fns = str_trim)) %>% 
  mutate(X3 = as.numeric(X3),
         X2 = str_replace_all(X2, 'St.', 'St'))

colnames(primary_tables_prev) <- c('school', 'comparison_school', 'distance', 
                                   'star_rating')

schools_new <-  primary_tables[, c('school', 'comparison_school')] %>% 
  unlist(use.names = FALSE) %>% 
  unique()

schools_prev <- primary_tables_prev[, c('school', 'comparison_school')] %>% 
  unlist(use.names = FALSE) %>% 
  unique()

# Primary schools - fuzzy match the names --------------------------------------

# There are spelling differnces etc between the school names. Some are genuinely
# new schools, some schools have closed but some are just spelled differently

distance_matrix <- stringdistmatrix(schools_prev, schools_new,  method = "jw") 

# I played about with the threshold - lower score is better. I set it 
# ridiculously high so every single name would get a match.

threshold <- 0.9  

matches <- apply(distance_matrix, 2, function(x) {
  
  if (min(x) < threshold) {
    
    return(which.min(x))
    
  } else {
    
    return(NA)
    
  }
  
})

match_scores <- sapply(1:length(matches), function(i) {
  
  if (!is.na(matches[i])) {
    
    return(distance_matrix[matches[i], i])
    
  } else {
    
    return(NA)
    
  }
  
})

matched_schools <- tibble(ids = 1:length(schools_new),
                          new = schools_new,
                          old = schools_prev[matches],
                          score = match_scores)

fuzzy_matched_schools <- matched_schools %>% 
  filter(score > 0) %>% 
  arrange(score) %>% 
  mutate(old_checked = old)

# Primary schools - manual check -----------------------------------------------

# Output the schools which didnt have an exact match and do a check on them.
# Copy the file and change the 'pre' part of the filename to 'post'. Save in
# the same folder. Check the school name in the old column. If it is correct
# leave it in the old_checked column. If it is wrong you should either replace
# it with the correct one or make it blank if no match can be found.

file_fuzzy <- file.path(wd$output, 'primary-fuzzy-pre-check.csv')

write_csv(fuzzy_matched_schools, file_fuzzy)

file_fuzzy_post <- file.path(wd$output, 'primary-fuzzy-post-check.csv')

fuzzy_post <- read_csv(file_fuzzy_post, show_col_types = FALSE)

# Primary schools - determine new and existing ---------------------------------

# Read in the checked file and drop all the columns we don't need plus the 
# missing school names

school_name_lookup_nas <- fuzzy_post %>% 
  select(ids, old_checked) %>% 
  mutate(fuzzy = TRUE) %>% 
  left_join(matched_schools, ., by = 'ids') %>% 
  mutate(fuzzy = if_else(is.na(fuzzy), FALSE, fuzzy),
         old = if_else(fuzzy, old_checked, old)) %>% 
  select(-ids, -score, -old_checked, -fuzzy)

school_name_lookup <- filter(school_name_lookup_nas, !is.na(old))

# In the previous table, replace the old names with the new names

primary_tables_prev <- primary_tables_prev %>% 
  left_join(school_name_lookup, by = c('school' = 'old')) %>% 
  mutate(school = if_else(is.na(new), school, new)) %>% 
  select(-new) %>% 
  left_join(school_name_lookup, by = c('comparison_school' = 'old')) %>% 
  mutate(comparison_school = if_else(is.na(new), comparison_school, new)) %>% 
  select(-new) 

# Create the final primary tables ----------------------------------------------

primary_tables <- primary_tables$school %>% 
  unique() %>% 
  map_dfr(compare_prev, tables_new = primary_tables, 
          tables_prev = primary_tables_prev) 

# Secondary schools - bring in previous data -----------------------------------

file_schools_data_prev <- file.path(wd$data, 'Secondary Schools Previous.xlsx')

# The format of the column names in the data is not ideal for coding but great 
# for a human - its over 2 lines. Let's sort them first.

secondary_tables_prev <- read.xlsx(file_schools_data_prev, colNames = FALSE, 
                                 sheet = 'Five Comparators') %>% 
  as_tibble() %>% 
  fill('X1', .direction = 'down') %>% 
  filter(!is.na(X2), !is.na(X4), X4 != 'Level') %>% 
  mutate(across(everything(), .fns = str_trim)) %>% 
  mutate(X3 = as.numeric(X3),
         X2 = str_replace_all(X2, 'St.', 'St'))

colnames(secondary_tables_prev) <- c('school', 'comparison_school', 'distance', 
                                   'star_rating')

schools_new <-  secondary_tables[, c('school', 'comparison_school')] %>% 
  unlist(use.names = FALSE) %>% 
  unique()

schools_prev <- secondary_tables_prev[, c('school', 'comparison_school')] %>% 
  unlist(use.names = FALSE) %>% 
  unique()

# Secondary schools - fuzzy match the names ------------------------------------

# There are spelling differnces etc between the school names. Some are genuinely
# new schools, some schools have closed but some are just spelled differently

distance_matrix <- stringdistmatrix(schools_prev, schools_new,  method = "jw") 

# I played about with the threshold - lower score is better. I set it 
# ridiculously high so every single name would get a match.

threshold <- 0.9  

matches <- apply(distance_matrix, 2, function(x) {
  
  if (min(x) < threshold) {
    
    return(which.min(x))
    
  } else {
    
    return(NA)
    
  }
  
})

match_scores <- sapply(1:length(matches), function(i) {
  
  if (!is.na(matches[i])) {
    
    return(distance_matrix[matches[i], i])
    
  } else {
    
    return(NA)
    
  }
  
})

matched_schools <- tibble(ids = 1:length(schools_new),
                          new = schools_new,
                          old = schools_prev[matches],
                          score = match_scores)

fuzzy_matched_schools <- matched_schools %>% 
  filter(score > 0) %>% 
  arrange(score) %>% 
  mutate(old_checked = old)

# Secondary schools - manual check ---------------------------------------------

# Output the schools which didnt have an exact match and do a check on them.
# Copy the file and change the 'pre' part of the filename to 'post'. Save in
# the same folder. Check the school name in the old column. If it is correct
# leave it in the old_checked column. If it is wrong you should either replace
# it with the correct one or make it blank if no match can be found.

file_fuzzy <- file.path(wd$output, 'secondary-fuzzy-pre-check.csv')

write_csv(fuzzy_matched_schools, file_fuzzy)

file_fuzzy_post <- file.path(wd$output, 'secondary-fuzzy-post-check.csv')

fuzzy_post <- read_csv(file_fuzzy_post, show_col_types = FALSE)

# Secondary schools - determine new and existing -------------------------------

# Read in the checked file and drop all the columns we don't need plus the 
# missing school names

school_name_lookup_nas <- fuzzy_post %>% 
  select(ids, old_checked) %>% 
  mutate(fuzzy = TRUE) %>% 
  left_join(matched_schools, ., by = 'ids') %>% 
  mutate(fuzzy = if_else(is.na(fuzzy), FALSE, fuzzy),
         old = if_else(fuzzy, old_checked, old)) %>% 
  select(-ids, -score, -old_checked, -fuzzy)

school_name_lookup <- filter(school_name_lookup_nas, !is.na(old))

# In the previous table, replace the old names with the new names

secondary_tables_prev <- secondary_tables_prev %>% 
  left_join(school_name_lookup, by = c('school' = 'old')) %>% 
  mutate(school = if_else(is.na(new), school, new)) %>% 
  select(-new) %>% 
  left_join(school_name_lookup, by = c('comparison_school' = 'old')) %>% 
  mutate(comparison_school = if_else(is.na(new), comparison_school, new)) %>% 
  select(-new) 

# Create the final secondary tables --------------------------------------------

secondary_tables <- secondary_tables$school %>% 
  unique() %>% 
  map_dfr(compare_prev, tables_new = secondary_tables, 
          tables_prev = secondary_tables_prev) 


# Output -----------------------------------------------------------------------

file_output <- file.path(wd$output, 'schools-with-comparators.xlsx')

output <- list(primary = primary_tables, secondary = secondary_tables)

write.xlsx(output, file_output)

