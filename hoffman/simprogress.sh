#!/usr/bin/bash
### Reports progress of the current batch of Hoffman2 array-job simulations.
### Usage: simprogress.sh [results_dir]
### results_dir defaults to $SCRATCH/$LSLEARN_RESULTS_NAME, or
### $SCRATCH/ResultsSample-<current month-year> if that is unset

RESULTS_DIR="${1:-${SCRATCH}/${LSLEARN_RESULTS_NAME:-ResultsSample-$(date +%m-%y)}}"

# --array lists every pending array task on its own line rather than as one
# collapsed range (e.g. 12345_[40-351]), so wc -l counts tasks.
running="$(squeue --me --noheader --states=RUNNING --format=%i | wc -l)"
pending="$(squeue --me --noheader --states=PENDING --array --format=%i | wc -l)"

now="$(date +%r)"
current_date="$(date +%m-%d-%Y)"

completed_comm=($(wc "${RESULTS_DIR}/completed_sims.txt"))
total_completed=${completed_comm[0]}

one_completed_comm=($(wc "${RESULTS_DIR}/completed_1_sim.txt"))
total_one_completed=${one_completed_comm[0]}

two_completed_comm=($(wc "${RESULTS_DIR}/completed_2_sim.txt"))
total_two_completed=${two_completed_comm[0]}

total_one_completed="$((total_one_completed-total_two_completed))"
total_two_completed="$((total_two_completed-total_completed))"

cat <<EOF > simulation_report.txt

SIMULATION REPORT
----------------------------
DATE: ${current_date}
TIME: ${now}
AUTHOR: $(whoami)

RESEARCH SIMULATION UPDATE

At the current time, ${running} array tasks are running and ${pending} are waiting to start.
Of those, ${total_completed} are completely finished. For each simulation job, we run three datasets. For the jobs which have run, ${total_one_completed} have finished one dataset, and ${total_two_completed} have finished two datasets.
EOF
