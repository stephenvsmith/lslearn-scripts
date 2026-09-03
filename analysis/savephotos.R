### Applies axis labels/styling to the plot .rds files saved by
### compile_results_sample.R and extraplots.R, and exports them (plus any
### result tables) as .eps/.pdf for use in reports.

library(tidyverse)
library(latex2exp)
library(kableExtra)
theme_set(theme_classic())
setwd("~/Dropbox/Academics/Research/Reports/October 2025/")
f <- list.files(pattern="*.rds")

axis_labels <- list(
  "mb_time_plot_comp.rds"=list("xlab"=TeX(r'($\log_{10}$(Network Size))'),
                               "ylab"=TeX(r'($\log_{10}$(Mb Estimation Time))')),
  "sample_broad_skel_f1.rds"=list("ylab"="Skeleton F1 Score (Broad)"),
  "sample_broad_skel_fn.rds"=list("ylab"="Skeleton False Negatives (Broad)"),
  "sample_broad_skel_fp.rds"=list("ylab"="Skeleton False Positives"),
  "sample_broad_skel_precision.rds"=list("ylab"="Skeleton Precision (Broad)"),
  "sample_broad_skel_recall.rds"=list("ylab"="Skeleton Recall (Broad)"),
  "sample_broad_skel_tp.rds"=list("ylab"="Skeleton True Positives (Broad)"),
  "sample_broad_v_f1.rds"=list("ylab"="v-Structures F1 Score (Broad)"),
  "sample_broad_v_fn.rds"=list("ylab"="v-Structures False Negatives (Broad)"),
  "sample_broad_v_fp.rds"=list("ylab"="v-Structures False Positives (Broad)"),
  "sample_broad_v_precision.rds"=list("ylab"="v-Structures Precision (Broad)"),
  "sample_broad_v_recall.rds"=list("ylab"="v-Structures Recall (Broad)"),
  "sample_broad_v_tp.rds"=list("ylab"="v-Structures True Positives (Broad)"),
  "sample_narrow_v_f1.rds"=list("ylab"="v-Structures F1 Score"),
  "sample_narrow_v_fn.rds"=list("ylab"="v-Structures False Negatives (Narrow)"),
  "sample_narrow_v_fp.rds"=list("ylab"="v-Structures False Positives (Narrow)"),
  "sample_narrow_v_precision.rds"=list("ylab"="v-Structures Precision"),
  "sample_narrow_v_recall.rds"=list("ylab"="v-Structures Recall"),
  "sample_narrow_v_tp.rds"=list("ylab"="v-Structures True Positives (Narrow)"),
  "sample_narrow_skel_f1.rds"=list("ylab"="Skeleton F1 Score"),
  "sample_narrow_skel_fn.rds"=list("ylab"="Skeleton False Negatives"),
  "sample_narrow_skel_fp.rds"=list("ylab"="Skeleton False Positives (Narrow)"),
  "sample_narrow_skel_precision.rds"=list("ylab"="Skeleton Precision"),
  "sample_narrow_skel_recall.rds"=list("ylab"="Skeleton Recall"),
  "sample_narrow_skel_tp.rds"=list("ylab"="Skeleton True Positives (Narrow)"),
  "sample_narrow_shd.rds"=list("ylab"="SHD"),
  "sample_broad_shd.rds"=list("ylab"="SHD (Broad)"),
  "sample_mb_children_fn.rds"=list("ylab"="Mb Recovery Children False Negatives","xlab"="Neighborhood Size"),
  "sample_mb_children_tp.rds"=list("ylab"="Mb Recovery Children True Positives","xlab"="Neighborhood Size"),
  "sample_mb_parents_fn.rds"=list("ylab"="Mb Recovery Parents False Negatives","xlab"="Neighborhood Size"),
  "sample_mb_parents_tp.rds"=list("ylab"="Mb Recovery Parents True Positives","xlab"="Neighborhood Size"),
  "sample_mb_spouses_fn.rds"=list("ylab"="Mb Recovery Spouses False Negatives","xlab"="Neighborhood Size"),
  "sample_mb_spouses_tp.rds"=list("ylab"="Mb Recovery Spouses True Positives","xlab"="Neighborhood Size"),
  "sample_mb_f1.rds"=list("ylab"="Mb Recovery F1 Score","xlab"="Neighborhood Size"),
  "sample_mb_fn.rds"=list("ylab"="Mb Recovery False Negatives","xlab"="Neighborhood Size"),
  "sample_mb_fp.rds"=list("ylab"="Mb Recovery False Positives","xlab"="Neighborhood Size"),
  "sample_mb_tp.rds"=list("ylab"="Mb Recovery True Positives","xlab"="Neighborhood Size"),
  "sample_mb_precision.rds"=list("ylab"="Mb Recovery Precision","xlab"="Neighborhood Size"),
  "sample_mb_recall.rds"=list("ylab"="Mb Recovery Recall","xlab"="Neighborhood Size"),
  "sample_pra_precision_loose.rds"=list("ylab"="Parent Recovery Precision (Loose)"),
  "sample_pra_precision_strict.rds"=list("ylab"="Parent Recovery Precision (Strict)"),
  "sample_pra_potential.rds"=list("ylab"="Parent Recovery Potential Parents"),
  "sample_pra_fn.rds"=list("ylab"="Parent Recovery False Negatives"),
  "sample_pra_fp.rds"=list("ylab"="Parent Recovery False Positives"),
  "sample_pra_tp.rds"=list("ylab"="Parent Recovery True Positives"),
  "sample_pra_f1_loose.rds"=list("ylab"="Neighbor Recovery F1"),
  "sample_pra_f1_strict.rds"=list("ylab"="Parent Recovery F1"),
  "sample_pra_recall_loose.rds"=list("ylab"="Neighbor Recovery Recall"),
  "sample_pra_recall_strict.rds"=list("ylab"="Parent Recovery Recall"),
  "sample_overall_f1.rds"=list("ylab"="Overall F1 Score")
)

