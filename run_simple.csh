#!/bin/csh

# note to myself - there is an issue happening when it tries to copy the RUN_LETKF directory into "simple_exper", so maybe remove that? 

echo "Starting run_simple_bench.csh"

setenv OMP_NUM_THREADS 1

set dir = "simple_exper"

echo "running job "$dir

date

# run job script

setenv PYTHONUNBUFFERED TRUE

python run_simple_exper.py >& $dir.out

cp -R RUN_LETKF $dir

cp *.pdf $dir/Plots/.

date
exit(0)
#---------------------------------------------------------
