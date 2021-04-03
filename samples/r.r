library(bipartite)
library(tidyverse)
library(purrrlyr)
library(ape)
library(caper)
library(vegan)
library(GGally)

source("funcs.R")
setwd("./saturniidae/")


### データ：系統樹 ###########################################################
tree <- read.nexus("silk19.tree")
tree$tip.label[21] <- "Copaxa_sp."
tree$tip.label[29] <- "Eubergia_caisa"

lis_taxa <- read.csv("tip.csv") %>%
    separate(
        col = tip,
        into = c("genus", "species"),
        sep = "_",
        remove = F,
        fill = "warn"
    )

dropper <- as.character(lis_taxa$tip)[lis_taxa$drop == 1]
outgroup <- as.character(lis_taxa$genus)[lis_taxa$outgroup == 1]

tree <- drop.tip(tree, dropper)
tree$tip.label <- lis_taxa$genus[lis_taxa$drop == 0]

ages <- tipager(tree)
ages <- ages[!ages$tip %in% outgroup, ] %>%
    as_tibble()





### データ：種数~多様化率 ###############################################

sr <- read.table("nsp_silk.txt", sep = " ") %>%
    dplyr::select(V3, V4)
names(sr) <- c("genus", "richness")
sr

sr$richness <- as.numeric(as.character(sr$richness))


df_div <- left_join(ages, sr, c("tip" = "genus")) %>%
    mutate(
        e00 = (1 / age) * log(richness * (1 - 0.0) + 0.0),
        e05 = (1 / age) * log(richness * (1 - 0.5) + 0.5),
        e09 = (1 / age) * log(richness * (1 - 0.9) + 0.9)
    )

head(df_div)
# # A tibble: 6 x 6
# tip            age richness    e00    e05     e09
# <chr>        <dbl>    <dbl>  <dbl>  <dbl>   <dbl>
# 1 Actias        33.0       11 0.0726 0.0543 0.0210
# 2 Opodiphthera  33.0        7 0.0589 0.0420 0.0142
# 3 Copaxa        35.0       32 0.0991 0.0802 0.0404
# 4 Saturnia      35.0        5 0.0460 0.0314 0.00963

cor.test(df_div$age, df_div$richness)





### データ：食性 ###############################################
load(file = "host0213.Rdata") # host
df_host <- do.call(rbind, host)

df_host_ed <- host_edit(data = df_host, show_rejected = F)

indice_diet <- indicer_diet(data = df_host_ed)
indice_network <- indicer_network(data = df_host_ed)

df_diet <- indicer_table(diet = indice_diet, network = indice_network)






### PGLS #################################################
df_analysis <- left_join(df_div, df_diet, by = c("tip" = "lepi_genus")) %>%
    as.data.frame()

var_y <- c("e00", "e05", "e09")
var_x <- c("q90", "q75", "alph", "sia", "nodf", "bzsc", "beta", "mdlr")


result_pgls <- pgls_summarize(
    phy = tree,
    data = df_analysis,
    variables_y = var_y,
    variables_x = var_x,
    names_col = "tip",
    warn_dropped = T,
    vcv = T
)

result_pgls

timestampe <- str_extract(Sys.time(), "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}") %>%
    gsub(pattern = " ", replacement = "_", x = .) %>%
    gsub(pattern = ":", replacement = "_", x = .) %>%
    gsub(pattern = "-", replacement = "_", x = .)

save(
    result_pgls,
    file = paste(c("silk_result_", timestampe, ".Rdata"),
        collapse = ""
    )
)