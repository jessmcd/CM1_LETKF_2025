#!/usr/bin/env python
#
# System imports
#

import sys, os
import datetime
from optparse import OptionParser
import numpy as N
import f90nml
import json

# these will change parameters in the namelist file for microphysics

_microphysics_options = {"morrison": 5, "zvdLFO":  28, "thompson": 3, "zvd": 26, "zvdh": 27}

# DEFAULTS: blank key variables are set by program:  do not set directly!

defaults = {
            "base_dir":  "RUN_LETKF",                    # this is set in experiment_driver.py
            "fprefix":   "cm1",
    
            "ne":         20,                            # this is set in experiment_driver.py
            "model":     "cm1r21v1/run/cm1.exe",
            "src":       "cm1r21v1/run/onefile.F",
            "namelist":  "cm1r21v1/run/namelist.input",
            "landsfc":   "cm1r21v1/run/LANDUSE.TBL",
            "sounding":  "soundings",                     # this is set in experiment_driver.py
            "radar_obs": 'Obs/8may24_cm1_obs.csv',        # this is set in experiment_driver.py

# Starting YYYY-MM-DD-HH-MM-SS for model run

            "YEAR":      2024,
            "MONTH":        5,
            "DAY":          8,
            "HOUR":        19,
            "MINUTE":      15,
            "SECOND":       0,

# Grid location:  lat0/lon0 is a reference point (often radar loc)
# Grid location:  xoffset/yoffset/hgt are physical lengths in meters offset from (lon0,lat0,0)
# example: if the radar is at x = 180km and y = 140 km, then xoffset would be -180000 and yoffset would be -140000

            "lat0":          35.23583, 
            "lon0":         -97.46194,
            "hgt":           0.,
            "xoffset":      -180000.,
            "yoffset":      -180000.,

# Microphysics

            "microphysics": "zvdh",

# Initial 1D perturbations used in ens_IC_pertUV

            "pscale":   2.0,
            "rampS":    4.0,
            "rampZ":    10000.,

# Initial 3D perturbations used in ens_IC_pert_from_box
# Coordinates are relative to the SW corner of the box which is (0,0) meters.
# Box is not specified using any offsets or lat lons.

            # "IC_BOX": {
            #            'nb':             3,
            #            'tpert':        2.0,
            #            'wpert':        1.0,
            #            'tdpert':       0.0,
            #            'upert':        0.0,
            #            'vpert':        0.0,
            #            'qvpert':       5.0,
            #            'xbmin':      90000,#15000.0,
            #            'xbmax':     110000, #35000.0,
            #            'ybmin':      90000,#15000.0,
            #            'ybmax':     110000, #55000.0,
            #            'zbmin':        0.0,
            #            'zbmax':     1500.0,
            #            'rbubh':    10000.0,
            #            'rbubv':     2000.0,
            #         'bbletype':          1,
            #           'r_seed': 2147483562,
            #            },

    
            "INIT": {
                       'nb':                 3, # number of warm bubbles
                       'tpert':            2.0, # 
                       'wpert':            1.0,
                       'tdpert':           0.0,
                       'qvpert':           5.0,
                       'upert':            0.0,
                       'vpert':            0.0,
                       
                       'centerx':       100000, #meters, approx location of warm bubbles
                       'centery':       100000, #meters, approx location of warm bubbles
                       'max_x_offset':    8000, # max random displacment from centerx for a warm bubble
                       'max_y_offset':    8000, # max random displacment from centery for a warm bubble
                       'zbmin':            0.0,
                       'zbmax':         1500.0,
                       'rbubh':        10000.0,
                       'rbubv':         2000.0, 
                      'r_seed':     2147483562, # leave this alone
                       },
    
# Parameters for the additive noise

            "ADD_NOISE": {
                          "min_dbz_4pert":  25.,
                          'tpert':          1.0,
                          'wpert':          0.5,
                          'tdpert':         0.25,
                          'upert':          1.0,
                          'vpert':          1.0,
                          'qvpert':         0.0,    # this number means add perturbations up to 1 g/kg (but limited to 99% RH)
                          'hradius':      9000., 
                          'vradius':      4000.,
                           'r_seed':     123321, 
                           'gaussH':          5, 
                           'gaussV':          5, 
                          },

# Parameters for the data assimilation
                        
           "DA_PARAMS" : {
                           "obs_errors":     {           # the errors that are used for observations
                                              11:  ["VR", 3.0],
                                              12:  ["DBZ",7.0],
                                             },
                           "aInflate":             1,       # type(int): 0 => no adapt inflat / 1 => LETKF AI / 2 => WH2010 RTPS / 3 => RTPP
                           "outlier":              3,       # type(int): Outlier threshold:  None means dont threshold, else set to sigma (e.g., 3, 5, 7 etc.)
                           "nthreads":            1,       # type(int):  number of threads used to run the ensemble members and enkf (if parallel)
                           "assim_window":       30,        # edited for synthetic data, original was 300,       # type(int):  window for assimilation
                                                            #             (note that the assim window will be +/- (assim_window/2) )
                           "assim_freq":         300,       # type(int):  used to set asynchronous DA assimilation
                           "async_freq":         300,
                           "cook":              2700,       # type(int): time to pre-cook initial perturbations
                           "additive_noise":    [False,1],   # type(list): whether to add noise based on 1=cref, 2 = adaptive-inflation field
                           "mpass":             False,
                           "writeFcstMean":     True,
                           "writeAnalMean":     True,
                           "saveWeights":       False,
                           "readWeights":       False,
                           "rhoriz":            18000.,
                           "rvert":             4500.,
                           "rtime":             -600.,
                           "cutoff":            2,
                           "zcutoff":           10000.,
                           "inflate":           1.0,
                           "print_state_stats": True,
                          },

# Dont mess with stuff below this line, as they are set by program

            "base_path": "", 
            "fcst_path": "", 
            "plots_path": "",
            "fcst_members": [],
            
           }
           
