# FOCUS Schools Tool

The FOCUS tool is used by schools to compare themselves to other, similar schools. Similarity is scored in a variety of ways. This repo processes the data which goes into the tool.

More information on the FOCUS tool can be found in the following places:

* https://glasgow.gov.uk/index.aspx?articleid=23801
* https://glasgow.gov.uk/index.aspx?articleid=23800

## User Guide

This section instructs you how to re-run the code, either with new data or the same data used previously, without getting too far into the weeds of the technical details.

### Folder Overview

## Technical Guide

This section goes into more technical details about the project and code. 

I have written the code in such a way that (I hope) it is understandable and usable for beginners to R. If you already know R you might find my documentation and comments in my code to be overkill but given there are only a few of us in GCC that know R I think my approach is the right one.

### GitHub

### Packages

In `scripts/install-packges.R` you will find a script that installs packages used in this script to your machine. You will only need to run this once per machine - they are now installed on your machine and can be called using `library(packagename)`. 

Packages change over time, it may be that some small aspect of the code errors and no longer works. To avoid this there is a practice known as dependency control but, to be honest, for small analyses like this, and for beginners, I think it causes more confusion and chaos than it saves. You'll just need to problem solve but I don't envisage this being a major issue.

### functions.R

### run.R

This is the main script that does everything. 

### Coding Style

#### Style Guide

I pretty much follow the tidyverse style guide which you can find here:

https://style.tidyverse.org/

#### Pipes

In this code you will find pipes %>%, you can look them up. They make coding with R great. The pipe used in this code is the pipe from the magrittr package. This is where the pipe in R first appeared. Because of it's wildly success they build pipes into base R. 

Given you will be running this in the future it is likely you might be more familiar with the base R pipe |>. If this confuses you look it up, it may be that you hardly see the old pipes anywhere and didn't even know they were a thing.

#### Calling Functions from Packages

I have adopted the convention of loading all the packages I use at the top of the script with `library(packagename)` calls.

This means the functions within that package can be simply called using the following syntax: `function_name(arguments, ...)`. 

To make it clear which function is from which package, the first time I use a function from package I use the following syntax `packagename::function_name(arguments, ...)` then default to the prior syntax. Hopefully that helps you understand the code a bit more.












