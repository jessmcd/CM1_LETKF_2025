import os
import datetime as dt
import numpy as np
import glob
import json


import sys
sys.path.append('../run/')
import forecast_namelist as namelist
os.chdir('../src/') # back to original directory

from ens import FindRestartFiles

debug = True

def myconverter(o):
    if isinstance(o, dt.datetime):
        return o.__str__()
        

def linkit(from_path,to_path ,link_option):
    '''from create_run_letkf'''
    
    if debug: print(f"LINKIT:  ARG[0]: {from_path}  ARG[1]:  {to_path }")

    if link_option == 1:
        LINK_CMD =f"ln -s {from_path} {to_path}" 
        
        if os.system(LINK_CMD) != 0:
            print(f"\n ERROR!!!\n ERROR!!! FAILIED TO EXECUTE: {LINK_CMD}\n ERROR!!!")
            sys.exit(1)
        print("Linked " + from_path + " to directory  " + to_path)
      
    if link_option == 2:
        CP_CMD = f"cp  {from_path} {to_path}" 
        
        if os.system(CP_CMD) != 0:
            print(f"\n ERROR!!!\n ERROR!!! FAILIED TO EXECUTE: {LINK_CMD}")
            if not os.path.exists(from_path):
                print(f"\nCOMMAND FAILED because {from_path} does not exist\n ")
            elif not os.path.join(to_path):
                print(f"COMMAND FAILED because{to_path} does not exist\n ")
            else:
                print("\nBOTH FILE AND DIRECTORY EXISTS....something else f__ked up here....\n")
            print("ERROR!!!\n") 
            sys.exit(1)
            
        print(f"Copied {from_path} to directory {to_path}")

    return

################### reading in namelist variables

base_dir             = namelist.base_dir
ncores               = namelist.ncores
forecast_freq        = namelist.forecast_output_freq
forecast_start       = namelist.forecast_start
forecast_end         = namelist.forecast_end
forecast_launch_freq = namelist.forecast_launch_freq # seconds. if more than zero, a new forecast will be launched at the time interval specified here
same_end_time        = namelist.same_end_time 

name = base_dir.split('/')[-1]
exp_name = f'{base_dir}/{name}.exp' # name of json file with all of the experiment info

# open experiment file to get experiment info
with open(exp_name, 'rb') as f: exper = json.load(f)

# determing forecast len
if forecast_launch_freq != 0:
    dtime = dt.timedelta(seconds=forecast_launch_freq)
    times = np.arange(forecast_start, forecast_end+ dtime, dtime)
else:
    times = [forecast_start]

################# now start forecast

for time in times:

    # determine length of each launched forecast
    if same_end_time:
        forecast_len = (forecast_end - time).seconds
    else:
        forecast_len = namelist.forecast_len


     # find the proper restart file to copy into each directory
    files, myDT = FindRestartFiles(exper, time, ret_exp=False)


    # create a forecast_dir in base_dir
    fpath =  os.path.join(base_dir, dt.datetime.strftime(time, 'FORECAST_%Y%m%d_%H%M'))
    
    cmd   =f'mkdir {fpath}'
    os.system(cmd)

    # now copy in the cm1 files to the forecast directory
    for var in ['model', 'src', 'landsfc', 'namelist']:

        # first copy into forecast directory, link_option=2
        from_path = os.path.join(base_dir, os.path.basename(exper[var]))
        to_path   = os.path.join(fpath, os.path.basename(exper[var]))
        ret       = linkit(from_path, to_path, 2)


    # now set up member diirctories 
    fcst_members = []
    for mem in range(1, exper['ne']+1, 1):
    #for mem in range(1, 6, 1):

        # make directory
        mem_path = os.path.join(fpath, f'member{mem:03d}')
        fcst_members.append(mem_path)
        cmd = f'mkdir {mem_path}'
        os.system(cmd)

        # loop over cm1 files from forecast directory and link them to each member, link_option=1
        for var in ['model', 'src', 'landsfc', 'namelist']:
            from_path = os.path.join(fpath, os.path.basename(exper[var]))
            to_path   = mem_path
            ret       = linkit(from_path, to_path, 1)

        #now copy over the sounding file- NOTE: the "files" variable is sorted, so you can safely index this variable
        from_path = os.path.join(files[mem-1][:-17],'input_sounding')
        ret       = linkit(from_path, to_path, 2)

        # now copy the proper restart file over 
        from_path = files[mem-1]
        ret       = linkit(from_path, to_path, 2)
        

    # now, make a new experiment file to give to run_fcst.py  
    # clean up dictionary and update paths, leave DA_PARAMS because run_fcst.py expects them
    del exper['INIT']
    del exper['ADD_NOISE']
    
    exper['FORECAST'] = {'start':time, 'end':time+dt.timedelta(seconds=forecast_len), 'freq': forecast_freq}

    exper['base_dir']     = fpath
    exper['base_path']    = fpath
    exper['fcst_path']    = fpath
    exper['fcst_members'] = fcst_members
    
    exp_name = os.path.join(fpath,os.path.basename(fpath)+'.exp' )
    with open(exp_name, 'w') as handle:
        json.dump(exper, handle, default = myconverter)
    

    # YOU ARE NOW READY TO RUN THE FORECAST!!!!! 
    time_str = time.strftime('%Y,%m,%d,%H,%M,%S')

    os.system(f"python run_fcst.py -e {exp_name} --run_time {forecast_len} --freq {forecast_freq} -t {time_str} --ncores {ncores}")

    # make the full forecast netcdf
    os.system(f"python stats_calc.py -e {exp_name} -f --fcst_file -w") # combine forecast plots into single file, make balance file (if applicable)