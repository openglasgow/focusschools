
# Setup ------------------------------------------------------------------------

# Load packages - you may need to install first, run scripts/install-packages.R
# first if that is the case. You will only need to run that script once per 
# machine.

library(here)      # To find what folder your project lives in
library(openxlsx)  # For working with excel docs
library(dplyr)     # To manipulate data frames
library(tidyr)     # Handy tidying functions
library(stringr)   # For working with strings

# Setup paths for easy access (working directory = wd)

wd <- list() 

wd$wd <- here::here()
wd$data <- file.path(wd$wd, 'data')
wd$scripts <- file.path(wd$wd, 'scripts')
wd$output <- file.path(wd$wd, 'output')

# Read in custom functions

source(file.path(wd$scripts, 'functions.R'))

# Data prep --------------------------------------------------------------------

file <- file.path(wd$data, 'FOCUS comparator data Nov 2023.xlsx')

# The format of the column names in the data is not ideal for coding but great 
# for a human - its over 2 lines. Let's sort them first.

schools_data <- openxlsx::read.xlsx(file, colNames = FALSE)
schools_data <- 

cols1 <- unname(unlist(schools_data[1, ]))
cols2 <- unname(unlist(schools_data[2, ]))

col_names <- tidyr::fill(tibble(cols1, cols2), cols1) %>% 
  dplyr::mutate(col_name = paste(cols1, cols2)) %>% 
  pull(col_name) %>% 
  stringr::str_replace('NA ', '') %>% 
  stringr::str_replace_all('\\(|\\)', '') %>% 
  str_replace_all(' ', '_') %>% 
  str_replace_all('#', 'count') %>% 
  str_replace_all('%', 'percent') %>% 
  tolower()
  
# Now read back in, convert to a tibble and set the well formatted column names

schools_data <- file %>% 
  read.xlsx(colNames = FALSE, startRow = 3) %>% 
  tidyr::as_tibble() 

colnames(schools_data) <- col_names

schools_data <- select(schools_data, -contains('not_known'))

primary_data <- dplyr::filter(schools_data, sector == 'Primary')
secondary_data <- filter(schools_data, sector == 'Secondary')

# Format the inputs into primary and secondary school matrices -----------------

primary_inputs <- calc_compartor_inputs(primary_data)
secondary_inputs <- calc_compartor_inputs(secondary_data)
