#!/bin/bash
#Logging doesn't seem necessary when creating a spreadsheet.
#logFile=log-ipf-$(date +%Y%m%d%H%M%S)
matlabExecutable=matlab
matFunction=multiIPF
tmpMatFile=$(mktemp)
echo "cli params:" $@
cat $@
echo "Running function" $matFunction "."
echo "${matFunction}('${@}',1,2)" >> $tmpMatFile
${matlabExecutable} -nosplash < $tmpMatFile
rm $tmpMatFile
