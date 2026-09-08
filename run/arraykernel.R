### Simulation Setup
# Load the file with functions for generating data
source(data_gen_file)
# Define the number of trials for each simulation setting
num_trials <- 3
# Define the number of targets considered for each setting
max_targets <- 4
# Define the number of cores used for parallel processing
#num_cores <- min(parallel::detectCores()-2,4)
num_cores <- 1
cat("We are using",num_cores,"core(s).\n\n")

# Set up a generic data grid for simulated data
# True values will be replace these later
data.grid <- data.frame(network = "asia",
                        data.type = "continuous",
                        n.dat = num_trials,
                        n.obs = 1000,
                        c.ratio = 0,
                        max.in.degree = Inf,
                        lb = 0.4,  # lower bound of coefficients
                        ub = 5,  # upper bound of coefficients
                        low = 0.01,  # lower bound of variances if continuous, of number of levels if discrete
                        high = 5,  # upper bound of variances if continuous, of number of levels if discrete
                        scale = FALSE,
                        stringsAsFactors = FALSE)


go_to_dir(result_dir)
### Read the table containing each simulation setting
sim_vals <- read.csv("sim_vals.csv",stringsAsFactors = FALSE)[,-1]

### Claim an incomplete row atomically. Concurrent array tasks used to pick
# a row via incomplete[min(array_num, length(incomplete))] -- once enough
# tasks' own SGE_TASK_ID exceeded the (shrinking) incomplete count, every
# one of them clamped to the SAME last element and silently duplicated
# work (observed: 13 tasks all landing on one row once the fast n=500/1000
# tier drained, corrupting each other's data files mid-write). dir.create()
# is atomic even on a shared/NFS filesystem, unlike a file-existence check,
# so claims/<row>/ existing is unambiguous proof someone already has that
# row -- if our candidate is taken, re-read what's actually still
# unclaimed and try again rather than trusting a single stale computation.
claims_dir <- "claims"
# NOT dir.check(claims_dir): dir.check() (data_gen.R) always builds an
# ABSOLUTE path internally (paste0(c('', folders), collapse='/') prepends a
# leading "/"), so a relative name like "claims" silently tries to create
# "/claims" at the filesystem root instead -- fails on permissions, doesn't
# error (the failure isn't checked), and every claim_a_row() dir.create()
# below then fails forever since its parent was never actually created
# (confirmed: every task spun in the retry loop for 3+ hours, ~30s of
# actual CPU time each -- all Sys.sleep(), no progress). Every existing
# dir.check() call elsewhere happens to already use absolute paths, so this
# was latent until this new relative-path use.
dir.create(claims_dir, showWarnings = FALSE)

claim_a_row <- function(preferred_index){
  repeat {
    complete <- if (file.exists("completed_sims.txt")) read.table("completed_sims.txt")[,1] else integer(0)
    claimed <- suppressWarnings(as.integer(list.files(claims_dir)))
    incomplete <- setdiff(seq_len(nrow(sim_vals)), c(complete, claimed))
    if (length(incomplete) == 0) return(NA_integer_)

    candidate <- incomplete[min(preferred_index, length(incomplete))]
    if (dir.create(file.path(claims_dir, candidate), showWarnings = FALSE)) {
      # Kept for hoffman/simprogress.sh's reporting; claims/ is now the
      # actual source of truth for what's spoken for.
      cat(candidate, file = "in_process_sims.txt", append = TRUE)
      cat("\n", file = "in_process_sims.txt", append = TRUE)
      return(candidate)
    }
    Sys.sleep(runif(1, 0.1, 1)) # someone else claimed it first -- retry fresh
  }
}

array_num <- claim_a_row(array_num)
if (is.na(array_num)) {
  cat("No incomplete settings remain; nothing to do.\n")
  quit(save = "no", status = 0)
}

cat("Array Number (System):",array_num,"\n\n")

### Save the settings for this simulation run
alpha <- sim_vals$alpha[array_num]
mb_alpha <- sim_vals$mb_alpha[array_num]
net <- sim_vals$net[array_num]
high <- sim_vals$high[array_num]
ub <- sim_vals$ub[array_num]
n <- sim_vals$n[array_num]
algo <- sim_vals$algo[array_num]

