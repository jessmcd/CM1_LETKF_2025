## Namelist options for the LETKF CM1 system - forecast driver
import datetime as dt

# directory that your existing experiment is in
base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/CI_3min_loc2" # do not include final "/"
ncores               = 64

forecast_output_freq = 180  # 5 minutes, output interval
forecast_start       = dt.datetime(2024,5,8,20,30)
forecast_end         = dt.datetime(2024,5,8,22,30) 


forecast_launch_freq = 0 # seconds. if more than zero, a new forecast will be launched at the time interval specified here
same_end_time        = True # if True, forecast_end will overwrite forecast_len. if False, forecast_end is ignored
forecast_len         = 0.0 # only used if you want a different length other than what forecast_end provides