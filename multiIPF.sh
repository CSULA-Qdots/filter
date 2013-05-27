#!/bin/bash
#Wrap multiIPF with typical input structure

matFunction=multiIPF
matlabFileList=$(mktemp)
matlabInputFile=$(mktemp)

#multiIPF requires newline-separated input list within a file
#Translate literal space characters of input to newline character
echo $@ | tr ' ' '\n' > $matlabFileList

echo "Running function $matFunction on $@"

#Matlab is difficult to invoke directly from shell, but accepts standard input
#1,2 indicate energy and intensity columns of data
echo "${matFunction}('$matlabFileList',1,2)" > $matlabInputFile

matlab -nosplash < $matlabInputFile

rm $matlabInputFile
rm $matlabFileList
