Experimental Commits
====================
Please don't push them to 'master' and... in fact, any time you do work on this, work on a branch. Even if it works and you merge it right in after.
'master' should /always/ be functioning code. Branch, code, merge. It keeps things self consistant.

filter.tcl
==========
Data filtering for the CSULA quantum-dot spectroscopy experiment

Basic noise-reject algorythm:

* X = Wavelength under consideration.
* T = Reject threshold.
* delta =Range to average over.
* A = Running average over points between x +/- delta.
* D = |(X-A)/A|
* Reject if D>T

Some experimentation shows minimal noise rejection until threshhold is below 0.5
and/or delta grows over 4. Suggest values of 0.10 and 10.

filter.tcl
===========
New options file format. New, more powerful command line syntax. Actually writes the default config file! Doesn't do globbing, so windows users will need to specify full filnemaes, not just \*.dat

Options:
* `-` 
  Read more filenames from STDIN
* `--optname`
shorthand for --optname=1
* `--optname=value`
set the option named 'optname' to 'value'
* `--`
all things after this are treated as filenames.`

Order isn't important unless you have some wierd filenames that look like options. Options on the command line over-ride those in the defaults file.

Options list:
+ delta (integer)
+ threshold (float)
+ operator "Your Full Name"
+ rescale (not yet implimented)
+ sortby "columnName"
+ laser "lasername"
+ laserlow (integer)
+ laserhigh (integer)

Valid column names are: "none", "ev", "lambda", "corrected", "intensity", and "temp". Valid Laser Names are "red" and "green" No quotes please.

`--laser=red` is short for `--laserlow=7000 --laserhigh=7250`

`--laser=green` is short for `--laserlow=10300 --laserhigh=11600`

`--laser=foo` will override high/low settings.

NOTE: This needs a rewrite.

MultiIPF
========

MultiIPF instructions:
Run multiIPF, via mcp.sh or in matlab directly. 
multiIPF uses 3 parameters: The first is the name of a file that is a list of all the files 
you want to analyze (which must be in the same directory as multiIPF) The files must include 
extensions and must be line delimited.
The second two parameters are the columns in the data files that you wish to analyze. These are columns 1 and 2.
All the files that are to be analyzed should be sorted, in eV, and no header columns. There is a catch statement that will 
correct the header columns, but this has not been tested.

multiIPF('FileList.dat', 1, 2)

The program will run ipf on each file. The normal window will appear, asking you to set the number of peaks, baseline, etc.
Proceed as usual, but after fitting, press = to save your fit results to NewStuff.dat. The name of the file will be saved before your peaks.
Note that it will be appended, so you should clear NewStuff.dat beforehand. mcp.sh automatically does this.
Also, if there is an error with the file that should be analyzed, multiIPF will catch it and will report that in NewStuff.dat: 
'There was an error with this file' and move on.

Caution with =:
Also note that pressing = the very first time without fitting anything will cause an error: = reads out the FitResults to NewStuff.dat, so 
if there is no fit, an error will be thrown. A catch statement has been implemented but not tested. If = is pressed accidentally twice after 
a successful fit, the same list of peaks will be appended again.

After finishing all the files, the program will exit, and the peak results will be in NewStuff.dat.

rescale.tcl
===========
Removed since we are workign on makign this an option. Functionality is being worked into stock filter.

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
