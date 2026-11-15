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
## Number of tasks should match the number of rows in sim_vals.csv (351 for
## the full grid in run/initializekernel.R)
#$ -t 1-351:1

# echo job info on joblog:
echo "Job $JOB_ID.$SGE_TASK_ID started on:   " $(hostname -s)
echo "Job $JOB_ID.$SGE_TASK_ID started on:   " $(date)
echo " "

# load the job environment. This exact combination was arrived at after
# extensive trial and error getting lslearn's full dependency chain
# (igraph, pcalg+Bioconductor graph/RBGL, MXM+Rfast/energy/nloptr/etc.) to
# build and load on this cluster -- see hoffman/README.md for the full
# story. Order matters: gcc must load before R.
#
# R/4.6.0 (this cluster's newest R at the time) turned out to be
# INCOMPATIBLE with lslearn's dependency chain: it has removed PREXPR from
# its C API, which some CRAN packages' compiled code still references,
# causing them to build but fail to *load*. R/4.4.1 (paired with the older
# gcc/10.2.0, per `modules_lookup -m R`) is the combination that actually
# works end-to-end.
. /u/local/Modules/default/init/modules.sh
module load gcc/10.2.0
module load R/4.4.1
module load gsl/2.6      # required by the R gsl/energy packages (MXM dep chain)
module load nlopt/2.7.1  # required by nloptr (MXM dep chain) -- builds fine
                          # without it, but fails to *load* (unresolved
                          # libnlopt.so.0) without this module loaded
module load cmake/3.19.5 # required to build igraph and RcppParallel/Rfast;
                          # not needed at runtime, but harmless to keep loaded

# R/4.4.1's gcc/10.2.0 module sets CC/CXX but not FC/F77 -- without these,
# any package with Fortran source (energy, Rfast, lme4's minqa dependency,
# ...) fails to compile. Only matters if a fresh personal library needs
# (re)building; harmless otherwise.
export FC=/u/local/compilers/gcc/10.2.0/bin/gfortran
export F77=/u/local/compilers/gcc/10.2.0/bin/gfortran

# Code belongs in $HOME (persistent, backed up), not $SCRATCH (purged after
# 14 days) -- see hoffman/README.md.
REPO_DIR="${HOME}/lslearn-scripts"

# Results directory name under $SCRATCH. Must match the LSLEARN_RESULTS_NAME
# used when running run/initialize.R. Override per run with
#   qsub -v LSLEARN_RESULTS_NAME=<name> hoffman/submit/submit_array.sh
export LSLEARN_RESULTS_NAME="${LSLEARN_RESULTS_NAME:-ResultsFullTargets}"
echo "Results directory: ${SCRATCH}/${LSLEARN_RESULTS_NAME}"

echo "Rscript ${REPO_DIR}/hoffman/run_array.R ${SGE_TASK_ID} ${REPO_DIR}"
Rscript "${REPO_DIR}/hoffman/run_array.R" "${SGE_TASK_ID}" "${REPO_DIR}"

# echo job info on joblog:
echo "Job $JOB_ID.$SGE_TASK_ID ended on:   " $(hostname -s)
echo "Job $JOB_ID.$SGE_TASK_ID ended on:   " $(date)
echo " "
