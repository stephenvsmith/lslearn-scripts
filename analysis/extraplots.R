### Ad-hoc extra plots, run after compile_results_sample.R has built `df`.

measure <- "broad_skel_fp"
df_plot <- df %>%
  filter(alpha == 0.01) %>%
  mutate(neighborhood_category=cut_number(size,2)) %>%
  select(neighborhood_category,network_category,n,mb_alpha,paste0(c("pc_","lfci_","lpc_"),measure)) %>%
  pivot_longer(ends_with(measure),names_to = "algorithm",values_to = measure,
               names_transform = function(x) str_extract(x,"^[a-z]{2,4}"))
val <- measure

df_plot$mb_alpha <- factor(df_plot$mb_alpha)
levels(df_plot$mb_alpha) <- paste("Mb Signif. Lev. =",unique(df_plot$mb_alpha))
df_plot$network_category <- factor(df_plot$network_category)
levels(df_plot$network_category) <- c("Network Size < 100",
                                      "Network Size ≥ 100")
df_nums <- df_plot %>% count(network_category,mb_alpha)
measure_plot <- ggplot(df_plot,aes_string(x=factor(0),y=val,fill="algorithm"))+
  geom_boxplot()+
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank())+
  scale_fill_discrete(name="Algorithm",labels=c('CML','SNL','PC'))+
  facet_wrap(network_category ~ mb_alpha,
             ncol = length(unique(df_plot$mb_alpha)))+
  theme(text = element_text(size=20),legend.key.size = unit(1.5, 'cm'))

measure_plot <- measure_plot + ylim(0,10)
measure_plot <- measure_plot + ylab("Skeleton False Positives")
name <- paste0("~/Desktop/photos/sample_broad_skel_fp.eps")
ggsave(name,plot = measure_plot,width = 9.5,dpi = 320,device = cairo_ps)

measure <- "narrow_skel_fn"
df_plot <- df %>%
  filter(alpha == 0.01) %>%
  mutate(neighborhood_category=cut_number(size,2)) %>%
  select(neighborhood_category,network_category,n,mb_alpha,paste0(c("pc_","lfci_","lpc_"),measure)) %>%
  pivot_longer(ends_with(measure),names_to = "algorithm",values_to = measure,
               names_transform = function(x) str_extract(x,"^[a-z]{2,4}"))
val <- measure

df_plot$mb_alpha <- factor(df_plot$mb_alpha)
levels(df_plot$mb_alpha) <- paste("Mb Signif. Lev. =",unique(df_plot$mb_alpha))
df_plot$network_category <- factor(df_plot$network_category)
levels(df_plot$network_category) <- c("Network Size < 100",
                                      "Network Size ≥ 100")
df_nums <- df_plot %>% count(network_category,mb_alpha)
measure_plot <- ggplot(df_plot,aes_string(x=factor(0),y=val,fill="algorithm"))+
  geom_boxplot()+
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank())+
  scale_fill_discrete(name="Algorithm",labels=c('CML','SNL','PC'))+
  facet_wrap(network_category ~ mb_alpha,
             ncol = length(unique(df_plot$mb_alpha)))+
  theme(text = element_text(size=20),legend.key.size = unit(1.5, 'cm'))

measure_plot <- measure_plot + ylab("Skeleton False Negatives")
name <- paste0("~/Desktop/photos/sample_narrow_skel_fn.eps")
ggsave(name,plot = measure_plot,width = 9.5,dpi = 320,device = cairo_ps)
