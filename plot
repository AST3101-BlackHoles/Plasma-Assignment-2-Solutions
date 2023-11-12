#!/usr/bin/env python

"""a quick script to plot the mass-radius curve
"""
__author__ = "Reed Essick (essick@cita.utoronto.ca)"

#-------------------------------------------------

import numpy as np

import matplotlib
matplotlib.use("Agg")
from matplotlib import pyplot as plt

from argparse import ArgumentParser

#-------------------------------------------------

parser = ArgumentParser()

parser.add_argument('path', type=str)

parser.add_argument('-v', '--verbose', default=False, action='store_true')

args = parser.parse_args()

#-------------------------------------------------

# load data
if args.verbose:
    print('loading TOV solutions from: '+args.path)

data = np.genfromtxt(args.path, delimiter=',', names=True)

#-------------------------------------------------

raise NotImplementedError
