#!/usr/bin/env python 

import os
import datetime as dt
import numpy as np

import sys
sys.path.append('../run/')
import namelist
os.chdir('../src/') # back to original directory
print(os.getcwd())

# read in namelist options
ensN              = namelist.ne                        
base_dir          = namelist.base_dir 
nthreads          = namelist.nthreads        
ncores            = namelist.ncores           
init_sounding     = namelist.sounding 
obs_loc           = namelist.radar_obs 
obs_inc           = namelist.obs_include 
DA_start_time     = namelist.DA_start_time   
DA_end_time       = namelist.DA_end_time 
assim_freq        = namelist.assim_freq  
cook_period       = namelist.cook_period    
cook_freq         = namelist.cook_freq     
forecast_length   = namelist.forecast_length 
forecast_freq     = namelist.forecast_freq   
run_setup         = namelist.run_setup  
run_cook          = namelist.run_cook 
run_assim         = namelist.run_assim
run_fcst          = namelist.run_forecast
make_plots        = namelist.make_plots           

name = base_dir.split('/')[-1]
exp_name = f'{base_dir}/{name}.exp' # name of json file with all of the experiment info
obs_inc_list = ','.join(obs_inc)    # convert the list of obs to include into proper format, "opt1,opt2,opt3" ... etc

# --------------------------------------------------------------------------
# THIS PART ACTUALLY DRIVES THE ENTIRE EXPERIEMENT

if run_setup:

    print('Beginning model set up and cook period')
    if namelist.auto_model_start:
        model_start = (DA_start_time - dt.timedelta(seconds=cook_period)).strftime('%Y,%m,%d,%H,%M,%S')  
    else:
        model_start = namelist.model_start
        
    os.system(f"python create_run_letkf.py") 
    os.system(f"python run_fcst.py          -e {exp_name} --ncores {ncores} -i") 
    os.system(f"python ens.py               -e {exp_name} --init0 -t {model_start} --write ")
      
    # cook period!
    if run_cook:
        os.system(f"python run_fcst.py -e {exp_name} --run_time {cook_period} --freq {cook_freq} -t {model_start} --ncores {ncores}")

# --------------------------------------------------------------------------
# Now loop through the cycling

if run_assim:
    dtime = dt.timedelta(seconds=assim_freq)
    times = np.arange(DA_start_time, DA_end_time + dtime, dtime)
    
    for time in times:
        print(f' **************** \n **************** \n now starting time = {time}!!!!')
        time = time.astype(dt.datetime).strftime('%Y,%m,%d,%H,%M,%S')
    
        os.system(f"python run_filter.py -e {exp_name} -t {time} --freq -{assim_freq} --nthreads {nthreads} --included_obs {obs_inc_list}" ) 
    
        if time != times[-1]: #do the pure forecast at the end, not forward integration to next DA cycle
            os.system(f"python run_fcst.py -e {exp_name} --run_time {assim_freq} -t {time} --ncores {ncores}" )
            
#--------------------------------------------------------------------------
# Make a forecast
if run_forecast:
    if forecast_length > 0:
        time = times[-1].astype(dt.datetime).strftime('%Y,%m,%d,%H,%M,%S')
        os.system(f"python run_fcst.py -e {exp_name} --run_time {forecast_length} --freq {forecast_freq} -t {time} --ncores {ncores}")

#--------------------------------------------------------------------------
# Make a few plots every 10 minutes
if make_plots:

    for time in times[::2]:
        time = time.astype(dt.datetime).strftime('%Y,%m,%d,%H,%M,%S')
        os.system(f"python ens.py -e {exp_name} -t {time} -v W --plot9" )
        os.system(f"python ens.py -e {exp_name} -t {time} -v WZ --plot9" )
        os.system(f"python ens.py -e {exp_name} -t {time} -v DBZ --plot8")
    
    #--------------------------------------------------------------------------
    # Create DA diagnostics 
    
    os.system(f"python plot_src/DBZ_CR.py  -d {base_dir} -t DBZ_CR  --noshow")
    os.system(f"python plot_src/DBZ_INV.py -d {base_dir} -t DBZ_INV --noshow")
    os.system(f"python plot_src/VR_CR.py   -d {base_dir} -t VR_CR   --noshow")
    os.system(f"python plot_src/VR_INV.py  -d {base_dir} -t VR_INV  --noshow")
    
    
    os.system(f"mv *.pdf {base_dir}/Plots/")

### after running cm1, delete any cm1out files that were produced
### we only need the restart files, and I'm not even sure why cm1 is making the cm1out files
if run_setup | run_experiment | run_cook :
    import json
    with open(exp_name, 'rb') as f:
        experiment = json.load(f)
        for mem in experiment['fcst_members']:
            os.system('rm '+os.path.join(mem, 'cm1out_000*.nc'))

print("\nEnded CM1 OSSE experiment")

