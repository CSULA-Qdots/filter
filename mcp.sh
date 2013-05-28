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
#sed (S)earches for ".dat", replacing with ".out.dat", (G)lobally
outfiles=$(echo ${@} | sed -e "s/.dat/.out.dat/g")

#Return code reading example
#if (./sort.sh $outfiles != 0 ); then
#  echo Sort failed
#  exit 1
#fi
echo Sorting data
./sort.sh $outfiles

echo Subtracting GaAs baseline
./baseline.sh $outfiles

#Operate on files output by baseline
correctedfiles=$(echo ${@} | sed -e "s/.dat/_corrected.dat/g")

echo Calling IPF
./multiIPF.sh $correctedfiles

#Move out files from current directory to prevent tripling the already large number present.
echo Cleanup
#p option prevents error if folder is extant
mkdir -p out
mkdir -p corrected
mv $outfiles out/
mv $correctedfiles corrected/

#Rename generic output file to current date
#Date code used is YYYYMMDDHMS, such as 20130115161205, matching logs from Filter
if (test -e NewStuff.dat); then
    mv NewStuff.dat fits-$(date +%Y%m%d%H%M%S).txt
  else
    echo Something went wrong, no fits found.
    exit 1 #Script failed, return non-zero code
fi
