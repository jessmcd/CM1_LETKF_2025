## Namelist options for the LETKF CM1 system
import datetime as dt

#### BASIC SETUP #######

base_dir            = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/CI_3min_R05_multi"# do not include final "/"
fprefix             = "cm1"
ne                  = 36
model               = "cm1r21v1/run/cm1.exe"
src                 = "cm1r21v1/run/onefile.F"
namelist            = "cm1r21v1/run/namelist.input"
landsfc             = "cm1r21v1/run/LANDUSE.TBL"
sounding            = "soundings/"
radar_obs           = "observations/8may24_cm1_5km_obs_multi.csv" #"observations/8may24_cm1_5km_obs.csv"
nthreads            = 8
ncores              = 64

model_start         = dt.datetime(2024,5,8,19,30) # manually set this if you're doing a control run!!!
auto_model_start    = False   # allows you to have the program automatically determine start date/time based on DA parameters
lat0                = 35.23583
lon0                = -97.46194
hgt                 = 0
xoffset             = -160000.0 #-180000.0 
yoffset             = -115000.0 #-125000.0
microphysics        = 27 #same as CM1 ptype

# settings to help facilitate experiments: set all to True for a normal experiment
run_setup           = False # DA experiment only - ensemble "cook time" has already been done
run_cook            = False  # run the warm up period before DA starts
run_assim           = True  # does the assimilation 
run_forecast        = True # does the forecast
make_plots          = False  # if you want to make the summary plots at the end (these need work... lol)

#### additional, more specialized settings
pre_cook            = True #IF THIS IS TRUE = run_setup and run_cook are ignored! It copies the directory below and sets up a new experiment
                           # only do this if you have "locked in" your inital CM1 set up
cook_path           = '/work/jessica.mcdonald/CM1_LETKF_2025/experiments/Control_multi'#_60

### DATA ASSIMILATION PARAMETERS ###

DA_start_time       = dt.datetime(2024, 5, 8, 20,0) # if run_assim is false, this is the start of "run forecast" if using a precooked run
DA_end_time         = dt.datetime(2024, 5, 8, 21,30) # time that DA will end (inclusive)
assim_freq          = 180  # 10 minutes
cook_period         = 1800 # 30 minutes
cook_freq           = 900  # note: cook_period must be evenly divisible by cook_freq
forecast_length     = 3600 # 60 minutes
forecast_freq       = 300  # 5 minutes

obs_include         = ['DBZ', 'VR', 'DBZ0'] #options: DBZ, VR, DBZ0, DBZ0_W(updates w instead of ref)
obs_error           = {'VR':3.0, 'DBZ':7.0, 'DBZ0':5.0, 'DBZ0_W': 0.5} #{'VR':4.24, 'DBZ':9.899, 'DBZ0':7.071, 'DBZ0_W': 0.5} #{'VR':5.196, 'DBZ':12.124, 'DBZ0':8.660}
aInflate            = 3  # 1 is letkf adaptive, 3 is RTPP
outlier             = 3
inlier              = 0.0 # set to 0 to turn off
nthreads            = 8
assim_window        = 15    # set to a small number for synthetic data (real radar data has a slight time range)
async_freq          = 0     # this is currently not really used... you can do asynchronous assimilation by adjusting the assimilation window
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
nz                  = 52
ppnode              = ncores
dx                  = 3000.0
dy                  = 3000.0
dz                  = 400.0
dtl                 = 6.0
isnd                = 7
ihail               = 1
stretch_z           = 1
ztop                = 25000.0
str_bot             = 0.0
str_top             = 12400.0
dz_bot              = 200
dz_top              = 600.0
radopt              = 0



### INITIATION MECHANISM ###

nb                  = 3
tpert               = 3.0
wpert               = 1.0
tdpert              = 0.0
qvpert              = 5.0
upert               = 0.0
vpert               = 0.0
centerx             =  80000.0
centery             = 120000.0
centerz             = 1500.0
max_x_offset        = 20000.0
max_y_offset        = 20000.0
#min_z               = 0.0
#max_z               = 1500.0
bub_horz_radius     = 10000.0
bub_vert_radius     = 2000.0
r_seed              = 2147483562


### ADDING NOISE TO MODEL FIELDS ###

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


#### DONT EDIT BELOW THIS ########
# this helps RUN.sh properly name/move things or sends out error information
if __name__ == "__main__":

    error_out = []
    if (cook_period % cook_freq) != 0:
        error_out.append('cook period is not evenly divisible by cook_freq, try again.  ')
        
    if ((nx % ncores) != 0) | ((ny % ncores) != 0):
        error_out.append('nx or ny is not evenly divisible by ncores, try again.  ')
        
    if ('DBZ0' in obs_include) & ('DBZ0_W' in obs_include):
        error_out.append('you included both DBZ0 and DBZ0_W. Please only select one.')

    if (assim_freq < 190) & (dtl > 7):
        error_out.append('You need to decrease your timestep (dtl). If not, comment out lines 146-147 in namelist.py')
    
    if len(error_out) != 0:
        print(error_out)
    else:

        if base_dir[-1] =='/':
            print(base_dir[:-1])
        else:
            print(base_dir)
