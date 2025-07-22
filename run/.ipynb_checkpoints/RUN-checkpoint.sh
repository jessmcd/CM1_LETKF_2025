#!/bin/bash

# just in case one already exists
rm letkf.out

sed -i  '6s|.*|''base_dir            = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/CI_3min_Ra"''|' namelist.py
sed -i  '43s|.*|''assim_freq          = 180''|' namelist.py
sed -i  '54s|.*|''post_inflate        = 4''|' namelist.py
sed -i  '55s|.*|''post_inflate_alpha  = 0.5''|' namelist.py

#get experiment filepath
base_dir=$(python namelist.py)
fname=$(basename "$base_dir")


# if an error string was returned by the namelist:
first="${base_dir:0:1}"
if [ "$first" == "[" ]; then
    echo "$base_dir"
    echo "ERROR, stopping...."

# no errors returned from namelist, continue experiment
else
    echo "Beginning $fname Experiment..."
    echo "Output directory is $base_dir"
    
    #run experiment 
    python ../src/experiment_driver.py > letkf.out 2>&1 
    
    # copy the outfile to the experiment directory
    echo "copying letkf.out to $base_dir"
    cp letkf.out $base_dir
    
    echo "Experiment has completed"

fi

