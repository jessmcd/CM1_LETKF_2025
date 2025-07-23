
#################
echo "Beginning $fname Experiment..."
echo "Output directory is $base_dir"

# just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/CI_3min_adapt"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,20,30)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

####
echo "Beginning $fname Experiment..."
echo "Output directory is $base_dir"

# just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/CI_3min_adapt"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 
#################


#################
echo "Beginning $fname Experiment..."
echo "Output directory is $base_dir"

# just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/CI_3min_adaptR"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,20,30)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 

####
echo "Beginning $fname Experiment..."
echo "Output directory is $base_dir"

# just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/CI_3min_adaptR"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 
#################

