#!/usr/bin/env python
#
# System imports
#

#import datetime as dt

import numpy as np
import sys, os
import datetime
from optparse import OptionParser
import f90nml
import json

import sys
sys.path.append('../run/')
import namelist
os.chdir('../src/') # back to original directory
print(os.getcwd())

# variable prep
_microphysics_options = {"morrison": 5, "zvdLFO":  28, "thompson": 3, "zvd": 26, '27':"zvdh" }
_obs_codes = {'DBZ':12, 'VR':11, 'DBZ0':13, 'DBZ0_W':14}

if namelist.auto_model_start:
    ms = namelist.DA_start_time - datetime.timedelta(seconds=namelist.cook_period)
else:
    ms = namelist.model_start

ob_error_dict={}
for k,v in namelist.obs_error.items():
   ob_error_dict[_obs_codes[k]] = [k,v]


# fill dictionary with namelist options
defaults = {
"base_dir":         namelist.base_dir,           
"fprefix":          namelist.fprefix,
"ne":               namelist.ne,                 
"model":            namelist.model,
"src":              namelist.src,
"namelist":         namelist.namelist,
"landsfc":          namelist.landsfc,
"sounding":         namelist.sounding,           
"radar_obs":        namelist.radar_obs,        
"YEAR":             ms.year,
"MONTH":            ms.month,
"DAY":              ms.day,
"HOUR":             ms.hour,
"MINUTE":           ms.minute,
"SECOND":           ms.second,
"lat0":             namelist.lat0, 
"lon0":             namelist.lon0,
"hgt":              namelist.hgt,
"xoffset":          namelist.xoffset,
"yoffset":          namelist.yoffset,
"microphysics":     _microphysics_options[str(namelist.microphysics)],

"cook_period":      namelist.cook_period,
"cook_freq":        namelist.cook_freq,
"forecast_length":  namelist.forecast_length,
"forecast_freq":    namelist.forecast_freq,

"INIT": {
    'nb':           namelist.nb, 
    'tpert':        namelist.tpert,  
    'wpert':        namelist.wpert,
    'tdpert':       namelist.tdpert,
    'qvpert':       namelist.qvpert,
    'upert':        namelist.upert,
    'vpert':        namelist.vpert,
    'centerx':      namelist.centerx, 
    'centery':      namelist.centery, 
    'centerz':      namelist.centerz, 
    'max_x_offset': namelist.max_x_offset, 
    'max_y_offset': namelist.max_y_offset, 
    #'zbmin':        namelist.min_z,
    #'zbmax':        namelist.max_z,
    'rbubh':        namelist.bub_horz_radius,
    'rbubv':        namelist.bub_vert_radius, 
    'r_seed':       namelist.r_seed,
            },
    
"ADD_NOISE": {
    "min_dbz_4pert":  namelist.min_dbz_4pert,
    "min_inno_4pert": namelist.min_inno_4pert,
    'tpert':          namelist.tpert_noise,
    'wpert':          namelist.wpert_noise,
    'tdpert':         namelist.tdpert_noise,
    'upert':          namelist.upert_noise,
    'vpert':          namelist.vpert_noise,
    'qvpert':         namelist.qvpert_noise,    
    'hradius':        namelist.hradius, 
    'vradius':        namelist.vradius,
    'r_seed':         namelist.r_seed_noise
            },
                      
"DA_PARAMS" : {
    "obs_errors":        ob_error_dict,
    "aInflate":          namelist.aInflate,     
    "outlier":           namelist.outlier, 
    "inlier":            namelist.inlier,  
    "nthreads":          namelist.nthreads,      
    "assim_window":      namelist.assim_window,                                       
    "assim_freq":        namelist.assim_freq,     
    "async_freq":        namelist.async_freq,
    "cook":              namelist.cook_period,       
    "additive_noise":    namelist.additive_noise,  
    "mpass":             namelist.mpass,
    "writeFcstMean":     namelist.writeFcstMean,
    "writeAnalMean":     namelist.writeAnalMean,
    "saveWeights":       namelist.saveWeights,
    "readWeights":       namelist.readWeights,
    "rhoriz":            namelist.rhoriz,
    "rvert":             namelist.rvert,
    "rtime":             namelist.rtime,
    "cutoff":            namelist.cutoff,
    "zcutoff":           namelist.zcutoff,
    "inflate":           namelist.inflate,
    "print_state_stats": namelist.print_state_stats,
    "DA_start_time":     namelist.DA_start_time,
    "DA_end_time":       namelist.DA_end_time,
    "obs_included":      namelist.obs_include
               },
    
"base_path": "", 
"fcst_path": "", 
"plots_path": "",
"fcst_members": [],
}

