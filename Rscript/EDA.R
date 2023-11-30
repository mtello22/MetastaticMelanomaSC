library(data.table)
library(ggplot2)
library(tidyverse)
library(Rtsne)


setwd("~/GitHub/MetastaticMelanomaSC/Data/")

sc_metadata <- fread("GSE72056_melanoma_single_cell_revised_v2.tsv", nrows = 3, header = TRUE, drop = 1)
sc_metadata <- data.table(names(sc_metadata), data.table:::transpose(sc_metadata))
names(sc_metadata) <- c("cell_id", "tumor_id", "malignant", "nm_celltype")
sc_metadata[, tumor_id := factor(tumor_id)]
sc_metadata[, malignant := factor(malignant, levels = c("1", "2", "0"), labels = c("No", "Yes", "Unresolved"))]

cell_type <- data.table(code = seq(0,6,1), cell = c("T-cell", "B-cell", "Macrophage", "Endothelial", "CAF", "NaturalKiller", "Unresolved"), key = "code")
sc_metadata <- merge(sc_metadata, cell_type, by.x = "nm_celltype", by.y = "code", all.x = TRUE)
sc_metadata[,cell := factor(cell)]
sc_metadata[,nm_celltype := NULL]

sample_metadata <- fread("sample_metadata.tsv")




scexp <- fread("GSE72056_melanoma_single_cell_revised_v2.tsv", header = TRUE)
scexp <- scexp[4:nrow(scexp),]
setnames(scexp, "Cell", "Gene")
all_genes <- scexp$Gene
scexp <- as.matrix(scexp[, .SD, .SDcols = !"Gene"])

## Reproduce 1C for malignant cells
fig1c_id <- c("78","79","80","81","84","88")
scexp_tsne <- scexp[,colnames(scexp) %in% sc_metadata[malignant == "Yes" & tumor_id %in% fig1c_id, cell_id]]
# scexp_tsne <- scexp[,colnames(scexp) %in% sc_metadata[malignant == "Yes", cell_id]]
scexp_tsne <- t(scexp_tsne)
tsne_plot <- Rtsne(scexp_tsne, partial_pca = TRUE, verbose = TRUE, num_threads = 6)
tsne_plot <- data.frame(cell_id = rownames(scexp_tsne), 
                        x = tsne_plot$Y[,1], 
                        y = tsne_plot$Y[,2])
tsne_plot <- merge.data.table(tsne_plot, sc_metadata, by = "cell_id")
ggplot(tsne_plot) + 
  geom_point(aes(x,y, color = tumor_id))


# Reproduce 1D for nonmalignant cells
# scexp_tsne <- scexp[,colnames(scexp) %in% sc_metadata[malignant == "No" & cell != "Unresolved", cell_id]]
scexp_tsne <- scexp[,colnames(scexp) %in% sc_metadata[malignant == "No", cell_id]]
scexp_tsne <- t(scexp_tsne)
tsne_plot <- Rtsne(scexp_tsne, partial_pca = TRUE, verbose = TRUE, num_threads = 6)
tsne_plot <- data.frame(cell_id = rownames(scexp_tsne), 
                        x = tsne_plot$Y[,1], 
                        y = tsne_plot$Y[,2])
tsne_plot <- merge.data.table(tsne_plot, sc_metadata, by = "cell_id")
ggplot(tsne_plot) + 
  geom_point(aes(x,y, color = cell))





library(ggplot2)
ggplot(sc_metadata[cell != "Unresolved" & malignant != "Unresolved"], aes(x = tumor_id, fill = malignant)) +
  geom_bar(position = position_dodge())


ggplot(sc_metadata[cell != "Unresolved" & malignant != "Unresolved"], aes(x = tumor_id, fill = cell)) +
  geom_bar(position = position_dodge()) +
  facet_wrap(~malignant, scales = "free",nrow = 2)

# Given that most cell types classified as malignant are classified as T-cells I will remove T-cells from the non malignant group

training_metadata <- sc_metadata[cell != "Unresolved" & malignant != "Unresolved"]
training_metadata <- training_metadata[!(cell == "T-cell" & malignant == "No")]
training_metadata <- training_metadata[!(cell != "T-cell" & malignant == "Yes")]
training_data <- scexp[,colnames(scexp) %in% training_metadata[,cell_id]]
# scexp_tsne <- scexp[,colnames(scexp) %in% sc_metadata[malignant == "Yes", cell_id]]
training_data <- t(training_data)
tsne_plot <- Rtsne(training_data, partial_pca = TRUE, verbose = TRUE, num_threads = 6)
tsne_plot <- data.frame(cell_id = rownames(training_data), 
                        x = tsne_plot$Y[,1], 
                        y = tsne_plot$Y[,2])
tsne_plot <- merge.data.table(tsne_plot, training_metadata, by = "cell_id")
ggplot(tsne_plot) + 
  geom_point(aes(x,y, color = cell))

colnames(training_data) <- all_genes
training_data <- data.table(cell_id = rownames(training_data), training_data)
training_data <- merge.data.table(training_metadata, training_data, by = "cell_id")
training_data[,1:6]








