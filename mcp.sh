#!/bin/bash
#Master Control Program
#Perform all automated analysis and present user with data to fit

#Help text if user calls with no files
if [[ "$#" -lt 1 ]]; then
  echo "Pass a list of data file names to analyse."
  exit 0
fi

#Remove NewStuff.dat file, containing last run's fits
#sleep waits 5 seconds for user to realize potential mistake
if [ -e NewStuff.dat ] ; then
  echo "Removing NewStuff.dat ... ctrl-C to cancel"
  sleep 5
  rm NewStuff.dat
fi #/NewStuff removal

#Operate separately on each laser color, due to laser second order
#Translate literal space characters of input to newline character,
#	then search for laser string

redfiles=$(echo $@ | tr ' ' '\n' | grep RMG | xargs)
greenfiles=$(echo $@ | tr ' ' '\n' | grep 20G | xargs)

#oredfiles=$(echo $@ | tr ' ' '\n' | grep 5R | xargs)
#ogreenfiles=$(echo $@ | tr ' ' '\n' | grep 5G | xargs)
#violetfiles=$(echo $@ | tr ' ' '\n' | grep 5V | xargs)

echo "Filtering data"
#Only continue if Filter prceeded error-free

#Only operate on laser colors actually passed
if [[ -n $redfiles ]]; then
  tclsh filter.tcl --laser=red --sortby=ev -- $redfiles
  returncode=$?
  if [[ "$returncode" -ne "0" ]]; then
    echo "Filtering red failed"
    exit 1 #Script failed, return non-zero code
  fi
fi
if [[ -n $greenfiles ]]; then
  tclsh filter.tcl --laser=green --sortby=ev -- $greenfiles
  returncode=$?
  if [[ "$returncode" -ne "0" ]]; then
    echo "Filtering green failed"
    exit 1
  fi
fi

#Uncomment if we create new data with old lasers
#if [[ -n $oredfiles ]]; then
#   tclsh filter.tcl --laser=red --sortby=ev -- $oredfiles
#   returncode=$?
#   if [[ "$returncode" -ne "0" ]]; then
#     echo "Filtering old red failed"
#     exit 1
#   fi
# fi
# if [[ -n $ogreenfiles ]]; then
#   tclsh filter.tcl --laser=green --sortby=ev -- $ogreenfiles
#   returncode=$?
#   if [[ "$returncode" -ne "0" ]]; then
#     echo "Filtering old green failed"
#     exit 1
#   fi
# fi
# if [[ -n $violetfiles ]]; then
#   tclsh filter.tcl --laser=violet --sortby=ev -- $violetfiles
#   returncode=$?
#   if [[ "$returncode" -ne "0" ]]; then
#     echo "Filtering violet failed"
#     exit 1
#   fi
# fi


#Operate on files output by filter
#sed (s)earches for ".dat", replacing with ".out.dat", (g)lobally

outfiles=$(ls $@ | cat | xargs | sed -e "s/.dat/.out.dat/g")
rejectfiles=$(ls $@ | cat | xargs | sed -e "s/.dat/.out.dat.reject/g")

echo "Subtracting GaAs baseline"
#Only continue if Baseline prceeded error-free

#Only operate on laser colors actually passed
if [[ -n $redfiles ]]; then
  outredfiles=$(ls $redfiles | cat | xargs | sed -e "s/.dat/.out.dat/g")
  bash baseline.sh $outredfiles
  returncode=$?
  if [[ "$returncode" -ne "0" ]]; then
    echo "Zeroing red failed"
    exit 1
  fi
fi
if [[ -n $greenfiles ]]; then
  outgreenfiles=$(ls $greenfiles | cat | xargs | sed -e "s/.dat/.out.dat/g")
  bash baseline.sh $outgreenfiles
  returncode=$?
  if [[ "$returncode" -ne "0" ]]; then
    echo "Zeroing green failed"
    exit 1
  fi
fi


#Operate on files output by baseline
correctedfiles=$(ls $@ | cat | xargs | sed -e "s/.dat/_corrected.dat/g")

echo "Calling IPF"
#No return code possible because Matlab launcher closes before Matlab does
bash multiIPF.sh $correctedfiles


echo "Press enter to clean up, ctrl-C to cancel"
#Waits for user input. Input is not actually used, but allows arbitrary wait time
read

#Move out files from current directory to prevent tripling the already large number present.
#p option prevents error if folder is extant
mkdir -p corrected
mkdir -p out
mkdir -p reject
mv $correctedfiles corrected/
mv $outfiles out/
mv $rejectfiles reject/
echo "File not found errors indicate data with unhandled lasers"

#Rename generic output file to current date
#Date code used is YYYYMMDDHMS, such as 20130115161205, matching logs from Filter
if [[ -e NewStuff.dat ]]; then
    mv NewStuff.dat fits-$(date +%Y%m%d%H%M%S).txt
else
    echo "No fits found."
    exit 1
fi