# If you want to change namelist input file, this is the place to do this...
# Create a new list tuple item to overwrite what is in the  namelist from the namelist directory.
# IORIGIN MUST BE SET To "1", or the coordinate system will be a mess...

# I created a second dictionary to be able to use the defaults information where needed -
#   then I join them together into 1 dictionary that is stored for the run

cm1_nml = {"cm1namelist": [
                           ('param0',  'nx', 128),
                           ('param0',  'ny', 128),
                           ('param0',  'nz', 51),
                           ('param0',  'ppnode', 32),
                           ('param1',  'dx', 3000.),
                           ('param1',  'dy', 3000.),
                           ('param1',  'dz', 400.),
                           ('param1',  'dtl', 5.0), # NOTE: this number MUST be a factor of 300!
                           ('param1',  'run_time', 0),
                           ('param1',  'rstfrq', 0.0),
                           ('param2',  'ptype', _microphysics_options[defaults['microphysics']]),
                           ('param2',  'rstnum', 0),
                           ('param2',  'irst', 0),
                           ('param2',  'iorigin', 1),
                           ('param2',  'isnd', 7),
                           ('param2',  'imove', 0),
                           ('param2',  'iinit', 0),
                           ('param2',  'ihail', 1),
                           ('param6',  'stretch_z', 2),
                           ('param6',  'ztop', 20000.),
                           ('param6',  'str_bot', 0.0),
                           ('param6',  'str_top', 8625.),
                           ('param6',  'dz_bot', 150.),
                           ('param6',  'dz_top', 600.),
    
                           ('param9',  'output_format', 2),
                           ('param9',  'output_filetype', 2),
    
                           ('param11', 'radopt', 0),
                           ('param11', 'ctrlat', defaults['lat0']),
                           ('param11', 'ctrlon', defaults['lon0']),
                           ('param11', 'year',   defaults['YEAR']),
                           ('param11', 'month',  defaults['MONTH']),
                           ('param11', 'day',    defaults['DAY']),
                           ('param11', 'hour',   defaults['HOUR']),
                           ('param11', 'minute', defaults['MINUTE']),
                           ('param11', 'second', defaults['SECOND']),
    
                           ('param16',  'restart_format', 2),
                           ('param16',  'restart_filetype', 2),
                           ('param16',  'restart_file_theta', True),
                           ('param16',  'restart_file_dbz', True),
                           ('param16',  'restart_file_pi0', True),
                           ('param16',  'restart_file_rho0', True),
                           ('param16',  'restart_use_theta', True),
                           

                          ]}
# Now JOIN the cm1_nm1 data into defaults...

defaults.update(cm1_nml)

debug = True

#=======================================================================
#
#  Python setup script for CM1-LETKF
#
#=======================================================================

# Extra help

myhelp = """

         A general setup script for the LETFK enkf runs.

         Usage examples:

         python create_fcst_CM1.py 
          
                                 ==> create an experiment directory,

                                     copy/links in the needed executables and scripts,

                                     and creates the ensemble directory structures.

         """ 

#-----------------------------------------------------------------------------------------------------------------------
# FILE DICTIONARY

#           dir level                from                      to                type of
#            to copy                location                  location             copy 

#                                                                               (1=link, 2=cp)
#-----------------------------------------------------------------------------------------------------------------------
DIR_DICT= {
            'top':     [['model', 2], ['src', 2], ['namelist', 2], ['landsfc', 2], ['sounding', 3]], #J modified sounding, it was 2 before

            'fcst':    [['model', 2], ['src', 1], ['namelist', 1], ['landsfc', 1], ['sounding', 2]],
           }

