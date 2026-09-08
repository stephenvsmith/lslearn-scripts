### One-off (and reusable) cleanup for a results directory after the
### array_num collision bug that run/arraykernel.R used to have (multiple
### concurrent array tasks silently landing on the same sim_vals.csv row
### once the incomplete pool shrank past their own SGE_TASK_ID, corrupting
### each other's data files mid-write -- see hoffman/README.md).
###
### For every row not yet in completed_sims.txt, removes its data/<net>_<row>
### directory (may be partially/corruptly written) and any partial
### per-trial results_<row>_<num>.rds caches (may have been computed from
### data a colliding task later overwrote), so a fresh submission
### regenerates everything cleanly. Safe to re-run any time; a no-op for
### rows with nothing to clean.
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
removed_results <- 0
for (row in incomplete) {
  net <- sim_vals$net[row]
  data_dir <- file.path("data", paste0(net, "_", row))
  if (dir.exists(data_dir)) {
    unlink(data_dir, recursive = TRUE)
    removed_data <- removed_data + 1
  }
  partials <- Sys.glob(paste0("results_", row, "_*.rds"))
  if (length(partials) > 0) {
    unlink(partials)
    removed_results <- removed_results + length(partials)
  }
  final_res <- paste0("results_", row, ".rds")
  if (file.exists(final_res)) unlink(final_res) # shouldn't exist if not in completed_sims.txt, but be safe
}

cat("Removed", removed_data, "data directories and", removed_results, "partial results files.\n")
cat("Safe to resubmit now: the fixed run/arraykernel.R claims rows atomically\n",
    "via a claims/ directory, so stale in_process_sims.txt entries from the\n",
    "old logic are simply ignored for row selection.\n")