sapply(f,function(x){
  if (!(endsWith(x,"table.rds") || endsWith(x,"tab.rds"))){
    plot <- readRDS(x)
    if (endsWith(x,"_n.rds")){
      x_n <- sub("_n","",x)
    } else {
      x_n <- x
    }
    x_label = axis_labels[[x_n]]$xlab
    y_label = axis_labels[[x_n]]$ylab
    if (length(x_label)>0){
      plot <- plot + xlab(x_label)
    }
    if (length(y_label)>0){
      plot <- plot + ylab(y_label)
    }
    if (x %in% c("sample_tests_netsize.rds")){
      plot <- plot + theme(legend.position = "none")
    }
    if (x %in% c("sample_mb_fp.rds","sample_mb_fn.rds")){
      plot <- plot +
        theme(legend.position = "none")+
        xlab("Neighborhood Size")
      if (x == "sample_mb_fp.rds"){
        plot <- plot + ylim(0,25) + ylab("Mb Recovery False Positives")
      } else {
        plot <- plot + ylab("Mb Recovery False Negatives")
      }
    }

    if (x %in% c("sample_broad_skel_fn.rds","sample_broad_skel_fp.rds")){
      if (x == "sample_broad_skel_fn.rds"){
        plot <- plot + ylim(0,15)
      } else {
        plot <- plot + ylim(0,10)
      }
    }
    plot <- plot + theme(legend.key.size = unit(1.5, 'cm'), #change legend key size
                         legend.key.height = unit(1.5, 'cm'), #change legend key height
                         legend.key.width = unit(1.5, 'cm'), #change legend key width
                         legend.title = element_text(size=18), #change legend title font size
                         legend.text = element_text(size=18),
                         text=element_text(size=18))
    name <- paste0("~/Desktop/photos_new/",sub("\\.rds","",x),".eps")
    ggsave(name,plot = plot,width = 9.5,dpi = 320,device = cairo_ps)
  }
})

sapply(f,function(x){
  if (endsWith(x,"table.rds")){
    tab <- readRDS(x)
    name <- paste0("~/Desktop/photos_new_new/",sub("\\.rds","",x),".pdf")
    latex_str <- kable(tab,'latex')
    pre_string <- paste0("\\begin{table}[!h]\n\\centering\n\\caption{",sub("\\.rds","",x),
                         "} \\label{tab:",sub("\\.rds","",x),"}")
    cat(pre_string,file = "~/Desktop/photos_new/table_str.txt",append = TRUE)
    cat(latex_str,file = "~/Desktop/photos_new/table_str.txt",append = TRUE)
    cat("\\end{table}",file = "~/Desktop/photos_new/table_str.txt",append = TRUE)
    cat("\n\n",file = "~/Desktop/photos_new/table_str.txt",append = TRUE)
  }
})

sapply(f,function(x){
  if (!endsWith(x,"table.rds")){
    plot <- readRDS(x)
    name <- sub("\\.rds","",x)
    f <- "~/Desktop/photos_new/figure_text.txt"
    txt <- paste0("\\begin{figure*}\n\\centering\n\\includegraphics[scale=0.35]{",name,"}\n",
                  "\\caption{}\n\\label{fig:",name,"}\n\\end{figure*}\n\n\\newpage\n\n")
    cat(txt,file = f,append = TRUE)
  }
})
