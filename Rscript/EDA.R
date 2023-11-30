library(data.table)
library(ggplot2)
library(Rtsne)
library(biomaRt)


setwd("~/GitHub/MetastaticMelanomaSC/Data/")

# Read header of the file for metadata
sc_metadata <- fread("GSE72056_melanoma_single_cell_revised_v2.tsv", nrows = 3, header = TRUE, drop = 1)
sc_metadata <- data.table(names(sc_metadata), data.table:::transpose(sc_metadata))
# Change colnames
names(sc_metadata) <- c("cell_id", "tumor_id", "malignant", "nm_celltype")
sc_metadata[, tumor_id := factor(tumor_id)]
# Create descriptive values for malignant status
sc_metadata[, malignant := factor(malignant, levels = c("1", "2", "0"), labels = c("No", "Yes", "Unresolved"))]
# Create descriptive values for cell type
cell_type <- data.table(code = seq(0,6,1), cell = c("T-cell", "B-cell", "Macrophage", "Endothelial", "CAF", "NaturalKiller", "Unresolved"), key = "code")
sc_metadata <- merge(sc_metadata, cell_type, by.x = "nm_celltype", by.y = "code", all.x = TRUE)
sc_metadata[,cell := factor(cell)]
sc_metadata[,nm_celltype := NULL]


# Load donor metadata
sample_metadata <- fread("sample_metadata.tsv")

# Load sc expression data
scexp <- fread("GSE72056_melanoma_single_cell_revised_v2.tsv", header = TRUE)
scexp <- scexp[4:nrow(scexp),]
setnames(scexp, "Cell", "Gene")
# Save gene names for later use
all_genes <- scexp$Gene
# Convert to matrix
scexp <- as.matrix(scexp[, .SD, .SDcols = !"Gene"])

# #### Reproduce fig 1C for malignant cells ####
# fig1c_id <- c("78","79","80","81","84","88")
# scexp_tsne <- scexp[,colnames(scexp) %in% sc_metadata[malignant == "Yes" & tumor_id %in% fig1c_id, cell_id]]
# # scexp_tsne <- scexp[,colnames(scexp) %in% sc_metadata[malignant == "Yes", cell_id]]
# scexp_tsne <- t(scexp_tsne)
# tsne_plot <- Rtsne(scexp_tsne, partial_pca = TRUE, verbose = TRUE, num_threads = 6)
# tsne_plot <- data.frame(cell_id = rownames(scexp_tsne), 
#                         x = tsne_plot$Y[,1], 
#                         y = tsne_plot$Y[,2])
# tsne_plot <- merge.data.table(tsne_plot, sc_metadata, by = "cell_id")
# ggplot(tsne_plot) + 
#   geom_point(aes(x,y, color = tumor_id))
# 
# #### Reproduce fig 1D for nonmalignant cells ####
# # scexp_tsne <- scexp[,colnames(scexp) %in% sc_metadata[malignant == "No" & cell != "Unresolved", cell_id]]
# scexp_tsne <- scexp[,colnames(scexp) %in% sc_metadata[malignant == "No", cell_id]]
# scexp_tsne <- t(scexp_tsne)
# tsne_plot <- Rtsne(scexp_tsne, partial_pca = TRUE, verbose = TRUE, num_threads = 6)
# tsne_plot <- data.frame(cell_id = rownames(scexp_tsne), 
#                         x = tsne_plot$Y[,1], 
#                         y = tsne_plot$Y[,2])
# tsne_plot <- merge.data.table(tsne_plot, sc_metadata, by = "cell_id")
# ggplot(tsne_plot) + 
#   geom_point(aes(x,y, color = cell))


# Visualize frequency of malignant cells by tumor
ggplot(sc_metadata[cell != "Unresolved" & malignant != "Unresolved"], aes(x = tumor_id, fill = malignant)) +
  geom_bar(position = position_dodge())

# Seems like donors who did not survived 59,78 had a proportion above 75% of malignant cells
ggplot(sc_metadata[cell != "Unresolved" & malignant != "Unresolved"], aes(x = tumor_id, fill = malignant)) +
  geom_bar(position = "fill")
# Confirm the high association between malignant cells and T-cell annotation 
ggplot(sc_metadata[cell != "Unresolved" & malignant != "Unresolved"], aes(x = tumor_id, fill = cell)) +
  geom_bar(position = position_dodge()) +
  facet_wrap(~malignant, scales = "free",nrow = 2)

# Given that most cell types classified as malignant are classified as T-cells I will remove T-cells from the non malignant group
training_metadata <- sc_metadata[cell != "Unresolved" & malignant != "Unresolved"]
training_metadata <- training_metadata[!(cell == "T-cell" & malignant == "No")]
training_metadata <- training_metadata[!(cell != "T-cell" & malignant == "Yes")]
training_data <- scexp[,colnames(scexp) %in% training_metadata[,cell_id]]
training_data <- t(training_data)

# # Visualize tSNE for training data
# tsne_plot <- Rtsne(training_data, partial_pca = TRUE, verbose = TRUE, num_threads = 6)
# tsne_plot <- data.frame(cell_id = rownames(training_data), 
#                         x = tsne_plot$Y[,1], 
#                         y = tsne_plot$Y[,2])
# tsne_plot <- merge.data.table(tsne_plot, training_metadata, by = "cell_id")
# ggplot(tsne_plot) + 
#   geom_point(aes(x,y, color = cell))


# Load sc expression data
scexp <- fread("GSE72056_melanoma_single_cell_revised_v2.tsv", header = TRUE)
scexp <- scexp[4:nrow(scexp),]
setnames(scexp, "Cell", "Gene")
# Convert gene names to ENSG 
ensembl <- useEnsembl(biomart = "genes", dataset = "hsapiens_gene_ensembl", GRCh = 37)
gb <- getBM(attributes=c("ensembl_gene_id", "ensembl_gene_id_version", "hgnc_symbol"),
            filters = c("hgnc_symbol","biotype"),
            values= list(scexp$Gene,"protein_coding"),
            mart=ensembl)
gene_id_table <- data.table(Gene = gb$hgnc_symbol,
                            ENSG = gb$ensembl_gene_id, 
                            ENSGN = gb$ensembl_gene_id_version)
# Make sure match with validation data
validation_genes <- fread("GSE77940_pre_post_melanoma.tsv", select = 1, col.names = "ENSGN")
gene_id_table <- merge.data.table(gene_id_table, validation_genes)

scexp_annot <- merge.data.table(gene_id_table, scexp, by = "Gene")
scexp_annot[, Gene := NULL]
scexp_annot[, ENSGN := NULL]

training_data <- scexp_annot[, lapply(.SD, mean), by = ENSG, .SDcols = -1]
training_data <- transpose(training_data, make.names = "ENSG")
training_data <- data.table(cell_id = colnames(scexp_annot)[-1], training_data)
training_data <- merge.data.table(training_metadata, training_data, by = "cell_id")
training_data <- merge.data.table(sample_metadata, training_data, by = "tumor_id")
setcolorder(training_data, c("cell_id", "tumor_id", "malignant", "cell", "Alive"))
fwrite(training_data, "training_data.tsv", append = FALSE, quote = FALSE, sep = '\t', row.names = FALSE, col.names = TRUE)

