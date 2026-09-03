### Directories for running simulations on the Hoffman2 cluster.
###
### Builds the standard set of paths used by run/arraykernel.R, rooted at the
### current user's Hoffman2 scratch directory ($SCRATCH), so this works for
### any account without hardcoding a username. Assumes this repository has
### been cloned to "$SCRATCH/lslearn-scripts" (see hoffman/README.md).

hoffman_dirs <- function(vars, pop_string){
  user <- Sys.getenv("USER")
  scratch_root <- Sys.getenv("SCRATCH", unset = sprintf("/u/scratch/%s/%s", substr(user, 1, 1), user))

  vars$home_dir <- scratch_root
  cat(vars$home_dir,":",dir.exists(vars$home_dir),"\n")

  vars$repo_dir <- file.path(scratch_root, "lslearn-scripts")
  cat(vars$repo_dir,":",dir.exists(vars$repo_dir),"\n")

  vars$package_loc <- file.path(scratch_root, "Hoffman/Packages/LocalPC")
  cat(vars$package_loc,":",dir.exists(vars$package_loc),"\n")

  vars$data_gen_file <- file.path(vars$repo_dir, "R/data_gen.R")
  cat(vars$data_gen_file,":",file.exists(vars$data_gen_file),"\n")

  vars$result_dir <- file.path(scratch_root, "Hoffman/LocalPC/Results/sample/")
  cat(vars$result_dir,":",dir.exists(vars$result_dir),"\n")

  vars$simulation_dir <- file.path(scratch_root, "Hoffman/LocalPC/Simulations/")
  cat(vars$simulation_dir,":",dir.exists(vars$simulation_dir),"\n")

  vars$rds_dir <- file.path(vars$repo_dir, "networks/rds")
  cat(vars$rds_dir,":",dir.exists(vars$rds_dir),"\n")

  return(vars)
}
