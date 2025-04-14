#!/usr/bin/env python

import os
import datetime as dt
import numpy as np


################# USER UPDATE THE ITEMS BELOW ######################
### some of these can be set in create_run_letkf.py and that's probably a better spot for it
### but anything you put here will overwrite stuff in there.
### that makes it easier for adjustments and testing


ensN=20                 # ensemble size
base_dir = "RUN_LETKF"  # name/location of the directory where all of your model output will go (it doesn't need to already exist)

nthreads = 8            # number of threads for run_filter.py (the actual DA)
ncores   = 64           # the number of cores that CM1 will use to run in run_fcst.py

init_sounding = "run_soundings"    # location of soundings for each ensemble (sounding name should match ensemble name (i.e. member 001 gets init_sounding/Run01Sounding.txt for input_sounding))
obs_loc = 'Obs/8may24_cm1_obs.csv' # location of radar files
obs_inc = ['VR', 'DBZ']            # options: VR, DBZ, or all (for any available data in data file). 
                                   # Add soon: CA for clear air (?). Let's you control what's being assimilated. Given to run_filter.py and implemented in computeHx.py

cook_period       = 45 # time in minutes, amount of time to let CM1 run before DA starts
assimilation_freq = 5  # time in minutes, cycling interval
forecast_length   = 30 # time in minutes, amount of time to run CM1 after DA cycling completes  

DA_start_time = dt.datetime(2024, 5, 8, 20) # time that DA will start
DA_end_time   = dt.datetime(2024, 5, 8, 21) # time that DA will end (note that DA will occur/an analysis file will be produced for this time)

out_file_name = f'{base_dir}.out'  # name of outfile, can be helpful for determining errors. it gets copied into the base_dir at the end of the experiment
run_setup     = True               # set this to false if you have already done the warmup period (or already have those files) and ONLY want to do a DA experiment 
make_plots    = True               # if you want to make the summary plots at the end (these need work... lolz)

#################################################################### 
#################################################################### 

# --------------------------------------------------------------------------
# Initialize the run, and add perturbations to the backround and 3D fields

exp_name = f'{base_dir}/{base_dir}.exp' # name of json file with all of the experiment info

print("\nStarting CM1 OSSE experiment")
if run_setup:

    print('Beginning model set up and cook period')

    model_start = (DA_start_time - dt.timedelta(minutes=cook_period)).strftime('%Y,%m,%b,%H,%M,%S')  # model start time is da_start_time - cook period, in YYYY,mm,dd,HH,MM,SS format

    # set up experiment file and create all of the base states
    os.system(f"python create_run_letkf.py -n {ensN} -b {base_dir}") #add model_start, sounding-loc, obs_loc
    os.system(f"python run_fcst.py -e {exp_name} -i --nthreads 1") #add ncores
    os.system(f"python ens.py -e {base_dir}/{base_dir}.exp --init0 -t {model_start} --write ")
      
    # cook period!
    os.system(f"python /work/jessica.mcdonald/CM1_LETKF_2025/run_fcst.py -e {exp_name} --run_time {cook_period*60} -t {model_start} --nthreads 1")

# --------------------------------------------------------------------------
# Now loop through the cycling
dtime = dt.timedelta(minutes=assimilation_freq)
times = np.arange(DA_start_time, DA_end_time + dtime, dtime)

for time in times:
    print(f' **************** \n **************** \n now starting time = {time}!!!!')
    time = time.astype(dt.datetime).strftime('%Y,%m,%b,%H,%M,%S')

    os.system(f"python /work/jessica.mcdonald/CM1_LETKF_2025/run_filter.py --exper {exp_name} -t {time} --freq -{assimilation_freq*60} --nthreads {nthreads}" ) #add in obs_include

    if time != times[-1]: #do the pure forecast at the end, not forward integration to next DA cycle
        os.system(f"python /work/jessica.mcdonald/CM1_LETKF_2025/run_fcst.py -e {exp_name} --run_time {assimilation_freq*60} -t {time} --nthreads 1" )

#--------------------------------------------------------------------------
# Make a 30 minute forecast
if forecast_length > 0:
    os.system(f"python /work/jessica.mcdonald/CM1_LETKF_2025/run_fcst.py -e {exp_name} --run_time {forecast_length*60} -t {times[-1]} --nthreads 1")

#--------------------------------------------------------------------------
# Make a few plots every 10 minutes
if make_plots:

    for time in times[::2]:
        os.system(f"python /work/jessica.mcdonald/CM1_LETKF_2025/ens.py -e {exp_name} -t {time} -v W --plot9" )
        os.system(f"python /work/jessica.mcdonald/CM1_LETKF_2025/ens.py -e {exp_name} -t {time} -v WZ --plot9" )
        os.system(f"python /work/jessica.mcdonald/CM1_LETKF_2025/ens.py -e {exp_name} -t {time} -v DBZ --plot8")
    
    #--------------------------------------------------------------------------
    # Creat DA diagnostics 
    
    os.system(f"python DBZ_CR.py  -d {base_dir} -t DBZ_CR  --noshow")
    os.system(f"python DBZ_INV.py -d {base_dir} -t DBZ_INV --noshow")
    os.system(f"python VR_CR.py   -d {base_dir} -t VR_CR   --noshow")
    os.system(f"python VR_INV.py  -d {base_dir} -t VR_INV  --noshow")
    
    
    os.system(f"mv *.pdf {base_dir}/Plots/")
    os.system(f'cp {out_file_name} {base_dir}/')

print("\nEnded CM1 OSSE experiment")