cm1_nml = {"cm1namelist": [
 ('param0',  'nx', namelist.nx),
 ('param0',  'ny', namelist.ny),
 ('param0',  'nz', namelist.nz),
 ('param0',  'ppnode', namelist.ppnode),
 ('param1',  'dx', namelist.dx),
 ('param1',  'dy', namelist.dy),
 ('param1',  'dz', namelist.dz),
 ('param1',  'dtl', namelist.dtl),
 ('param1',  'run_time', 0),
 ('param1',  'rstfrq', 0.0),
 ('param1',  'statfrq',  namelist.dtl),
 ('param2',  'ptype', namelist.microphysics),
 ('param2',  'rstnum', 0),
 ('param2',  'irst', 0),
 ('param2',  'iorigin', 1),
 ('param2',  'isnd', namelist.isnd),
 ('param2',  'imove', 0),
 ('param2',  'iinit', 0),
 ('param2',  'ihail', namelist.ihail),
 ('param6',  'stretch_z', namelist.stretch_z),
 ('param6',  'ztop', namelist.ztop),
 ('param6',  'str_bot', namelist.str_bot),
 ('param6',  'str_top', namelist.str_top),
 ('param6',  'dz_bot', namelist.dz_bot),
 ('param6',  'dz_top', namelist.dz_top),
 ('param9',  'output_format', 2),
 ('param9',  'output_filetype', 2),
 ('param11', 'radopt', namelist.radopt),
 ('param11', 'ctrlat', defaults['lat0']),
 ('param11', 'ctrlon', defaults['lon0']),
 ('param11', 'year',   defaults['YEAR']),
 ('param11', 'month',  defaults['MONTH']),
 ('param11', 'day',    defaults['DAY']),
 ('param11', 'hour',   defaults['HOUR']),
 ('param11', 'minute', defaults['MINUTE']),
 ('param11', 'second', defaults['SECOND']),
 ('param16', 'restart_format', 2),
 ('param16', 'restart_filetype', 2),
 ('param16', 'restart_file_theta', True),
 ('param16', 'restart_file_dbz', True),
 ('param16', 'restart_file_pi0', True),
 ('param16', 'restart_file_rho0', True),
 ('param16', 'restart_use_theta', True)]}

# Now JOIN the cm1_nm1 data into defaults...
defaults.update(cm1_nml)

debug = True


# quick cleanup of filepaths:
path = defaults['radar_obs']
if os.path.exists(path) == False:
    defaults['radar_obs'] = os.path.join(os.getcwd().replace('src', 'run'), path)


#=======================================================================
#
#  Python setup script for CM1-LETKF
#
#=======================================================================

#-----------------------------------------------------------------------------------------------------------------------
# FILE DICTIONARY

#           dir level                from                      to                type of
#            to copy                location                  location             copy 

