[![Abcdspec-compliant](https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg)](https://github.com/brain-life/abcd-spec)
[![Run on Brainlife.io](https://img.shields.io/badge/Brainlife-brainlife.app.238-blue.svg)](https://doi.org/10.25663/brainlife.app.238)

# Fit Constrained Deconvolution Model for Tracking 

This app will fit the constrained spherical deconvolution model using MrTrix3. This app requires DWI and anatomical (T1w) datatypes. Optionally, the user can input a precomputed five tissue type mask and/or DWI brainmask. If empty, this app will precompute these using MrTrix3's 5ttgen and dwi2mask functions. The user can also specify the maximum lmax to generate and whether or not an 'ensemble' of lmaxs (i.e. sequence up to max) is generated. The user can also specify whether or not the FOD's should be normalized. The output of this app can be used to guide white matter tracking. 

### Authors 

- Brad Caron (bacaron@iu.edu)
- Brent McPherson (bcmcpher@iu.edu) 

### Contributors 

- Soichi Hayashi (hayashis@iu.edu) 

### Funding 

[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-1636893](https://img.shields.io/badge/NSF_BCS-1636893-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-ACI-1916518](https://img.shields.io/badge/NSF_ACI-1916518-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1916518)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://grantome.com/grant/NIH/R01-EB029272-01)

### Citations 

Please cite the following articles when publishing papers that used data, code or other resources created by the brainlife.io community. 

1. Tournier, J.-D.; Calamante, F. & Connelly, A. Robust determination of the fibre orientation distribution in diffusion MRI: Non-negativity constrained super-resolved spherical deconvolution. NeuroImage, 2007, 35, 1459-1472
2. Jeurissen, B; Tournier, J-D; Dhollander, T; Connelly, A & Sijbers, J. Multi-tissue constrained spherical deconvolution for improved analysis of multi-shell diffusion MRI data. NeuroImage, 2014, 103, 411-426 

## Running the App 

### On Brainlife.io 

You can submit this App online at [https://doi.org/10.25663/brainlife.app.238](https://doi.org/10.25663/brainlife.app.238) via the 'Execute' tab. 

### Running Locally (on your machine) 

1. git clone this repo 

2. Inside the cloned directory, create `config.json` with something like the following content with paths to your input files. 

```json 
{
   "dwi":    "testdata/dwi/dwi.nii.gz",
   "bvals":    "testdata/dwi/dwi.bvals",
   "bvecs":    "tesdata/dwi/dwi.bvecs",
   "mask":    "testdata/mask/mask.nii.gz",
   "brainmask":    "testdata/brainmask/mask.nii.gz",
   "anat":    "testdata/anat/t1.nii.gz",
   "lmax":    8,
   "norm":    false,
   "ensemble":    true
} 
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

The main output of this App is contains all the requested FOD images (example: lmax2.nii.gz,lmax4.nii.gz,response.txt) and the internally generated masks. If masks were inputted to this app, these will be copied over as the outputs. 

#### Product.json 

The secondary output of this app is `product.json`. This file allows web interfaces, DB and API calls on the results of the processing. 

### Dependencies 

This App requires the following libraries when run locally. 

- MRtrix3: https://mrtrix.readthedocs.io/en/3.0_rc3/installation/linux_install.html
- jsonlab: https://github.com/fangq/jsonlab
- singularity: https://singularity.lbl.gov/quickstart
- FSL: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation
