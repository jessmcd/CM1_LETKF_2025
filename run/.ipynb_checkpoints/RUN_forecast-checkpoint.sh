

####
echo "Beginning $fname Experiment..."
echo "Output directory is $base_dir"

# just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C3_5L07_R5"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 
#################


####
echo "Beginning $fname Experiment..."
echo "Output directory is $base_dir"

# just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C3_5L09_R5"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 
#################



####
echo "Beginning $fname Experiment..."
echo "Output directory is $base_dir"

# just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C3_5L12_R5"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 



####
echo "Beginning $fname Experiment..."
echo "Output directory is $base_dir"

# just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C3_5L15_R5"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 
#################







####
echo "Beginning $fname Experiment..."
echo "Output directory is $base_dir"

# just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C3_5L07_R3"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 
#################


####
echo "Beginning $fname Experiment..."
echo "Output directory is $base_dir"

# just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C3_5L09_R3"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 
#################



####
echo "Beginning $fname Experiment..."
echo "Output directory is $base_dir"

# just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C3_5L12_R3"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 



####
echo "Beginning $fname Experiment..."
echo "Output directory is $base_dir"

# just in case one already exists
rm forecast.out

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C3_5L15_R3"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 
#################