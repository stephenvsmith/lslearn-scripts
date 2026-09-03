library(tidyverse)
library(latex2exp)
library(kableExtra)
theme_set(theme_classic())

# Load and Filter Data ---------------------------------------------------------------

# setwd("~/Desktop/results_sample")
setwd("~/Dropbox/Academics/tmp/results_sample")

result_df <- readRDS("results_final.rds")

result_df <- result_df %>%
  mutate(targetSkeletonTotalTime=
           unlist(lapply(str_split(lfci_target,","),
                         function(t){sum(as.numeric(t))})))
folder_name <- "October 2025"

datashare <- NULL
alphavals <- NULL
maxnetsize <- NULL
rmNet <- NULL
datasetsize <- NULL
minnbhdsize <- 8
maxnbhdsize <- 20
edgenum <- c(3,20)
maxnumtargets <- c(2,6)
mbalgo <- c("MMPC")
mbalphavals <- NULL
measure <- TRUE


filterData <- function(df){
  if (!is.null(datashare)){
    df <- df %>%
      slice_sample(prop = datashare/100)
  }
  if (!is.null(alphavals)){
    df <- df %>% filter(alpha %in% as.numeric(alphavals))
  }
  if (!is.null(maxnetsize)){
    df <- df %>%
      filter(p>=maxnetsize[1]) %>%
      filter(p<=maxnetsize[2])
  }
  if (!is.null(rmNet)){
    rm_net <- unlist(str_split(rmNet,","))
    df <- df %>% filter(!(net %in% rm_net))
  }
  if (!is.null(datasetsize)){
    df <- df %>%
      filter(n>=datasetsize[1]) %>%
      filter(n<=datasetsize[2])
  }
  if (!is.null(maxnbhdsize)){
    df <- df %>% filter(size<=maxnbhdsize)
  }
  if (!is.null(minnbhdsize)){
    df <- df %>% filter(size>=minnbhdsize)
  }
  if (!is.null(edgenum)){
    df <- df %>%
      filter(num_edges >= edgenum[1]) %>%
      filter(num_edges <= edgenum[2])
  }
  if (!is.null(maxnumtargets)){
    df <- df %>%
      filter(num_targets>=maxnumtargets[1]) %>%
      filter(num_targets<=maxnumtargets[2])
  }
  if (!is.null(mbalgo)){
    df <- df %>% filter(algo %in% mbalgo)
  }
  if (!is.null(mbalphavals)){
    df <- df %>% filter(mb_alpha %in% as.numeric(mbalphavals))
  }

  if (!is.null(measure)){
    df <- df %>%
      select(sim_number,p,size,n,alpha,algo,net,mb_alpha,num_targets,
             net_edges,num_edges,
             contains("skel"),contains("_v_"),
             contains("mb_"),contains("pra"),
             contains("time"),contains("test"),
             contains("ancestor"),contains("orient"),
             contains("connect"),contains("f1"),contains("shd"),
             contains("target"),contains("overall")
      )
  }
  return(df)
}

df <- filterData(result_df)

# Simulation Setting Table ------------------------------------------------

overall_summary <- df %>%
  mutate(Network=net) %>%
  group_by(Network) %>%
  summarise(`Network Size`=mean(p),
            `Network Edges`=mean(net_edges),
            `Total Sims.`=n(),
            `Avg. MB Size`=mean(size),
            `Avg. MB Edges`=mean(num_edges)) %>%
  arrange(`Network Size`) %>%
  mutate(across(where(is.numeric),round,1))

saveRDS(overall_summary,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,
               "/overall_summary_table.rds"))

settings <- c("n","ub","high","alpha")

sapply(settings,function(setting){
  sim_setting_tab <- result_df %>%
    filter(mb_alpha==0.01) %>%
    mutate(Network=net) %>%
    group_by(Network,across(setting)) %>%
    summarise(`Network Size`=mean(p),
              `Total Sims.`=n()) %>%
    ungroup() %>%
    pivot_wider(names_from = setting,values_from = `Total Sims.`,names_prefix = paste(setting,"= ")) %>%
    arrange(`Network Size`) %>%
    mutate(across(where(is.numeric),round,1))

  saveRDS(sim_setting_tab,
          paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/sample_",
                 setting,"_table.rds"))
})

setting_tab <- df %>%
  filter(mb_alpha==0.01) %>%
  group_by(net,n,alpha,mb_alpha) %>%
  summarise(total=n(),p=mean(p)) %>%
  ungroup() %>%
  group_by(net) %>%
  summarise(p=mean(p),`Num. Settings`=n()) %>%
  ungroup() %>%
  arrange(p)

setting_target_table <- df %>%
  filter(mb_alpha==0.01) %>%
  group_by(net,num_targets) %>%
  summarise(N=n()) %>%
  ungroup() %>%
  pivot_wider(names_from=num_targets,values_from=N,names_prefix = "|T|=")

setting_tab %>%
  right_join(setting_target_table,by='net') %>%
  kable('latex')

# Skeleton summary scores for all algorithms ------------------------------

