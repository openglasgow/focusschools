# focusschools

**focusschools** is a tool designed to help schools compare their performance to similar schools within Glasgow and the wider Glasgow City region. By analyzing data such as SIMD (Scottish Index of Multiple Deprivation), free school meal uptake, percentage of English as an additional language, and school roll size, the tool identifies and groups schools based on similarity. The comparison supports schools in benchmarking and improving their outcomes.

The tool has been expanded in 2024 to include the following local authorities: 

- East Dunbartonshire
- East Renfrewshire
- Glasgow
- Inverclyde
- North Lanarkshire
- Renfrewshire
- South Lanarkshire
- West Dunbartonshire.

Put simply it:

- Compares primary and secondary schools across multiple local authorities.
- Ranks similar schools using a custom distance calculation algorithm. See the section on **Similarity Calculations** below.
- Exports detailed comparison tables in both .xlsx and .csv formats with a specified number of comparison schools
- Generates within-local-authority and across-authority comparisons.

The outputs of this project are loaded into the FOCUS schools tool.

### Setup

The repository is hosted on the `openglasgow` GitHub account. The account is 
private so you will need to be added to it. Speak to either:

- Neil Currie - neil.currie@glasgow.gov.uk
- Guy Wells - guy.wells@glasgow.gov.uk
- Steven Livingstone-Perez - steven.livingstone-perez@glasgow.gov.uk

1. Clone the repository:

```
git clone https://github.com/openglasgow/focusschools.git
```

2. Place the input data files in the data directory adjacent to the project repository:

```
/path/focusschools/
   ├── data/
        ├── Glasgow_input.xlsx
        ├── North Lanarkshire_input.xlsx
        └── [Other Local Authority Data]
   ├── focusschools/
         ├── .gitignore
         ├── focusschools.Rproj
         ├── functions/
         ├── README.md         
         ├── run.R       
         └── [Other Project Files]
```

### Dependencies

The project will automatically install the required R packages if they are not already installed:
These packages will be installed and loaded automatically when running the main script.

### Usage

1. Open the `focusschools.Rproj` file in RStudio.
2. Open `run.R` and run the code.
3. The output files will be saved in the `output` folder within the project folder. If no folder exists one will be created. Output files are in both xlsx and csv format. Files will include:
- All LAs_primary-schools.xlsx
- All LAs_secondary-schools.xlsx
- [Local Authority]_primary-schools.xlsx
- [Local Authority]_secondary-schools.xlsx

### Input Data Requirements

Input data should be in .xlsx format and named in the following way:

- File naming convention: [Local Authority]_input.xlsx with a single sheet
- Each file is read in using readxl::read_excel
- File structure is checked using the `check_input_data` function. See this function for required variable names.

### Similarity Calculations

Similarity is calculated using the following metrics:

- School roll i.e. the number of pupils attending the school
- Free School Meals uptake percentage
- The percentage of pupils for whom English is an additional language
- SIMD

For the school roll, I calculate the mean school roll and change this variable to be the percentage difference from the mean school roll.

SIMD is slightly more involved and is split into 2 measures:

- The mean SIMD
- The standard deviation in SIMD

The mean SIMD is calculated using a weighted mean. The count and percentage of pupils living in SIMD areas 1 to 10 is contained in the input data. As an example, to calculate the mean SIMD for a random school you would do the following:

```
Mean SIMD = (1 * simd_1%) + (2 * simd_1%) + ... + (10 * simd_10%)
```

However, just using the mean can hide inequality in a school catchment area. The old methodology used a custom variance measure. I changed this to standard deviation because I think it is a better statistical approach since standard deviations have the same units as the original data. Variance is the square of the standard deviation. Therefore, for this use, I think it could over inflated differences. It is broadly the same principle though, it is still a measure of dispersion.

When all the input data is sorted the distance between each school and every other school is calculated in a similar way to an error measure in a stats model. This is done in `calc_distances` function. 

A star rating system is applied which displays the closeness of the match. 3 starts indicates a very good match, 2 a less good match and 1 a not so good match. This was a feature of the original tool. I updated it to be done in a more automated way as the thresholds for the stars seemed to be hardcoded before.

For some local authorities they have few schools. Therefore, fewer within-local authority comparisons can be made. Therefore, the number of comparisons generated for each school is adjusted up to a maximum of 10 schools.
