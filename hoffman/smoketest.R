### Hoffman2 environment smoke test.
###
### Exercises the real pipeline functions end-to-end -- data generation,
### global PC, CML, SNL, and the lslearn compatibility shims -- against a
### small, self-contained stand-in network (asia, 8 nodes, built from
### bnlearn's own bundled example data). This is NOT one of the paper's 13
### networks and doesn't touch networks/rds/ at all; it's purely to confirm
### the environment (modules, R library, lslearn) actually works before
### committing to a real qsub run.
###
### Usage (from an interactive qrsh session, with the modules from
### hoffman/README.md's "Environment setup" section loaded):
###   Rscript hoffman/smoketest.R
### Takes well under a minute.

home_dir <- path.expand("~/lslearn-scripts")
scratch_root <- Sys.getenv("SCRATCH", unset = tempdir())
scratch_dir <- file.path(scratch_root, "lslearn-smoketest")
unlink(scratch_dir, recursive = TRUE)
dir.create(scratch_dir, recursive = TRUE)

# Throwaway test network fixture, kept OUT of networks/rds/ so it never
# mixes with the real 13 bnlearn-repository networks used for the actual
# simulation study.
test_rds_dir <- file.path(scratch_dir, "rds")
dir.create(test_rds_dir, recursive = TRUE)
library(bnlearn)
data(asia)
dag <- model2network("[A][S][T|A][L|S][B|S][D|B:E][E|T:L][X|E]")
fit <- bn.fit(dag, asia)
saveRDS(fit, file.path(test_rds_dir, "asia.rds"))

result_dir <- file.path(scratch_dir, "results")
rds_dir <- test_rds_dir
data_gen_file <- file.path(home_dir, "R/data_gen.R")

source(file.path(home_dir, "R/helperfunctions.R"))
source(data_gen_file)

cat("\n==== 1. get_network_DAG ====\n")
net <- "asia"
network_info <- get_network_DAG(net)
cat("p =", network_info$p, " nodes:", paste(network_info$node_names, collapse = ","), "\n")
stopifnot(network_info$p == 8)

cat("\n==== 2. Data generation (data_gen.R) ====\n")
array_num <- 1
alpha <- 0.05
mb_alpha <- 0.05
algo <- "MMPC"
n <- 200
ub <- 0.75
high <- 0.25
data.grid <- data.frame(
  network = net, data.type = "continuous", n.dat = 1, n.obs = n,
  c.ratio = 0, max.in.degree = Inf, lb = 0.4, ub = ub,
  low = 0.01, high = high, scale = FALSE, stringsAsFactors = FALSE
)

go_to_dir(result_dir)
simulation_data_creation()
df <- grab_data(1)
cat("Generated data dim:", paste(dim(df), collapse = " x "), "\n")
stopifnot(nrow(df) == n, ncol(df) == 8, all(colnames(df) == network_info$node_names))
stopifnot(!any(!is.finite(as.matrix(df))))
cat("OK -- data generation produced a clean", n, "x 8 matrix\n")

cat("\n==== 3. Target selection ====\n")
max_targets <- 4 # normally set by run/arraykernel.R
targets_all <- check_targets_defined_get_targets(network_info)
t <- targets_all[[which(sapply(targets_all, length) == 2)[1]]]
cat("Using target set:", paste(t, collapse = ","),
    "(", paste(network_info$node_names[t], collapse = ","), ")\n")

cat("\n==== 4. Global PC (pcalg) ====\n")
pc_res <- run_global_pc(df, 1)
cat("PC lmax:", pc_res$lmax$PC, " PC num_tests:", pc_res$num_tests$PC, "\n")
stopifnot(is.matrix(pc_res$pc))

cat("\n==== 5. CML (lslearn::cml + compatibility shims) ====\n")
cml_out <- run_cml(t, df, 1, pc_res, algo)
cat("CML result:", ncol(cml_out), "columns,", nrow(cml_out), "row\n")
print(t(cml_out))
stopifnot(nrow(cml_out) == 1)

cat("\n==== 6. SNL (lslearn::snl + compatibility shims) ====\n")
snl_out <- run_snl(t, df, 1, pc_res, algo)
cat("SNL result:", ncol(snl_out), "columns,", nrow(snl_out), "row\n")
print(t(snl_out))
stopifnot(nrow(snl_out) == 1)

cat("\n==== 7. Unit-check the compatibility shims directly ====\n")
mb_r <- mb_recovery(network_info$cpdag, network_info$true_dag, t)
cat("mb_recovery(ref, ref-as-est, t) [expect fn=0, fp=0]:\n")
print(mb_r)
stopifnot(mb_r$mb_fn == 0, mb_r$mb_fp == 0)
nm <- get_neighborhood_metrics(network_info$cpdag[t, t, drop = FALSE])
cat("get_neighborhood_metrics on target-only submatrix:\n")
print(nm)

cat("\n==== ALL CHECKS PASSED ====\n")
cat("(Safe to remove the test fixture: rm -rf", scratch_dir, ")\n")
