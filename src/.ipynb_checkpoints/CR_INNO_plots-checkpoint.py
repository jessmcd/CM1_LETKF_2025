from optparse import OptionParser
import sys
import os
import numpy as np
import datetime as DT 
import netCDF4 as ncdf
import glob
import pylab as P
from datetime import datetime
from src.plot_src.cbook2 import nice_mxmnintvl, nice_clevels
import matplotlib.cm as cm
import matplotlib.ticker as ticker
import matplotlib.dates as mdates
from scipy import ndimage


from matplotlib.colors import LinearSegmentedColormap, to_rgb

_bin_delta = 1
radar_hgt = 0

_prior_files = "Prior_*"
_plotfilename = "DBZ_ConsistencyRatio"

sec_utime = "seconds since 1970-01-01 00:00:00"


## settings for plots - makes them look nicer
import matplotlib as mpl
import matplotlib.pyplot as plt
plt.rc('xtick', labelsize=14) 
plt.rc('ytick', labelsize=14) 
plt.rc('axes', labelsize=14, titlesize=18) 
mpl.rcParams.update({"axes.grid" : False, "grid.color": "0.6",  'grid.linestyle':':',
                    'grid.linewidth':1, 'axes.labelweight':'bold', 'legend.framealpha':1.0})


def smfnc(x):
    return ndimage.gaussian_filter(x, sigma=0.75)
    
# ------------------------------------------------------------------------------------------
# Search functions  each returns a boolean array of T/F with the same dimensions as field

def getIndexVariable(field, variable):
    return (field == variable)
    
def getIndexGreaterThan(field, value):
    return ( field > value )
    
def getIndexLessThan(field, value):
    return ( field < value )
    
def getIndexGreaterThanOrEqual(field, value):
    return ( field >= value )
    
def getIndexLessThanOrEqual(field, value):
    return ( field <= value )

def getIndexEqual(field, value):
    return ( field == value )

def getIndexNotEqual(field, value):
    return ( field != value )

def get_stats_timeseries(experiment_location, only_pos_dbz=True, variable='REFL', full_field=False, dz=2000):
    '''experiment_location = path to the .exp file
       only_pos_dbz = if True, then only >10 dBZ is inluded in calculations (innovations will still include all data)
       variable = REFL or DBZ 
       full_field = if True, returns 2d field (x=time, y=height).
       dz is the size of the vertical bins'''

    if variable !='REFL':
        only_pos_dbz=False
    
    dirname = os.path.join(experiment_location,_prior_files)
    #plotfilename='DBZ_CR'
    #noshow=True

    file_list = glob.glob(dirname)
    file_list = sorted(file_list,key=os.path.getmtime)

    bin_delta = _bin_delta

    nbins     = len(file_list) // bin_delta
    CR_T      = np.zeros((nbins))
    IN_T      = np.zeros((nbins))
    RMSI_T    = np.zeros((nbins))
    Spread_T  = np.zeros((nbins))

    if full_field:
        print('RETURNING 2D FIELDS')
        zbins    = dz*np.arange(int(8000/dz))
        print(zbins)
        CR_T     = np.zeros((zbins.size,nbins))
        IN_T     = np.zeros((zbins.size,nbins))
        RMSI_T   = np.zeros((zbins.size,nbins))
        Spread_T = np.zeros((zbins.size,nbins))

    datebins = []
    secsbins = []
    m = -1

    for n, file in enumerate(file_list):

        f = ncdf.Dataset(file)

        if n % bin_delta == 0:
            HxfL,valueL,depL,errorL,secsL,zL,kindL = [],[],[],[],[],[],[]

        valueL.append(f.variables["value"][:])
        HxfL.append(f.variables["Hxf"][:]) #hxf is the model value at the location of that ob
        zL.append(f.variables["z"][:] - radar_hgt)
        depL.append( f.variables["value"][:] - f.variables["Hxfbar"][:] ) #hxfbar is the mean model values at that location
        secsL.append(f.variables["secs"][:])
        errorL.append(np.sqrt(f.variables["error"][:])) # error is the standard deviation
        kindL.append(ncdf.chartostring(f.variables["type"][:]))

        if n % bin_delta == bin_delta-1:
            Hxf   = np.concatenate(HxfL, axis=0)
            value = np.concatenate(valueL, axis=0)
            z     = np.concatenate(zL, axis=0)
            dep   = np.concatenate(depL, axis=0)
            secs  = np.concatenate(secsL, axis=0)
            error = np.concatenate(errorL, axis=0)
            kind  = np.concatenate(kindL, axis=0)
            datebins.append(DT.datetime.utcfromtimestamp(secs.mean()))

            m+=1

            index_kind  = getIndexVariable(kind,variable)

            #### do a 1D timeseries for each variable
            if full_field == False: 
    
                if only_pos_dbz & (variable=='REFL'):
                    index_pos   = getIndexGreaterThanOrEqual(value,10.0)
                    index       = index_kind & index_pos
                else:
                    index = index_kind
           
                if np.sum(index == True) > 2: 
                    
                    d           = dep[index] # innovation
                    obs_var     = error[index]
                    Hxftmp      = Hxf[index,:]
                    Hxf_var     = Hxftmp.var(ddof=1, axis=1).mean() 
                    inno_var    = np.mean((d - d.mean())**2) 
                    RMSI_T[m]   = np.mean(np.sqrt((d - d.mean())**2))
                    
                    Spread_T[m] = np.sqrt((obs_var[1]**2 + Hxf_var))
                    CR_T[m]     = (obs_var[1]**2 + Hxf_var) / inno_var # same thing as total spread squared / RMSI sqared
    
                    # for now, calculate innovations WITHOUT a positive DBZ filter (if you're using DBZ)
                    if only_pos_dbz:
                        d        = dep[index_kind] # innovation
                        IN_T[m]  = d.mean()
                    else:
                        IN_T[m]  = d.mean()

            #### return 2D fields
            else:
                for k in np.arange(zbins.size-1):
                    index1                = getIndexGreaterThanOrEqual(z, zbins[k])
                    index2                = getIndexLessThan(z, zbins[k+1])
                    if only_pos_dbz & (variable=='REFL'):
                        index_pos   = getIndexGreaterThanOrEqual(value,10.0)
                        index             = index_kind & index1 & index2 & index_pos
                    else:
                        index             = index_kind & index1 & index2
        
                    if np.sum(index == True) > 2: 
                        d             = dep[index]
                        obs_var       = error[index]
                        Hxftmp        = Hxf[index,:]
                        Hxf_var       = Hxftmp.var(ddof=1, axis=1).mean()
                        inno_var      = np.mean((d - d.mean())**2)
                        CR_T[k,m]     = (obs_var[1]**2 + Hxf_var) / inno_var
                        RMSI_T[k,m]   = np.mean(np.sqrt((d - d.mean())**2))
                        Spread_T[k,m] = np.sqrt((obs_var[1]**2 + Hxf_var))
                        if only_pos_dbz:
                            d         = dep[index_kind & index1 & index2] # innovation
                            IN_T[k,m] = d.mean()
                        else:
                            IN_T[k,m] = d.mean()
                            
        f.close()

    if full_field:
        datebins = [datebins, zbins]

    return datebins, CR_T, IN_T, Spread_T, RMSI_T


