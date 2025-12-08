#!/usr/bin/env python

from optparse import OptionParser
import sys
import netCDF4
import os
import numpy as np
from scipy import signal
import xarray as xr
import datetime as dt
import pandas as pd
import glob

import matplotlib.pyplot as plt

import skimage.measure as sm

sys.path.append('/work/jessica.mcdonald/CAM_analysis_tools/filter/')
import RaymondFilters

def findnearest(array, value):
    array = np.asarray(array)
    return (np.abs(array-value)).argmin()

#-------------------------------------------------------------------------------
# Function for FFT convolution filter.

def fft_filter(binfld, winsize):

    n = int(winsize)
    conv = np.ones((n,n))

    fract = np.absolute(np.round(signal.fftconvolve(binfld, conv, mode='same'), 0)) / winsize**2.

    return fract

#-------------------------------------------------------------------------------
# Function for FFT convolution filter.

def fft_filter_ens(binfld, ne, winsize):

    n = int(winsize)
    conv = np.ones((2*ne,n,n))

    fract = np.amax(np.absolute(np.round(signal.fftconvolve(binfld, conv, mode='same'), 0)) / (ne*winsize**2.), axis=0)

    return fract

#-------------------------------------------------------------------------------
# Function to compute FSS using convolution via fast fourier transform (FFT).

def fourier_fss(fcst, obs, fthld, othld, winsize):

    pf = fft_filter(fcst >= fthld, winsize)
    po = fft_filter(obs >= othld, winsize)

    fbs = np.nanmean(np.power(pf - po, 2))
    fbsw = np.nanmean(np.power(pf, 2) + np.power(po, 2))

    fss = 1. - fbs/fbsw

    return fss, fbs, fbsw

#-------------------------------------------------------------------------------
# Function to compute eFSS using convolution via fast fourier transform (FFT).

def fourier_efss(fcst, obs, fthld, othld, ne, winsize):

    pf = fft_filter_ens(fcst >= fthld, ne, winsize)
    po = fft_filter(obs >= othld, winsize)

    fbs = np.nanmean(np.power(pf - po, 2))
    fbsw = np.nanmean(np.power(pf, 2) + np.power(po, 2))

    fss = 1. - fbs/fbsw

    return fss, fbs, fbsw



mrmsdir = '/work/jessica.mcdonald/scratch_link/extra_NR_500m_may8/'

var = 'compdz'

#################################### User-Defined Variables:  #####################################################

# Use percentile thresholds instead?
usepct = 0    # 1 for yes, 0 for no

# Bounds for subdomain if used

neighsize =[1.,3.,5.,9.,17.,33.,65.,129.,257.]  #[1.,7.,13.,25.,49.,97.,193.,385.,709.] #[1.,3.,5.,9.,17.,33.,65.,129.,257.]                 # neighborhood sizes

# Use neighborhoods that extend beyond domain boundaries?
usebdy = 1    # 1 for yes, 0 for no, currently not used

#################################### Set variable specific values:  #####################################################

if (var == 'compdz'):
    #mrms_var = 'refl_consv'
    #mrms_var = 'dz_consv'
    fcst_var = 'comp_dz'
    mrms_prct = [90.,95.,99.]
    fcst_prct = [90.,95.,99.]
    
    
    fcst_thds = [30.,35.,40.,45.,50.,55.]
    mrms_thds = [8. ,16.,24.,32.,40.,48.] # equivalent percentile value

elif (var == 'uh0to2'):
    mrms_var = 'azlo_cress'
    fcst_var = 'uh_0to2'
    mrms_prct = [99.5, 99.9, 99.95]
    fcst_prct = [99.5, 99.9, 99.95]
elif (var == 'uh2to5'):
    mrms_var = 'azmd_cress'
    fcst_var = 'uh_2to5'
    mrms_prct = [99.0, 99.9, 99.95]
    fcst_prct = [99.0, 99.9, 99.95]
   
    fcst_thds = [25, 50, 75, 100, 125, 150]
    mrms_thds = [46, 94, 141, 182, 226, 268] #quivalent percentile value
    
else:
   print("%s is an unsupported variable, please use 'compdz', 'uh0to2', or 'uh2to5'" %var)
   sys.exit(1)


ens2nr = {'UH_2-5km': {25: 46, 50: 94, 75: 141, 100: 182, 125: 226, 150: 268}, 
               'dbz': {30: 8, 35: 16, 40: 24, 45: 32, 50: 40, 55: 48}}