#                                                                               (1=link, 2=cp, 3=modified cp)
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
    
    if debug: print(f"LINKIT:  ARG[0]: {dir_from_target}  ARG[1]:  {dir_to_target}")
    if link_option == 0:  return

    from_path = dir_from_target
    to_path   = dir_to_target

    if link_option == 1:
        LINK_CMD =f"ln -s {from_path} {to_path}" 
        
        if os.system(LINK_CMD) != 0:
            print(f"\n ERROR!!!\n ERROR!!! FAILIED TO EXECUTE: {LINK_CMD}\n ERROR!!!")
            sys.exit(1)
            
        print("Linked " + dir_from_target + " to directory  " + dir_to_target)

    
    if link_option == 2:
        CP_CMD = f"cp  {from_path} {to_path}" 
        
        if os.system(CP_CMD) != 0:
            print(f"\n ERROR!!!\n ERROR!!! FAILIED TO EXECUTE: {LINK_CMD}")
            if not os.path.exists(dir_from_target):
                print(f"\nCOMMAND FAILED because {dir_from_target} does not exist\n ")
            elif not os.path.join(dir_to_target):
                print(f"COMMAND FAILED because{dir_to_target} does not exist\n ")
            else:
                print("\nBOTH FILE AND DIRECTORY EXISTS....something else f__ked up here....\n")
            print("ERROR!!!\n") 
            sys.exit(1)
            
        print(f"Copied {dir_from_target} to directory {dir_to_target}")

              
    if link_option == 3:
        CP_CMD = f"cp -r {from_path} {to_path}" 
        
        if os.system(CP_CMD) != 0:
            print(f"\n ERROR!!!\n ERROR!!! FAILIED TO EXECUTE: {LINK_CMD}")
            if not os.path.exists(dir_from_target):
                print(f"\nCOMMAND FAILED because {dir_from_target} does not exist\n ")
            elif not os.path.join(dir_to_target):
                print(f"COMMAND FAILED because{dir_to_target} does not exist\n ")
            else:
                print("\nBOTH FILE AND DIRECTORY EXISTS....something else f__ked up here....\n")
            print("ERROR!!!\n") 
            sys.exit(1)

        print(f"Copied {dir_from_target} to directory {dir_to_target}")

    return

#===============================================================================================================
# main script

print("\n<<<<<===========================================================================================>>>>>>\n")

#///////////////////////////////////////////////////////////////////////////////////////////////////////
# Section finishing create data structure and create directories for run
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

print(defaults['base_dir'])
defaults['base_path']  = defaults['base_dir']
defaults['plots_path'] = os.path.join(defaults['base_dir'], "plots")
defaults['fcst_path']  = defaults['base_dir']
defaults['date_time']  = ms 

if not os.path.exists(defaults['base_path']):
    os.mkdir(defaults['base_path'])
else:
    timestamp  = datetime.datetime.fromtimestamp( os.path.getctime(defaults['base_path'] ) )     
    newbasedir = defaults['base_path'] + "_" + timestamp.isoformat().replace('T', '_')

    print(f"\nERROR:  EXPERIMENT DIRECTORY ALREADY EXISTS, MOVING IT TO: {newbasedir} \n")

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
    from_target = os.path.join(os.getcwd().replace('src', 'run'),defaults[item[0]])
    to_target   = os.path.join(defaults['base_path'],os.path.basename(defaults[item[0]]))
    ret         = linkit(from_target, to_target, item[1])

#-----------------------------------------------------------------------------------------------------
# Write now we assume that the namelist each member uses is the same namelist.  So we just need to 
# edit the namelist.input file found at the top level of the run directory.  
cm1namelist = f90nml.read(os.path.join(defaults['base_path'],"namelist.input"))


# This uses the information at the top defaults level to alter the values of the default namelist.

for tup in defaults['cm1namelist']:
    cm1namelist[tup[0]][tup[1]] = tup[2]
    
print(cm1namelist)
cm1namelist.write(os.path.join(defaults['base_path'],"namelist.input"), force=True)

#-----------------------------------------------------------------------------------------------------
# Now create member directories and namelists

## note: you now need to update the namelist location to be your base path, not the original location 
## I'm not sure if before updating the current directory namelist updated the cm1 namelist? 
# or if I changed something? but you need to copy the modified namelist that was just saved above
defaults['namelist'] = os.path.join(defaults['base_path'],"namelist.input")

for n in np.arange(1,defaults['ne']+1):

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
                    from_target = os.path.join(os.getcwd().replace('src', 'run'),defaults[item[0]], f'Run{n:02d}Sounding.txt')
                    to_target   = os.path.join(fcst_member,"input_sounding")
                    ret         = linkit(from_target, to_target, item[1])
       
                else:
                    from_target = os.path.join(os.getcwd().replace('src', 'run'),defaults[item[0]])
                    to_target   = os.path.join(fcst_member,os.path.basename(defaults[item[0]]))
                    ret         = linkit(from_target, to_target, item[1])

def myconverter(o):
    if isinstance(o, datetime.datetime):
        return o.__str__()
        
with open(f"{defaults['base_path']}/letkf.exp", 'w') as handle:
    json.dump(defaults, handle, default = myconverter)