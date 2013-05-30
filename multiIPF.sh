#!/bin/bash
#Wrap MultiIPF with typical input structure

matFunction=multiIPF
#Creates uniquely named file in system temporary directory
mulitiIpfFileList=$(mktemp)
matlabInputFile=$(mktemp)

#multiIPF requires newline-separated input list within a file
#Translate literal space characters of input to newline character
echo $@ | tr ' ' '\n' > $mulitiIpfFileList

#List inputs recieved to user
echo "Running function $matFunction on $@"

#Matlab is difficult to invoke directly from shell, but standard input goes to Matlab cli
#1,2 indicate energy and intensity columns of data
echo "${matFunction}('$mulitiIpfFileList',1,2)" > $matlabInputFile

matlab -nosplash < $matlabInputFile

rm $matlabInputFile
rm $mulitiIpfFileList
