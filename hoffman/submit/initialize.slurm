#!/bin/bash
### Runs the smoke test, then run/initialize.R, as a batch job, and backs up
### the run definition (sim_vals.csv and the target pools) to $HOME, since
### $SCRATCH is purged after 14 days. Submit from the repository root,
### optionally after the R library build finishes:
###   sbatch [--dependency=afterok:<build job id>] hoffman/submit/initialize.slurm
#SBATCH --job-name=lslearn-init
#SBATCH --account=pi_qingzhou
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --output=logs/init.%j

set -e
module purge
module load R/4.4.1

REPO_DIR="${HOME}/lslearn-scripts"
export LSLEARN_RESULTS_NAME="${LSLEARN_RESULTS_NAME:-ResultsFullTargets}"
RESULTS="${SCRATCH}/${LSLEARN_RESULTS_NAME}"

cd "${REPO_DIR}"
Rscript hoffman/smoketest.R
Rscript run/initialize.R

# initialize.R writes under config/config.R's scratch_dir; the array jobs
# read from $SCRATCH. Fail here, not in 351 tasks, if those differ.
test -f "${RESULTS}/sim_vals.csv" || { echo "No sim_vals.csv in ${RESULTS}; check scratch_dir in config/config.R"; exit 1; }

BACKUP="${HOME}/${LSLEARN_RESULTS_NAME}-backup"
mkdir -p "${BACKUP}"
cp "${RESULTS}"/sim_vals.csv "${RESULTS}"/targets_*.rds "${BACKUP}/"
echo "Initialized ${RESULTS}: $(ls "${RESULTS}"/targets_*.rds | wc -l) target files; backed up to ${BACKUP}"
