list_Of_Names=(*_eV.out.dat)

for i in ${list_Of_Names[@]}
do
   echo $i
   string=$i
   #insert the matlab code to call zero.m for string here
	./mb.sh zero $string
done
