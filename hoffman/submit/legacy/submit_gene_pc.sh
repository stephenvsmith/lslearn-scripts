#!/bin/bash
#$ -cwd
# error = Merged with joblog
#$ -o ./logs_genes_pc/joblog.$JOB_ID.$TASK_ID
#$ -j y
## Edit the line below as needed:
#$ -l h_rt=48:00:00,h_data=210M,highp
## Modify the parallel environment
#$ -pe shared 8
## and the number of cores as needed:
# Email address to notify
#$ -M $USER@mail
#$ -t 1-4:1

# echo job info on joblog:
echo "Job $JOB_ID.$SGE_TASK_ID started on:   " $(hostname -s)
echo "Job $JOB_ID.$SGE_TASK_ID started on:   " $(date)
echo " "

# load the job environment:
. /u/local/Modules/default/init/modules.sh
## Load the right R files
module load R/4.0.2
module load gcc/11.3.0

## substitute the command to run your code
## in the two lines below:
echo "Rscript ${SCRATCH}/PC.R"
Rscript "${SCRATCH}/PC.R"

# echo job info on joblog:
echo "Job $JOB_ID.$SGE_TASK_ID ended on:   " $(hostname -s)
echo "Job $JOB_ID.$SGE_TASK_ID ended on:   " $(date)
echo " "
