#################
#### just in case one already exists
rm forecast1.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H18_V2"''|' forecast_namelist1.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist1.py

#run experiment 
python ../src/forecast_driver1.py > forecast1.out 2>&1 

cp forecast1.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H18_V2/FORECAST_*/
#################


#################
#### just in case one already exists
rm forecast1.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H12_V2"''|' forecast_namelist1.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist1.py

#run experiment 
python ../src/forecast_driver1.py > forecast1.out 2>&1 

cp forecast1.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H12_V2/FORECAST_*/
#################


#################
#### just in case one already exists
rm forecast1.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H12_V6"''|' forecast_namelist1.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist1.py

#run experiment 
python ../src/forecast_driver1.py > forecast1.out 2>&1 

cp forecast1.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C10_H12_V6/FORECAST_*/
#################




#################
#### just in case one already exists
rm forecast1.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H18_V6"''|' forecast_namelist1.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist1.py

#run experiment 
python ../src/forecast_driver1.py > forecast1.out 2>&1 

cp forecast1.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H18_V6/FORECAST_*/
#################

#################
#### just in case one already exists
rm forecast1.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H18_V2"''|' forecast_namelist1.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist1.py

#run experiment 
python ../src/forecast_driver1.py > forecast1.out 2>&1 

cp forecast1.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H18_V2/FORECAST_*/
#################


#################
#### just in case one already exists
rm forecast1.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H12_V6"''|' forecast_namelist1.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist1.py

#run experiment 
python ../src/forecast_driver1.py > forecast1.out 2>&1 

cp forecast1.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/2/FORECAST_*/
#################


#################
#### just in case one already exists
rm forecast1.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H12_V2"''|' forecast_namelist1.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist1.py

#run experiment 
python ../src/forecast_driver1.py > forecast1.out 2>&1 

cp forecast1.out /work/jessica.mcdonald/CM1_LETKF_2025/experiments/C03_H12_V2/FORECAST_*/
#################