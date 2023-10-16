if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
  BiocManager::install("ggtree")
  BiocManager::install("Biostrings")

library("ggtree")
library("ape")
library("ggplot2")
library(tidyverse)
  
# metadata <- read.csv("data/COVID_Ireland.csv")

tree <- read.tree("data/COVID_Ireland.MAPLE_output_tree.tree")
tree1 <- full_join(as_tibble(tree), groups, by = c('label' = 'ID'))
tree2 <- as.treedata(tree1)

phyloTree <- ggtree(tree2)  + geom_treescale() + geom_tiplab(aes(color = Organism_Name))

ggsave(filename = "COVID_Ireland.pdf", plot = phyloTree)