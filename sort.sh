#!/bin/bash
tmpfile=$(mktemp)
for i in $@
do
  sort $i > $tmpfile
  if $(diff -q $i $tmpfile); then
      cat $tmpfile > $i
      echo different;
    else
      echo same;
  fi
done
rm $tmpfile