#=======================================================================================================================  
#///////////////////////////////////////////////////////////////////////////////////////////////////////
# Function to do the link/copy of the needed scripts, info, etc.
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

def linkit(dir_from_target,dir_to_target,link_option):
    '''JMCDONALD added option 3'''


    if debug: print(("LINKIT:  ARG[0]: %s  ARG[1]:  %s" % (dir_from_target,dir_to_target)))

    if link_option == 0:  return

    from_path = dir_from_target
    to_path   = dir_to_target

    if link_option == 1:

        LINK_CMD ="ln -s %s %s" % (from_path, to_path)

        if os.system(LINK_CMD) != 0:

            print("\nERROR!!! ") 

            print(("ERROR!!!  Failed to EXECUTE: " + LINK_CMD))

            print("ERROR!!!\n") 

            sys.exit(1)

        print(("Linked " + dir_from_target + " to directory  " + dir_to_target))

    if link_option == 2:

        CP_CMD = "cp  %s %s" % (from_path, to_path)

        if os.system(CP_CMD) != 0:

            print("\nERROR!!! ") 

            print(("ERROR!!!  Failed to EXECUTE: " + CP_CMD))

            if not os.path.exists(dir_from_target):

                print(("\nCOMMAND FAILED because %s does not exist\n " % dir_from_target))

            elif not os.path.join(dir_to_target):

                print(("\nCOMMAND FAILED because %s does not exist\n " % dir_to_target))

            else:

                print("\nBOTH FILE AND DIRECTORY EXISTS....something else f__ked up here....\n")

            print("ERROR!!!\n") 

            sys.exit(1)

        print(("Copied " + dir_from_target + " to directory  " + dir_to_target))

    if link_option == 3:

        CP_CMD = "cp -r %s %s" % (from_path, to_path)

        if os.system(CP_CMD) != 0:

            print("\nERROR!!! ") 

            print(("ERROR!!!  Failed to EXECUTE: " + CP_CMD))

            if not os.path.exists(dir_from_target):

                print(("\nCOMMAND FAILED because %s does not exist\n " % dir_from_target))

            elif not os.path.join(dir_to_target):

                print(("\nCOMMAND FAILED because %s does not exist\n " % dir_to_target))

            else:

                print("\nBOTH FILE AND DIRECTORY EXISTS....something else f__ked up here....\n")

            print("ERROR!!!\n") 

            sys.exit(1)

        print(("Copied " + dir_from_target + " to directory  " + dir_to_target))

    return

#===============================================================================================================
# main script

print("\n<<<<<===========================================================================================>>>>>>\n")

#///////////////////////////////////////////////////////////////////////////////////////////////////////
# Section to parse command line arguments, and use information to create default data structure for run
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

usage  = "usage: %prog [options] arg \n" + myhelp

parser = OptionParser(usage)

parser.add_option("-b", "--base", dest="base_dir", default = None, type="string", help="Name of the exper directory, \
                           this is the top level directory from which everything else will be under...")

parser.add_option("-n", "--ne",  dest="ne",                 type="int", help="Number of ensemble members")

parser.add_option("-m", "--cm1", dest="model",     default = None, type="string", help="FULL PATH to cm1 model executable, \
                           the default is to use the cm1r18/run/cm1.exe from same directory as run script")

parser.add_option("-s","--model_start"    , dest="model_start",  default=None,  type="string", help="time in YYYY,mm,dd,HH,MM,SS format, sets the start time in the CM1 files")
parser.add_option("-i", "--init_sounding" , dest="sounding_loc", default=None,  type="string", help="local path to the directory containing sounding files. \
                                                                                            Sounding name format should be RunXXXSounding.txt, with XXX = 0-padded member number") 
parser.add_option("-o",  "--obs_loc",       dest="obs_loc",  default=None,  type="string", help="path to radar obs file")

(options, args) = parser.parse_args()

# Figure out what information user has provided and then fill in the option data structure

if options.base_dir:
    defaults['base_dir'] = options.base_dir

if options.model:
    defaults['model'] = options.model

if options.sounding_loc:
    defaults['sounding'] = options.sounding_loc 
    
if options.obs_loc:
    defaults['radar_obs'] = options.obs_loc 

if not options.ne:
    options.ne = defaults['ne']
else:
    defaults['ne'] = options.ne

if options.model_start:
    year, month, day, hour, minute, second = options.model_start.split(',')
    defaults["YEAR"]   = int(year)  
    defaults["MONTH"]  = int(month)  
    defaults["DAY"]    = int(day)  
    defaults["HOUR"]   = int(hour)  
    defaults["MINUTE"] = int(minute)  
    defaults["SECOND"] = int(second)  
 

