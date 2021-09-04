# pipeline-ms-lesion

Pre-processing pipeline for multi-contrast spinal MS lesion segmentation. 

## Goals

The goals of this project are to:
- Provide a single multi-contrast model that generalizes well across different sites/vendors/sequence parameters;
- Establish an analysis framework that accommodates multiple sessions (over time) to estimate lesion growth/reduction;

## Methods

The segmentation algorithm uses the deep learning framework [SoftSeg](https://pubmed.ncbi.nlm.nih.gov/33784599/), providing outputs that encode partial volume effect and provide uncertainty measures.

## Data

The data come from the following sites:
- Brigham and Women's Hospital 🇺🇸
- Massachusetts General Hospital 🇺🇸
- New York University 🇺🇸
- Vanderbilt University 🇺🇸
- Zuckerberg San Francisco General Hospital 🇺🇸
- National Institute of Health 🇺🇸
- U. Mass (in data.neuro) 🇺🇸
- CanProCo (_in process_) 🇨🇦
- University College London 🇬🇧
- Inserm 🇫🇷
- Aix Marseille Université 🇫🇷
- OFSEP 🇫🇷
- Ospedale San Raffaele 🇮🇹
- Karolinska Insitutet 🇸🇪
