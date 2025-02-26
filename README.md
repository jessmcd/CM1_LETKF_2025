2025 update

Install a miniconda2 env in your home directory.

Update conda:  conda update conda

Install (using conda -c conda-forge):  netCDF4, matplotlib, numpy, spicy, pyproj, potables, pushup, proj4, json

Install f90nml:  conda install -c anaconda f90nml

————  Consider this as your “base library” ——————

Now to protect that install from being trashed:

conda create -n main27 --clone base

conda activate main27

To check to see if all that is working write - download the little import file below:  python test_import.py

All the imports should work, except Basemap.

—— To get basemap installed —

Download baseman from the git repo:  git clone https://github.com/matplotlib/basemap.git

Compile geos3.3 - install it locally on your home directory, and then set the environment variable GEOS_DIR to point at that directory.

python setup.py install

——————— basemap should be installed ———

python test_import.py

Should now work.

For the f2py compile, you can set explicitly the compilers for f2py to use from anywhere on the system.  So I have set in my .tcshrc

# Compiler stuff

setenv CC "/opt/local/bin/gcc-mp-7"
setenv CXX "/opt/local/bin/g++-mp-7"
setenv FC "/opt/local/bin/gfortran-mp-7"
setenv FOPTS "-O2 -m64 -ffixed-line-length-132"

#
# How to run the CM1_LETKF system
#
#

0.  Required software:

    Anaconda python distribution:  need pytables, netCDF4, pyproj, basemap, and probably something else...
    Gfortran > 4.8
    netCDF installation (I use homebrew)

1.  Compilation.

a)  compile the CM1r18v2 code (not the code from the G. Bryan site, I need to retro my
    altered I/O code in as of yet).

b)  compile the code in fsrc:  type fcompile.py, make sure at the end you get:

     ==========================================================================================


     Successfully compiled file: fpython2.f90

     Object file is: fpython2.so

        --> fpython2 was successfully imported into python, you should be good to go...

     
     ==========================================================================================

   If you get a series of link errors complaining about x86_64 incompatibilities, cp "Plotting/gnu.py" into
   "~user/anaconda/lib/python2.7/site-packages/numpy/distutils/fcompiler/." as this should fix it. Try the compile
   again.


2.  There are two main python scripts and one csh script that runs the entire system.

   The base run will run by simply doing:

   runit.csh > log

   This run requires about 6 hours of CPU.  Most of that time is the CM1 model (about 5 hours).
   The base run is a 40 member, 2km mesh.

   runit.csh runs 1 python script at the top, called "run_exper.py".  That script runs the initialization
   and then runs the forecast and data assimilation cycle.  Look inside, and the top lines are the 
   "ic_cmds" --> which create the initialization.  The only thing you might want change in run_exper.py is

   stop     = [2013,5,20,20,10,0]
   fcst     = 0

   Which tell the system to stop assimilation at 20:10, and do not run a forecast after this.  Right now,
   every other piece of possible parameter change in run_exper.py IS IGNORED.  

   The BIG file to change is one called "create_run_letkf.py".  This is my attempt (not perfect)
   a having all the parameters for data assimilation and the run in one file.  For testing, do
   not change the top stuff, but the stuff you might want to play with, after you replicate the
   benchmark run is in the list:

   cm1_nml = {"cm1namelist": [......


   That is where the model time step, grid pts, domain, etc. are run.  The microphysics is
   actually set higher up in the code, the in the "defaults" section.  This code creates
   a file in the RUN_LETKF directory called "RUN_LETKF.exp" which contains a pickled dictionary
   of all the model and data assimilation information.  That is why all the commands to plot
   or analyze the data use the "-d directory", because they read that information.

3.  Benchmark run:  if you have all things compiled, and all the python libs installed, then
    type "runit.csh".  About 6 hours later you should have a run.

    The run is not great, but its not bad either.  Pretty noisy, I probably have to turn down the
    additive noise.  We can talk about tunning after you start to get a feel for things.

   




