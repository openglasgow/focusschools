
# Format Tables
#
# Final formatting for output data
#
# Args:
# 
# distance_tables: output of calc_distances
# schools_data: original input schools data either for all schools or a single
#               local authority

format_tables <- function (distance_table, schools_data) {
  
  distance_table |> 
    left_join(select(schools_data, school_id, school_name), by = 'school_id') |> 
    relocate(school_name, .before = comparison_school_id) |> 
    left_join(select(schools_data, school_id, school_name), 
              by = c('comparison_school_id' = 'school_id')) |> 
    rename(school_name = school_name.x, 
           comparison_school_name = school_name.y)
  
}
