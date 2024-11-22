# focusschools

This code was created by Neil Currie (neil.currie@glasgow.gov.uk | neil.george.currie@gmail.com) with thanks to Guy Wells for providing QA.

## Purpose of the FOCUS schools tool

FOCUS is a web tool that helps schools compare pupil achievement with other, *similar* schools. It uses data like English as an Additional Language (EAL), deprivation (SIMD), free meal uptake and school roll size. The goal is to avoid unfair comparisons, like between schools in very rich and very poor areas, and instead focus on schools with similar challenges. Schools then form networks of their peer schools, and can then share ideas and best practice and improve results together.

https://www.ceg.org.uk/focus.shtml


## Purpose of this repo

In 2024, the data team were approached to review the methodology and re-run the comparisons for Glasgow. The comparison file will then be loaded into the FOCUS tool. We were then asked to expand the tool to include all schools in the Glasgow City Region. This repo stores the code, methods, and documents for the project, making it easy to update and collaborate on in the future.

In the November 2024 run, this repo included the following local authorities: 

- East Dunbartonshire
- East Renfrewshire
- Glasgow
- Inverclyde
- North Lanarkshire
- Renfrewshire
- South Lanarkshire
- West Dunbartonshire

However, it could easily be expanded to other local authorities by simply adding xlsx to the data folder in the same format (more on that later).

Put simply it:

- Compares primary and secondary schools across multiple local authorities.
- Ranks similar schools using a custom distance calculation algorithm. See the section on **Similarity Calculations** below.
- Exports detailed comparison tables in both .xlsx and .csv formats with a specified number of comparison schools
- Generates within-local-authority and across-authority comparisons.

The outputs of this project are loaded into the FOCUS schools tool.

### Setup

The repository is hosted on the `openglasgow` GitHub account and is publicly available.

1. Clone the repository:

From the terminal, navigate to the folder where you would like to host the 
project and create a folder called `focusschools`. You then want to navigate to
this new folder. 

For me this looks like:

```
cd Developer
mkdir focusschools
cd focusschools
```

Now you want to clone the git repo into here.

```
git clone https://github.com/openglasgow/focusschools.git
```

2. Setup your data folder and files

Create a folder for your data files to be stored in. This should be adjacent to 
the repo you cloned, so, from same folder, in my case that would be 
`/Developer/focusschools/`. If you've just cloned the repo you are already here.

You can do it manually or from the terminal. Run:

```
mkdir data
```

Now add in your data files. You'll end up with a structure like the below.

```
/Developer/focusschools/
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

The project will automatically install the required R packages if they are not 
already installed when you trigger the `run.R` file.

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