def format_time_ticks(ax, dates, minute_interval=10, approx_number_of_ticks=8,  tick_format='%H:%M', rotation=30, fontsize=14):
    ''' This does basic formatting to help clean up the plot cells'''

    start = dates[0]
    end   = dates[-1]
    ax.set_xlim(start, end)
    nticks_approx = 8
    minute_interval = 5*round((end-start).seconds/(approx_number_of_ticks*60*5)) #find the best interval divisble by 5 based on nticks
    maj_loc = mdates.MinuteLocator(interval=minute_interval)
    ax.xaxis.set_major_locator(maj_loc)
    dateFmt = mdates.DateFormatter(tick_format)
    ax.xaxis.set_major_formatter(dateFmt)
    labels = ax.get_xticklabels()
    plt.setp(labels, rotation=30, fontsize=fontsize)


def CR_cmap():
    col1 = list(plt.cm.YlGn(np.linspace(0,.68, 10)))
    col2 = list(plt.cm.BuGn(np.linspace(0,.7, 10))[::-1])
    col1.extend(col2)
    clist = [to_rgb(c) for c in col1[::-1]]
    i1,i2 = 9,11
    clist[i1:i2] = np.array(clist[i1:i2])*1.18
    cmap = LinearSegmentedColormap.from_list("CR", clist, 20)
    return cmap