# Narrow first
df <- df %>% mutate(
  pc_narrow_skel_precision = pc_narrow_skel_tp / (pc_narrow_skel_tp + pc_narrow_skel_fp),
  pc_narrow_skel_recall = pc_narrow_skel_tp / (pc_narrow_skel_tp + pc_narrow_skel_fn),
  pc_narrow_skel_f1 = 2*pc_narrow_skel_tp / (2*pc_narrow_skel_tp + pc_narrow_skel_fp + pc_narrow_skel_fn),
  lpc_narrow_skel_precision = lpc_narrow_skel_tp / (lpc_narrow_skel_tp + lpc_narrow_skel_fp),
  lpc_narrow_skel_recall = lpc_narrow_skel_tp / (lpc_narrow_skel_tp + lpc_narrow_skel_fn),
  lpc_narrow_skel_f1 = 2*lpc_narrow_skel_tp / (2*lpc_narrow_skel_tp + lpc_narrow_skel_fp + lpc_narrow_skel_fn),
  lfci_narrow_skel_precision = lfci_narrow_skel_tp / (lfci_narrow_skel_tp + lfci_narrow_skel_fp),
  lfci_narrow_skel_recall = lfci_narrow_skel_tp / (lfci_narrow_skel_tp + lfci_narrow_skel_fn),
  lfci_narrow_skel_f1 = 2*lfci_narrow_skel_tp / (2*lfci_narrow_skel_tp + lfci_narrow_skel_fp + lfci_narrow_skel_fn))

# Broad
df <- df %>% mutate(
  pc_broad_skel_precision = pc_broad_skel_tp / (pc_broad_skel_tp + pc_broad_skel_fp),
  pc_broad_skel_recall = pc_broad_skel_tp / (pc_broad_skel_tp + pc_broad_skel_fn),
  pc_broad_skel_f1 = 2*pc_broad_skel_tp / (2*pc_broad_skel_tp + pc_broad_skel_fp + pc_broad_skel_fn),
  lpc_broad_skel_precision = lpc_broad_skel_tp / (lpc_broad_skel_tp + lpc_broad_skel_fp),
  lpc_broad_skel_recall = lpc_broad_skel_tp / (lpc_broad_skel_tp + lpc_broad_skel_fn),
  lpc_broad_skel_f1 = 2*lpc_broad_skel_tp / (2*lpc_broad_skel_tp + lpc_broad_skel_fp + lpc_broad_skel_fn),
  lfci_broad_skel_precision = lfci_broad_skel_tp / (lfci_broad_skel_tp + lfci_broad_skel_fp),
  lfci_broad_skel_recall = lfci_broad_skel_tp / (lfci_broad_skel_tp + lfci_broad_skel_fn),
  lfci_broad_skel_f1 = 2*lfci_broad_skel_tp / (2*lfci_broad_skel_tp + lfci_broad_skel_fp + lfci_broad_skel_fn))

### V-Structures

# Narrow first
df <- df %>% mutate(
  pc_narrow_v_precision = pc_narrow_v_tp / (pc_narrow_v_tp + pc_narrow_v_fp),
  pc_narrow_v_recall = pc_narrow_v_tp / (pc_narrow_v_tp + pc_narrow_v_fn),
  pc_narrow_v_f1 = 2*pc_narrow_v_tp / (2*pc_narrow_v_tp + pc_narrow_v_fp + pc_narrow_v_fn),
  lpc_narrow_v_precision = lpc_narrow_v_tp / (lpc_narrow_v_tp + lpc_narrow_v_fp),
  lpc_narrow_v_recall = lpc_narrow_v_tp / (lpc_narrow_v_tp + lpc_narrow_v_fn),
  lpc_narrow_v_f1 = 2*lpc_narrow_v_tp / (2*lpc_narrow_v_tp + lpc_narrow_v_fp + lpc_narrow_v_fn),
  lfci_narrow_v_precision = lfci_narrow_v_tp / (lfci_narrow_v_tp + lfci_narrow_v_fp),
  lfci_narrow_v_recall = lfci_narrow_v_tp / (lfci_narrow_v_tp + lfci_narrow_v_fn),
  lfci_narrow_v_f1 = 2*lfci_narrow_v_tp / (2*lfci_narrow_v_tp + lfci_narrow_v_fp + lfci_narrow_v_fn))

# Broad
df <- df %>% mutate(
  pc_broad_v_precision = pc_broad_v_tp / (pc_broad_v_tp + pc_broad_v_fp),
  pc_broad_v_recall = pc_broad_v_tp / (pc_broad_v_tp + pc_broad_v_fn),
  pc_broad_v_f1 = 2*pc_broad_v_tp / (2*pc_broad_v_tp + pc_broad_v_fp + pc_broad_v_fn),
  lpc_broad_v_precision = lpc_broad_v_tp / (lpc_broad_v_tp + lpc_broad_v_fp),
  lpc_broad_v_recall = lpc_broad_v_tp / (lpc_broad_v_tp + lpc_broad_v_fn),
  lpc_broad_v_f1 = 2*lpc_broad_v_tp / (2*lpc_broad_v_tp + lpc_broad_v_fp + lpc_broad_v_fn),
  lfci_broad_v_precision = lfci_broad_v_tp / (lfci_broad_v_tp + lfci_broad_v_fp),
  lfci_broad_v_recall = lfci_broad_v_tp / (lfci_broad_v_tp + lfci_broad_v_fn),
  lfci_broad_v_f1 = 2*lfci_broad_v_tp / (2*lfci_broad_v_tp + lfci_broad_v_fp + lfci_broad_v_fn))

### PRA

