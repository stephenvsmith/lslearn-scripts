# Running on Hoffman2

This directory holds everything needed to run the simulation study as SGE
array jobs on [UCLA's Hoffman2 cluster](https://www.hoffman2.idre.ucla.edu).

## Recommended workflow

1. Clone this repository to your scratch space: `$SCRATCH/lslearn-scripts`.
2. Download the bnlearn network `.rds` files you need into
   `$SCRATCH/lslearn-scripts/networks/rds/` (see the top-level README).
3. Run `run/initialize.R` once (interactively, or via `Rscript`) to build
   `sim_vals.csv` in your results directory — this defines one simulation
   setting per row/array task.
4. Submit `hoffman/submit/submit_array.sh` with `qsub`, after adjusting
   `-t 1-N:1` to match the number of rows in `sim_vals.csv` and the
   `-M` address to your own email. Each array task calls
   `hoffman/run_array.R`, which wires up `run/arraykernel.R` for that task.
5. Use `hoffman/simprogress.sh` to check on progress while jobs run.

## `hoffman/submit/legacy/`

The scripts in `submit/legacy/` are the original per-algorithm Hoffman job
scripts (`finalResults.R`, `rwsims.R`, `SNL.R`, `CML.R`, `PC.R`,
`arrayscripthoffman.R`, ...) kept for reference. Their target R scripts
predate the `run/arrayscript.R` + `run/arraykernel.R` consolidation and are
not part of this repository, so they won't run as-is — either point them at
your own copies of those drivers, or prefer `submit/submit_array.sh` above.
Hardcoded scratch paths in these legacy scripts have been replaced with
`$SCRATCH` so they work under any Hoffman2 account.
