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

#Operate separately on each laser color, due to laser second order
#Translate literal space characters of input to newline character,
#	then search for laser string
redfiles=$(echo $@ | tr ' ' '\n' | grep RMG | xargs)
greenfiles=$(echo $@ | tr ' ' '\n' | grep 20G | xargs)
#ogreenfiles=$(echo $@ | tr ' ' '\n' | grep 5G | xargs)
#violetfiles=$(echo $@ | tr ' ' '\n' | grep 5V | xargs)
#oredfiles=$(echo $@ | tr ' ' '\n' | grep 5R | xargs)

echo "Filtering data"
#Only continue if Filter prceeded error-free
if (tclsh filter.tcl --sortby=ev -- $redfiles); then
if (tclsh filter.tcl --sortby=ev -- $greenfiles); then

  #Operate on files output by filter
  #sed (s)earches for ".dat", replacing with ".out.dat", (g)lobally
  
  outfiles=$(ls $@ | cat | xargs | sed -e "s/.dat/.out.dat/g")
  outgreenfiles=$(ls $greenfiles | cat | xargs | sed -e "s/.dat/.out.dat/g")
  outredfiles=$(ls $redfiles | cat | xargs | sed -e "s/.dat/.out.dat/g")
  
  rejectfiles=$(ls $@ | cat | xargs | sed -e "s/.dat/.out.dat.reject/g")

  echo "Subtracting GaAs baseline"
  #Only continue if Baseline prceeded error-free
  if (bash baseline.sh $outredfiles); then
  if (bash baseline.sh $outgreenfiles); then

    #Operate on files output by baseline
    correctedfiles=$(ls $@ | cat | xargs | sed -e "s/.dat/_corrected.dat/g")

    echo "Calling IPF"
    #No return code possible because Matlab launcher closes before Matlab does
    bash multiIPF.sh $correctedfiles

    #Move out files from current directory to prevent tripling the already large number present.
    echo "Press enter to clean up"
    #Waits for input. We ignore it
    read
    #p option prevents error if folder is extant
    mkdir -p corrected
    mkdir -p out
    mkdir -p reject
    mv $correctedfiles corrected/
    mv $outfiles out/
    mv $rejectfiles reject/

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
  fi #/Baseline green conditional
  fi #/Baseline red conditional
else
    echo "Filtering failed"
    exit 1
fi #/Filter green conditional
fi #/Filter red conditional
