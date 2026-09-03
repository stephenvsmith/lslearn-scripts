# lslearn-scripts

Scripts for running the local structure learning (CML / SNL vs. global PC)
simulation study, either locally or as SGE array jobs on
[UCLA's Hoffman2 cluster](https://www.hoffman2.idre.ucla.edu).

For each simulation setting, data is generated from a `bnlearn` reference
network, then the global PC algorithm, Coordinated Multi-neighborhood
Learning (CML), and Single Neighborhood Learning (SNL) are each run and
scored against the true network structure.

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
   `discretecdAlgorithm`, `gRbase`, `igraph`, `parallel`, and the `CML`
   package implementing the CML/SNL algorithms.
2. Download the `bnlearn` reference networks you want to simulate from the
   [bnlearn Bayesian network repository](https://www.bnlearn.com/bnrepository/)
   as `.rds` files, and place them in `networks/rds/`.
3. Copy `config/config.example.R` to `config/config.R` and set `home_dir`
   (where this repo lives) and `scratch_dir` (where generated data and
   results should be written).

## Running locally

```r
source("run/initialize.R")       # one-time: builds sim_vals.csv in scratch_dir
source("run/arrayscript.R")      # runs the setting for array_num (default 1)
```

Edit `array_num` at the top of `run/arrayscript.R` (or set it before
sourcing) to run a different row of `sim_vals.csv`.

## Running on Hoffman2

See [hoffman/README.md](hoffman/README.md).

## Analyzing results

Once a batch of simulations has produced per-setting `.rds` result files,
`analysis/compile_results.R` combines them into one `results_final.rds`,
`analysis/checking_results.R` reports on completion status, and
`analysis/compile_results_sample.R` / `analysis/extraplots.R` /
`analysis/savephotos.R` build the summary tables and plots. These scripts
have hardcoded personal paths (`~/Desktop/...`, `~/Dropbox/...`) at the top —
update them to point at your own results and output directories before
running.

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
