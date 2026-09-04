# lslearn-scripts

Scripts for reproducing the simulation study in Smith & Zhou, "Coordinated
Multi-Neighborhood Learning on a Directed Acyclic Graph" (JMLR, 2026),
either locally or as SGE array jobs on
[UCLA's Hoffman2 cluster](https://www.hoffman2.idre.ucla.edu). The algorithms
themselves (CML, SNL) are implemented in the companion package
[`stephenvsmith/lslearn`](https://github.com/stephenvsmith/lslearn) (a
ground-up reimplementation that superseded the original `stephenvsmith/CML`
package this repo was originally written against — see
[Compatibility with `lslearn`](#compatibility-with-lslearn) below); this repo
only drives that package to generate data, run it against `bnlearn`
reference networks, and score the results.

For each simulation setting, data is generated from a `bnlearn` reference
network, then the global PC algorithm, Coordinated Multi-Neighborhood
Learning (CML), and Single Neighborhood Learning (SNL) are each run on
randomly selected target sets and scored against the true network structure
(skeleton/v-structure/parent-recovery F1, SHD, runtime, and CI test counts).

## Scope

This repo reproduces the **Section 4 simulation study**: the settings grid
(13 `bnlearn` networks, 3 significance levels for each of Mb and skeleton
recovery, 3 sample sizes, 3 datasets per setting) matches the paper exactly —
`run/initializekernel.R` builds the same 13-network, α/α_Mb ∈ {0.01,0.05,0.1}²,
n ∈ {500,1000,10000} grid described in the paper, and `analysis/compile_results_sample.R`
builds the F1/SHD/PRA summaries and plots behind Figures 2–4 and 8.

**Not included**: the Section 5 gene regulatory network case study (the
Chu et al. scRNA-seq cross-validation analysis) and the exact scripts behind
Tables 1, 2, and 4 were not part of this repository's source material, so
they aren't reproduced here.

## Compatibility with `lslearn`

`R/helperfunctions.R` was written against the original `CML` package and has
been updated to run against `lslearn` (as of the `lslearn` `main` branch,
2026-09-04). Status:

**Works unchanged:** `cml()`, `snl()`, and `allMetrics()` — the functions
that produce every skeleton/v-structure/parent-recovery/ancestor F1 number
and SHD behind Figures 2–4 and 8 — kept compatible call signatures across
the migration. No changes were needed at these call sites.

**Patched locally:** `lslearn` renamed several functions this file called to
snake_case and made them internal-only (`getNeighborhoodMetrics` was
removed outright; `mbRecovery`, `mbRecoveryMetrics`, `getTotalMBTime`,
`getTotalMBTests` became unexported `mb_recovery()`, `mb_recovery_metrics()`,
`get_total_mb_time()`, `get_total_mb_tests()`; `check_neighbors_retrieval()`
was removed). `helperfunctions.R`'s "lslearn Compatibility Shims" section
ports these faithfully from `lslearn`'s own (unexported) source, and
`get_nbhds()` now uses this file's own `find_all_neighbors()` instead of the
removed C++ export. Also fixed: `lslearn::cml()` now separates skeleton CI
tests (`NumTests`) from Markov Blanket estimation tests (`MBNumTests`),
where `snl()`'s `NumTests` already includes both — `run_cml()` now sums them
for CML so the "total CI tests" comparison across CML/SNL/PC (Figures 3a,
7a) is on the same basis for all three. This also resolves a caveat the
paper had to make in Section 4.1 ("we were unable to obtain these values"
for Mb test counts) — `MBNumTests` is now available directly.

**Not yet resolved — blocks fresh data generation:** `R/data_gen.R` builds
its network/edge representation entirely on `sparsebnUtils`
(`edgeList`/`get.adjacency.matrix`/`to_igraph`/`as.sparse`/`to_edgeList`)
plus `discretecdAlgorithm` for the (currently unused) discrete-data branch.
**Both packages were archived by CRAN on 2024-04-12** and no longer install
via `install.packages()` — `sparsebnUtils` for unfixed issues, and
`discretecdAlgorithm` because it requires `sparsebnUtils`. This is almost
certainly why `lslearn` itself only depends on `bnlearn`/`MXM`/`Rcpp`/
`RcppArmadillo` now. As written, `data_gen.R` cannot generate simulation
data on a machine that doesn't already have these two packages installed
from an old source (e.g. the CRAN archive, or a cached local library) — this
is the actual blocker to a from-scratch reproduction, independent of
anything above. Two ways forward, in rough order of effort:
1. Pin the archived versions (e.g. `remotes::install_version("sparsebnUtils", "0.1.2")`
   from the CRAN archive) as a stopgap — lowest effort, but not a durable fix.
2. Rewrite `data_gen.R`'s graph plumbing on packages that remain available
   (`bnlearn` — already a dependency — plus `igraph`, which is still
   maintained and was the only non-archived package `sparsebnUtils` wrapped
   for these calls). The `sparsebnUtils` calls here don't do anything
   `bnlearn`/`igraph` can't: `edgeList`/`get.adjacency.matrix` is just a
   parent-index list ↔ adjacency-matrix conversion, `to_igraph`/`to_edgeList`
   round-trip through `igraph::graph_from_adjacency_matrix()`, and
   `as.sparse()` is only used internally to attach randomly-generated
   coefficients to edges in a self-consistent order — none of that requires
   matching `sparsebnUtils`'s exact internal representation, just a fixed
   convention on the R side.

This hasn't been attempted here — it's a substantive rewrite of the data
generation core, not a mechanical fix like the shims above, and is worth a
design conversation before touching it.

## Notation

Script variable names map to the paper's notation as follows:

| Script variable | Paper notation | Meaning |
|---|---|---|
| `alpha`   | α_skel | significance level for CML/SNL/PC skeleton CI tests |
| `mb_alpha`| α_Mb   | significance level for Markov blanket (MMPC/SES) recovery |
| `algo`    | —      | Mb recovery algorithm (`MMPC` or `SES`; the paper's results use `MMPC`) |
| `net`     | —      | `bnlearn` network name |
| `n`       | n      | sample size |
| `ub`/`lb` | Unif(0.4, 0.75) | bounds for SEM edge coefficients |
| `high`/`low` | σ ~ Unif(0.1, 0.5) | bounds for noise variance (0.01–0.25) |

## Layout

```
R/          Core library code: data generation (data_gen.R) and the
            simulation/scoring helpers used by every run (helperfunctions.R)
run/        Entry points for one simulation study:
              initialize.R      -- one-time setup, builds sim_vals.csv
              initializekernel.R
              arrayscript.R     -- runs one setting (array_num) locally
              arraykernel.R
config/     config.example.R -- copy to config.R and fill in your paths
              (config.R is gitignored)
networks/   networks/rds/ -- bnlearn network .rds files (gitignored; see below)
hoffman/    Hoffman2-specific glue: hoffman_dirs.R, run_array.R, the
            submit/ SGE job scripts, and simprogress.sh
analysis/   Scripts for compiling and plotting results after a batch of
            simulations has finished
```

## Setup

1. Install R 4.4+, a C++ compiler toolchain, and the GNU Scientific Library
   (GSL) — required by `lslearn`. Then install the required packages:
   `tidyverse`, `bnlearn`, `pcalg`, `parallel`, and
   [`lslearn`](https://github.com/stephenvsmith/lslearn) itself (not yet on
   CRAN — install with `pak::pak("stephenvsmith/lslearn")`). Also required
   for `R/data_gen.R`, but **archived and no longer `install.packages()`-able**
   — see [Compatibility with `lslearn`](#compatibility-with-lslearn) —
   `sparsebnUtils` and `discretecdAlgorithm`.
2. Download the 13 `bnlearn` reference networks used in the paper —
   `alarm`, `barley`, `insurance`, `arth150`, `andes`, `diabetes`, `link`,
   `mildew`, `hepar2`, `pigs`, `munin2`, `munin3`, `munin4` — from the
   [bnlearn Bayesian network repository](https://www.bnlearn.com/bnrepository/)
   as `.rds` files, and place them in `networks/rds/` (named e.g. `alarm.rds`,
   lowercase, matching `run/initializekernel.R`'s `net` list).
3. Copy `config/config.example.R` to `config/config.R` and set `home_dir`
   (the absolute path to this repo) and `scratch_dir` (where generated data
   and results should be written — expect several GB for the full grid).

## Running locally

All commands below assume your R working directory is the repository root
(`setwd()` there first, or launch R/RStudio with it as the project directory).

```r
source("run/initialize.R")   # one-time: builds sim_vals.csv in scratch_dir
source("run/arrayscript.R")  # runs the setting for array_num (default 1)
```

Both scripts read `config/config.R` relative to the working directory at the
moment they're sourced, so run them in the same session from the repo root —
`initialize.R` restores the working directory to the repo root when it
finishes, and `arrayscript.R` itself `setwd()`s into `scratch_dir` at the
end (that's expected; it's meant to be the last thing run in a session, or
run standalone via `Rscript run/arrayscript.R`).

To run every setting, loop over `array_num` (1 to `nrow(sim_vals.csv)`),
either by editing `array_num` in `run/arrayscript.R` and re-sourcing it, or
by running it fresh per setting with `Rscript run/arrayscript.R` after
setting `array_num` via an environment variable or command-line argument of
your own. Each `array_num` selects one incomplete row of `sim_vals.csv`
(tracked via `completed_sims.txt`/`in_process_sims.txt` in `scratch_dir`),
so you can also just re-run the same command repeatedly (e.g. in a shell
loop) to work through the whole grid.

## Running on Hoffman2

See [hoffman/README.md](hoffman/README.md) for the full walkthrough. In
short: clone this repo to `$SCRATCH/lslearn-scripts`, run `run/initialize.R`
once to build `sim_vals.csv`, then `qsub hoffman/submit/submit_array.sh`
with `-t` set to the number of rows in `sim_vals.csv` — each array task runs
one setting via `hoffman/run_array.R` → `run/arraykernel.R`.

## Analyzing results

Once a batch of simulations has produced per-setting `.rds` result files,
`analysis/compile_results.R` combines them into one `results_final.rds`,
`analysis/checking_results.R` reports on completion status, and
`analysis/compile_results_sample.R` / `analysis/extraplots.R` /
`analysis/savephotos.R` build the F1/SHD/PRA summary tables and plots
(Figures 2–4 and 8 in the paper). These scripts have hardcoded personal
paths (`~/Desktop/...`, `~/Dropbox/...`) at the top — update them to point
at your own results and output directories before running. They also
reproduce the paper's filtering (neighborhood size in [8, 20], edge count in
[3, 20], `mb_alpha == 0.01`, `algo == "MMPC"`) — adjust `analysis/compile_results_sample.R`'s
filter variables at the top if you want unfiltered or differently filtered
results.

## Development

Pre-commit hooks (shellcheck, an R parse check, and general whitespace/YAML
hygiene) are configured in [.pre-commit-config.yaml](.pre-commit-config.yaml):

```sh
pip install pre-commit
pre-commit install
```

CI (`.github/workflows/ci.yml`) runs the same shellcheck and R parse check —
both block the build. It also runs `styler` and `lintr` for feedback, but
these are advisory-only (they report, they don't fail CI): these scripts
were carried over from an existing reproducibility repo, so reformatting
every file to tidyverse style isn't worth the churn — the parse check is
the real correctness gate.
