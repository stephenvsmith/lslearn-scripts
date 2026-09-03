#!/bin/bash
#$ -cwd
# error = Merged with joblog
#$ -o ./logs_nbhd/joblog.$JOB_ID.$TASK_ID
#$ -j y
## Edit the line below as needed:
#$ -l h_rt=08:00:00,h_data=520M
## Modify the parallel environment
## and the number of cores as needed:
#$ -pe shared 12
# Email address to notify
#$ -M $USER@mail
#$ -t 2555-3888:1

# echo job info on joblog:
echo "Job $JOB_ID.$SGE_TASK_ID started on:   " $(hostname -s)
echo "Job $JOB_ID.$SGE_TASK_ID started on:   " $(date)
echo " "

# load the job environment:
. /u/local/Modules/default/init/modules.sh
## Load the right R files
module load R/4.0.2

## substitute the command to run your code
## in the two lines below:
echo 'Rscript ./HoffmanNbhdArray/arrayscripthoffman.R'
Rscript ./HoffmanNbhdArray/arrayscripthoffman.R

# echo job info on joblog:
echo "Job $JOB_ID.$SGE_TASK_ID ended on:   " $(hostname -s)
echo "Job $JOB_ID.$SGE_TASK_ID ended on:   " $(date)
echo " "