# Strict: potential (undirected edges) regarded as false negatives
df <- df %>% mutate(
  pc_pra_precision_strict = pc_pra_tp / (pc_pra_tp + pc_pra_fp),
  pc_pra_recall_strict = pc_pra_tp / (pc_pra_tp + pc_pra_fn + pc_pra_potential),
  pc_pra_f1_strict = 2*pc_pra_tp / (2*pc_pra_tp + pc_pra_fp + pc_pra_fn + pc_pra_potential),
  lpc_pra_precision_strict = lpc_pra_tp / (lpc_pra_tp + lpc_pra_fp),
  lpc_pra_recall_strict = lpc_pra_tp / (lpc_pra_tp + lpc_pra_fn + lpc_pra_potential),
  lpc_pra_f1_strict = 2*lpc_pra_tp / (2*lpc_pra_tp + lpc_pra_fp + lpc_pra_fn + lpc_pra_potential),
  lfci_pra_precision_strict = lfci_pra_tp / (lfci_pra_tp + lfci_pra_fp),
  lfci_pra_recall_strict = lfci_pra_tp / (lfci_pra_tp + lfci_pra_fn + lfci_pra_potential),
  lfci_pra_f1_strict = 2*lfci_pra_tp / (2*lfci_pra_tp + lfci_pra_fp + lfci_pra_fn + lfci_pra_potential))

# Loose: potential (undirected edges) regarded as false negatives
df <- df %>% mutate(
  pc_pra_precision_loose = (pc_pra_tp + pc_pra_potential) / (pc_pra_tp + pc_pra_potential + pc_pra_fp),
  pc_pra_recall_loose = (pc_pra_tp + pc_pra_potential) / (pc_pra_tp + pc_pra_potential + pc_pra_fn),
  pc_pra_f1_loose = 2*(pc_pra_tp + pc_pra_potential) / (2*(pc_pra_tp + pc_pra_potential) + pc_pra_fp + pc_pra_fn),
  lpc_pra_precision_loose = (lpc_pra_tp + lpc_pra_potential) / (lpc_pra_tp + lpc_pra_potential + lpc_pra_fp),
  lpc_pra_recall_loose = (lpc_pra_tp + lpc_pra_potential) / (lpc_pra_tp + lpc_pra_potential + lpc_pra_fn),
  lpc_pra_f1_loose = 2*(lpc_pra_tp + lpc_pra_potential) / (2*(lpc_pra_tp + lpc_pra_potential) + lpc_pra_fp + lpc_pra_fn),
  lfci_pra_precision_loose = (lfci_pra_tp + lfci_pra_potential) / (lpc_pra_tp + lpc_pra_potential + lfci_pra_fp),
  lfci_pra_recall_loose = (lpc_pra_tp + lpc_pra_potential) / (lpc_pra_tp + lpc_pra_potential + lfci_pra_fn),
  lfci_pra_f1_loose = 2*(lpc_pra_tp + lpc_pra_potential) / (2*(lpc_pra_tp + lpc_pra_potential) + lfci_pra_fp + lfci_pra_fn))

### MB Recovery
df <- df %>% mutate(
  mb_precision = mb_tp / (mb_tp + mb_fp),
  mb_recall = mb_tp / (mb_tp + mb_fn),
  mb_f1 = 2*mb_tp / (2*mb_tp + mb_fp + mb_fn))

### Divide small and large networks
df <- df %>%
  mutate(network_category=ifelse(p<100,"<100",">=100")) %>%
  mutate(sample_size_category=paste("Sample Size =",n))

num_nets <- length(unique(df$net))

# Save MB Metric Plots -------------------------------------------------------

mb_measures <- c("mb_tp","mb_fp","mb_fn","mb_precision","mb_recall","mb_f1",
                 "mb_children_fn","mb_children_tp","mb_parents_fn","mb_parents_tp",
                 "mb_spouses_fn","mb_spouses_tp","mb_total_fp")

sapply(mb_measures, function(measure){
  df_plot <- df %>%
    mutate(neighborhood_category=cut_number(size,2)) %>%
    select(neighborhood_category,network_category,n,mb_alpha,algo,all_of(measure)) %>%
    mutate(Algorithm=algo)
  df_plot$mb_alpha <- factor(df_plot$mb_alpha)
  levels(df_plot$mb_alpha) <- paste("Signif. Level =",unique(df_plot$mb_alpha))
  df_plot$network_category <- factor(df_plot$network_category)
  levels(df_plot$network_category) <- c("Network Size < 100",
                                        "Network Size ≥ 100")
  df_nums <- df_plot %>% count(network_category,mb_alpha)
  measure_plot <- ggplot(df_plot,aes_string(x="neighborhood_category",y=measure,fill="Algorithm"))+
    scale_fill_discrete(name="MB Algorithm",labels=c('MMPC'))+
    geom_boxplot(size=1.3)+
    facet_wrap(network_category ~ mb_alpha,
               ncol = length(unique(df_plot$mb_alpha)))+
    theme(text = element_text(size=20),legend.key.size = unit(1.2, 'cm'))
  saveRDS(measure_plot,
          paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
                 "sample_",measure,".rds"))
})

