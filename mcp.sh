#!/bin/bash
#Master Control Program
#Perform all automated analysis and present user with data to fit

#Remove NewStuff.dat file, containing last run's fits
#sleep waits 5 seconds for user to realize potential mistake
if [ -e NewStuff.dat ]; then
  echo "Removing NewStuff.dat ... ctrl-C to cancel"
  sleep 5
  rm NewStuff.dat
fi #/NewStuff removal

echo "Filtering data"
#Only continue if Filter prceeded error-free
if (tclsh filter.tcl $@); then

  #Operate on files output by filter
  #sed (s)earches for ".dat", replacing with ".out.dat", (g)lobally
  outfiles=$(echo ${@} | sed -e "s/.dat/.out.dat/g")

  echo "Subtracting GaAs baseline"
  #Only continue if Baseline prceeded error-free
  if (bash baseline.sh $outfiles); then

    #Operate on files output by baseline
    correctedfiles=$(echo ${@} | sed -e "s/.dat/_corrected.dat/g")

    echo "Calling IPF"
    #No return code possible because Matlab launcher closes before Matlab does
    bash multiIPF.sh $correctedfiles

    #Move out files from current directory to prevent tripling the already large number present.
    echo "Cleanup"
    #p option prevents error if folder is extant
    mkdir -p out
    mkdir -p corrected
    mv $outfiles out/
    mv $correctedfiles corrected/

    #Rename generic output file to current date
    #Date code used is YYYYMMDDHMS, such as 20130115161205, matching logs from Filter
    if [ -e NewStuff.dat ]; then
	mv NewStuff.dat fits-$(date +%Y%m%d%H%M%S).txt
    else
	echo "Something went wrong, no fits found."
	exit 1 #Script failed, return non-zero code
    fi #/NewStuff renaming
  else
    echo "Zeroing failed"
    exit 1
  fi #/Baseline conditional
else
    echo "Filtering failed"
    exit 1
fi #/Filter conditional
