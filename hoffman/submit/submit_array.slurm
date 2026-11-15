#!/bin/bash
### Slurm array job for the simulation study (Hoffman2's Rocky Linux 9 /
### Slurm cluster, Nov 2026 onward). submit_array.sh is the Grid Engine
### version for the legacy cluster.
###
### Before submitting:
###   1. Check --account below (pi_<PI's username>; see `sacctmgr show assoc user=$USER`).
###   2. Check R_MODULE below is the module your R library was built with.
###   3. Run run/initialize.R with the same LSLEARN_RESULTS_NAME.
###   4. mkdir -p logs   (Slurm won't create the --output directory; tasks
###      fail immediately without it)
### Submit from the repository root:
###   sbatch hoffman/submit/submit_array.slurm
#SBATCH --job-name=lslearn
#SBATCH --account=pi_qingzhou
## highp runs on the group's own nodes (up to 14 days). Comment it out to
## use shared nodes instead, and lower --time to 24:00:00 or less.
#SBATCH --qos=highp
#SBATCH --time=7-00:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=2G
## Number of tasks should match the number of rows in sim_vals.csv (351 for
## the full grid in run/initializekernel.R)
#SBATCH --array=1-351
#SBATCH --output=logs/joblog.%A_%a
## #SBATCH lines don't expand variables, so write the address out in full.
##SBATCH --mail-user=CHANGEME@mail
##SBATCH --mail-type=END,FAIL

R_MODULE="R/4.4.1"

echo "Job ${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} started on: $(hostname -s) $(date)"

# The login shell loads an Intel compiler module that conflicts with R's
# dependencies, so start clean.
module purge
module load "${R_MODULE}"

# The R module sets R_LIBS_USER to a library for this exact build
# (~/R/4.4.1/gcc-11.4.1_intel-2024.1.0), separate from the legacy cluster's
# ~/R/library, whose compiled packages won't load on Rocky Linux 9.

REPO_DIR="${HOME}/lslearn-scripts"

# Results directory name under $SCRATCH. Must match the LSLEARN_RESULTS_NAME
# used when running run/initialize.R. Override per run with
#   sbatch --export=ALL,LSLEARN_RESULTS_NAME=<name> hoffman/submit/submit_array.slurm
export LSLEARN_RESULTS_NAME="${LSLEARN_RESULTS_NAME:-ResultsFullTargets}"
echo "Results directory: ${SCRATCH}/${LSLEARN_RESULTS_NAME}"

Rscript "${REPO_DIR}/hoffman/run_array.R" "${SLURM_ARRAY_TASK_ID}" "${REPO_DIR}"

echo "Job ${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} ended on: $(hostname -s) $(date)"
