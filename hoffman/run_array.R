### Hoffman2 entry point: runs one simulation setting for a single SGE array
### task. Invoked by hoffman/submit/submit_array.sh, which passes the SGE
### task id and the repository directory as arguments.
###
### Usage: Rscript hoffman/run_array.R <array_num> <repo_dir>

args <- commandArgs(trailingOnly = TRUE)
array_num <- as.integer(args[1])
home_dir <- args[2]
scratch_dir <- Sys.getenv("SCRATCH", unset = home_dir)

# LSLEARN_RESULTS_NAME (set in hoffman/submit/submit_array.sh) fixes the
# results directory for the whole run. The date-based fallback changes at
# each month boundary, which would strand a run that spans two months.
result_dir <- file.path(scratch_dir, Sys.getenv("LSLEARN_RESULTS_NAME",
                                                paste0("ResultsSample-", format(Sys.Date(), "%m-%y"))))
if (!file.exists(file.path(result_dir, "sim_vals.csv"))) {
  stop("No sim_vals.csv in ", result_dir, ". Run run/initialize.R with the same ",
       "LSLEARN_RESULTS_NAME first.")
}
rds_dir <- file.path(home_dir, "networks/rds")
data_gen_file <- file.path(home_dir, "R/data_gen.R")

source(file.path(home_dir, "R/helperfunctions.R"))
setwd(scratch_dir)

source(file.path(home_dir, "run/arraykernel.R"))
