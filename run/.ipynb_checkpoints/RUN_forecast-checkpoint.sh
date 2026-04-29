#!/bin/bash



#################
#### just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C15_H07_V6"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

cp forecast.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C15_H07_V6FORECAST_*/
#################

#################
#### just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C15_H07_V2"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

cp forecast.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C15_H07_V2/FORECAST_*/
#################


#################
#### just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H07_V6"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

cp forecast.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H07_V6/FORECAST_*/
#################

#################
#### just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H07_V2"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

cp forecast.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H07_V2/FORECAST_*/
#################

#################
#### just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H09_V4_noREF"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

cp forecast.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H09_V4_noREF/FORECAST_*/
#################