cat("This is row",array_num,"of our simulation grid.\n")
cat("Simulation Parameters:\n")
cat("Significance:",alpha,"\n")
cat("Markov Blanket Estimation Significance:",mb_alpha,"\n")
cat("Network:",net,"\n")
cat("high:",high,"\n")
cat("ub:",ub,"\n")
cat("n:",n,"\n")
cat("MB algo:",algo,"\n")

# Obtain network information, including the true DAG adj. mat.
network_info <- get_network_DAG(net)

# Generate/Retrieve Targets
targets <- check_targets_defined_get_targets(network_info)
t_tot <- length(targets)
set.seed(111)
targets <- targets[sort(sample(seq(t_tot),4))]

# Set up for simulated data and directory for context
data.grid$network <- net
data.grid$n.obs <- n
n <- n
ub <- ub
high <- high
data.grid$ub <- ub
data.grid$high <- high

# Generate the data
simulation_data_creation()

# Grab simulated data
df_list <- lapply(1:num_trials,function(i) grab_data(i))

# Keep network directory
curr_dir <- getwd()

# Get results for each trial if they exist
results_list <- lapply(1:num_trials,function(num){
  if (file.exists(paste0("results_",array_num,"_",num,".rds"))){
    return(readRDS(paste0("results_",array_num,"_",num,".rds")))
  }

  # Run Global PC Algorithm
  trial_num <- num
  cat("Running Global PC for Dataset",num,"... ")
  results_pc <- run_global_pc(df_list[[num]],trial_num)
  time_pc <- results_pc$time_diff$PC
  units(time_pc) <- "secs"
  cat("completed in",as.numeric(time_pc),units(time_pc),"\n")

  # Run CML Algorithm for all sets of targets
  results_cml_df <- mclapply(targets,
                             run_cml_target,
                             df=df_list[[num]],
                             num,
                             results_pc,
                             algo,
                             curr_dir,
                             mc.preschedule = FALSE,mc.cores = num_cores)

  # Run SNL Algorithm for all sets of targets
  results_snl_df <- mclapply(targets,
                             run_snl_target,
                             df=df_list[[num]],
                             num,
                             results_pc,
                             algo,
                             curr_dir,
                             mc.preschedule = FALSE,mc.cores = num_cores)

  results_final_df_cml <- data.frame(do.call(rbind,results_cml_df))
  results_final_df_snl <- data.frame(do.call(rbind,results_snl_df))
  results_final_df <- results_final_df_cml %>%
    left_join(results_final_df_snl,by=c("targets","trial_num"),suffix=c("_cml","_snl")) %>%
    rename_with(~paste0(str_extract(.,"(snl|cml)$"),
                        "_",
                        str_extract(.,"^[a-z]+")),
                ends_with(c("_snl","_cml")))

  saveRDS(results_final_df,paste0("results_",array_num,"_",num,".rds"))
  if (num < num_trials){
    cat(array_num,file = paste0("completed_",num,"_sim.txt"),append = TRUE)
    cat("\n",file = paste0("completed_",num,"_sim.txt"),append = TRUE)
  }

  unlink(paste0("cml_",array_num,"_",num,"_","*","_results.rds"))
  unlink(paste0("snl_",array_num,"_",num,"_","*","_results.rds"))

  setwd(curr_dir)
  return(results_final_df)
})

results_iteration <- data.frame(do.call(rbind,results_list))
saveRDS(results_iteration,paste0("results_",array_num,".rds"))
# Remove temporary files (if the program gets to this point)
for (i in 1:num_trials){
  unlink(paste0("results_",array_num,"_",i,".rds"))
  unlink(paste0("pc_",array_num,"_",i,"_results.rds"))
}

unlink(paste0("pc_",array_num,"_tests.txt"))

cat(array_num,file = "completed_sims.txt",append = TRUE)
cat("\n",file = "completed_sims.txt",append = TRUE)