sapply(mb_measures, function(measure){
  df_plot <- df %>%
    filter(mb_alpha == 0.01) %>%
    mutate(neighborhood_category=cut_number(size,2)) %>%
    select(neighborhood_category,network_category,mb_alpha,n,algo,all_of(measure)) %>%
    mutate(Algorithm=algo)
  df_plot$mb_alpha <- factor(df_plot$mb_alpha)
  levels(df_plot$mb_alpha) <- paste("Signif. Level =",unique(df_plot$mb_alpha))
  df_plot$network_category <- factor(df_plot$network_category)
  levels(df_plot$network_category) <- c("Network Size < 100",
                                        "Network Size ≥ 100")
  df_nums <- df_plot %>% count(network_category,mb_alpha)
  measure_plot <- ggplot(df_plot,aes_string(x="neighborhood_category",y=measure,fill="Algorithm"))+
    scale_fill_discrete(name="MB Algorithm",labels=c('MMPC'))+
    geom_boxplot(size=1.3)+
    facet_wrap(mb_alpha ~ network_category,
               ncol = length(unique(df_plot$network_category)))+
    theme(text = element_text(size=20),legend.key.size = unit(1.2, 'cm'))
  saveRDS(measure_plot,
          paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
                 "sample_",measure,"_min.rds"))
})

### Save log(MB Time) by log(p)
df_plot <- df %>%
  select(totalMBEstTime,p,algo) %>%
  mutate(Algorithm=algo) %>%
  mutate(log_p=log10(p)) %>%
  mutate(log_p_bin=cut(log_p,breaks = 1:4))

mb_time_plot <- ggplot(df_plot,aes(x=log_p_bin,y=log10(totalMBEstTime),fill=Algorithm))+
  scale_fill_discrete(name="Algorithm",labels=c('MMPC'))+
  geom_boxplot()+
  xlab(TeX(r'($\log_{10}$(Network Size))'))+ylab(TeX(r'($\log_{10}$(MB Estimation Time))'))+
  ggtitle("Comparison of Runtime for\nMarkov Blanket Estimation Algorithms")+
  theme(text = element_text(size=20))

saveRDS(mb_time_plot,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "mb_time_plot_comp.rds"))

# Save Skeleton, V, PRA, and Overall F1 Metric Plots -------------------------------------------------------
df <- df %>% filter(algo=="MMPC") # MMPC is the faster of the two algorithms which are most accurate
measures <- c("narrow_v_tp","narrow_v_fn","narrow_v_fp","narrow_v_precision","narrow_v_recall","narrow_v_f1",
              "broad_v_tp","broad_v_fn","broad_v_fp","broad_v_precision","broad_v_recall","broad_v_f1",
              "narrow_skel_tp","narrow_skel_fn","narrow_skel_fp","narrow_skel_precision","narrow_skel_recall","narrow_skel_f1",
              "broad_skel_tp","broad_skel_fn","broad_skel_fp","broad_skel_precision","broad_skel_recall","broad_skel_f1",
              "pra_tp","pra_fn","pra_fp","pra_potential",
              "pra_precision_strict","pra_recall_strict","pra_f1_strict",
              "pra_precision_loose","pra_recall_loose","pra_f1_loose",
              "broad_shd","narrow_shd",
              "overall_f1")

sapply(measures,function(measure){
  if (str_detect(measure,"pra_")){
    df_plot <- df %>% filter(mb_parents_fn+mb_parents_tp>0)
  } else {
    df_plot <- df
  }
  df_plot <- df_plot %>%
    filter(mb_alpha == 0.01) %>%
    mutate(neighborhood_category=cut_number(size,2)) %>%
    select(neighborhood_category,network_category,n,alpha,paste0(c("pc_","lfci_","lpc_"),measure)) %>%
    pivot_longer(ends_with(measure),names_to = "algorithm",values_to = measure,
                 names_transform = function(x) str_extract(x,"^[a-z]{2,4}"))
  val <- measure

  df_plot$alpha <- factor(df_plot$alpha)
  levels(df_plot$alpha) <- paste("Signif. Level =",unique(df_plot$alpha))
  df_plot$network_category <- factor(df_plot$network_category)
  levels(df_plot$network_category) <- c("Network Size < 100",
                                        "Network Size ≥ 100")
  df_nums <- df_plot %>% count(network_category,alpha)
  measure_plot <- ggplot(df_plot,aes_string(x=factor(0),y=val,fill="algorithm"))+
    geom_boxplot()+
    theme(axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank())+
    scale_fill_discrete(name="Algorithm",labels=c('CML','SNL','PC'))+
    facet_wrap(network_category ~ alpha,
               ncol = length(unique(df_plot$alpha)))+
    theme(text = element_text(size=20),legend.key.size = unit(1.5, 'cm'))
  if (max(unlist(df_plot[,val]),na.rm = TRUE)>30){
    measure_plot <- measure_plot + ylim(0,20)
  }
  saveRDS(measure_plot,
          paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
                 "sample_",measure,".rds"))
})

sapply(measures,function(measure){
  if (str_detect(measure,"pra_")){
    df_plot <- df %>% filter(mb_parents_fn+mb_parents_tp>0)
  } else {
    df_plot <- df
  }
  df_plot <- df_plot %>%
    filter(mb_alpha == 0.01) %>%
    mutate(neighborhood_category=cut_number(size,2)) %>%
    select(neighborhood_category,sample_size_category,n,alpha,paste0(c("pc_","lfci_","lpc_"),measure)) %>%
    pivot_longer(ends_with(measure),names_to = "algorithm",values_to = measure,
                 names_transform = function(x) str_extract(x,"^[a-z]{2,4}"))
  val <- measure

  df_plot$alpha <- factor(df_plot$alpha)
  levels(df_plot$alpha) <- paste("Signif. Level =",unique(df_plot$alpha))
  df_plot$sample_size_category <- factor(df_plot$sample_size_category)
  levels(df_plot$sample_size_category) <- c("Sample Size = 500",
                                            "Sample Size = 1,000",
                                            "Sample Size = 10,000")
  df_nums <- df_plot %>% count(sample_size_category,alpha)
  measure_plot <- ggplot(df_plot,aes_string(x=factor(0),y=val,fill="algorithm"))+
    geom_boxplot()+
    theme(axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank())+
    scale_fill_discrete(name="Algorithm",labels=c('CML','SNL','PC'))+
    facet_wrap(sample_size_category ~ alpha,
               ncol = length(unique(df_plot$alpha)))+
    theme(text = element_text(size=20),legend.key.size = unit(1.5, 'cm'))
  saveRDS(measure_plot,
          paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
                 "sample_",measure,"_n.rds"))
})

