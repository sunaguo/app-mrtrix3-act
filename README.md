[![Abcdspec-compliant](https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg)](https://github.com/brain-life/abcd-spec)
[![Run on Brainlife.io](https://img.shields.io/badge/Brainlife-brainlife.app.297-blue.svg)](https://doi.org/https://doi.org/10.25663/brainlife.app.297)

# Anatomically Constrained Tractography using precomputed 5tt & CSD 

This app will This app will perform Anatomically-Constrained Tractography (ACT) using precomputed tissue-type mask for seeding and fiber orientation distribution (FODs) computed from the Constrained Spherical Deconvolution Model. This app takes in a dwi, anatomical/t1w, and csd datatypes as mandatory inputs, with the tissue-type mask and dwi brainmask as optional inputs. This app will output a tractogram (tck) datatype and a tensor datatype from the DTI model. This is all performed within MrTrix3. It is important to note that this app is purely a copy of RACE-Track (https://doi.org/10.25663/bl.app.101), except modified to take in the tissue-type and CSD datatypes as inputs. 

### Authors 

- Brent McPherson (bcmcpher@iu.edu) 
- Brad Caron (bacaron@utexas.edu) 

### Contributors 

- Soichi Hayashi (shayashi@iu.edu) 

### Funding Acknowledgement

brainlife.io is publicly funded and for the sustainability of the project it is helpful to Acknowledge the use of the platform. We kindly ask that you acknowledge the funding below in your publications and code reusing this code. 

[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-1636893](https://img.shields.io/badge/NSF_BCS-1636893-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-ACI-1916518](https://img.shields.io/badge/NSF_ACI-1916518-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1916518)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://grantome.com/grant/NIH/R01-EB029272-01)

### Citations 

We kindly ask that you cite the following articles when publishing papers and code using this code. 

1. Smith, R. E., Tournier, J. D., Calamante, F., & Connelly, A. (2012). Anatomically-constrained tractography: improved diffusion MRI streamlines tractography through effective use of anatomical information. Neuroimage, 62(3), 1924-1938. 

2. Takemura, H., Caiafa, C. F., Wandell, B. A., & Pestilli, F. (2016). Ensemble tractography. PLoS computational biology, 12(2), e1004692. 

3. Tournier, J. D., Smith, R., Raffelt, D., Tabbara, R., Dhollander, T., Pietsch, M., … & Connelly, A. (2019). MRtrix3: A fast, flexible and open software framework for medical image processing and visualisation. NeuroImage, 202, 116137. https://doi.org/10.1016/j.neuroimage.2019.116137 

 4.Avesani, P., McPherson, B., Hayashi, S. et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. Sci Data 6, 69 (2019). https://doi.org/10.1038/s41597-019-0073-y 

#### MIT Copyright (c) 2020 brainlife.io The University of Texas at Austin and Indiana University 

## Running the App 

### On Brainlife.io 

You can submit this App online at [https://doi.org/https://doi.org/10.25663/brainlife.app.297](https://doi.org/https://doi.org/10.25663/brainlife.app.297) via the 'Execute' tab. 

### Running Locally (on your machine) 

1. git clone this repo 

2. Inside the cloned directory, create `config.json` with something like the following content with paths to your input files. 

```json 
'{
	"dwi": "/input/dwi/dwi.nii.gz",
	"anat": "/input/anat/t1.nii.gz",
	"mask": "/input/5tt/mask.nii.gz",
	"brainmask": "/input/brainmask/mask.nii.gz"
	"lmax2": "/input/csd/lmax2.nii.gz",
	"tensor_fit": 1000,
	"min_length": 10,
	"max_length": 200,
	"imaxs": 2,
	"ens_lmax": false,
	"curvs": 35,
	"num_fibers": 10000,
	"do_dtdt": false,
	"do_dtpb": false,
	"do_detr": "false",
	"do_prb1": false,
	"do_prb2": true,
	"do_fact": false,
	"fact_dirs": 3,
	"fact_fibs": 5000,
	"premask": false
}' 
``` 

### Sample Datasets 

You can download sample datasets from Brainlife using [Brainlife CLI](https://github.com/brain-life/cli). 

```
npm install -g brainlife 
bl login 
mkdir input 
bl dataset download 
``` 

3. Launch the App by executing 'main' 

```bash 
./main 
``` 

## Output 

The main output of this App is a track/tck datatype and tensor datatype. 

#### Product.json 

The secondary output of this app is `product.json`. This file allows web interfaces, DB and API calls on the results of the processing. 

### Dependencies 

This App only requires [singularity](https://www.sylabs.io/singularity/) to run. If you don't have singularity, you will need to install following dependencies.   

- MRtrix3: https://www.mrtrix.org/ 
- FSL: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki 
- ANTs: http://stnava.github.io/ANTs/

#### MIT Copyright (c) 2020 brainlife.io The University of Texas at Austin and Indiana University