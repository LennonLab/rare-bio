from __future__ import division
import  matplotlib.pyplot as plt

import numpy as np
import random
import scipy as sc
from scipy import stats

import os
import sys

import statsmodels.stats.api as sms
import statsmodels.formula.api as smf
from statsmodels.sandbox.regression.predstd import wls_prediction_std
from statsmodels.stats.outliers_influence import summary_table

from numpy import log, log2, exp, sqrt, log10, pi
from scipy.optimize import fsolve
import scipy.optimize as opt

import pandas as pd
#import patsy
import mpmath as mpm
from scipy.optimize import fsolve
from math import erf, pi
import linecache

mydir = os.path.expanduser("~/GitHub/rare-bio/")
mydir2 = os.path.expanduser("~/")

import math
pi = math.pi


def Preston1(N, Nmax, guess):

    def alpha1(a):
        return (sqrt(pi) * Nmax)/(2.0*a) * erf(log(2.0)/a) - N # find alpha

    def s1(a):
        return sqrt(pi)/a * exp( (log(2.0)/(2.0*a))**2.0 ) # Using equation 8

    a = opt.fsolve(alpha1, guess)[0]
    #a = opt.newton(alpha1, guess, maxiter=100)
    print 'Preston1:  guess:',guess,' alpha:',a

    return s1(a)


def Preston2(N, Nmax, Nmin, guess):

    def alpha2(a):
        y = sqrt(pi*Nmin*Nmax)/(2.0*a) * exp((a * log2(sqrt(Nmax/Nmin)))**2.0)
        y = y * exp((log(2.0)/(2.0*a))**2.0)
        y = y * erf(a * log2(sqrt(Nmax/Nmin)) - log(2.0)/(2.0*a)) + erf(a * log2(sqrt(Nmax/Nmin)) + log(2.0)/(2.0*a))
        y -= N
        return y # find alpha

    def s2(a):
        return sqrt(pi)/a * exp( (a * log2(sqrt(Nmax/Nmin)))**2) # Using equation 10

    a = opt.fsolve(alpha2, guess)[0]
    #a = opt.newton(alpha2, guess, maxiter=100)

    print 'Preston2:  guess:',guess,' alpha:',a
    #print '\nalpha2 = ', a, 'f(alpha2) = ','%.2e' % alpha2(a), 'S2:','%.2e' % S2
    return s2(a)


def get_EMP_SSADs():

    DATA = mydir2 + "data/micro/EMPclosed/EMPclosed-SSADdata.txt"

    SSADdict = {}

    with open(DATA) as f:

        for d in f:
            if d.strip():

                d = d.split()
                species = d[0]
                abundance = float(d[2])

                if abundance > 0:
                    if species in SSADdict:
                        SSADdict[species].append(abundance)
                    else:
                        SSADdict[species] = [abundance]

    SSADs = []
    SSADlist = SSADdict.items()

    S = len(SSADlist)
    N = 0
    for tup in SSADlist:

        SSAD = tup[1]
        if len(SSAD) >= 1:

            N += sum(SSAD)

    return [N, S]



