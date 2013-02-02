filter
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