if __name__ == "__main__":

    print("\n \n <<<<<======================================================================>>>>>> \n \n")
    print("     EXPERIMENT STATS PLOTS       \n\n ")

    usage = "usage: %prog [options] arg"
    parser = OptionParser(usage)

    parser.add_option("-e",  "--exp",    dest="exp",      default=None, type="string", help = "Path to the json experiment file generated by run")
    
    # parser.add_option("-d",  "--dir",    dest="dir",  type="string", help="Name of directory where Prior files are")
    # parser.add_option("-t",  "--title",  dest="title", type="string", help="Name of plot and used as the name of the outputfile")
    # parser.add_option(       "--noshow",  dest="noshow", default=False, action="store_true", help="Turn off screen plotting")

    (options, args) = parser.parse_args()

    if options.exp:
        with open(options.exp, 'rb') as f:
        exper = json.load(f)
        save_path = exper['plots_path']
    else:
        save_path = os.getcwd()


    ### 8 panel line plot
    fig,axes = plt.subplots(2,4, figsize=(18,7), sharex=True)
    
    axes[0,0].set_title('Mean Innovation', weight='bold', y=1.01)
    axes[0,1].set_title('Root Mean Square\nInnovation', weight='bold', y=1.01)
    axes[0,2].set_title('Total\nEnsemble Spread', weight='bold', y=1.01)
    axes[0,3].set_title('Consistency Ratio', weight='bold', y=1.01)
    
    for i,exp in enumerate(['/scratch/home/jessica.mcdonald/LETKF_runs/DBZ_VR']):
    
        for ii,var in enumerate(['REFL', 'VR']):
    
            dates, CR, IN, SPRD, RMSI = get_stats_timeseries(exp, only_pos_dbz=True, variable=var)
            axes[ii,0].plot(dates, IN,   )
            axes[ii,1].plot(dates, RMSI, )
            axes[ii,2].plot(dates, SPRD, )
            axes[ii,3].plot(dates, CR,   )
    
    # formatting
    plt.subplots_adjust(hspace=0.1)
    for ax in axes[1:].flatten():
        format_time_ticks(ax, dates, fontsize=12)
        ax.set_xlabel('Time (HH:MM UTC)')
    for ax in axes.flatten():
        ax.grid(ls=':', alpha=0.7)
    for ax in axes[:,[0,1,2]].flatten():
        ax.axhline(0, ls=':', color='k')
    for ax in axes[:,3].flatten():
        ax.axhline(1, ls=':', color='k')
    
    # share ylim but only for the CR plot
    axes[1,3].sharey(axes[0,3])
    
    axes[0,0].set_ylabel('Reflectivity (dBZ)', weight='bold');
    axes[1,0].set_ylabel(r'Radial Velocity (m s$\mathbf{^{-1}}$)', weight='bold');
    plt.savefig(f'{save_path}/StatsOverview.png', bbox_inches='tight')
    plt.close()
    
    
    
    
    ### 4 panel 2D plots
    
    fig, axes = plt.subplots(2,2, figsize=(12,8), sharey=True, sharex=True)
    
    vals = [20, 30]
    fs = 14
    cmap = CR_cmap()
    
    for ii,var in enumerate(['REFL', 'VR']): 
        TZ, CR, IN, SPRD, RMSI = get_stats_timeseries(exp, only_pos_dbz=True, variable=var, full_field=True, dz=2000)
        t, z = list(TZ[0]), list(TZ[1]/1000)
        z.append(z[-1]+z[1]-z[0])
        t.append(t[-1]+(t[1]-t[0]))
        im1 = axes[ii,0].pcolormesh(t,z, IN, vmin=-1*vals[ii], vmax=vals[ii], cmap='RdBu')
        im2 = axes[ii,1].pcolormesh(t,z, CR, vmin=0, vmax=2, cmap=cmap)
    
        if ii ==1:format_time_ticks(axes[ii,0],t[:-1]);format_time_ticks(axes[ii,1],t[:-1])
    
        if ii==0: 
            axes[ii,0].text(0.5, .95, 'Reflectivity (dBZ)', ha='center', va='top', transform=axes[ii,0].transAxes, fontsize=fs )
            axes[ii,1].text(0.5, .95, 'Reflectivity',       ha='center', va='top', transform=axes[ii,1].transAxes, fontsize=fs )
    
        if ii==1: 
            axes[ii,0].text(0.5, .95, r'Radial Velocity (m s$\mathbf{^{-1}}$)', ha='center', va='top', transform=axes[ii,0].transAxes, fontsize=fs )
            axes[ii,1].text(0.5, .95, 'Radial Velocity',                        ha='center', va='top', transform=axes[ii,1].transAxes, fontsize=fs )
    
        plt.colorbar(im1, ax =axes[ii,0], pad=.02, extend='both')
        plt.colorbar(im2, ax =axes[ii,1], pad=.02, extend='max') 
    
    axes[0,0].set_ylim(0,7)
    
    plt.subplots_adjust(hspace=.1, wspace=0.05)
    
    axes[0,0].set_title('Mean Innovation',   weight='bold',fontsize=22, y=1.04)
    axes[0,1].set_title('Consistency Ratio', weight='bold',fontsize=22, y=1.04)
    
    fig.text(0.5, 0.01, 'Time (HH:MM UTC)', ha='center', va='center', weight='bold', fontsize=18);
    fig.text(0.07,0.5, 'Height (km)', weight='bold', va='center', fontsize=18, rotation='vertical');
    plt.savefig(f'{save_path}/StatsOverview_2D.png', bbox_inches='tight')
    plt.close()
    
    
    
    
