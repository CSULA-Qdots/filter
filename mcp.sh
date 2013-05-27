#!/bin/bash
#Master Control Program
tmpfile=$(mktemp)
echo call filter
tclsh filter.tcl $@
#Clear NewStuff file
echo delete newstuff
if (test -e NewStuff.dat); then
  rm NewStuff.dat
fi
echo call sort

./sort.sh $@
echo call baselineCorrector
outfiles=$(echo $@ | sed -e "s/.dat/.out.dat/g")
./baseline.sh $outfiles
echo find corrected
#find * -prune -type f -name \*corrected.dat > $tmpfile
correctedfiles=$(echo $@ | sed -e "s/.dat/_corrected.dat/g")
echo $correctedfiles | tr ' ' '\n' > $tmpfile
echo call ipf
./multiIPF.sh $tmpfile
echo cleanup
rm $tmpfile
