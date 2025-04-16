## Namelist options for the LETKF CM1 system
import datetime as dt

#### BASIC SETUP #######

base_dir            = "/work/jessica.mcdonald/newCM1_LETKF/test"# do not include final "/"/scratch/home/jessica.mcdonald/LETKF_runs/test"
fprefix             = "cm1"
ne                  = 3
model               = "cm1r21v1/run/cm1.exe"
src                 = "cm1r21v1/run/onefile.F"
namelist            = "cm1r21v1/run/namelist.input"
landsfc             = "cm1r21v1/run/LANDUSE.TBL"
sounding            = "soundings/"
radar_obs           = "observations/8may24_cm1_obs.csv"
nthreads            = 8
ncores              = 32

model_start         = dt.datetime(2000,1,1,1)
auto_model_start    = True   # allows you to have the program automatically determine start date/time based on DA parameters
lat0                = 35.23583
lon0                = -97.46194
hgt                 = 0
xoffset             = -180000.0
yoffset             = -180000.0
microphysics        = 27

# settings to help facilitate experiments: set all to True for a normal experiment
run_setup           = True  # DA experiment only - ensemble "cook time" has already been done
run_cook            = True  # run the warm up period before DA starts
run_assim           = True  # does the assimilation 
run_forecast        = True  # does the forecast
make_plots          = True  # if you want to make the summary plots at the end (these need work... lolz)


### DATA ASSIMILATION PARAMETERS ###

DA_start_time       = dt.datetime(2024, 5, 8, 20)
DA_end_time         = dt.datetime(2024, 5, 8, 20,5) # time that DA will end (inclusive)
assim_freq          = 300  # 5 minutes
cook_period         = 2700 # 45 minutes
cook_freq           = 900  #assim_freq # note: cook_period must be evenly divisible by cook_freq
forecast_length     = 1800 # 30 minutes
forecast_freq       = assim_freq

obs_include         = ['DBZ', 'VR'] #options: DBZ, VR
obs_error           = {'VR':3, 'DBZ':7}
aInflate            = 1
outlier             = 3
nthreads            = 8
assim_window        = 30
async_freq          = 300
additive_noise      =[False,1]
mpass               = False
writeFcstMean       = True
writeAnalMean       = True
saveWeights         = False
readWeights         = False
rhoriz              = 18000.0
rvert               = 4500.0
rtime               = -600.0
cutoff              = 2
zcutoff             = 10000.0
inflate             = 1.0
print_state_stats   = True


#### IMPORTANT CM1 NAMELIST VALUES ####
## note that time, ctrlat/lon, and ptype have already been set
## other items are not listed because they can't be changed, like
## iorigin or file type

nx                  = 128
ny                  = 128
nz                  = 51
ppnode              = ncores
dx                  = 3000.0
dy                  = 3000.0
dz                  = 400.0
dtl                 = 5.0 # NOTE: this num
isnd                = 7
ihail               = 1
stretch_z           = 2
ztop                = 20000.0
str_bot             = 0.0
str_top             = 8625.0
dz_bot              = 150.0
dz_top              = 600.0
radopt              = 0


### INITIATION MECHANISM ###

nb                  = 3
tpert               = 2.0
wpert               = 1.0
tdpert              = 0.0
qvpert              = 5.0
upert               = 0.0
vpert               = 0.0
centerx             = 100000.0
centery             = 100000.0
max_x_offset        = 8000.0
max_y_offset        = 8000.0
min_z               = 0.0
max_z               = 1500.0
bub_horz_radius     = 10000.0
bub_vert_radius     = 2000.0
r_seed              = 2147483562


### ADDING NOISE TO MODEL FIELDS ###

add_noise           = False
min_dbz_4pert       = 25
tpert_noise         = 1.0
wpert_noise         = 0.5
tdpert_noise        = .25
upert_noise         = 1.0
vpert_noise         = 1.0
qvpert_noise        = 0.0
hradius             = 9000.
vradius             = 4000.
r_seed_noise        = 123321
gaussH              = 5
gaussV              = 5


#### DONT EDIT BELOW THIS ########
# this helps RUN.sh properly name/move things or sends out error information
if __name__ == "__main__":

    error_out = []
    if (cook_period % cook_freq) != 0:
        error_out.append('cook period is not evenly divisible by cook_freq, try again.  ')
        
    if ((nx % ncores) != 0) | ((ny % ncores) != 0):
        error_out.append('nx or ny is not evenly divisible by ncores, try again.  ')
    
    if len(error_out) != 0:
        print(error_out)
    else:

        if base_dir[-1] =='/':
            print(base_dir[:-1])
        else:
            print(base_dir)