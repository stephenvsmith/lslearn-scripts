### Hoffman2 entry point: runs one simulation setting for a single SGE array
### task. Invoked by hoffman/submit/submit_array.sh, which passes the SGE
### task id and the repository directory as arguments.
###
### Usage: Rscript hoffman/run_array.R <array_num> <repo_dir>

args <- commandArgs(trailingOnly = TRUE)
array_num <- as.integer(args[1])
home_dir <- args[2]
scratch_dir <- Sys.getenv("SCRATCH", unset = home_dir)

result_dir <- file.path(scratch_dir, paste0("ResultsSample-", format(Sys.Date(), "%m-%y")))
rds_dir <- file.path(home_dir, "networks/rds")
data_gen_file <- file.path(home_dir, "R/data_gen.R")

source(file.path(home_dir, "R/helperfunctions.R"))
setwd(scratch_dir)

source(file.path(home_dir, "run/arraykernel.R"))