# One more comparing overall F1 with different sample sizes
df_plot <- df
measure <- "overall_f1"
df_plot <- df_plot %>%
  filter(mb_alpha == 0.01) %>%
  filter(alpha == 0.01) %>%
  mutate(neighborhood_category=cut_number(size,2)) %>%
  select(neighborhood_category,network_category,sample_size_category,n,alpha,paste0(c("pc_","lfci_","lpc_"),measure)) %>%
  pivot_longer(ends_with(measure),names_to = "algorithm",values_to = measure,
               names_transform = function(x) str_extract(x,"^[a-z]{2,4}"))
val <- measure
df_plot$network_category <- factor(df_plot$network_category)
levels(df_plot$network_category) <- c("Network Size < 100",
                                      "Network Size ≥ 100")

df_plot$sample_size_category <- factor(df_plot$sample_size_category)
levels(df_plot$sample_size_category) <- c("Sample Size = 500",
                                          "Sample Size = 1,000",
                                          "Sample Size = 10,000")
df_nums <- df_plot %>% count(sample_size_category,network_category)
measure_plot <- ggplot(df_plot,aes_string(x=factor(0),y=val,fill="algorithm"))+
  geom_boxplot()+
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank())+
  scale_fill_discrete(name="Algorithm",labels=c('CML','SNL','PC'))+
  facet_wrap(network_category~sample_size_category)+
  theme(text = element_text(size=20),legend.key.size = unit(1.5, 'cm'))+
  ylab("Overall F1 Score")

saveRDS(measure_plot,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "sample_",measure,"2_n.rds"))

### Table with Parent Recovery

df_pra <- df %>%
  filter(mb_alpha==0.01) %>%
  select(net,p,lfci_pra_fn,lfci_pra_tp,lfci_pra_precision_strict,lfci_pra_f1_strict,lfci_pra_recall_strict) %>%
  mutate(`Total Parents`=lfci_pra_tp+lfci_pra_fn) %>%
  mutate(Network=net) %>%
  group_by(Network) %>%
  summarise(
    p = mean(p),
    `Avg. True Parents`=mean(`Total Parents`),
    `Avg. Pred. Parents`=mean(`lfci_pra_tp`),
    `Avg. PRA Precision`=mean(lfci_pra_precision_strict,na.rm = TRUE),
    `Avg. PRA Recall`=mean(lfci_pra_recall_strict,na.rm = TRUE),
    `Avg. PRA F1`=mean(lfci_pra_f1_strict,na.rm = TRUE)
  ) %>%
  arrange(p) %>%
  select(-p) %>%
  mutate(across(where(is.numeric),round,2))

saveRDS(df_pra,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "pra_summary_tab.rds"))

# Save Ancestral Metric Plots ---------------------------------------------

anc_measures <- c("ancestors_incorrect","ancestors_correct","ancestors_total")

df_plot <- df %>%
  filter(num_targets > 1) %>%
  filter(mb_alpha==0.01) %>%
  mutate(neighborhood_category=cut_number(size,2)) %>%
  select(neighborhood_category,network_category,n,alpha,lfci_ancestors_total)
df_plot$alpha <- factor(df_plot$alpha)
levels(df_plot$alpha) <- paste("Signif. Level =",unique(df_plot$alpha))
df_plot$network_category <- factor(df_plot$network_category)
levels(df_plot$network_category) <- c("Network Size < 100",
                                      "Network Size ≥ 100")
df_nums <- df_plot %>% count(network_category,alpha)
measure_plot <- ggplot(df_plot,aes(neighborhood_category,lfci_ancestors_total,fill='red'))+
  geom_boxplot(show.legend = FALSE)+
  facet_wrap(network_category ~ alpha,
             ncol = length(unique(df_plot$alpha)))+
  xlab("Neighborhood Size")+ylab("Ancestral Edges in Estimated Graph")+
  theme(text = element_text(size=20))
saveRDS(measure_plot,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "sample_ancestors_total.rds"))

# Timing Plots ------------------------------------------------------------

df_time <- result_df %>%
  filter(algo=="MMPC") %>%
  filter(mb_alpha==0.01) %>%
  select(net,p,n,size,contains("time"),contains("test"),contains("target"),contains("edge"))
cat("The dataset has",nrow(df_time),"rows and",ncol(df_time),"columns.\n")

### Compare timing of the algorithms

# log10(time) by log10(network size)
df_plot <- df_time %>%
  select(p,ends_with("_time")) %>%
  select(-mb_time) %>%
  mutate(across(!p,as.numeric)) %>%
  pivot_longer(ends_with("_time"),names_to = "algorithm",values_to = "time",
               names_transform = function(x) str_extract(x,"^[a-z]{2,4}")) %>%
  mutate(log_p = log10(p)) %>%
  mutate(log_time = log10(as.numeric(time))) %>%
  mutate(log_p_bin = cut(log_p,breaks=seq(1,4)))

