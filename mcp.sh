#!/bin/bash
#Master Control Program
#Perform all automated analysis and present user with data to fit

echo Filtering data
tclsh filter.tcl $@

#Remove NewStuff.dat file, containing last run's fits
#sleep waits 5 seconds for user to realize potential mistake
if (test -e NewStuff.dat); then
  echo Removing NewStuff.dat ... ctrl-C to cancel
  sleep 5
  rm NewStuff.dat
fi

#Operate on files output by filter
outfiles=$(echo $@ | sed -e "s/.dat/.out.dat/g")

echo Sorting data
./sort.sh $outfiles

echo Subtracting GaAs baseline
./baseline.sh $outfiles

#Operate on files output by baseline
correctedfiles=$(echo $@ | sed -e "s/.dat/_corrected.dat/g")

echo Calling IPF
./multiIPF.sh $correctedfiles

echo Cleanup
#Unsure if out files without zero adjustment are worth keeping
#rm $outfiles
