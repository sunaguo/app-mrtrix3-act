#!/bin/bash

## define number of threads to use
NCORE=8

## export more log messages
set -x
set -e

## mkdir
mkdir -p csd 5tt

##
## parse inputs
##

## raw inputs
DIFF=`jq -r '.dwi' config.json`
BVAL=`jq -r '.bvals' config.json`
BVEC=`jq -r '.bvecs' config.json`
ANAT=`jq -r '.anat' config.json`
mask=`jq -r '.brainmask' config.json`
fivett=`jq -r '.mask' config.json`
IMAXS=`jq -r '.lmax' config.json`
ENS_LMAX=`jq -r '.ensemble' config.json`

## perform multi-tissue intensity normalization
NORM=`jq -r '.norm' config.json`

# PREMASK option for 5ttgen
PREMASK=`jq -r '.premask' config.json`

##
## begin execution
##

## working directory labels
rm -rf ./tmp
mkdir ./tmp

## define working file names
difm=dwi
mask=mask
anat=t1

## convert input diffusion data into mrtrix format
if [ ! -f ${difm}.mif ]; then
	echo "Converting raw data into MRTrix3 format..."
	mrconvert -fslgrad $BVEC $BVAL $DIFF ${difm}.mif --export_grad_mrtrix ${difm}.b -force -nthreads $NCORE -quiet
fi

## create mask of dwi data - use bet for more robust mask
# create mask of dwi
if [ ! -f mask.mif ]; then
	if [[ ${brainmask} == 'null' ]]; then
		[ ! -f mask.mif ] && bet $DIFF bet -R -m -f 0.3 && mrconvert bet_mask.nii.gz mask.mif -force -nthreads $NCORE -quiet
	else
		echo "brainmask input exists. converting to mrtrix format"
		mrconvert ${brainmask} -stride 1,2,3,4 mask.mif -force -nthreads $NCORE
	fi
fi

mask='mask'

## convert anatomy
[ ! -f t1.mif ] && mrconvert ${ANAT} t1.mif -nthreads $NCORE

anat='t1'

## create b0 
[ ! -f b0.mif ] && dwiextract dwi.mif - -bzero | mrmath - mean b0.mif -axis 3 -nthreads $NCORE

## check if b0 volume successfully created
if [ ! -f b0.mif ]; then
    echo "No b-zero volumes present."
    NSHELL=`mrinfo -shell_bvalues ${difm}.mif | wc -w`
    NB0s=0
    EB0=''
else
    ISHELL=`mrinfo -shell_bvalues ${difm}.mif | wc -w`
    NSHELL=$(($ISHELL-1))
    NB0s=`mrinfo -shell_sizes ${difm}.mif | awk '{print $1}'`
    EB0="0,"
fi

## determine single shell or multishell fit
if [ $NSHELL -gt 1 ]; then
    MS=1
    echo "Multi-shell data: $NSHELL total shells"
else
    MS=0
    echo "Single-shell data: $NSHELL shell"
    if [ ! -z "$TENSOR_FIT" ]; then
    echo "Ignoring requested tensor shell. All data will be fit and tracked on the same b-value."
    fi
fi

## print the # of b0s
echo Number of b0s: $NB0s 

## extract the shells and # of volumes per shell
BVALS=`mrinfo -shell_bvalues ${difm}.mif`
COUNTS=`mrinfo -shell_sizes ${difm}.mif`

## echo basic shell count summaries
echo -n "Shell b-values: "; echo $BVALS
echo -n "Unique Counts:  "; echo $COUNTS

## echo max lmax per shell
MLMAXS=`dirstat ${difm}.b | grep lmax | awk '{print $8}' | sed "s|:||g"`
echo -n "Maximum Lmax:   "; echo $MLMAXS

## find maximum lmax that can be computed within data
MAXLMAX=`echo "$MLMAXS" | tr " " "\n" | sort -nr | head -n1`
echo "Maximum Lmax across shells: $MAXLMAX"

## if input $IMAXS is empty, set to $MAXLMAX
if [ -z $IMAXS ]; then
    echo "No Lmax values requested."
    echo "Using the maximum Lmax of $MAXLMAX by default."
    IMAXS=$MAXLMAX
fi

## check if more than 1 lmax passed
NMAX=`echo $IMAXS | wc -w`

## find max of the requested list
if [ $NMAX -gt 1 ]; then

    ## pick the highest
    MMAXS=`echo -n "$IMAXS" | tr " " "\n" | sort -nr | head -n1`
    echo "User requested Lmax(s) up to: $MMAXS"
    LMAXS=$IMAXS

else

    ## take the input
    MMAXS=$IMAXS
    
fi

## make sure requested Lmax is possible - fix if not
if [ $MMAXS -gt $MAXLMAX ]; then
    
    echo "Requested maximum Lmax of $MMAXS is too high for this data, which supports Lmax $MAXLMAX."
    echo "Setting maximum Lmax to maximum allowed by the data: Lmax $MAXLMAX."
    MMAXS=$MAXLMAX

fi

