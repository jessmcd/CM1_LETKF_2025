echo "Beginning $fname Experiment..."
echo "Output directory is $base_dir"

#run experiment 
python ../src/forecast_driver.py > forecast.out 2>&1 