def Fig3():

    """ A figure demonstrating a strong richness relationship across 10 or 11
    orders of magnitude in total abundance. Taxonomic richness of a sample
    scales in a log-log fashion with the total abundance of the sample.
    """

    fs = 10 # font size used across figures
    Nlist, Slist, klist, NmaxList, datasets, radDATA = [[],[],[],[],[],[]]
    metric = 'Richness, '+'log'+r'$_{10}$'

    BadNames = ['.DS_Store', 'EMPclosed', 'AGSOIL', 'SLUDGE', 'FECES', 'FUNGI']

    for name in os.listdir(mydir2 +'data/micro'):
        if name in BadNames: continue

        #path = mydir2+'data/micro/'+name+'/'+name+'-SADMetricData_NoMicrobe1s.txt'
        path = mydir2+'data/micro/'+name+'/'+name+'-SADMetricData.txt'

        numlines = sum(1 for line in open(path))
        print name, numlines
        datasets.append([name, 'micro', numlines])

    its = 1
    for i in range(its):
        for dataset in datasets:
            name, kind, numlines = dataset

            lines = []
            lines = np.random.choice(range(1, numlines+1), 2000, replace=True)

            #path = mydir2+'data/'+kind+'/'+name+'/'+name+'-SADMetricData_NoMicrobe1s.txt'
            path = mydir2+'data/'+kind+'/'+name+'/'+name+'-SADMetricData.txt'

            for line in lines:
                data = linecache.getline(path, line)
                radDATA.append(data)


    for data in radDATA:
        data = data.split()
        name, kind, N, S, Evar, ESimp, EQ, O, ENee, EPielou, EHeip, BP, SimpDom, Nmax, McN, skew, logskew, chao1, ace, jknife1, jknife2, margalef, menhinick, preston_a, preston_S = data

        N = float(N)
        S = float(chao1)
        Nmax = float(Nmax)

        if S < 10 or N < 11: continue # Min species richness

        Nlist.append(float(np.log10(N)))
        Slist.append(float(np.log10(S)))
        NmaxList.append(float(np.log10(Nmax)))
        klist.append('DarkCyan')

    N_open_ones = 1315651204
    S_open_ones = 5594412
    N_open_noones = 1252725686
    S_open_noones = 2826534
    N_closed_ones = 654448644
    S_closed_ones = 69444
    N_closed_noones = 648525168
    S_closed_noones = 64658

    empN = np.log10(N_open_ones)
    empS = np.log10(S_open_ones)

    fig = plt.figure()
    ax = fig.add_subplot(1, 1, 1)

    Nlist, Slist, NmaxList = zip(*sorted(zip(Nlist, Slist, NmaxList)))
    Nlist = list(Nlist)
    Slist = list(Slist)
    NmaxList = list(NmaxList)

    # Regression for Dominance (Nmax) vs. N
    d = pd.DataFrame({'N': Nlist})
    d['y'] = NmaxList
    f = smf.ols('y ~ N', d).fit()

    dR2 = f.rsquared
    dpval = f.pvalues[0]
    dintercept = f.params[0]
    dslope = f.params[1]
    print 'intercept, slope, pval, & R2 for Nmax vs. N:', round(dintercept,3), round(dslope,3), round(dpval,3), round(dR2,3)

    # Regression for Richness (S) vs. N
    d = pd.DataFrame({'N': Nlist})
    d['y'] = Slist
    f = smf.ols('y ~ N', d).fit()

    R2 = f.rsquared
    pval = f.pvalues[0]
    intercept = f.params[0]
    slope = f.params[1]

    print 'intercept, slope, pval, & R2 for S vs. N (w/out derived):', round(intercept, 3), round(slope,3), round(pval,3), round(R2,3)

    # code for prediction intervals
    X = np.linspace(5, 32, 100)
    Y = f.predict(exog=dict(N=X))
    Nlist2 = Nlist + X.tolist()
    Slist2 = Slist + Y.tolist()

    d = pd.DataFrame({'N': list(Nlist2)})
    d['y'] = list(Slist2)
    f = smf.ols('y ~ N', d).fit()

    st, data, ss2 = summary_table(f, alpha=0.05)
    fittedvalues = data[:,2]
    pred_mean_se = data[:,3]
    pred_mean_ci_low, pred_mean_ci_upp = data[:,4:6].T
    pred_ci_low, pred_ci_upp = data[:,6:8].T

    plt.fill_between(Nlist2, pred_ci_low, pred_ci_upp, color='r', lw=0.5, alpha=0.2)
    z = np.polyfit(Nlist2, Slist2, 1)
    p = np.poly1d(z)
    xp = np.linspace(0, 32, 1000)

    plt.plot(xp, p(xp), '--', c='red', lw=2, alpha=0.8, label= r'$S$'+ ' = '+str(round(intercept,2))+'+'+str(round(slope,2))+'*'+r'$N$', color='Crimson')
    plt.hexbin(Nlist, Slist, mincnt=1, gridsize = 40, bins='log', cmap=plt.cm.Blues_r, label='EMP')

    # Adding in derived/inferred points
    c = '0.3'
    GO = 1110*10**26 # estimated open ocean bacteria; add reference
    Pm = 2.9*10**27 # estimated Prochlorococcus marinus; add reference
    Earth = 10**30 # estimated bacteria on Earth; add reference
    SAR11 = Earth*0.1 #2*10**28 # estimated Pelagibacter ubique; add reference

    HGx =10**14 # estimated bacteria in Human gut; add reference
    HGy = 0.1169*(10**14) # estimated most abundant bacteria in Human gut; add reference # 0.0053
    COWx = 2.226*10**15 # estimated bacteria in Cow rumen; add reference
    COWy = (0.52/80)*(2.226*10**15) # estimated dominance in Cow rumen; add reference #0.5/80

    Nmin = 1
    # Global Ocean estimates based on Whitman et al. (1998) and P. marinus (2012 paper)
    N = float(GO)
    Nmax = float(Pm)
    guess = 0.1
    S2 = Preston2(N, Nmax, Nmin, guess)
    guess = 0.01
    S1 = Preston1(N, Nmax, guess)
    S2 = log10(S2)
    S1 = log10(S1)
    N = log10(N)

    ax.text(2, S1-1.5, 'predicted high', fontsize=fs+2, color = c)
    ax.axhline(S1, 0, 0.80, ls = '--', c = c)
    ax.text(2, S2-1.5, 'predicted low', fontsize=fs+2, color = c)
    ax.axhline(S2, 0, 0.80, ls = '--', c = c)
    ax.text(N-1, 8, 'Global ocean', fontsize=fs+2, color = c, rotation = 90)
    ax.axvline(N, 0, S2/25, ls = '--', c = c)
    Nlist.extend([N,N])
    Slist.extend([S1,S2])
    print 'predicted S1 & S2 for the Global Ocean:', S1, S2


    # Global estimates based on Kallmeyer et al. (2012) and SAR11 (2002 paper)
    N = float(Earth)
    Nmax = float(SAR11)
    guess = 0.1
    S2 = Preston2(N, Nmax, Nmin, guess)
    guess = 0.01
    S1 = Preston1(N, Nmax, guess)
    S2 = log10(S2)
    S1 = log10(S1)
    N = log10(N)

    ax.text(2, S1-1.5, 'predicted high', fontsize=fs+2, color = c)
    ax.axhline(S1, 0, 0.80, ls = '--', c = c)
    ax.text(2, S2-1.5, 'predicted low', fontsize=fs+2, color = c)
    ax.axhline(S2, 0, 0.80, ls = '--', c = c)
    ax.text(N-1, 8, 'Earth', fontsize=fs+2, color = c, rotation = 90)
    ax.axvline(N, 0, S2/25, ls = '--', c = c)
    Nlist.extend([N, N])
    Slist.extend([S1,S2])
    print 'predicted S1 & S2 for Earth:', S1, S2


    # Human Gut based on ...
    N = float(HGx)
    Nmax = float(HGy)
    guess = 0.1
    S2 = Preston2(N, Nmax, Nmin, guess)
    guess = 0.01
    S1 = Preston1(N, Nmax, guess)
    S2 = log10(S2)
    S1 = log10(S1)
    N = log10(N)

    ax.text(2, S1-1.5, 'predicted high', fontsize=fs+2, color = c)
    ax.axhline(S1, 0, 0.45, ls = '--', c = c)
    ax.text(2, S2-1.5, 'predicted low', fontsize=fs+2, color = c)
    ax.axhline(S2, 0, 0.45, ls = '--', c = c)
    ax.text(N-1, 8, 'Human Gut', fontsize=fs+2, color = c, rotation = 90)
    ax.axvline(N, 0, S2/25, ls = '--', c = c)
    Nlist.extend([N, N])
    Slist.extend([S1,S2])
    print 'predicted S1 & S2 for Human Gut:', S1, S2


    # Cow Rumen based on ...
    N = float(COWx)
    Nmax = float(COWy)
    guess = 0.1
    S2 = Preston2(N, Nmax, Nmin, guess)
    guess = 0.01
    S1 = Preston1(N, Nmax, guess)
    S2 = log10(S2)
    S1 = log10(S1)
    N = log10(N)

    """
    ax.text(2, S1-1.5, 'predicted high', fontsize=fs+2, color = c)
    ax.axhline(S1, 0, 0.40, ls = '--', c = c)
    ax.text(2, S2-1.5, 'predicted low', fontsize=fs+2, color = c)
    ax.axhline(S2, 0, 0.40, ls = '--', c = c)
    ax.text(N-1, 8, 'Cow Rumen', fontsize=fs+2, color = c, rotation = 90)
    ax.axvline(N, 0, 0.38, ls = '--', c = c)
    Nlist.extend([N, N])
    Slist.extend([S1,S2])
    print 'predicted S1 & S2 for Cow Rumen:', S1, S2
    """

    """
    # N and S for the Human Microbiome Project,
    S = np.log10(27483)
    N = np.log10(22618041)
    plt.scatter([N], [S], color = 'b', alpha= 1 , s = 40, linewidths=1, edgecolor='w', label='Human Microbiome Project')
    Nlist.append(N)
    Slist.append(S)
    """

    ax.text(8, -2., 'Total abundance, '+ 'log'+r'$_{10}$', fontsize=fs*2)
    ax.text(-2.3, 18, 'OTU '+ metric, fontsize=fs*2, rotation=90)

    #leg = plt.legend(loc=2, numpoints = 1, prop={'size':fs})
    #leg.draw_frame(False)

    plt.xlim(1, 31)
    plt.ylim(0.8, 25)

    #plt.savefig(mydir+'/figs/Fig3/Locey_Lennon_2015_Fig3-OpenReference_NoSingletons.png', dpi=600, bbox_inches = "tight")
    plt.savefig(mydir+'/figs/Fig3/Locey_Lennon_2015_Fig3-OpenReference.png', dpi=600, bbox_inches = "tight")
    #plt.savefig(mydir+'/figs/Fig3/Locey_Lennon_2015_Fig3-ClosedReference_NoSingletons.png', dpi=600, bbox_inches = "tight")
    #plt.savefig(mydir+'/figs/Fig3/Locey_Lennon_2015_Fig3-ClosedReference.png', dpi=600, bbox_inches = "tight")

    #plt.show()
    #plt.close()

    return


""" The following lines call figure functions to reproduce figures from the
    Locey and Lennon (2014) manuscript """

Fig3()