## create the list of the ensemble lmax values
if [ $ENS_LMAX == 'true' ] && [ $NMAX -eq 1 ]; then
    
    ## create array of lmaxs to use
    emax=0
    LMAXS=''
    
    ## while less than the max requested
    while [ $emax -lt $MMAXS ]; do

    ## iterate
    emax=$(($emax+2))
    LMAXS=`echo -n $LMAXS; echo -n ' '; echo -n $emax`

    done

else

    ## or just pass the list on
    LMAXS=$IMAXS

fi

## create repeated lmax argument(s) based on how many shells are found

## create the correct length of lmax
if [ $NB0s -eq 0 ]; then
    RMAX=${MAXLMAX}
else
    RMAX=0
fi
iter=1

## for every shell (after starting w/ b0), add the max lmax to estimate
while [ $iter -lt $(($NSHELL+1)) ]; do
    
    ## add the $MAXLMAX to the argument
    RMAX=$RMAX,$MAXLMAX

    ## update the iterator
    iter=$(($iter+1))

done

## just pass the data forward
dift=${difm}
    
## 5tt probability
if [ -f ${fivett} ]; then
	[ ! -f 5tt.mif ] && mrconvert ${fivett} 5tt.mif -nthreads $NCORE
else
	5ttgen fsl ${anat}.mif 5tt.mif -nocrop -sgm_amyg_hipp -tempdir ./tmp -force $([ "$PREMASK" == "true" ] && echo "-premasked") -nthreads $NCORE -quiet
fi

## generate gm-wm interface seed mask
5tt2gmwmi 5tt.mif gmwmi_seed.mif -force -nthreads $NCORE -quiet

## create visualization output
5tt2vis 5tt.mif 5ttvis.mif -force -nthreads $NCORE -quiet

if [ $MS -eq 0 ]; then

    echo "Estimating CSD response function..."
    time dwi2response tournier ${difm}.mif wmt.txt -lmax $MAXLMAX -force -nthreads $NCORE -tempdir ./tmp -quiet
    
else

    echo "Estimating MSMT CSD response function..."
    time dwi2response msmt_5tt ${difm}.mif 5tt.mif wmt.txt gmt.txt csf.txt -mask ${mask}.mif -lmax $RMAX -tempdir ./tmp -force -nthreads $NCORE -quiet

fi

## fit the CSD across requested lmax's
if [ $MS -eq 0 ]; then

    for lmax in $LMAXS; do

    echo "Fitting CSD FOD of Lmax ${lmax}..."
    time dwi2fod -mask ${mask}.mif csd ${difm}.mif wmt.txt wmt_lmax${lmax}_fod.mif -lmax $lmax -force -nthreads $NCORE -quiet

    ## intensity normalization of CSD fit
    # if [ $NORM == 'true' ]; then
    #     #echo "Performing intensity normalization on Lmax $lmax..."
    #     ## function is not implemented for singleshell data yet...
    #     ## add check for fails / continue w/o?
    # fi
    
    done
    
else

    for lmax in $LMAXS; do

    echo "Fitting MSMT CSD FOD of Lmax ${lmax}..."
    time dwi2fod msmt_csd ${difm}.mif wmt.txt wmt_lmax${lmax}_fod.mif gmt.txt gmt_lmax${lmax}_fod.mif csf.txt csf_lmax${lmax}_fod.mif -mask ${mask}.mif -lmax $lmax,$lmax,$lmax -force -nthreads $NCORE -quiet

    if [ $NORM == 'true' ]; then

        echo "Performing multi-tissue intensity normalization on Lmax $lmax..."
        mtnormalise -mask ${mask}.mif wmt_lmax${lmax}_fod.mif wmt_lmax${lmax}_norm.mif gmt_lmax${lmax}_fod.mif gmt_lmax${lmax}_norm.mif csf_lmax${lmax}_fod.mif csf_lmax${lmax}_norm.mif -force -nthreads $NCORE -quiet

        ## check for failure / continue w/o exiting
        if [ -z wmt_lmax${lmax}_norm.mif ]; then
        echo "Multi-tissue intensity normalization failed for Lmax $lmax."
        echo "This processing step will not be applied moving forward."
        NORM='false'
        fi

    fi

    done
    
fi

##
## convert outputs to save to nifti
##

for lmax in $LMAXS; do
    
    if [ $NORM == 'true' ]; then
    mrconvert wmt_lmax${lmax}_norm.mif -stride 1,2,3,4 ./csd/lmax${lmax}.nii.gz -force -nthreads $NCORE -quiet
    else
    mrconvert wmt_lmax${lmax}_fod.mif -stride 1,2,3,4 ./csd/lmax${lmax}.nii.gz -force -nthreads $NCORE -quiet
    fi

done

cp wmt.txt ./csd/response.txt

## 5 tissue type visualization
mrconvert 5ttvis.mif -stride 1,2,3,4 ./5tt/5ttvis.nii.gz -force -nthreads $NCORE -quiet
mrconvert 5tt.mif -stride 1,2,3,4 ./5tt/5tt.nii.gz -force -nthreads $NCORE -quiet

## 5 tissue type visualization
mrconvert ${mask}.mif -stride 1,2,3,4 ./brainmask/mask.nii.gz -force -nthreads $NCORE -quiet

## clean up
rm -rf tmp
rm -rf *.mif

