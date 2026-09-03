### Timing
start <- Sys.time()

### Directories (match with initialize.R)
home_dir <- NA
scratch_dir <- NA
if (file.exists("config/config.R")) source("config/config.R")

result_dir <- file.path(scratch_dir, paste0("ResultsSample-", format(Sys.Date(), "%m-%y")))
rds_dir <- file.path(home_dir, "networks/rds")
data_gen_file <- file.path(home_dir, "R/data_gen.R")

### Setup
source(file.path(home_dir, "R/helperfunctions.R"))
# This file is set up to run one setting at a time, so you can vary the array_number
# Each setting is defined in the file "sim_vals.csv" in result_dir, and the array_number corresponds
# to the row in this file.
array_num <- 1
setwd(scratch_dir)

source(file.path(home_dir, "run/arraykernel.R"))