#///////////////////////////////////////////////////////////////////////////////////////////////////////
# Section finishing create data structure and create directories for run
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

# cwd = os.getcwd()

# defaults['base_path']  = os.path.join(cwd, defaults['base_dir'])
# defaults['plots_path'] = os.path.join(cwd, defaults['base_dir'], "Plots")
# defaults['fcst_path']  = os.path.join(cwd, defaults['base_dir'])

print(defaults['base_dir'])
defaults['base_path']  = defaults['base_dir']
defaults['plots_path'] = os.path.join(defaults['base_dir'], "Plots")#os.path.join(cwd, defaults['base_dir'], "Plots")
defaults['fcst_path']  = defaults['base_dir']


defaults['date_time']  = datetime.datetime(defaults['YEAR'],   \
                                           defaults['MONTH'],  \
                                           defaults['DAY'],    \
                                           defaults['HOUR'],   \
                                           defaults['MINUTE'], \
                                           defaults['SECOND']) 

if not os.path.exists(defaults['base_path']):
    os.mkdir(defaults['base_path'])
else:
    timestamp  = datetime.datetime.fromtimestamp( os.path.getctime(defaults['base_path'] ) )     
    newbasedir = defaults['base_path'] + "_" + timestamp.isoformat().replace('T', '_')

    print(("\nERROR:  EXPERIMENT DIRECTORY ALREADY EXISTS, MOVING IT TO: %s \n" % (newbasedir)))

    os.rename(defaults['base_path'], newbasedir)
    os.mkdir(defaults['base_path'])

if not os.path.exists(defaults['plots_path']):
    os.mkdir(defaults['plots_path'])

#///////////////////////////////////////////////////////////////////////////////////////////////////////
# Section to copy/link needed information for letkf run
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

print("\n\nCreating directory structure and linking/copying CM1 files\n\n")

# Set up top level directory, cause everything else is copied from it

for item in DIR_DICT['top']:
    from_target = os.path.join(os.getcwd(),defaults[item[0]])
    to_target   = os.path.join(defaults['base_path'],os.path.basename(defaults[item[0]]))
    ret         = linkit(from_target, to_target, item[1])

#-----------------------------------------------------------------------------------------------------
# Write now we assume that the namelist each member uses is the same namelist.  So we just need to 
# edit the namelist.input file found at the top level of the run directory.  
# 
# HANDY Python module:  f90nml  -->  this is why python is great, someone already did this!!!!!!

namelist = f90nml.read(os.path.join(defaults['base_path'],"namelist.input"))


# This uses the information at the top defaults level to alter the values of the default namelist.

for tup in defaults['cm1namelist']:
    namelist[tup[0]][tup[1]] = tup[2]
    
print(namelist)
namelist.write(os.path.join(defaults['base_path'],"namelist.input"), force=True)

#-----------------------------------------------------------------------------------------------------
# Now create member directories and namelists

## note: you now need to update the namelist location to be your base path, not the original location 
## I'm not sure if before updating the current directory namelist updated the cm1 namelist? 
# or if I changed something? but you need to copy the modified namelist that was just saved above
defaults['namelist'] = os.path.join(defaults['base_path'],"namelist.input")

for n in N.arange(1,defaults['ne']+1):

# Create forecast directory

    fcst_member = "%s/member%3.3i" % (defaults['fcst_path'], n)
    os.mkdir(fcst_member)
    defaults['fcst_members'].append(fcst_member)
    
# Copy needed stuff into directories

    for key in list(DIR_DICT.keys()):
        
        if (key == 'fcst'):
            for item in DIR_DICT[key]:
                print(item[0])

                if item[0] == 'sounding':
                    #from_target = os.path.join(defaults['base_path'],os.path.basename(defaults[item[0]]), f'Run{(n-1):02d}Sounding.txt')
                    from_target = os.path.join(defaults[item[0]], f'Run{(n-1):02d}Sounding.txt')
                    to_target   = os.path.join(fcst_member,"input_sounding")
                    ret         = linkit(from_target, to_target, item[1])
       
                else:
                    from_target = os.path.join(os.getcwd(),defaults[item[0]])
                    to_target   = os.path.join(fcst_member,os.path.basename(defaults[item[0]]))
                    ret         = linkit(from_target, to_target, item[1])

def myconverter(o):
    if isinstance(o, datetime.datetime):
        return o.__str__()
        
# with open("%s/%s.exp" % (defaults['base_path'],defaults['base_dir']), 'w') as handle:
#     json.dump(defaults, handle, default = myconverter)

with open("%s/%s.exp" % (defaults['base_path'],defaults['base_dir'].split('/')[-1]), 'w') as handle:
    json.dump(defaults, handle, default = myconverter)
