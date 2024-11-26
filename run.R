
# Setup ------------------------------------------------------------------------

message('---> Setting things up')

# Load packages

suppressPackageStartupMessages({
  
  library(here)
  library(openxlsx)
  library(dplyr)
  library(stringr)
  library(purrr)
  library(readr)
  library(stringdist)
  library(janitor)
  library(readxl)
  
})

# Setup paths for easy access

dirs <- list() 

dirs$working_dir <- here()

project_name <- dirs$working_dir |> 
  list.files(pattern = '.Rproj') |> 
  str_replace('.Rproj', '')

# Find data path based on project name

working_dir_split <- dirs$working_dir |> str_split('/') |> unlist()
master_dir_pos <- which(working_dir_split == project_name)[1]
dirs$master_dir <- paste(working_dir_split[1:master_dir_pos], collapse = '/')

dirs$data <- file.path(dirs$master_dir, 'data')

dirs$functions <- file.path(dirs$working_dir, 'functions')
dirs$output <- file.path(dirs$master_dir, 'output')

if (!dir.exists(dirs$output)) { 
  
  message('---> Created output folder ', dirs$output)
  
  dir.create(dirs$output)

}
  
# Read in custom functions

function_files <- list.files(dirs$functions, full.names = TRUE, pattern = '.R')

walk(function_files, source)

function_files_short <- list.files(dirs$functions, pattern = '.R')

message('---> Loaded custom function files: ', 
        paste(function_files_short, collapse = ', '))

# Data prep --------------------------------------------------------------------

message('---> Preparing the data')

# If you have an Excel file open on a Mac a temporary copy is saved in the same
# folder with this prefix: '~$'. The str_subset line drops this out.

files <- list.files(dirs$data, pattern = '_input.xlsx', 
                    full.names = TRUE) |> 
  str_subset('\\~\\$', negate = TRUE)

la_names <- dirs$data |> 
  list.files(pattern = '_input.xlsx') |> 
  str_subset('\\~\\$', negate = TRUE) |> 
  str_replace('_input.xlsx', '')

schools_data <- files |> 
  map(read_excel) |> 
  map(check_input_data) |> 
  map2_dfr(la_names, 
           ~mutate(.x, 
                   local_authority = .y,
                   `Seed Code` = as.character(`Seed Code`))) |>
  as_tibble() |> 
  clean_names() |> 
  select(-contains('not_known')) |> 
  mutate(across(c(sector, seed_code, school_name), str_trim)) |> 
  mutate(school_id = paste0(local_authority, '_', sector, '_', seed_code))

primary_data <- filter(schools_data, sector == 'Primary')
secondary_data <- filter(schools_data, sector == 'Secondary')

# Specify number of comparisons ------------------------------------------------

num_comparisons_primary_overall <- 10
num_comparisons_secondary_overall <- 10
num_comparisons_primary_la <- 10
num_comparisons_secondary_la <- 5

# Overall comparison -----------------------------------------------------------

message('---> Processing for all schools')

# Primaries

primary_inputs <- build_inputs(primary_data)
primary_tables <- calc_distances(primary_inputs, 
                                 num_comparisons_primary_overall)

primary_output <- format_tables(primary_tables, primary_data)

file_primary_output_xlsx <- file.path(dirs$output, 
                                 'All LAs_primary-schools.xlsx')

file_primary_output_csv <- str_replace(file_primary_output_xlsx,
                                       '.xlsx', '.csv')

write.xlsx(primary_output, file_primary_output_xlsx)
write_csv(primary_output, file_primary_output_csv, progress = FALSE)

# Secondaries

secondary_inputs <- build_inputs(secondary_data)
secondary_tables <- calc_distances(secondary_inputs, 
                                   num_comparisons_secondary_overall)

secondary_output <- format_tables(secondary_tables, secondary_data)

file_secondary_output_xlsx <- file.path(dirs$output, 
                                   'All LAs_secondary-schools.xlsx')

file_secondary_output_csv <- str_replace(file_secondary_output_xlsx,
                                         '.xlsx', '.csv')

write.xlsx(secondary_output, file_secondary_output_xlsx)
write_csv(secondary_output, file_secondary_output_csv, progress = FALSE)

# Within LA comparison ---------------------------------------------------------

message('---> Processing for individual local authorities')

num_las <- length(la_names)

primary_output_la <- vector('list', length = num_las)
secondary_output_la <- vector('list', length = num_las)

names(primary_output_la) <- la_names
names(secondary_output_la) <- la_names

for (i in 1:num_las) {

  # Primary Schools
  
  primary_data_la <- filter(primary_data, 
                            local_authority == la_names[i])

  primary_inputs_la <- build_inputs(primary_data_la)

  primary_tables_la <- calc_distances(primary_inputs_la,
                                      num_comparisons_primary_la)

  primary_output_la[[i]] <- format_tables(primary_tables_la, primary_data_la)

  file_primary_output_la_xlsx <- file.path(
    dirs$output,
    paste0(la_names[i], '_primary-schools.xlsx')
    )

  file_secondary_output_la_csv <- str_replace(file_primary_output_la_xlsx,
                                              '.xlsx', '.csv')

  write.xlsx(primary_output_la[[i]], file_primary_output_la_xlsx)
  write_csv(primary_output_la[[i]], file_secondary_output_la_csv,
            progress = FALSE)

  # Secondary Schools
  
  secondary_data_la <- filter(secondary_data, 
                              local_authority == la_names[i])
  
  secondary_inputs_la <- build_inputs(secondary_data_la)

  secondary_tables_la <- calc_distances(secondary_inputs_la,
                                        num_comparisons_secondary_la)

  secondary_output_la[[i]] <- format_tables(secondary_tables_la,
                                            secondary_data_la)

  file_secondary_output_la_xlsx <- file.path(
    dirs$output,
    paste0(la_names[i], '_secondary-schools.xlsx')
  )

  file_secondary_output_la_csv <- str_replace(file_secondary_output_la_xlsx,
                                              '.xlsx', '.csv')

  write.xlsx(secondary_output_la[[i]], file_secondary_output_la_xlsx)
  write_csv(secondary_output_la[[i]], file_secondary_output_la_csv,
            progress = FALSE)
  
}

message('---> Finished')
