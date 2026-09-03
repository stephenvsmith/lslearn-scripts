### Make sure you have already installed the lslearn/CML package before running this file.

# Home directory where you have placed this repository, and the scratch
# directory where results will be placed. Set these directly below, or copy
# config/config.example.R to config/config.R and fill them in there.
home_dir <- NA
scratch_dir <- NA
if (file.exists("config/config.R")) source("config/config.R")

# File which generates the data
data_gen_file <- file.path(home_dir, "R/data_gen.R")
result_dir <- file.path(scratch_dir, paste0("ResultsSample-", format(Sys.Date(), "%m-%y")))
# Directory where bnlearn RDS files are stored
rds_dir <- file.path(home_dir, "networks/rds")

source(file.path(home_dir, "R/helperfunctions.R"))
source(file.path(home_dir, "run/initializekernel.R"))
