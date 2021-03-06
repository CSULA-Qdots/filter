#!/bin/bash
list_Of_Names=(*.out.dat)
#Logging doesn't seem necessary when creating a spreadsheet.
#logFile=log-ipf-$(date +%Y%m%d%H%M%S)
matlabExecutable=matlab
matFunction=ipf_wrapper
tmpMatFile=$(mktemp)
for i in ${list_Of_Names[@]}
do
	echo "Running function" $matFunction " on file " $i
#	As in zero.m
	echo "dataStructure = importdata(char('$i'));" > $tmpMatFile
	echo "${matFunction}(dataStructure.data)" >> $tmpMatFile
#	echo "${matFunction}(dataStructure.data(:,1),dataStructure.data(:,3))" >> $tmpMatFile
#	${matlabExecutable} -nojvm -nodisplay -nosplash &>> $logFile < $tmpMatFile
#	Wait option prevents running the loop concurrently, as "matlab" is actually a launcher script
	${matlabExecutable} -nosplash < $tmpMatFile
	read -p "Press enter to run next file "
done
cat $tmpMatFile
rm $tmpMatFile
