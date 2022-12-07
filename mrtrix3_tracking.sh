#!/bin/bash

## define number of threads to use
NCORE=8

## export more log messages
set -x
set -e

##
## parse inputs
##

## raw inputs
MASK=`jq -r '.mask' config.json`
lmax2=`jq -r '.lmax2' config.json`
lmax4=`jq -r '.lmax4' config.json`
lmax6=`jq -r '.lmax6' config.json`
lmax8=`jq -r '.lmax8' config.json`
lmax10=`jq -r '.lmax10' config.json`
lmax12=`jq -r '.lmax12' config.json`
lmax14=`jq -r '.lmax14' config.json`
lmax16=`jq -r '.lmax16' config.json`

## parse potential ensemble / individual lmaxs
ENS_LMAX=`jq -r '.ens_lmax' config.json`
IMAXS=`jq -r '.imaxs' config.json`

## tracking params
CURVS=`jq -r '.curvs' config.json`
NUM_FIBERS=`jq -r '.num_fibers' config.json`
MIN_LENGTH=`jq -r '.min_length' config.json`
MAX_LENGTH=`jq -r '.max_length' config.json`

## tracking types
DO_PRB2=`jq -r '.do_prb2' config.json`
DO_PRB1=`jq -r '.do_prb1' config.json`
DO_DETR=`jq -r '.do_detr' config.json`

## FACT kept separately
DO_FACT=`jq -r '.do_fact' config.json`
FACT_DIRS=`jq -r '.fact_dirs' config.json`
FACT_FIBS=`jq -r '.fact_fibs' config.json`

# stepsize
STEPSIZE=`jq -r '.stepsize' config.json`
if [ -z ${STEPSIZE} ]; then
	step_line='-step ${STEPSIZE}'
else
	step_line=''
fi

##
## begin execution
##

## working directory labels
rm -rf ./tmp
mkdir ./tmp

## create the list of the ensemble lmax values
if [ $ENS_LMAX == 'true' ]; then
    
    ## create array of lmaxs to use
    emax=0
    LMAXS=''
	
    ## while less than the max requested
    while [ $emax -lt $IMAXS ]; do

	## iterate
	emax=$(($emax+2))
	LMAXS=`echo -n $LMAXS; echo -n ' '; echo -n $emax`

    done

else

    ## or just pass the list on
    LMAXS=$IMAXS

fi

echo "Tractography will be created on lmax(s): $LMAXS"

## compute the required size of the final output
TOTAL=0

if [ $DO_PRB2 == "true" ]; then
    for lmax in $LMAXS; do
	for curv in $CURVS; do
	    TOTAL=$(($TOTAL+$NUM_FIBERS))
	done
    done
fi

if [ $DO_PRB1 == "true" ]; then
    for lmax in $LMAXS; do
	for curv in $CURVS; do
	    TOTAL=$(($TOTAL+$NUM_FIBERS))
	done
    done
fi

if [ $DO_DETR == "true" ]; then
    for lmax in $LMAXS; do
	for curv in $CURVS; do
	    TOTAL=$(($TOTAL+$NUM_FIBERS))
	done
    done
fi

if [ $DO_FACT == "true" ]; then
    for lmax in $LMAXS; do
	TOTAL=$(($TOTAL+$FACT_FIBS))
    done
fi

echo "Expecting $TOTAL streamlines in track.tck."

## generate gm-wm interface seed mask
mrconvert ${MASK} 5tt.mif -nthreads $NCORE -force -quiet
5tt2gmwmi 5tt.mif gmwmi_seed.mif -force -nthreads $NCORE -quiet

## create visualization output
5tt2vis 5tt.mif 5ttvis.mif -force -nthreads $NCORE -quiet

echo "Performing Anatomically Constrained Tractography (ACT)..."

if [ $DO_PRB2 == "true" ]; then

    echo "Tracking iFOD2 streamlines..."
    
    for lmax in $LMAXS; do
    	fod=$(eval "echo \$lmax${lmax}")
	
	for curv in $CURVS; do

	    echo "Tracking iFOD2 streamlines at Lmax ${lmax} with a maximum curvature of ${curv} degrees..."
	    tckgen $fod -algorithm iFOD2 \
		   -select $NUM_FIBERS -act 5tt.mif -backtrack -crop_at_gmwmi -seed_gmwmi gmwmi_seed.mif \
		   -angle ${curv} -minlength $MIN_LENGTH -maxlength $MAX_LENGTH -seeds 0 -max_attempts_per_seed 500 \
		   wb_iFOD2_lmax${lmax}_curv${curv}.tck ${step_line} -force -nthreads $NCORE -quiet

	    exit_status=$?
	    if [ $exit_status -eq 124 ]; then
		echo "iFOD2 Probabilistic tracking timed out with settings: Lmax: $lmax; Curvature: $curv"
		exit 1
	    fi
	    
	done
    done
