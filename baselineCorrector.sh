#/bin/bash
unset DISPLAY
list_Of_Names=(*_eV.out.dat)
logFile=log-baseline-$(date +%Y%m%d%H%M%S)
matlabExecutable=matlab
matFunction=zero
tmpMatFile=$(mktemp)
version=1.1
echo "Baseline correction version $version" > $logFile
echo $(head -n1 zero.m) >> $logFile
for i in ${list_Of_Names[@]}
do
	echo "Running function" $matFunction " on file " $i
	echo "${matFunction}('${i}')" > $tmpMatFile
	${matlabExecutable} -nojvm -nodisplay -nosplash &>> $logFile < $tmpMatFile
done
rm $tmpMatFile
