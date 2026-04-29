#!/bin/bash


########################################
# just in case one already exists
rm letkf1.out

sed -i  '6s|.*|''base_dir            = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C05_H18_V6"''|' namelist1.py
sed -i  '43s|.*|''assim_freq          = 300''|' namelist1.py
sed -i  '68s|.*|''rhoriz              = 18000.0''|' namelist1.py
sed -i  '69s|.*|''rvert               = 6500.0''|' namelist1.py

sed -i  '52s|.*|''prior_inflate       = 1''|' namelist1.py
sed -i  '54s|.*|''post_inflate        = 3''|' namelist1.py
sed -i  '55s|.*|''post_inflate_alpha  = 0.0''|' namelist1.py

# #get experiment filepath
base_dir=$(python namelist1.py)
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
    python ../src/experiment_driver1.py > letkf1.out 2>&1 
    
    # copy the outfile to the experiment directory
    echo "copying letkf.out to $base_dir"
    cp letkf1.out $base_dir/letkf.out
    
    echo "Experiment has completed"

fi
########################################

########################################
# just in case one already exists
rm letkf1.out

sed -i  '6s|.*|''base_dir            = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C05_H18_V4"''|' namelist1.py
sed -i  '43s|.*|''assim_freq          = 300''|' namelist1.py
sed -i  '68s|.*|''rhoriz              = 18000.0''|' namelist1.py
sed -i  '69s|.*|''rvert               = 4500.0''|' namelist1.py

sed -i  '52s|.*|''prior_inflate       = 1''|' namelist1.py
sed -i  '54s|.*|''post_inflate        = 3''|' namelist1.py
sed -i  '55s|.*|''post_inflate_alpha  = 0.0''|' namelist1.py

# #get experiment filepath
base_dir=$(python namelist1.py)
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
    python ../src/experiment_driver1.py > letkf1.out 2>&1 
    
    # copy the outfile to the experiment directory
    echo "copying letkf.out to $base_dir"
    cp letkf1.out $base_dir/letkf.out
    
    echo "Experiment has completed"

fi
########################################


########################################
# just in case one already exists
rm letkf1.out

sed -i  '6s|.*|''base_dir            = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C05_H18_V2"''|' namelist1.py
sed -i  '43s|.*|''assim_freq          = 300''|' namelist1.py
sed -i  '68s|.*|''rhoriz              = 18000.0''|' namelist1.py
sed -i  '69s|.*|''rvert               = 2500.0''|' namelist1.py

sed -i  '52s|.*|''prior_inflate       = 1''|' namelist1.py
sed -i  '54s|.*|''post_inflate        = 3''|' namelist1.py
sed -i  '55s|.*|''post_inflate_alpha  = 0.0''|' namelist1.py

# #get experiment filepath
base_dir=$(python namelist1.py)
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
    python ../src/experiment_driver1.py > letkf1.out 2>&1 
    
    # copy the outfile to the experiment directory
    echo "copying letkf.out to $base_dir"
    cp letkf1.out $base_dir/letkf.out
    
    echo "Experiment has completed"

fi
########################################


########################################
# just in case one already exists
rm letkf1.out

sed -i  '6s|.*|''base_dir            = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C05_H09_V4"''|' namelist1.py
sed -i  '43s|.*|''assim_freq          = 300''|' namelist1.py
sed -i  '68s|.*|''rhoriz              = 9000.0''|' namelist1.py
sed -i  '69s|.*|''rvert               = 4500.0''|' namelist1.py

sed -i  '52s|.*|''prior_inflate       = 1''|' namelist1.py
sed -i  '54s|.*|''post_inflate        = 3''|' namelist1.py
sed -i  '55s|.*|''post_inflate_alpha  = 0.0''|' namelist1.py

# #get experiment filepath
base_dir=$(python namelist1.py)
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
    python ../src/experiment_driver1.py > letkf1.out 2>&1 
    
    # copy the outfile to the experiment directory
    echo "copying letkf.out to $base_dir"
    cp letkf1.out $base_dir/letkf.out
    
    echo "Experiment has completed"

fi
########################################


#################
#### just in case one already exists
rm letkf1.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C05_H18_V6"''|' forecast_namelist1.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist1.py

#run experiment 
python ../src/forecast_driver1.py > letkf1.out 2>&1 

cp letkf1.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C05_H18_V6/FORECAST_*/forecast.out
#################


#################
#### just in case one already exists
rm letkf1.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C05_H18_V4"''|' forecast_namelist1.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist1.py

#run experiment 
python ../src/forecast_driver1.py > letkf1.out 2>&1 

cp letkf1.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C05_H18_V4/FORECAST_*/forecast.out
#################


#################
#### just in case one already exists
rm letkf1.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C05_H18_V2"''|' forecast_namelist1.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist1.py

#run experiment 
python ../src/forecast_driver1.py > letkf1.out 2>&1 

cp letkf1.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C05_H18_V2/FORECAST_*/forecast.out
#################



#################
#### just in case one already exists
rm letkf1.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C05_H09_V4"''|' forecast_namelist1.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist1.py

#run experiment 
python ../src/forecast_driver1.py > letkf1.out 2>&1 

cp letkf1.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C05_H09_V4/FORECAST_*/forecast.out
#################