fi

if [ $DO_PRB1 == "true" ]; then

    ## MRTrix 0.2.12 probabilistic
    echo "Tracking iFOD1 streamlines..."
    
    for lmax in $LMAXS; do
    	fod=$(eval "echo \$lmax${lmax}")

	for curv in $CURVS; do

	    echo "Tracking iFOD1 streamlines at Lmax ${lmax} with a maximum curvature of ${curv} degrees..."
	    timeout 3600 tckgen $fod -algorithm iFOD1 \
		   -select $NUM_FIBERS -act 5tt.mif -backtrack -crop_at_gmwmi -seed_gmwmi gmwmi_seed.mif \
		   -angle ${curv} -minlength $MIN_LENGTH -maxlength $MAX_LENGTH -seeds 0 -max_attempts_per_seed 500 \
		   wb_iFOD1_lmax${lmax}_curv${curv}.tck ${step_line} -force -nthreads $NCORE -quiet

	    exit_status=$?
	    if [ $exit_status -eq 124 ]; then
		echo "iFOD1 Probabilistic tracking timed out with settings: Lmax: $lmax; Curvature: $curv"
		exit 1
	    fi
	    
	done
    done
fi

if [ $DO_DETR == "true" ]; then

    ## MRTrix 0.2.12 deterministic
    echo "Tracking SD_STREAM streamlines..."
    
    for lmax in $LMAXS; do
    	fod=$(eval "echo \$lmax${lmax}")

	for curv in $CURVS; do

	    echo "Tracking SD_STREAM streamlines at Lmax ${lmax} with a maximum curvature of ${curv} degrees..."
	    timeout 3600 tckgen $fod -algorithm SD_STREAM \
		   -select $NUM_FIBERS -act 5tt.mif -crop_at_gmwmi -seed_gmwmi gmwmi_seed.mif \
		   -angle ${curv} -minlength $MIN_LENGTH -maxlength $MAX_LENGTH -seeds 0 -max_attempts_per_seed 500 \
		   wb_SD_STREAM_lmax${lmax}_curv${curv}.tck ${step_line} -force -nthreads $NCORE -quiet

	    exit_status=$?
	    if [ $exit_status -eq 124 ]; then
		echo "Deterministic tracking timed out with settings: Lmax: $lmax; Curvature: $curv"
		exit 1
	    fi

	done
    done
fi

if [ $DO_FACT == "true" ]; then

    echo "Tracking FACT streamlines..."

    for lmax in $LMAXS; do
    	fod=$(eval "echo \$lmax${lmax}")
	    
	echo "Extracting $FACT_DIRS peaks from FOD Lmax $lmax for FACT tractography..."
	pks=peaks_lmax$lmax.mif
	sh2peaks $fod $pks -num $FACT_DIRS -nthread $NCORE -quiet

	echo "Tracking FACT streamlines at Lmax ${lmax} using ${FACT_DIRS} maximum directions..."
	timeout 3600 tckgen $pks -algorithm FACT -select $FACT_FIBS -act 5tt.mif -crop_at_gmwmi -seed_gmwmi gmwmi_seed.mif -seeds 0 -max_attempts_per_seed 500 \
	       -minlength $MIN_LENGTH -maxlength $MAX_LENGTH wb_FACT_lmax${lmax}.tck ${step_line} -force -nthreads $NCORE -quiet

	exit_status=$?
	if [ $exit_status -eq 124 ]; then
	    echo "FACT tracking timed out with settings: Lmax: $lmax; Curvature: $curv"
	    exit 1
	fi
	
    done

fi

## combine different parameters into 1 output
tckedit wb*.tck track.tck -force -nthreads $NCORE -quiet

## find the final size
COUNT=`tckinfo track.tck | grep -w 'count' | awk '{print $2}'`
echo "Ensemble tractography generated $COUNT of a requested $TOTAL"

## if count is wrong, say so / fail / clean for fast re-tracking
if [ $COUNT -ne $TOTAL ]; then
    echo "Incorrect count. Tractography failed."
    rm -f wb*.tck
    rm -f track.tck
    exit 1
else
    echo "Correct count. Tractography complete."
    rm -f wb*.tck
fi

## simple summary text
tckinfo track.tck > tckinfo.txt

## clean up
rm -rf tmp
rm -rf *.mif

## curvature is an angle, not a number
## the radius/angle conversion is:
## https://www.nitrc.org/pipermail/mrtrix-discussion/2011-June/000230.html
# angle = 2 * asin (S / (2*R))
# R = curvature (.25-2)
# S = step-size (0.2 by defualt in MRTrix 0.2.12)
