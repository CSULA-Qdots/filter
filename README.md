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

rescale.tcl
===========
Same as filter with an adjustment for photomultiplier sensitivity.
Scaling performed according to an Excel polynomial fit to data from reading
and interpolating the RCA chart for the 7102 PMT.
Possibly deprecated, needs further testing in combination with background zeroing

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

Branch Naming
=============
So, the way you name a branch is this: initials.descriptive and then you
can work on it. Don't fork the project, it makes it harder for me to merge your improvements back into the mainline.

To make a branch to work on a feature, I (Ryan) will type: git branch rd.laserdetect
