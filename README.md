# pipeline-ms-lesion

Pre-processing pipeline for multi-contrast spinal MS lesion segmentation. 

The goals of this project are to:
- Provide a single multi-contrast model that generalizes well across different sites/vendors/sequence parameters;
- Establish an analysis framework that accommodates multiple sessions (over time) to estimate lesion growth/reduction;

The segmentation algorithm uses the deep learning framework [SoftSeg](https://pubmed.ncbi.nlm.nih.gov/33784599/), providing outputs that encode partial volume effect and provide uncertainty measures.
