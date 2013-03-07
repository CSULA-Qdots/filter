#!/bin/bash
unset DISPLAY
list_Of_Names=(*.out.dat)
#Logging doesn't seem necessary when creating a spreadsheet.
#logFile=log-ipf-$(date +%Y%m%d%H%M%S)
matlabExecutable=matlab
matFunction=ipf
tmpMatFile=$(mktemp)
for i in ${list_Of_Names[@]}
do
	echo "Running function" $matFunction " on file " $i
	echo "${matFunction}('${i}')" > $tmpMatFile
#	${matlabExecutable} -nojvm -nodisplay -nosplash &>> $logFile < $tmpMatFile
	${matlabExecutable} -nojvm -nodisplay -nosplash < $tmpMatFile
done
rm $tmpMatFile
