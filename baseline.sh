#/bin/bash
unset DISPLAY
logFile=log-baseline-$(date +%Y%m%d%H%M%S)
matlabExecutable=matlab
matFunction=zero
tmpMatFile=$(mktemp)
version=1.1
echo "Baseline correction version $version" | tee $logFile
echo $(head -n1 zero.m) | tee -a $logFile
echo "Start time $(date +%Y%m%d%H%M%S)" | tee -a $logFile
correctedString="corrected"

echo "Running function $matFunction" | tee -a $logFile
echo "${matFunction}('$@')" | tee -a $tmpMatFile
${matlabExecutable} -nojvm -nodisplay -nosplash &>> $logFile < $tmpMatFile
echo "" >> $logFile

echo "End time $(date +%Y%m%d%H%M%S)" | tee -a $logFile
rm $tmpMatFile
