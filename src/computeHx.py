#!/usr/bin/env python
import sys
import os
import numpy as np
import datetime as DT 
from netCDF4 import *
import pyDart
import ens 
import glob
from optparse import OptionParser
from multiprocessing import Pool
from time import time as timer
from nc_prior_file import *
from assim_util import *
import state_vector as state
import json

##### pandas update for obs file
import pandas as pd
import cftime
day_utime   = "days since 1601-01-01 00:00:00"
sec_utime   = "seconds since 1970-01-01 00:00:00"
#######

missing = -999.
diag = True

# Stuff to set observation std deviation in filter

_default_obs_error = {11: ["VR", 2.0], 12:["DBZ", 5.0], 13:["DBZ0", 5.0], 14:["DBZ0_W", 0.5]}
  
#-----------------------------------------------------------------------------------------------------------------------------------
# Main program

if __name__ == "__main__":
    
    stime = timer()
    now = DT.datetime.now()
    
    print("\n  ----------------------------------------------------------------------")
    print("\n                BEGIN PROGRAM ComputeHx                                 ")
    print("\n    WALLCLOCK START TIME:  %s \n" % now.strftime("%Y-%m-%d %H:%M")  )
    print("\n  ----------------------------------------------------------------------")
    
    #-----------------------------------------------
    # Timers for the code...
    
    timeUpdate  = myTimer(name = "Update")
    timePrint   = myTimer(name = "Print")
    timeIO      = myTimer(name = "I/O")
    timeMain    = myTimer(name = "MAIN Program", minutes=True)
    timeHxF     = myTimer(name = "HxF")
    
    # Time the ESRF analysis
    
    timeMain.start()

# Parse input command options

    parser = OptionParser()
    parser.add_option("-o", "--obs",        dest="obs",       type="string",  help = "Observation file")
    parser.add_option("-t", "--time",       dest="time",      type="string",  help = "Time of prior calculations: 2008,05,8,22,10,00")
    parser.add_option("-e", "--exper",      dest="exper",     type="string",  help = "experiment run file created to store database info")
    parser.add_option(      "--nthreads",   dest="nthreads",  type="int",     help = "Number of threads for LETKF computation")
    parser.add_option(      "--window",     dest="window",    type="int",     help = "Width in seconds of Hx window")
    parser.add_option(      "--init",       dest="init",      default=False,  help = "Create new prior file", action="store_true")
    parser.add_option(      "--final",      dest="final",     default=False,  help = "Movie prior file to new DT-labeled file", action="store_true")
    parser.add_option(      "--obserr",     dest="obserr",    default=None,   type = "string", nargs=4, help = "Set observational errors, e.g., VR 3.0 DBZ 7.5")
    parser.add_option(    "--included_obs", dest="obs_inc",   type="string", default='all',  help = "list of observation types to include, in form type1,type2,type3 etc.")
  
    (options, args) = parser.parse_args()
  
#-------------------------------------------------------------------------------  
# Get experiment file

    if options.exper == None:
        print("\n --> ComputeHx:  No experiment's run filename specified, exiting....\n")
        parser.print_help()
        sys.exit(-1)
    else:
        with open(options.exper, 'rb') as p:
            exper = json.load(p)
        
# get path for file creation and location
    path = exper['base_path']
  
#-------------------------------------------------------------------------------
# Get the time stamp
    
    if options.time == None:
        print("\n --> ComputeHx:  No analysis time specified, exiting....\n")
        parser.print_help()
        sys.exit(-1)
    else:
        time = options.time.split(",")

#-------------------------------------------------------------------------------
# Obs error

    if options.obserr == None:
        obs_error = exper['DA_PARAMS']['obs_errors']
        print("\n --> ComputeHx:  using the obs errors from the EXPER file:  %s" % obs_error) 
    else:
        print("\n --> ComputeHx:  using the obs errors from command line")
        obs_error = _default_obs_error
        
        for key in obs_error.keys():
            for n, item in enumerate(options.obserr):
                if item == obs_error[key][0]:
                   print("\n --> ComputeHx:  Changing %s observational error to:  %s" % (obs_error[key][0],options.obserr[n+1]))
                   obs_error[key][1] = float(options.obserr[n+1])

