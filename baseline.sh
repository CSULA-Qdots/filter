#/bin/bash
#Subtract GaAs background from files

unset DISPLAY
#Date code used is YYYYMMDDHMS, such as 20130115161205
#Such date codes match logs from Filter
logFile=log-baseline-$(date +%Y%m%d%H%M%S)
matFunction=corrector
#Creates uniquely named file in system temporary directory
matlabInputFile=$(mktemp)
version=1.2

#Log actions in case of changes to baseline fit
#tee allows simultaneous display and logging

echo "Baseline correction version $version" | tee $logFile
#Displays and logs first line of corrector.m, containing version information.
echo $(head -n1 corrector.m) | tee -a $logFile
echo "Start time $(date +%Y%m%d%H%M%S)" | tee -a $logFile

echo "Running function $matFunction on $@" | tee -a $logFile

#Matlab is difficult to invoke directly from shell, but standard input goes to Matlab cli
echo "${matFunction}('$@')" | tee $matlabInputFile

matlab -nojvm -nodisplay -nosplash &>> $logFile < $matlabInputFile
#Add newline to log file
echo "" >> $logFile

echo "End time $(date +%Y%m%d%H%M%S)" | tee -a $logFile
rm $matlabInputFile
