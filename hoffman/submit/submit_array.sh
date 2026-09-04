#!/bin/bash
#$ -cwd
# error = Merged with joblog
#$ -o ./logs/joblog.$JOB_ID.$TASK_ID
#$ -j y
## Edit the line below as needed:
#$ -l h_rt=04:00:00,h_data=1G
## Modify the parallel environment and the number of cores as needed:
#$ -pe shared 1
# Email address to notify
#$ -M $USER@mail
## Number of tasks should match the number of rows in sim_vals.csv
#$ -t 1-100:1

# echo job info on joblog:
echo "Job $JOB_ID.$SGE_TASK_ID started on:   " $(hostname -s)
echo "Job $JOB_ID.$SGE_TASK_ID started on:   " $(date)
echo " "

# load the job environment:
# R/4.0.2 (the version these scripts previously used) is too old -- lslearn
# requires R >= 4.4. Confirm exact current module names/versions with
# `module av R`, `module av gcc`, and `module av gsl` before your first run;
# the versions below are placeholders. gsl is required to build/load
# lslearn's compiled code (RcppArmadillo).
. /u/local/Modules/default/init/modules.sh
module load R/4.4.0
module load gcc/11.3.0
module load gsl

# Code belongs in $HOME (persistent, backed up), not $SCRATCH (purged after
# 14 days) -- see hoffman/README.md.
REPO_DIR="${HOME}/lslearn-scripts"

echo "Rscript ${REPO_DIR}/hoffman/run_array.R ${SGE_TASK_ID} ${REPO_DIR}"
Rscript "${REPO_DIR}/hoffman/run_array.R" "${SGE_TASK_ID}" "${REPO_DIR}"

# echo job info on joblog:
echo "Job $JOB_ID.$SGE_TASK_ID ended on:   " $(hostname -s)
echo "Job $JOB_ID.$SGE_TASK_ID ended on:   " $(date)
echo " "
