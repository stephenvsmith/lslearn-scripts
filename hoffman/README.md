# Running on Hoffman2

This directory holds everything needed to run the simulation study as SGE
array jobs on [UCLA's Hoffman2 cluster](https://www.hoffman2.idre.ucla.edu).

## Environment setup (one-time, verified working)

`lslearn`'s full dependency chain (`igraph`, `pcalg` + Bioconductor `graph`/
`RBGL`, `MXM` + `Rfast`/`Rfast2`/`energy`/`nloptr`/`lme4`/`bigmemory`, and
`lslearn` itself) took substantial trial and error to get building and
*loading* cleanly on this cluster. The short version, so this doesn't need
re-deriving on a fresh account:

**Use `gcc/10.2.0` + `R/4.4.1`, not the newest R available.** `R/4.6.0`
(the newest at the time this was worked out) has removed `PREXPR` from its
C API, which several CRAN packages in this dependency chain still
reference internally — they compile fine but fail to *load* with
`undefined symbol: PREXPR`. `modules_lookup -m R` shows which gcc version
pairs with which R version; `R/4.4.1` via `gcc/10.2.0` is the combination
that actually works end-to-end.

```bash
module load gcc/10.2.0
module load R/4.4.1
module load gsl/2.6       # for the R gsl/energy packages
module load nlopt/2.7.1   # for nloptr -- builds without it, but then fails
                           # to load (unresolved libnlopt.so.0)
module load cmake/3.19.5  # to build igraph and RcppParallel/Rfast

# gcc/10.2.0's module sets CC/CXX but not FC/F77 -- without these, any
# package with Fortran source (energy, Rfast, lme4's minqa dep) fails to
# compile:
export FC=/u/local/compilers/gcc/10.2.0/bin/gfortran
export F77=/u/local/compilers/gcc/10.2.0/bin/gfortran

# Personal R library, made version-independent and persistent so you don't
# have to re-export it (and re-discover why R CMD INSTALL is trying to
# write to a system directory) every new session:
echo 'R_LIBS_USER=~/R/library' >> ~/.Renviron
export R_LIBS_USER=~/R/library
mkdir -p "$R_LIBS_USER"
```

A couple of dependencies needed more than a module load:

- **`igraph`**: the modern CRAN release links against GLPK, and this
  cluster's *default* (non-module) GLPK build is incompatible at the
  symbol level (`undefined symbol: glp_at_error`). IDRE maintains a tested
  fix for this — see
  [their KB article](https://support.idre.ucla.edu/helpdesk/KB/View/76902445-installation-of-package-igraph-in-r):
  download the igraph source tarball, apply
  `/u/local/apps/igraph/HOW_TO_INSTALL_IN_R/configure.patch`, then
  `R CMD INSTALL` the patched tree.
- **`gsl`** (the R package `energy` depends on): the current CRAN release
  declares `Depends: R (>= 4.5.0)` for no code reason we could find (it's a
  thin C wrapper) — download it, relax that line in `DESCRIPTION`, and
  `R CMD INSTALL` directly. Its `ellint.c` also calls
  `gsl_sf_ellint_D_e()` with the wrong argument count *only* if it
  accidentally links against this system's non-module GLPK-adjacent GSL;
  against the `gsl/2.6` module (make sure it's actually loaded — `which
  gsl-config` should point into `/u/local/apps/gsl/2.6/...`, not
  `/usr/bin`) the original unpatched call is already correct.
- **`Rfast`**: fails with `'tbb::task' has not been declared` — a known
  GCC 9/10 + modern (oneTBB) `RcppParallel` conflict in libstdc++'s
  Parallel STL backend. Fix: add
  `CXX17FLAGS += -D_GLIBCXX_USE_TBB_PAR_BACKEND=0` to `~/.R/Makevars`.
- **`~/.R/Makevars`** should otherwise be empty/absent — a stale one left
  over from earlier troubleshooting caused unrelated build failures.

With all of that in place, `remotes::install_github("stephenvsmith/lslearn")`
(after `Sys.unsetenv("GITHUB_PAT")` if you hit a spurious "Bad credentials"
error — a stale `GITHUB_PAT` env var breaks anonymous access to public
repos) installs and `library(lslearn)` loads cleanly.

## Recommended workflow

1. Clone this repository to `$HOME/lslearn-scripts` — code belongs in
   `$HOME` (persistent, backed up), not `$SCRATCH` (purged after 14 days).
2. Download the bnlearn network `.rds` files you need into
   `$HOME/lslearn-scripts/networks/rds/` (see the top-level README).
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
