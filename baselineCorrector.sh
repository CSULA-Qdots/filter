#/bin/bash
unset DISPLAY
list_Of_Names=(*out.dat)
logFile=log-baseline-$(date +%Y%m%d%H%M%S)
matlabExecutable=matlab
matFunction=zero
tmpMatFile=$(mktemp)
version=1.1
echo "Baseline correction version $version" | tee $logFile
echo $(head -n1 zero.m) | tee -a $logFile
echo "Start time $(date +%Y%m%d%H%M%S)" | tee -a $logFile
for i in ${list_Of_Names[@]}
do
	echo "Running function $matFunction on file $i" | tee -a $logFile
	echo "${matFunction}('${i}')" > $tmpMatFile
	${matlabExecutable} -nojvm -nodisplay -nosplash &>> $logFile < $tmpMatFile
	echo "" >> $logFile
done
echo "End time $(date +%Y%m%d%H%M%S)" | tee -a $logFile
rm $tmpMatFile
