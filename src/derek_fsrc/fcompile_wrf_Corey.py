#!/usr/bin/env python

import sys
import os
import glob
import string
from optparse import OptionParser

# USE GFORTRAN COMPILER!!!!!!!!!!!!!!!!!!!! CKP

#preprocess   = ""
preprocess   = "-DF2PY_REPORT_ON_ARRAY_COPY"
#fopts        = ""
libs         = "-liomp5"
fopts        = {'pgf': ['pg',"-tp x64 -fastsse -mp -fPIC",""], \
                'gnu': ['gnu95',"-O3 -ffast-math -ftree-vectorizer-verbose=2 -fopenmp -fPIC","-lgomp"], \
                'intel': ['intelem',"-v -O3", "-liomp5"], \
                'cray': ['ftn',"-v -fPIC -O3", ""]}



preprocess   = "-I/opt/cray/netcdf/4.3.2/GNU/49/include"
fopts        = {'pgf': ['pg',"-tp x64 -fastsse -mp -fPIC",""], \
                'gnu': ['gnu95',"-O3 -ffast-math -ftree-vectorizer-verbose=2 -fopenmp -fPIC -I/opt/cray/netcdf/4.3.2/GNU/49/include","-lgomp"], \
                'intel': ['intelem',"-v -O3", "-liomp5"], \
                'cray': ['ftn',"-v -fPIC -O3", ""]}
libs         = "-L/opt/cray/netcdf/4.3.2/GNU/49/lib -lnetcdf -lnetcdff"

fortran_only = ["common_mtx.f90","common_letkf_wrf.f90","netlib.f","netlibblas.f"]
f2py_only    = ["fpython2_wrf.f90"]

parser = OptionParser()
parser.add_option("-f","--fc",dest="compiler",type="string", default='gnu', help = "fortran compiler to be used valid compiler: [gfortran, ifort_x86_64]")

(options, args) = parser.parse_args()

objects = ""

# First compiler the fortran only files
 
for item in fortran_only:
    print "\n=====================================================\n"
    print "  Compiling file: %s " % item
    print "\n====================================================="
    if options.compiler == 'gnu':
        print("\n  Using GNU gfortran compiler \n")
        cmd = 'gfortran %s -c %s ' % (fopts['gnu'][1],item)
    if options.compiler == 'cray':
        print("\n  Using default Cray compiler \n")
        cmd = 'ftn %s -c %s ' % (fopts['cray'][1],item)
    if options.compiler == 'intel':
        print("\n  Using Intel compiler \n")
        cmd = 'ifort %s -c %s ' % (fopts['intel'][1],item)
    if options.compiler == 'pgf':
        print("\n  Using Portland group compiler \n")
        cmd = 'pgf90 %s -c %s ' % (fopts['pgf'][1],item)

    print("  "+cmd+"\n")
    ret = os.system(cmd)

    if ret == 0:
        objects = objects + " %s.o" % item.split(".")[0]

print "\nDART object files compiled:  %s \n" % objects
print "\n=====================================================\n"

for item in f2py_only:
    ret = os.system('rm %s.so ' % (item.split(".")[0]))
    if options.compiler == 'gnu':
        ret = os.system('f2py --fcompiler="gfortran" "--f90flags=%s" %s -c -m %s %s %s %s ' \
            % (fopts['gnu'][1], preprocess, item.split(".")[0], item, objects, fopts['gnu'][2]))
    if options.compiler == 'cray':
        ret = os.system('f2py --fcompiler="ftn" "--f90flags=%s" %s -c -m %s %s %s %s '
            % (fopts['cray'][1], preprocess, item.split(".")[0], item, objects, fopts['cray'][2]))
    if options.compiler == 'intel':
       ret = os.system('f2py --fcompiler="intelem" "--f90flags= -nofor-main %s" %s -c -m %s %s %s %s'
           % (fopts['intel'][1], preprocess, item.split(".")[0], item, objects,fopts['intel'][2]))
    if options.compiler == 'pgf':
       ret = os.system('f2py --fcompiler="pg" "--f90flags=%s" %s -c -m %s %s %s %s'
           % (fopts['pgf'][1], preprocess, item.split(".")[0], item, objects,fopts['pgf'][2]))
    print "\n==========================================================================================\n"
    if ret == 0:
        print "   Successfully compiled file: %s " % item
        print "   Object file is: %s " % (item.split(".")[0] + ".so")
    else:
        print "   ERROR !!!!!   ERROR--> unsuccessful compile file: %s\n" % item

