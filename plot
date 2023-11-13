#!/usr/bin/env python

"""a quick script to plot the mass-radius curve
"""
__author__ = "Reed Essick (essick@cita.utoronto.ca)"

#-------------------------------------------------

import os
import sys

import numpy as np

import matplotlib
matplotlib.use("Agg")
from matplotlib import pyplot as plt
plt.rcParams['text.usetex'] = True

from argparse import ArgumentParser

#-------------------------------------------------

Msun = 1.989e30 # kg
G = 6.6743e-11 # kg m^3 / s^2
c = 299792458 # m/s

#-------------------------------------------------

parser = ArgumentParser()

parser.add_argument('path', type=str)

parser.add_argument('--max-radius', default=20, type=float,
    help='the maximum radius to consider. Should be specified in km')

parser.add_argument('-v', '--verbose', default=False, action='store_true')
parser.add_argument('-V', '--Verbose', default=False, action='store_true')

args = parser.parse_args()

args.verbose |= args.Verbose

#-------------------------------------------------

# load data
if args.verbose:
    print('loading TOV solutions from: '+args.path)

data = np.genfromtxt(args.path, delimiter=',', names=True)

# figure out the order of data points
pc2 = data['central_pressurec2'] # g/cm^3
order = np.argsort(pc2)
pc2 = pc2[order]

# grab data for convenience
mass = data['M'][order] # Msun
radius = data['R'][order] # km

# throw away big radii

keep = radius <= args.max_radius
mass = mass[keep]
radius = radius[keep]

# count how many points are left

N = len(radius)
if args.verbose:
    print('    retained %d / %d samples with radius <= %.3f km' % (N, len(data), args.max_radius))

#-------------------------------------------------

if args.verbose:
    print('plotting')

fig = plt.figure()
ax = fig.gca()

#------------------------

if args.verbose:
    print('    iterating to identify stable and unstable branches')

# identify stable/unstable branches
start = 0

# find the first stable branch
while start < N:
    if args.Verbose:
        sys.stdout.write('\r    %4d / %4d' % (start, N))
        sys.stdout.flush()

    if mass[start+1] < mass[start]:
        start += 1

    else:
        if args.Verbose:
            sys.stdout.write('\n')
            sys.stdout.flush()
        break

stop = start + 1
stable = True

mmax = []
rmax = []
r1d4 = []

num_branches = 0

# now iterate until we run out of points
while stop < N:
    if args.Verbose:
        sys.stdout.write('\r    %4d / %4d' % (stop, N))
        sys.stdout.flush()

    if stable: # on a stable branch
        if mass[stop] > mass[stop-1]: # stable branch continues
            stop += 1

        else: # end of stable branch

            num_branches += 1 # increment number of stable branches

            mmax.append(mass[stop-1]) # record properties at the end of the branch
            rmax.append(radius[stop-1])

            if (mass[start] <= 1.4) and (1.4 <= mass[stop-1]): # stable branch spans 1.4 Msun stars
                r1d4.append(np.interp(1.4, mass[start:stop], radius[start:stop]))

            ax.plot(
                radius[start:stop],
                mass[start:stop],
                color='b',
                linestyle='solid',
                alpha=0.75,
#                marker='.',
            )
            start = stop - 1
            stable = False

    else: # on an unstable branch
        if mass[stop] > mass[stop-1]: # end of unstable branch
            ax.plot(
                radius[start:stop],
                mass[start:stop],
                color='r',
                linestyle='dashed',
                alpha=0.75,
#                marker='.',
            )
            start = stop - 1
            stable = True

        else:
            stop += 1

if args.Verbose:
    sys.stdout.write('\n')
    sys.stdout.flush()

# intentionally do not plot the last unstable branch...
if stable:
    raise ValueError('ended on a stable branch...')

if args.verbose:
    print('        identified %d stable branches' % num_branches)

ax.set_title('%d stable branches' % num_branches)

#------------------------

if args.verbose:
    print('    annotating plot')

ind = np.argmax(mmax)

ax.plot(rmax[ind], mmax[ind], marker='o', markeredgecolor='b', markerfacecolor='none')
ax.text(
    rmax[ind],
    mmax[ind],
    '$R(M=%.3f\,M_\odot) = %.3f\,\mathrm{km}\ $'%(mmax[ind], rmax[ind]),
    ha='right',
    va='center',
)

for r in r1d4:
    ax.plot(r, 1.4, markeredgecolor='b', markerfacecolor='none', marker='s')
    ax.text(
        r,
        1.4,
        '$R(M=1.4\,M_\odot) = %.3f\,\mathrm{km}\ $'%(r),
        ha='right',
        va='center',
    )

#------------------------

ax.set_xlabel('$R\,[\mathrm{km}]$')
ax.set_ylabel('$M\,[M_\odot]$')

# plot Schwarzschild radius as a function of mass

if args.verbose:
    print('    plotting Schwarzschild radius')

_, ymax = ax.get_ylim()
ymin = 0.0
y = np.linspace(ymin, ymax, 101)

ax.fill_between(
    2*y*Msun*G/c**2 * 1e-3, # km
    y,
    ymax*np.ones_like(y),
    color='grey',
    alpha=0.25,
    label='Schwarzschild',
)

ax.set_ylim(ymin=ymin, ymax=ymax)
ax.set_xlim(xmin=0.0, xmax=args.max_radius)

#------------------------

figname = os.path.basename(__file__) + ".png"
if args.verbose:
    print('saving : '+figname)
fig.savefig(figname)
plt.close(fig)