#-------------------------------------------------------------------------------
# Set up window to look for
    
    if options.window == None:
        window = int(exper['DA_PARAMS']['assim_window'])
        print("\n --> ComputeHx:  using the window from the EXPER file:  +/- %d secs" % (window/2))
    else:
        window = int(options.window)
        print("\n --> ComputeHx:  using the window from the command line:  +/- %d secs" % (window/2))

#-------------------------------------------------------------------------------    
# Observation file

    if options.obs == None:
        obs_file = exper['radar_obs']
        print("\n --> ComputeHx:  using the observation file from the EXPER file:  %s" % obs_file)
    else:
        obs_file = options.obs
        print("\n --> ComputeHx:  using the observation file from the command line:  %s" % obs_file)


#-------------------------------------------------------------------------------    
# obs to assimilate
    if options.obs_inc != 'all':
        obs_include = options.obs_inc.split(',')
    else:
        obs_include = []

#-------------------------------------------------------------------------------    
# Init flag creates a new file

    if options.init:
        init = options.init
    else:
        init = False

#-------------------------------------------------------------------------------    
# Final flag moves prior file to Prior_DateTime.nc

    if options.final:
        final = options.final
    else:
        final = False

#-------------------------------------------------------------------------------    
# Need this value for 

    outlier = exper['DA_PARAMS']['outlier']
    print("\n --> ComputeHx: obs outlier is from EXPER file:  %d" % outlier)

   
#################################################################################################
# Read and search the observation file for each chunk of time...

    timeHxF.start()

    ob_f = pd.read_csv(obs_file)
  
# Initialize a bunch of containers, they get converted to numpy arrays below

    lat     = np.empty((0))
    lon     = np.empty((0))
    dates   = np.empty((0))
    value   = np.empty((0))
    kind    = np.empty((0))
    height  = np.empty((0))
    elev    = np.empty((0))
    az      = np.empty((0))
    err_var = np.empty((0))
    idx     = np.empty((0))

    analysis_time = DT.datetime(int(time[0]),int(time[1]),int(time[2]),int(time[3]),int(time[4]),int(time[5]))
     
    print("\n --> ComputeHx:  Reading in model state for HxF at %s \n" %  (analysis_time.strftime("%Y-%m-%d %H:%M:%S")))
    
# read from history files

    timeIO.start()
      
    files = ens.FindRestartFiles(exper, analysis_time, ret_exp=False, ret_DT=False)
    state = ens.read_CM1_ens(files, exper, state_vector=state.Hxf, DateTime=analysis_time)   
    ens.ens_CM1_C2A(state)
    ens.ens_CM1_coords(state)
    timeIO.stop()
      
    Hxfm = np.empty((0,state.ne))  # need to init this here cause need size of ensemble


# if you want only a subset of observations, this will do that. Make sure to add additional options as the file contains more data
    if len(obs_include) > 0:
        include = []
        for ob in obs_include:
            print(f'-------->> INCLDUING OBSERVATION TYPE {ob}')
            if ob == "DBZ0_W":
                include.append(14)
                ob_f.loc[ob_f.kind==13, 'kind'] = 14 # recode all clear air obs to be vertical velocity
                     
            if ob == "DBZ0":
                include.append(13)
            if ob == "DBZ":
                include.append(12)
            if ob == 'VR':
                include.append(11)
    
        ob_f = ob_f[ob_f['kind'].isin(include)]
 
#set spatial and temporal conditions to index the observation data 
    g_lat_max = state.late[:].max()
    g_lat_min = state.late[:].min()
    g_lon_max = state.lone[:].max()
    g_lon_min = state.lone[:].min()
    g_alt_max = max(state.zc.data[:]) + state.hgt
    g_alt_min = min(state.zc.data[:]) + state.hgt
    
    dt     = DT.timedelta(0,int(window/2))
    begin  = cftime.date2num(analysis_time - dt, sec_utime)
    ending = cftime.date2num(analysis_time + dt, sec_utime)
    
    data_mask = (ob_f.utime >= begin) & (ob_f.utime <= ending) & \
              (ob_f.lat <= g_lat_max) & (ob_f.lat >= g_lat_min) & \
              (ob_f.lon <= g_lon_max) & (ob_f.lon >= g_lon_min)
    
    subdata = ob_f[data_mask]

    if len(subdata.index) > 0:
        print("\n --> ComputeHx:  Total number of obs found at search time: %s \n" % len(subdata.index))
    else:
        print("\n --> ComputeHx:  No obs found at search time:  %s exiting......\n" % (analysis_time))
        sys.exit(0)



    #### IF DOING NORMAL EXPERIMENT, USE THIS
    idx, Hxf, kind, lat, lon, height, elev, azimuth = ens.calcHx(state, 
                                                               subdata['kind'].values, 
                                                               subdata['lat'].values,                                         
                                                               subdata['lon'].values,
                                                               subdata['height'].values,
                                                               subdata['elevation'].values,
                                                               subdata['azimuth'].values)

    
   #### IF DOING ONE OB TEST, USE THIS 
  # idx, Hxf, kind, lat, lon, height, elev, azimuth = ens.calcHx(state, 
  #                                                              np.array([subdata['kind']]), 
  #                                                              np.array([subdata['lat']]),                                         
  #                                                              np.array([subdata['lon']]),
  #                                                              np.array([subdata['height']]),
  #                                                              np.array([subdata['elevation']]), 
  #                                                              np.array([subdata['azimuth']]))