time_plot <- ggplot(df_plot,aes(x=log_p_bin,y=log_time,
                                fill=algorithm))+
  scale_fill_discrete(name="Algorithm",labels=c('CML','SNL','PC'))+
  geom_boxplot()+xlab(TeX(r'($\log_{10}$(Network Size))'))+ylab(TeX(r'($\log_{10}$(Time))'))+
  theme(text = element_text(size=20),legend.key.size = unit(2, 'cm'))
measure <- "time_netsize"
saveRDS(time_plot,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "sample_",measure,".rds"))

# log10(time) by log10(MB size)
df_plot <- df_time %>%
  select(size,ends_with("_time")) %>%
  select(-mb_time) %>%
  mutate(across(!size,as.numeric)) %>%
  pivot_longer(ends_with("_time"),names_to = "algorithm",values_to = "time",
               names_transform = function(x) str_extract(x,"^[a-z]{2,4}")) %>%
  mutate(log_time = log10(as.numeric(time))) %>%
  mutate(mb_size_bin = cut(size,breaks = c(0,5,10,15,20,110)))

time_plot <- ggplot(df_plot,aes(x=mb_size_bin,y=log_time,
                                fill=algorithm))+
  scale_fill_discrete(name="Algorithm",labels=c('CML','SNL','PC'))+
  geom_boxplot()+xlab("MB size")+ylab(TeX(r'($\log_{10}$(Time))'))

measure <- "time_mbsize"
saveRDS(time_plot,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "sample_",measure,".rds"))

# log10(time) by log10(MB edges)
df_plot <- df_time %>%
  select(-mb_time) %>%
  select(num_edges,ends_with("_time")) %>%
  mutate(across(!num_edges,as.numeric)) %>%
  pivot_longer(ends_with("_time"),names_to = "algorithm",values_to = "time",
               names_transform = function(x) str_extract(x,"^[a-z]{2,4}")) %>%
  mutate(log_time = log10(as.numeric(time))) %>%
  mutate(mb_edges_bin = cut(num_edges,breaks = c(0,10,20,30,100)))

time_plot <- ggplot(df_plot,aes(x=mb_edges_bin,y=log_time,
                                fill=algorithm))+
  scale_fill_discrete(name="Algorithm",labels=c('CML','SNL','PC'))+
  geom_boxplot()+xlab("MB edges")+ylab(TeX(r'($\log_{10}$(Time))'))+
  theme(text = element_text(size=20))
measure <- "time_mbedges"
saveRDS(time_plot,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "sample_",measure,".rds"))

# log10(time) by log10(network edges)
df_plot <- df_time %>%
  select(-mb_time) %>%
  select(net_edges,ends_with("_time")) %>%
  mutate(across(!net_edges,as.numeric)) %>%
  pivot_longer(ends_with("_time"),names_to = "algorithm",values_to = "time",
               names_transform = function(x) str_extract(x,"^[a-z]{2,4}")) %>%
  mutate(log_time = log10(as.numeric(time))) %>%
  mutate(log_edges = log10(net_edges)) %>%
  mutate(log_edges_bin = cut(log_edges,breaks = seq(1,4)))

time_plot <- ggplot(df_plot,aes(x=log_edges_bin,y=log_time,
                                fill=algorithm))+
  scale_fill_discrete(name="Algorithm",labels=c('CML','SNL','PC'))+
  geom_boxplot()+xlab(TeX(r'($\log_{10}$(Network Size))'))+ylab(TeX(r'($\log_{10}$(Time))'))+
  theme(text = element_text(size=20),legend.key.size = unit(2, 'cm'))
measure <- "time_netedges"
saveRDS(time_plot,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "sample_",measure,".rds"))

# log10(time) by log10(sample size)
df_plot <- df_time %>%
  select(-mb_time) %>%
  select(n,ends_with("_time")) %>%
  mutate(across(!n,as.numeric)) %>%
  pivot_longer(ends_with("_time"),names_to = "algorithm",values_to = "time",
               names_transform = function(x) str_extract(x,"^[a-z]{2,4}")) %>%
  mutate(log_time = log10(as.numeric(time))) %>%
  mutate(log_n = log10(n)) %>%
  mutate(log_n_bin = cut(log_n,breaks = seq(1,4)))

time_plot <- ggplot(df_plot,aes(x=log_n_bin,y=log_time,
                                fill=algorithm))+
  scale_fill_discrete(name="Algorithm",labels=c('CML','SNL','PC'))+
  geom_boxplot()+xlab(TeX(r'($\log_{10}$(Sample Size))'))+ylab(TeX(r'($\log_{10}$(Time))'))+
  theme(text = element_text(size=20),legend.key.size = unit(2, 'cm'))
measure <- "time_n"
saveRDS(time_plot,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "sample_",measure,".rds"))


# Testing Plots -----------------------------------------------------------

### Compare number of tests for the algorithms
df_tests <- df_time
# log10(tests) by log10(network size)
df_plot <- df_tests %>%
  select(p,ends_with("_tests")) %>%
  pivot_longer(ends_with("_tests"),names_to = "algorithm",values_to = "tests",
               names_transform = function(x) str_extract(x,"^[a-z]{2,4}")) %>%
  mutate(log_p = log10(p)) %>%
  mutate(log_tests = log10(as.numeric(tests))) %>%
  mutate(log_p_bin = cut(log_p,breaks=seq(1,4)))

