#################
#### just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H09_V2_60mem"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

cp forecast.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H09_V2_60mem/FORECAST_*/
#################

#################
#### just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H18_V2_60mem"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

cp forecast.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H18_V2_60mem/FORECAST_*/
#################


#################
#### just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H18_V4_noAI"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

cp forecast.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H18_V4_noAI/FORECAST_*/
#################

#################
#### just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H09_V2_noAI"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

cp forecast.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H09_V2_noAI/FORECAST_*/
#################

#################
#### just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H09_V2_noAI"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

cp forecast.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H09_V2_noAI/FORECAST_*/
#################

#################
#### just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C15_H09_V2_noAI"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

cp forecast.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C15_H09_V2_noAI/FORECAST_*/
#################

#################
#### just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H18_V2_noAI"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

cp forecast.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H18_V2_noAI/FORECAST_*/
#################

#################
#### just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H18_V2"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

cp forecast.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H18_V2/FORECAST_*/
#################

#################
#### just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H18_V6"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

cp forecast.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H18_V6/FORECAST_*/
#################