### Combines all per-array-job results .rds files in the current results
### directory into a single results_final.rds file.

library(tidyverse)
setwd("~/Desktop/results_sample")
unlink("results_final.rds")
files <- list.files(pattern = "*.rds")

data_list <- lapply(files,function(f) return(readRDS(f)))
df <- do.call(rbind,data_list)
rm(data_list)

saveRDS(df,"results_final.rds")
