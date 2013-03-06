filter.tcl
==========
Data filtering for the CSULA quantum-dot spectroscopy experiment

Basic noise-reject algorythm:

X = Wavelength under consideration.
T = Reject threshold.
delta =Range to average over.
A = Running average over points between x +/- delta.
D = |(X-A)/A|
Reject if D>T

Some experimentation shows minimal noise rejection until threshhold is below 0.5
and/or delta grows over 4. Suggest values of 0.10 and 10.

filter.tcl
===========
In progress. I'll write some docs for it once the features stabilize. Right now, adding an interpreter for command line options.

rescale.tcl
===========
removed since we are workign on makign this an option. Functionality is being worked into stock filter.

example.filterrc
================
Provides options to filter.tcl and rescale.tcl. example.filterrc should be copied into your home directory under the name .filterrc
Change username to your own name for logging purposes. See logs in QD/data

zero.m
===============
Subtracts a baseline from data based on a fit to a background run.
Use baselineCorrector.sh if possible. To use directly
Open MatLAB and type: zero('filename')
filename should be in the same directory as the baseline_zero.m unless pathed
This program will output filename_corrected.out.eV.dat 

baselineCorrector.sh
===============
Creates baseline subtracted versions of all eV.out.dat files in the current working directory. 
Works on linux only. 

spreadsheets/TestDataGenerator.ods
===============
Spreadsheet that creates data similar to our experiments. The centroids, height, and width factors of the peaks
are adjustable on the Controls tab. The NoiseEx tab contains some functions for different kinds of noise.
They can be summed up in the left column and the graph and first tab automatically update.
To export data switch to the Out tab, Save As csv, and check the box to adjust options. The text delimiter should be "
and the separator should be space or tab.

Branch Naming
=============
So, the way you name a branch is this: initials.descriptive and then you
can work on it. Don't fork the project, it makes it harder for me to merge your improvements back into the mainline.

To make a branch to work on a feature, I (Ryan) will type: git branch rd.laserdetect
