#!/usr/bin/bash
### Reports progress of the current batch of Hoffman2 array-job simulations.
### Usage: simprogress.sh [results_dir]
### results_dir defaults to $SCRATCH/ResultsSample-<current month-year>

RESULTS_DIR="${1:-${SCRATCH}/ResultsSample-$(date +%m-%y)}"

jobs_done="$(myjobs | grep -o '[0-9]*-[0-9]*:1' | grep -P '^\d+' -o)"
jobs_done=$((jobs_done-1))

jobs_to_do="$(myjobs | grep -o '[0-9]*-[0-9]*:1' | grep -P '\d+:' -o | sed 's/.$//')"

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

At the current time, we have ${jobs_done} simulations out of the submitted ${jobs_to_do} either running or already run.
Of those, ${total_completed} are completely finished. For each simulation job, we run three datasets. For the jobs which have run, ${total_one_completed} have finished one dataset, and ${total_two_completed} have finished two datasets.
EOF
