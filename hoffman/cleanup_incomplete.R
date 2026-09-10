### One-off (and reusable) cleanup for a results directory. Handles two
### situations: (1) the historical array_num collision bug (multiple
### concurrent array tasks landing on the same sim_vals.csv row, corrupting
### each other's data files mid-write -- fixed in run/arraykernel.R, see
### hoffman/README.md), and (2) the ordinary case of a task hitting its
### h_rt/h_data limit and getting killed mid-run.
###
### For every row not yet in completed_sims.txt, removes its data/<net>_<row>
### directory (may be partially/corruptly written) so a fresh submission
### regenerates it cleanly. Deliberately does NOT remove per-trial
### results_<row>_<num>.rds caches: data generation is fully deterministic
### (seeded by array_num and trial number), so regenerating data/ reproduces
### byte-identical input regardless of what happened before -- a cached
### trial result is either still valid against that data, or (if it was
### itself truncated by a kill signal mid-saveRDS()) readRDS() will fail
### loudly the next time run/arraykernel.R tries to reuse it, rather than
### silently returning wrong output. Keeping these caches means a row
### killed partway through its 3 trials only redoes the trial(s) that
### didn't finish, not all 3. Safe to re-run any time; a no-op for rows
### with nothing to clean.
###
### Usage: Rscript hoffman/cleanup_incomplete.R <result_dir>
### e.g.:  Rscript hoffman/cleanup_incomplete.R "$SCRATCH/ResultsSample-09-26"

args <- commandArgs(trailingOnly = TRUE)
result_dir <- if (length(args) >= 1) args[1] else getwd()
setwd(result_dir)

sim_vals <- read.csv("sim_vals.csv", stringsAsFactors = FALSE)[, -1]
complete <- if (file.exists("completed_sims.txt")) read.table("completed_sims.txt")[, 1] else integer(0)
incomplete <- setdiff(seq_len(nrow(sim_vals)), complete)

cat("Total settings:", nrow(sim_vals), " complete:", length(complete),
    " needing cleanup/regeneration:", length(incomplete), "\n")

removed_data <- 0
for (row in incomplete) {
  net <- sim_vals$net[row]
  data_dir <- file.path("data", paste0(net, "_", row))
  if (dir.exists(data_dir)) {
    unlink(data_dir, recursive = TRUE)
    removed_data <- removed_data + 1
  }
  final_res <- paste0("results_", row, ".rds")
  if (file.exists(final_res)) unlink(final_res) # shouldn't exist if not in completed_sims.txt, but be safe
}

cat("Removed", removed_data, "data directories (per-trial results_<row>_<num>.rds",
    "caches left in place -- see the header comment above for why).\n")
cat("Safe to resubmit now: the fixed run/arraykernel.R claims rows atomically\n",
    "via a claims/ directory, so stale in_process_sims.txt entries from the\n",
    "old logic are simply ignored for row selection.\n")
