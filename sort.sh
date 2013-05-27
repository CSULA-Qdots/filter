#!/bin/bash
tmpfile1=$(mktemp)
tmpfile2=$(mktemp)
for i in $@
do
  head -n2 $i > $tmpfile1
  tail -n +2 $i | sort > $tmpfile2
#  if $(diff -q $i $tmpfile); then
  cat $tmpfile1 $tmpfile2 > $i
#  echo different
#    else
#      echo same
#  fi
done
rm $tmpfile1
rm $tmpfile2
