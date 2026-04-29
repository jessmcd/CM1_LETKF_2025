#!/bin/bash

########################################
# just in case one already exists
rm letkf.out

sed -i  '6s|.*|''base_dir            = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C15_H18_V6_noAI"''|' namelist.py
sed -i  '43s|.*|''assim_freq          = 900''|' namelist.py
sed -i  '68s|.*|''rhoriz              = 18000.0''|' namelist.py
sed -i  '69s|.*|''rvert               = 6500.0''|' namelist.py

sed -i  '52s|.*|''prior_inflate       = 0''|' namelist.py
sed -i  '54s|.*|''post_inflate        = 3''|' namelist.py
sed -i  '55s|.*|''post_inflate_alpha  = 0.0''|' namelist.py

# #get experiment filepath
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
########################################


########################################
# just in case one already exists
rm letkf.out

sed -i  '6s|.*|''base_dir            = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C15_H09_V4_noAI"''|' namelist.py
sed -i  '43s|.*|''assim_freq          = 900''|' namelist.py
sed -i  '68s|.*|''rhoriz              = 9000.0''|' namelist.py
sed -i  '69s|.*|''rvert               = 4500.0''|' namelist.py

sed -i  '52s|.*|''prior_inflate       = 0''|' namelist.py
sed -i  '54s|.*|''post_inflate        = 3''|' namelist.py
sed -i  '55s|.*|''post_inflate_alpha  = 0.0''|' namelist.py

# #get experiment filepath
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
########################################



########################################
# just in case one already exists
rm letkf.out

sed -i  '6s|.*|''base_dir            = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H18_V6_noAI"''|' namelist.py
sed -i  '43s|.*|''assim_freq          = 600''|' namelist.py
sed -i  '68s|.*|''rhoriz              = 18000.0''|' namelist.py
sed -i  '69s|.*|''rvert               = 6500.0''|' namelist.py

sed -i  '52s|.*|''prior_inflate       = 0''|' namelist.py
sed -i  '54s|.*|''post_inflate        = 3''|' namelist.py
sed -i  '55s|.*|''post_inflate_alpha  = 0.0''|' namelist.py

# #get experiment filepath
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
########################################


########################################
# just in case one already exists
rm letkf.out

sed -i  '6s|.*|''base_dir            = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H09_V4_noAI"''|' namelist.py
sed -i  '43s|.*|''assim_freq          = 600''|' namelist.py
sed -i  '68s|.*|''rhoriz              = 9000.0''|' namelist.py
sed -i  '69s|.*|''rvert               = 4500.0''|' namelist.py

sed -i  '52s|.*|''prior_inflate       = 0''|' namelist.py
sed -i  '54s|.*|''post_inflate        = 3''|' namelist.py
sed -i  '55s|.*|''post_inflate_alpha  = 0.0''|' namelist.py

# #get experiment filepath
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
########################################



#################
#### just in case one already exists !!! thisis all gonna get written to letkf.out so just move that 
rm letkf.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C15_H18_V6_noAI"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > letkf.out 2>&1 

cp letkf.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C15_H18_V6_noAI/FORECAST_*/forecast.out
#################

#################
#### just in case one already exists
rm letkf.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C15_H09_V4_noAI"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > letkf.out  2>&1 

cp letkf.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C15_H09_V4_noAI/FORECAST_*/forecast.out
#################



#################
#### just in case one already exists !!! thisis all gonna get written to letkf.out so just move that 
rm letkf.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H18_V6_noAI"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > letkf.out 2>&1 

cp letkf.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H18_V6_noAI/FORECAST_*/forecast.out
#################

#################
#### just in case one already exists
rm letkf.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H09_V4_noAI"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > letkf.out  2>&1 

cp letkf.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H09_V4_noAI/FORECAST_*/forecast.out
#################