tests_plot <- ggplot(df_plot,aes(x=log_p_bin,y=log_tests,
                                 fill=algorithm))+
  scale_fill_discrete(name="Algorithm",labels=c('CML','SNL','PC'))+
  geom_boxplot()+xlab(TeX(r'($\log_{10}$(Network Size))'))+ylab(TeX(r'($\log_{10}$(Tests))'))+
  theme(text = element_text(size=20),legend.key.size = unit(2, 'cm'))
measure <- "tests_netsize"
saveRDS(tests_plot,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "sample_",measure,".rds"))

# log10(tests) by log10(MB size)
df_plot <- df_tests %>%
  select(size,ends_with("_tests")) %>%
  pivot_longer(ends_with("_tests"),names_to = "algorithm",values_to = "tests",
               names_transform = function(x) str_extract(x,"^[a-z]{2,4}")) %>%
  mutate(log_tests = log10(as.numeric(tests))) %>%
  mutate(mb_size_bin = cut(size,breaks = c(0,5,10,15,20,110)))

tests_plot <- ggplot(df_plot,aes(x=mb_size_bin,y=log_tests,
                                 fill=algorithm))+
  scale_fill_discrete(name="Algorithm",labels=c('CML','SNL','PC'))+
  geom_boxplot()+xlab("MB size")+ylab(TeX(r'($\log_{10}$(Tests))'))+
  theme(text = element_text(size=20))
measure <- "tests_mbsize"
saveRDS(tests_plot,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "sample_",measure,".rds"))

# log10(tests) by log10(MB edges)
df_plot <- df_tests %>%
  select(num_edges,ends_with("_tests")) %>%
  pivot_longer(ends_with("_tests"),names_to = "algorithm",values_to = "tests",
               names_transform = function(x) str_extract(x,"^[a-z]{2,4}")) %>%
  mutate(log_tests = log10(as.numeric(tests))) %>%
  mutate(mb_edges_bin = cut(num_edges,breaks = c(0,10,20,30,200)))

tests_plot <- ggplot(df_plot,aes(x=mb_edges_bin,y=log_tests,
                                 fill=algorithm))+
  scale_fill_discrete(name="Algorithm",labels=c('CML','SNL','PC'))+
  geom_boxplot()+xlab("MB edges")+ylab(TeX(r'($\log_{10}$(Tests))'))+
  theme(text = element_text(size=20))
measure <- "tests_mbedges"
saveRDS(tests_plot,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "sample_",measure,".rds"))

# log10(tests) by log10(network edges)
df_plot <- df_tests %>%
  select(net_edges,ends_with("_tests")) %>%
  pivot_longer(ends_with("_tests"),names_to = "algorithm",values_to = "tests",
               names_transform = function(x) str_extract(x,"^[a-z]{2,4}")) %>%
  mutate(log_tests = log10(as.numeric(tests))) %>%
  mutate(log_edges = log10(net_edges)) %>%
  mutate(log_edges_bin = cut(log_edges,breaks = seq(1,4)))

tests_plot <- ggplot(df_plot,aes(x=log_edges_bin,y=log_tests,
                                 fill=algorithm))+
  scale_fill_discrete(name="Algorithm",labels=c('CML','SNL','PC'))+
  geom_boxplot()+xlab(TeX(r'($\log_{10}$(Network Edges))'))+ylab(TeX(r'($\log_{10}$(Tests))'))+
  theme(text = element_text(size=20))
measure <- "tests_netedges"
saveRDS(tests_plot,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "sample_",measure,".rds"))

# Timing Breakdown --------------------------------------------------------

df_split_time <- df_time %>%
  group_by(net) %>%
  summarise(meanMBEst=mean(totalMBEstTime),
            meanSkeletonTotal=mean(totalSkeletonTime),
            meanSkeletonTarget=mean(targetSkeletonTotalTime)) %>%
  pivot_longer(!net, names_to = "Algorithm Step",values_to = "time")
time_plot <- ggplot(df_split_time,aes(fill=`Algorithm Step`,y=time,x=net))+
  geom_bar(position = "stack",stat = "identity")+
  theme(text = element_text(size=20))
saveRDS(time_plot,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "time_breakdown_bar.rds"))

df_split_time <- df_time %>%
  select(p,totalMBEstTimeInclusive,totalSkeletonTime,targetSkeletonTotalTime) %>%
  pivot_longer(!p,names_to = "Algorithm Step",values_to = "time") %>%
  mutate(log_p = log10(p)) %>%
  mutate(log_p_bin=cut(log_p,breaks = seq(1,4)))
time_plot <- ggplot(df_split_time,aes(fill=`Algorithm Step`,y=log10(time),x=log_p_bin))+
  geom_boxplot()+
  theme(text = element_text(size=20))

saveRDS(time_plot,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "time_breakdown.rds"))

# Save Metric Tables ------------------------------------------------------

### Overall F1 Table

results_f1 <- df %>%
  mutate(Network=net) %>%
  group_by(Network) %>%
  summarise(`Network Size`=mean(p),
            Simulations=n(),
            `Overall F1 LFCI`=mean(lfci_overall_f1),
            `Overall F1 LPC`=mean(lpc_overall_f1),
            `Overall F1 PC`=mean(pc_overall_f1),
            `LFCI Avg. % Improvement`=100*(`Overall F1 LFCI`-`Overall F1 PC`)/`Overall F1 PC`) %>%
  mutate(across(where(is.numeric),round,2)) %>%
  arrange(`Network Size`)
results_f1

saveRDS(results_f1,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "sample_f1mean_table.rds"))