# At this point we have created all the Hxfs and so we can make sure we have enough obs to run

    if idx != None:
    
        nobs = np.size(idx) 
        
        print("\n --> ComputeHx:  Total number of obs found is: %d \n" % (nobs))
        
          #### IF DOING NORMAL EXPERIMENT, USE THIS
        err_var = np.append(err_var, subdata['error_var'].values[idx])   
        value   = np.append(value,   subdata['value'].values[idx])
        dates   = np.append(dates,   subdata['date'].values[idx])
        
        #### IF DOING ONE OB TEST, USE THIS 
        # err_var = np.append(err_var, subdata['error_var'])   
        # value   = np.append(value,   subdata['value'])
        # dates   = np.append(dates,   subdata['date'])
    
    else:
        print("\n  >======================================================================<\n")   
        print("\n    ComputeHx: NOBS == 0:  NO HXF's were created - EXITING computeHx!!!  ")
        print("\n    ComputeHx:  NOBS == 0:  NO HXF's were created - EXITING computeHx!!! ")
        print("\n  >======================================================================<\n"   )
        sys.exit(0)
        
# Overide the file observation std deviations with either defaults at top of script or input parameters

    for key in obs_error.keys():
        print_once = True
        for n, item in enumerate(kind):
            if int(item) == int(key):
                err_var[n] = obs_error[key][1]**2.0
            if print_once:
                print("\n --> ComputeHx:  Changing %s observational error to:  %s" % (obs_error[key][0],obs_error[key][1]))
                print_once = False

# Here we choose to create a coordinate system of x/y's based from the SW corner (lat,lon) of model grid.
# The observations' new x/y's are then in the model's coordinate system relative to reference (lat,lon) of grid

    xs, ys = pyDart.dll_2_dxy(state.late[0], lat, state.lone[0], lon, degrees=True)
    zs     = height
    
    Hxfbar = np.average(Hxf,axis=1)
    
    # We dont use this flag (is supposed to be a flag to tell one whether the obs is used for verification or assimilation, or thrown out)
    status = np.ones(nobs)
    
    # Compute standard deviation of model priors versus observation
    outlier = np.abs(Hxfbar-value)/np.sqrt(Hxf.var(ddof=1,axis=1)+err_var)
    
    # WRITE OUT priors

# Here we create the Prior file if needed.  Note, the prior file may not be same datetime as current time
    if init:
        create_prior_file(state.ne, path)

    write_prior(state.ne, kind, value, dates, err_var, xs, ys, zs, Hxf, Hxfbar, lat, lon, elev, azimuth, status, outlier, path)
  
    if final:
        newPriorFile = os.path.join(path, "Prior_%s.nc" % analysis_time.strftime("%Y-%m-%d_%H:%M:%S"))
        os.rename("Prior.nc", newPriorFile)
  
    timeHxF.stop()
    timeIO.printit("--> ComputeHx:  Total time for ensemble I/O")
    timeHxF.printit("--> ComputeHx:  Time for searching ob table and computing priors")
    timeMain.stop()
    timeMain.printit("--> ComputeHx:  Total time in minutes")

# Print out Wallclock time for ComputeHx

    now = DT.datetime.now()
    
    print("\n  ----------------------------------------------------------------------")
    print("\n                END PROGRAM ComputeHx                                   ")
    print("\n      WALLCLOCK END TIME:  %s " % now.strftime("%Y-%m-%d %H:%M")     )
    print("\n  ----------------------------------------------------------------------\n")

