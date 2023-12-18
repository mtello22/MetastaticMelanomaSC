---
editor_options: 
  markdown: 
    wrap: 72
---

# MetastaticMelanomaSC

This repo focuses in the re-analysis of the dataset developed by Tirosh
and colleagues in the paper "Dissecting the multicellular ecosystem of
metastatic melanoma by single-cell RNA-seq" from 2016.

-   The main file for this repo is ProjectReport.Rmd, it contains the
    code to reproduce the data analysis and to generate the input
    feature tables for the supervised classification pipeline.

-   Under the main folder the file ProjectPresentation.pdf contains the
    PDF version of the presentation for future references.

-   The folder Data contains all the files downloaded from the original
    publications and the feature tables.

-   The folder JupyterNB contains the jupyter notebook that can be used
    to run the supervised learning pipeline and calculate the SHAP
    values for the best trained model.

Below is the original project proposal:

# Re-analysis proposal

In this study, Tirosh and colleagues sampled 18 melanoma tumors and
performed single cell RNA-seq (scRNA-seq) profiling. They defined gene
clusters using standard PCA to determine biological significance of
tumor cells (1). Since most of their interpretation is based on clusters
defined within the tumor cells, it is possible that the clusters do not
take full advantage of the transcriptomic variability in the dataset. I
aim to improve the understanding of gene relevance for tumor-specific
functions by incorporating microenvironment transcriptomic profiles. Due
to advances of interpretability tools for supervised regressors, it is
possible to see inside of "black box" models to understand what features
drive differences between conditions. For instance, Yap and colleagues
2021 utilized the SHAP framework to determine individual gene
contribution for classifying bulk RNA-seq samples into different tissues
(2). I intend to apply this framework in scRNA-seq to determine if there
are genes with a more subtle role in separating tumor vs
micro-environment cells.

**Methodology plan:** Train a gradient boosting model to classify cells
between "tumor" or "micro-environment". Use the SHAP framework to
determine which genes have the biggest role during classification.
Compare similarities of "SHAP genes" with results from a differential
expression analysis.

**Hypothesis:** If the supervised model identified genes relevant for
the tumor or micro- environment classification, this should be reflected
in the gene SHAP profile. If the genes have a significant role in
separating micro-environment from tumor cells, I expect a significant
overlap between differential expressed genes and "SHAP genes"

**Contribution:** This analysis explores the utility of supervised
classifiers to draw biological meaningful insights that separate cells
from the melanoma micro-environment and the actual tumor.

**References:**

1.  Tirosh I, Izar B, Prakadan SM, Wadsworth MH, Treacy D, Trombetta JJ,
    et al. Dissecting the multicellular ecosystem of metastatic melanoma
    by single-cell RNA-seq. Science. 2016 Apr 8;352(6282):189--96.

2.  Yap M, Johnston RL, Foley H, MacDonald S, Kondrashova O, Tran KA, et
    al. Verifying explainability of a deep learning tissue classifier
    trained on RNA-seq data. Sci Rep. 2021 Jan 29;11(1):2641.