# Repeat but with uniform number of simulations
results_f1 <- df %>%
  filter(net!="pathfinder") %>%
  group_by(net) %>%
  sample_n(size = 400) %>%
  summarise(`Network Size`=mean(p),
            Simulations=n(),
            `Mean Overall F1 LFCI`=mean(lfci_overall_f1),
            `Mean Overall F1 LPC`=mean(lpc_overall_f1),
            `Mean Overall F1 PC`=mean(pc_overall_f1),
            `LFCI Avg. Percent Improvement`=100*(`Mean Overall F1 LFCI`-`Mean Overall F1 PC`)/`Mean Overall F1 PC`) %>%
  mutate(across(where(is.numeric),round,2)) %>%
  arrange(`Network Size`)
results_f1

# Save Timing Tables ------------------------------------------------------

results_timing <- df %>%
  mutate(Network=net) %>%
  group_by(Network) %>%
  summarise(`Network Size`=median(p),
            Simulations=n(),
            `Mean Time LFCI (sec)`=median(as.numeric(lfci_time)),
            `Mean Time LPC (sec)`=median(as.numeric(lpc_time)),
            `Mean Time PC (sec)`=median(as.numeric(pc_time)),
            `Perc. Improvement`=mean(-1*as.numeric(lfci_time-pc_time)*100/as.numeric(pc_time))) %>%
  mutate(across(where(is.numeric),round,2)) %>%
  arrange(`Network Size`)

saveRDS(results_timing,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "sample_mean_time_table.rds"))

df %>%
  mutate(logp=log10(p)) %>%
  mutate(logSize=cut(logp,breaks = 1:4)) %>%
  group_by(logSize) %>%
  summarise(`Median Time LFCI (sec)`=median(log10(as.numeric(lfci_time))),
            `Median Time LPC (sec)`=median(log10(as.numeric(lpc_time))),
            `Median Time PC (sec)`=median(log10(as.numeric(pc_time))))

df %>%
  mutate(logp=log10(p)) %>%
  mutate(logSize=cut(logp,breaks = 1:4)) %>%
  group_by(logSize) %>%
  summarise(`Median Tests LFCI`=median(log10(lfci_num_tests)),
            `Median Tests LPC`=median(log10(lpc_num_tests)),
            `Median Tests PC`=median(log10(pc_num_tests),na.rm=TRUE))

df %>%
  mutate(logp=log10(p)) %>%
  mutate(logSize=cut(logp,breaks = 1:4)) %>%
  filter(algo=="PC") %>%
  group_by(net,n,mb_alpha,alpha) %>%
  summarise(logSize=mean(logSize),pc_time=median(pc_time)) %>%
  ungroup() %>%
  group_by(logSize) %>%
  summarise(`Median Time PC (sec)`=median(log10(as.numeric(pc_time))))


results_testing <- df %>%
  mutate(Network=net) %>%
  group_by(Network) %>%
  summarise(`Network Size`=median(p),
            Simulations=n(),
            `Mean Tests LFCI`=mean(lfci_num_tests),
            `Mean Tests LPC`=mean(lpc_num_tests),
            `Mean Tests PC`=mean(pc_num_tests),
            `Perc. Improvement`=mean(-1*as.numeric(lfci_time-pc_time)*100/as.numeric(pc_time))) %>%
  mutate(across(where(is.numeric),round,2)) %>%
  arrange(`Network Size`)

saveRDS(results_testing,
        paste0("~/Dropbox/Academics/Research/Reports/",folder_name,"/",
               "sample_mean_tests_table.rds"))


# Rule Usage --------------------------------------------------------------

rules_df <- result_df %>% select(contains("rule"))

# This is per run
rules_df %>%
  summarise(`V-Struct`=median(rule0),
            `Rule 1`=mean(rule1),
            `Rule 2`=mean(rule2),
            `Rule 3`=mean(rule3),
            `Rule 4`=mean(rule4),
            `Rule 5`=mean(rule5),
            `Rule 6`=mean(rule6),
            `Rule 7`=mean(rule7),
            `Rule 8`=mean(rule8),
            `Rule 9`=mean(rule9),
            `Rule 10`=mean(rule10))

rules_df %>%
  summarise(`V-Struct`=median(lpc_rule0),
            `Rule 1`=mean(lpc_rule1),
            `Rule 2`=mean(lpc_rule2),
            `Rule 3`=mean(lpc_rule3),
            `Rule 4`=mean(lpc_rule4))


# Total Amounts -----------------------------------------------------------

median_overall_f1 <- df %>% filter(algo=="MMPC") %>%
  filter(mb_alpha==0.01) %>%
  filter(alpha==0.01) %>%
  filter(p >= 100) %>%
  summarise(cml = median(lfci_overall_f1), pc=median(pc_overall_f1), snl=median(lpc_overall_f1))

small_median_overall_f1 <- df %>% filter(algo=="MMPC") %>%
  filter(mb_alpha==0.01) %>%
  filter(alpha==0.01) %>%
  filter(p < 100) %>%
  summarise(cml = median(lfci_overall_f1), pc=median(pc_overall_f1), snl=median(lpc_overall_f1))

# Ancestors ---------------------------------------------------------------

df %>%
  group_by(net,num_targets) %>%
  summarise(p=mean(p),`Median Ancestral Edges`=median(lfci_ancestors_total)) %>%
  pivot_wider(names_from = num_targets,values_from = `Median Ancestral Edges`) %>%
  arrange(p) %>% kable('latex')
