filter.tcl
======
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
See C:\Data\Dropbox\QD\2010\10-Oct\10-21-2010

rescale.tcl
======
Same as filter with an adjustment for photomultiplier sensitivity.
Scaling performed according to an Excel polynomial fit to data from reading
and interpolating the RCA chart for the 7102 PMT.

example.filterrc
======
A filterrc file to copy into your home directory under the name .filterrc
Change username to your own for logging purposes. See logs in data directory.
