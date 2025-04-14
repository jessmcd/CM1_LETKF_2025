#!/usr/bin/env python

import os
#import contextlib

print("\nStarting CM1 OSSE experiment")

ensN=20
base_dir = "RUN_LETKF"  # name of the directory where all of your model output will go


# #--------------------------------------------------------------------------
# #Initialize the run, and add perturbations to the backround and 3D fields

os.system(f"python create_run_letkf.py -n {ensN} -b {base_dir}") 
os.system(f"python run_fcst.py -e {base_dir}/{base_dir}.exp -i --nthreads 1")
os.system(f"python ens.py -e {base_dir}/{base_dir}.exp --init0 -t 2024,5,8,19,15,0 --write ")


# #--------------------------------------------------------------------------
# # this is the cook period.... try 45 minutes not 20 minutes!

os.system(f"python /work/jessica.mcdonald/CM1_LETKF_2025/run_fcst.py -e {base_dir}/{base_dir}.exp --run_time 2700 -t 2024,05,08,19,15,00 --nthreads 1")

# --------------------------------------------------------------------------
# Now loop through the cycling at 5 min intervals

times = ['2024,05,08,20,00,00', '2024,05,08,20,05,00', '2024,05,08,20,10,00', '2024,05,08,20,15,00', \
         '2024,05,08,20,20,00', '2024,05,08,20,25,00', '2024,05,08,20,30,00', '2024,05,08,20,35,00', \
         '2024,05,08,20,40,00', '2024,05,08,20,45,00', '2024,05,08,20,50,00', '2024,05,08,20,55,00', '2024,05,08,21,00,00']



for time in times:
    print(f' **************** \n **************** \n now starting time = {time}!!!!')

    os.system(f"python /work/jessica.mcdonald/CM1_LETKF_2025/run_filter.py --exper {base_dir}/{base_dir}.exp -t {time} --freq -300 --nthreads 8" )

    if time != times[-1]:  # dont the crefs or last 5 min forecast - do the pure forecast at the end

        os.system(f"python /work/jessica.mcdonald/CM1_LETKF_2025/run_fcst.py -e {base_dir}/{base_dir}.exp --run_time 300 -t {time} --nthreads 1" )

#--------------------------------------------------------------------------
# Make a 30 minute forecast

os.system(f"python /work/jessica.mcdonald/CM1_LETKF_2025/run_fcst.py -e {base_dir}/{base_dir}.exp --run_time 1800 -t {times[-1]} --nthreads 1")

#--------------------------------------------------------------------------
# Completed (hopefully) simple synchronous experiment

#--------------------------------------------------------------------------
# Make a few plots every 10 minutes

for time in times[::2]:
    os.system(f"python /work/jessica.mcdonald/CM1_LETKF_2025/ens.py -e {base_dir}/{base_dir}.exp -t {time} -v W --plot9" )
    os.system(f"python /work/jessica.mcdonald/CM1_LETKF_2025/ens.py -e {base_dir}/{base_dir}.exp -t {time} -v WZ --plot9" )
    os.system(f"python /work/jessica.mcdonald/CM1_LETKF_2025/ens.py -e {base_dir}/{base_dir}.exp -t {time} -v DBZ --plot8")

#--------------------------------------------------------------------------
# Creat DA diagnostics 

os.system(f"python DBZ_CR.py  -d {base_dir} -t DBZ_CR  --noshow")
os.system(f"python DBZ_INV.py -d {base_dir} -t DBZ_INV --noshow")
os.system(f"python VR_CR.py   -d {base_dir} -t VR_CR   --noshow")
os.system(f"python VR_INV.py  -d {base_dir} -t VR_INV  --noshow")


os.system(f"mv *.pdf {base_dir}/Plots/")

print("\nEnded CM1 OSSE experiment")

