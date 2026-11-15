set.seed(555)

# Set simulation settings
alpha <- c(0.01,0.05,0.1)
mb_alpha <- c(0.01,0.05,0.1)
net_names <- gsub(".rds","",list.files(rds_dir))
net <- c("alarm","barley","insurance","arth150","andes","diabetes",
         "link","mildew","hepar2","pigs","munin2","munin3","munin4")
high <- c(0.25) # For variances
ub <- c(0.75) # For coefficients
n <- c(500,1000,10000)
algos <- c("MMPC")

# Create a table with every combination of simulation settings
simulation_values <- expand.grid(alpha=alpha,mb_alpha=mb_alpha,net=net,
                                 high=high,ub=ub,n=n,algos=algos)
# Put the mb_alpha = 0.01 settings first, since those are the ones the
# paper's main results use. Array tasks claim rows roughly in order, so they
# finish first. Within each mb_alpha, n still varies slowest.
simulation_values <- simulation_values[order(simulation_values$mb_alpha != 0.01,
                                             simulation_values$mb_alpha),]
rownames(simulation_values) <- NULL

initializekernel_start_dir <- getwd()
go_to_dir(result_dir)
if (file.exists("incomplete.txt")){
  cat("We are skipping making the sim_vals file")
} else {
  write.csv(simulation_values,file = "sim_vals.csv")
}

# Generate each network's target pool once, up front. If array tasks
# generated it themselves, concurrent tasks for the same network could each
# draw (and save) a different pool. get_targets() reads the global
# max_targets, which must match run/arraykernel.R.
max_targets <- 4
for (target_net in unique(as.character(simulation_values$net))) {
  if (!file.exists(paste0("targets_",target_net,".rds"))) {
    set.seed(555)
    saveRDS(get_targets(get_network_DAG(target_net)$p),
            paste0("targets_",target_net,".rds"))
  }
}
setwd(initializekernel_start_dir)