usepct=0

exps = sorted([os.path.basename(g) for g in glob.glob('/work/jessica.mcdonald/CM1_LETKF_2025/experiments/C*')])[:-2]

fpath=[]
for exp in exps:
    fpath.extend([f"/work/jessica.mcdonald/CM1_LETKF_2025/experiments/{exp}/"])
    fpath.extend(glob.glob(f"/work/jessica.mcdonald/CM1_LETKF_2025/experiments/{exp}/"+'FORECAST*/'))
    
for indir in fpath:
    
    
    for var in ['uh2to5','compdz']:
        

        tempname = f'fss_{var}.nc'
        out_file = os.path.join(indir, tempname)
        if (os.path.isfile(out_file) == False) &(os.path.isfile(f'{indir}full_ens_fcst.nc')==True):
            print(f'********************************** {var}')

            print('EXPERIMENT ', indir)
            
            print('VARIABLE ', var)            
            if (var == 'compdz'):
             
                mrms_prct = [90.,95.,99.]
                fcst_prct = [90.,95.,99.]
                fcst_thds = [30.,35.,40.,45.,50.,55.]
                mrms_thds = [30.,35.,40.,45.,50.,55.]
                #mrms_thds = [8. ,16.,24.,32.,40.,48.] # equivalent percentile value
            
            elif (var == 'uh0to2'):
     
                mrms_prct = [99.5, 99.9, 99.95]
                fcst_prct = [99.5, 99.9, 99.95]
    
            elif (var == 'uh2to5'):
     
                mrms_prct = [99.0, 99.9, 99.95]
                fcst_prct = [99.0, 99.9, 99.95]
                fcst_thds = [25, 50, 75, 100, 125, 150]
                mrms_thds = [46, 94, 141, 182, 226, 268] #quivalent percentile value
    
            elif (var == 'w2to5'):
                fcst_thds = [4,6,8,10,12]
                mrms_thds = [4,6,8,10,12] #equivalent percentile value
                
                
            else:
               print("%s is an unsupported variable, please use 'compdz', 'uh0to2', or 'uh2to5'" %var)
               sys.exit(1)
                
        
            #indir = fpath+exp # do forecasts tomorrow
            #indir = glob.glob(os.path.join(fpath,exp, 'FORECAST*'))[0] 
            
            
           ### read in nature run 
            NR_full = xr.open_dataset('/work/jessica.mcdonald/CM1_LETKF_2025/experiments/Processed_VerificationVars.nc')
            
            NR_time = np.array([pd.to_datetime(t) for t in NR_full.dates.values])
            
            ### read in forecast
            fcst_full = xr.open_dataset(os.path.join(indir,'full_ens_fcst.nc'))
            fcst_time = [pd.to_datetime(t) for t in fcst_full.time.values]
            fcst_hr = [f.hour for f in fcst_time]
            fcst_min = [f.minute for f in fcst_time]
            nx, ny, nt, ne = fcst_full.sizes['ni'],fcst_full.sizes['nj'],fcst_full.sizes['t'],fcst_full.sizes['ne']-1
            dx,dy = np.gradient(fcst_full.xh).mean(),np.gradient(fcst_full.yh).mean()
            
            # # get proper times from nature run
            time_idx = [int(np.where(NR_time == t)[0][0]) for t in fcst_time]
            
            # now pull the variables you need
            if var == 'compdz':
                fcst = fcst_full['cdbz'][:, :-1]#.max(axis=2) # drop mean
                mrms = NR_full['cdbz'].values[time_idx]#.max(axis=1)
            
            if var == 'uh2to5':
                fcst = fcst_full['UH_2-5km'][:,:-1].values
                mrms = NR_full['UH2-5km'].values[time_idx]
    
            if var == 'w2to5':
                fcst = fcst_full['w_2-5km'][:,:-1].values
                mrms = NR_full['w_2-5km'].values[time_idx]
            
            
            ###################################### Computing eFSS #######################################################
            
            print("Computing eFSS")
            
            neighsize=[]
            
            if len(neighsize) == 0:
               minxy = min(nx, ny)
               for ii in range(1,minxy):
                  ns = ii**2
                  if ns % 2 == 0:
                     ns = ns - 1
                  if ns < minxy:
                     neighsize.append(ns)
            
            #neighsize=neighsize[0:5]
            
            # if nx == 300:
            #     print("\nUsing subdomain for 3KM.")
            #     usesub = 1
            
            
            #neighsize = np.asarray(neighsize)
            
            if usepct == 1:
               nft = len(fcst_prct)
               nmt = len(mrms_prct)
            else:
               nft = len(fcst_thds)
               nmt = len(mrms_thds)
            
            nnw = len(neighsize)
            
            fcst_thld = np.zeros((nt,nft))
            mrms_thld = np.zeros((nt,nmt))
            fcst_max = np.zeros((nt))
            mrms_max = np.zeros((nt))
            
            efbs = np.full((nt,nnw,nft),-999.)
            efbsr = np.full((nt,nnw,nft),-999.)
            efss = np.full((nt,nnw,nft),-999.)
            fssu = np.full((nt,nft),-999.)
            aefss = np.full((nt,nft),-999.)
            scales = np.zeros((nnw))
            po = np.full((nt,nft),0.0)
            pf = np.full((nt,nft),0.0)
            
            fbs = np.full((ne,nt,nnw,nft),-999.)
            fss = np.full((ne,nt,nnw,nft),-999.)
            fbsr = np.full((ne,nt,nnw,nft),-999.)
            afss = np.full((ne,nt,nft),-999.)
            
            for ii in range(0,nnw):
               print("\nWorking on neighborhood size of %s gridpoints..." %(neighsize[ii]))
               scales[ii] = (neighsize[ii] - 1.0)*dx/1000.
            
                   
            
               for jj in range(0,nft):
                  if usepct == 1:
                     print("Threshold: %s" %(fcst_prct[jj]))
                  # else:
                  #    print("MRMS Threshold: %s" %(mrms_thds[jj]))
                  #    print("FCST Threshold: %s" %(fcst_thds[jj]))
            
                  # Full domain
                  #if usesub == 0:
                      
                  for ts in range(0,nt):
                    if usepct == 1:
                       fcst_thld[ts,jj] = np.percentile(fcst[ts,:,:,:],fcst_prct[jj])
                       mrms_thld[ts,jj] = np.percentile(mrms[ts,:,:],mrms_prct[jj])
                    else:
                       fcst_thld[ts,jj] = fcst_thds[jj]
                       mrms_thld[ts,jj] = mrms_thds[jj]
                    
                    if ii == 0:
                       po[ts,jj] = 1.*np.count_nonzero(mrms[ts,:,:] >= mrms_thld[ts,jj])/np.count_nonzero(mrms[ts,:,:] >= 0.0)
                       pf[ts,jj] = 1.*np.count_nonzero(fcst[ts,:,:,:] >= fcst_thld[ts,jj])/np.count_nonzero(fcst[ts,:,:,:] >= 0.0)
                       fssu[ts,jj] = 0.5 + po[ts,jj]/2.
                       aefss[ts,jj] = (2.*po[ts,jj]*pf[ts,jj])/(np.power(po[ts,jj],2)+np.power(pf[ts,jj],2))
                    
                    if ((np.amax(fcst[ts,:,:,:]) >= fcst_thld[ts,jj]) or (np.amax(mrms[ts,:,:]) >= mrms_thld[ts,jj])):
                       efss[ts,ii,jj], efbs[ts,ii,jj], efbsr[ts,ii,jj] = fourier_efss(fcst[ts,:,:,:], mrms[ts,:,:], fcst_thld[ts,jj], mrms_thld[ts,jj], ne, neighsize[ii])
                    
                    if ii == 0 and jj == 0:
                       fcst_max[ts] = np.amax(fcst[ts,:,:,:])
                       mrms_max[ts] = np.amax(mrms[ts,:,:])
                    
                    # Compute FSS for each member
                    for em in range(0,ne):
                       if ii == 0:
                          ipo = 1.*np.count_nonzero(mrms[ts,:,:] >= mrms_thld[ts,jj])/np.count_nonzero(mrms[ts,:,:] >= 0.0)
                          ipf = 1.*np.count_nonzero(fcst[ts,em,:,:] >= fcst_thld[ts,jj])/np.count_nonzero(fcst[ts,em,:,:] >= 0.0)
                          afss[em,ts,jj] = (2.*ipo*ipf)/(np.power(ipo,2)+np.power(ipf,2))
                    
                       if ((np.amax(fcst[ts,em,:,:]) >= fcst_thld[ts,jj]) or (np.amax(mrms[ts,:,:]) >= mrms_thld[ts,jj])):
                          fss[em,ts,ii,jj], fbs[em,ts,ii,jj], fbsr[em,ts,ii,jj] = fourier_fss(fcst[ts,em,:,:], mrms[ts,:,:], fcst_thld[ts,jj], mrms_thld[ts,jj], neighsize[ii])
            
            ###################################### Output FSS: #######################################################
            
            tempname = f'fss_{var}.nc'
            out_file = os.path.join(indir, tempname)
            
            try:
               fout = netCDF4.Dataset(out_file, "w")
            except:
               print("Could not create %s!\n" % out_file)
            
            #fout = netCDF4.Dataset(out_file, "a")
            
            fout.createDimension('NE', ne) # number of ensemble members
            fout.createDimension('NT', nt) # n time steps 
            fout.createDimension('NW', nnw) # neightborhood window
            fout.createDimension('NTH', nft)  # length of percentile or threshold values 
            
            fout.createVariable('FCST_MAX_VALUE', 'f4', ('NT',))
            fout.createVariable('MRMS_MAX_VALUE', 'f4', ('NT',))
            ttt = fout.createVariable('TIME', np.float64, ('NT',))
            ttt.setncattr('unit', "seconds since 1970-01-01 00:00:00")
            fout.createVariable('HOUR', 'f4', ('NT',))
            fout.createVariable('MINUTE', 'f4', ('NT',))
            
            fout.createVariable('SCALES', 'f4', ('NW',))
            fout.createVariable('FCST_THLDS', 'f4', ('NT','NTH',))
            fout.createVariable('MRMS_THLDS', 'f4', ('NT','NTH',))
            fout.createVariable('FSSU', 'f4', ('NT','NTH',))
            fout.createVariable('EFSS', 'f4', ('NT','NW','NTH',))
            fout.createVariable('EFBS', 'f4', ('NT','NW','NTH',))
            fout.createVariable('EFBSR', 'f4', ('NT','NW','NTH',))
            fout.createVariable('AEFSS', 'f4', ('NT','NTH',))
            fout.createVariable('PO', 'f4', ('NT','NTH',))
            fout.createVariable('PF', 'f4', ('NT','NTH',))
            fout.createVariable('FSS', 'f4', ('NE','NT','NW','NTH',))
            fout.createVariable('FBS', 'f4', ('NE','NT','NW','NTH',))
            fout.createVariable('FBSR', 'f4', ('NE','NT','NW','NTH',))
            fout.createVariable('AFSS', 'f4', ('NE','NT','NTH',))
            
            fout.variables['TIME'][:] = [netCDF4.date2num(t,"seconds since 1970-01-01 00:00:00") for t in fcst_time]
            fout.variables['HOUR'][:] = fcst_hr[:]
            fout.variables['MINUTE'][:] = fcst_min[:]
            fout.variables['SCALES'][:] = scales
            fout.variables['FCST_THLDS'][:,:] = fcst_thld # percentile values or thresholds 
            fout.variables['MRMS_THLDS'][:,:] = mrms_thld # percentile values or thresholds 
            fout.variables['FCST_MAX_VALUE'][:] = fcst_max
            fout.variables['MRMS_MAX_VALUE'][:] = mrms_max
            fout.variables['FSSU'][:,:] = fssu  #FSS uniform, which is halfway between a random forecast and perfect skill ("target skill")
            fout.variables['EFSS'][:,:,:] = efss # ensemble FSS, neighborhood probabilities extend into ensemble space
            fout.variables['EFBS'][:,:,:] = efbs # "MSE for the observed and forecast fractions from a neighborhood length of n"
            fout.variables['EFBSR'][:,:,:] = efbsr # reference MSE, "largest possible MSE that can be obtained from the forecast and observed fractions"
            fout.variables['AEFSS'][:,:] = aefss  # asymptotic eFSS
            fout.variables['PO'][:,:] = po  # observed frequency f0 of the observations 
            fout.variables['PF'][:,:] = pf  # observed frequency of the forecasts
            fout.variables['FSS'][:,:,:,:] = fss # fraction skill score
            fout.variables['FBS'][:,:,:,:] = fbs
            fout.variables['FBSR'][:,:,:,:] = fbsr
            fout.variables['AFSS'][:,:,:] = afss #asymptotic FSS
            
            fout.close()
            del fout

        else:
            print(indir, ' file already made')
