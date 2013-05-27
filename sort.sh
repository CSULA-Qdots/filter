#!/bin/bash
#Sort data files in ascending numerical order

headTmp=$(mktemp)
tailTmp=$(mktemp)

echo Sorting $@

for i in $@
do
  #sort implements ASCII sorting, thus letters are after numbers
  #Input file must have numerical portion split out and sorted
  
  #Assumes all data follows standard one-line informational header and one line table header
  head -n2 $i > $headTmp

  #tail reads k'th to last line of file when n option is given as -n +k
  tail -n +2 $i | sort > $tailTmp
  
  #Recombine file header and now-sorted numerical portion
  cat $headTmp $tailTmp > $i

done

rm $headTmp
rm $tailTmp
