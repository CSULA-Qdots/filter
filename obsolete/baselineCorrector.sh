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
for i in ${@}
do
	if test "${i#*$correctedString}" == "$i"; then
#	  grep -v dmm $i | grep -v delta > $tmpMatFile
#	  cat $tmpMatFile > $i
	  echo "Running function $matFunction on file $i" | tee -a $logFile
	  echo "${matFunction}('${i}')" > $tmpMatFile
	  ${matlabExecutable} -nojvm -nodisplay -nosplash &>> $logFile < $tmpMatFile
	  echo "" >> $logFile
	 fi
done
echo "End time $(date +%Y%m%d%H%M%S)" | tee -a $logFile
rm $tmpMatFile
