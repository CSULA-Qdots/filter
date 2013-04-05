#!/bin/bash
#Master Control Program
tmpfile=$(mktemp)
tclsh filter.tcl $@
#Clear NewStuff file
if (-e NewStuff.dat); rm NewStuff.dat;
./baselineCorrector.sh *.out.dat
find -name \*corrected.dat > $tmpfile
./multiIPF.sh $tmpfile
rm $tmpfile
