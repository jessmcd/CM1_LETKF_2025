#!/bin/csh

echo "Starting run_simple_may8.csh"

setenv OMP_NUM_THREADS 1

set dir = "may8_exper"

echo "running job "$dir

date

# run job script

setenv PYTHONUNBUFFERED TRUE

echo "test run"

python May8_Experiment.py >& $dir.out

echo "um"

cp *.pdf RUN_LETKF/Plots/.

#cp -R RUN_LETKF $dir

#cp *.pdf $dir/Plots/.

date
exit(0)
#---------------------------------------------------------
