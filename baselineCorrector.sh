#!/bin/bash
unset DISPLAY
list_Of_Names=(*_eV.out.dat)
logFile=log-ipf-$(date +%Y%m%d%H%M%S)
matlabExecutable=matlab
matFunction=zero
tmpMatFile=$(mktemp)
for i in ${list_Of_Names[@]}
do
	echo "Running function" $matFunction " on file " $i
	echo "${matFunction}('${i}')" > $tmpMatFile
	${matlabExecutable} -nojvm -nodisplay -nosplash &>> $logFile < $tmpMatFile
done
rm tmpMatFile
