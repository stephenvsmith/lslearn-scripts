# lslearn-scripts

Scripts for reproducing the simulation study in Smith & Zhou, ["Coordinated
Multi-Neighborhood Learning on a Directed Acyclic Graph"](https://github.com/stephenvsmith/CML-Scripts)
(JMLR, 2026), either locally or as SGE array jobs on
[UCLA's Hoffman2 cluster](https://www.hoffman2.idre.ucla.edu). The algorithms
themselves (CML, SNL) are implemented in the companion package
[`stephenvsmith/CML`](https://github.com/stephenvsmith/CML); this repo only
drives that package to generate data, run it against `bnlearn` reference
networks, and score the results.

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

1. Install R (this project was developed against R 4.0.2) and the required
   packages: `tidyverse`, `bnlearn`, `pcalg`, `sparsebnUtils`,
   `discretecdAlgorithm`, `gRbase`, `igraph`, `parallel`, and
   [`CML`](https://github.com/stephenvsmith/CML) (the package implementing
   the CML/SNL algorithms — install it from source, it is not on CRAN).
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

Pre-commit hooks (shell lint via shellcheck, R style/lint/parse checks, and
general whitespace/YAML hygiene) are configured in
[.pre-commit-config.yaml](.pre-commit-config.yaml):

```sh
pip install pre-commit
pre-commit install
```

CI (`.github/workflows/ci.yml`) runs the same shellcheck and R checks on
every push and pull request.
