### Checks how many array-job simulations have completed, one/two/all
### datasets, based on the .rds files written to a local results directory
### (e.g. synced down from Hoffman2). Adjust the paths below to your setup.

library(tidyverse)
sims <- read.csv("~/Desktop/ResultsSample-04-23/sim_vals.csv")
setwd("~/Desktop/results_sample")
all_sim_nums <- sims$X

completed_files <- list.files()
all_done_sims <- completed_files[str_detect(completed_files,"results_[0-9]+.rds")]
all_done_sims <- gsub("results_","",all_done_sims)
all_done_sims <- sort(as.numeric(gsub(".rds","",all_done_sims)))

one_done_sims <- completed_files[str_detect(completed_files,"results_[0-9]+_1.rds")]
one_done_sims <- gsub("results_","",one_done_sims)
one_done_sims <- sort(as.numeric(gsub("_1.rds","",one_done_sims)))

to_remove <- intersect(one_done_sims,all_done_sims)
sapply(to_remove,function(x){
  unlink(paste0("results_",x,"_1.rds"))
})

one_done_sims_final <- setdiff(one_done_sims,all_done_sims)

two_done_sims <- completed_files[str_detect(completed_files,"results_[0-9]+_2.rds")]
two_done_sims <- gsub("results_","",two_done_sims)
two_done_sims <- as.numeric(gsub("_2.rds","",two_done_sims))

to_remove <- intersect(two_done_sims,all_done_sims)
sapply(to_remove,function(x){
  unlink(paste0("results_",x,"_2.rds"))
})

two_done_sims_final <- setdiff(two_done_sims,all_done_sims)
one_done_sims_final <- setdiff(one_done_sims_final,two_done_sims_final)


# Analysis ----------------------------------------------------------------

sims$completion <- "incomplete"
sims$completion[all_done_sims] <- "complete"
sims$completion[one_done_sims_final] <- "completed one"
sims$completion[two_done_sims_final] <- "completed two"

sims %>%
  group_by(n,completion) %>%
  summarise(total=n()) %>%
  ungroup() %>%
  pivot_wider(names_from = completion,values_from = total)

sims %>%
  filter(n==10000) %>%
  filter(completion=='incomplete') %>%
  group_by(net) %>%
  summarise(`total incomplete`=n())

sims %>% filter(n==10000) %>% filter(net=='pigs') %>% select(completion) %>%
  table()

# PC takes 1-3 hours at least -> lfci takes long too
sims %>% filter(n==1000) %>% filter(net=='pigs') %>% select(completion) %>%
  table()

sims %>% filter(n==500) %>% filter(net=='pigs') %>% select(completion) %>%
  table()

sims %>%
  filter(n==1000) %>%
  filter(completion=='incomplete') %>%
  group_by(net) %>%
  summarise(`total incomplete`=n())
