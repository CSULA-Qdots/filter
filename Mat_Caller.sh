#Code taken from discussion at http://stackoverflow.com/questions/2001183/how-to-call-matlab-functions-from-the-linux-command-line
list_Of_Names=(*_eV.out.dat)
tmpMatFile=$(mktemp)
matlabExecutable=matlab
matFunction=zero
for i in ${list_Of_Names[@]}
do
	echo "Running function" $matFunction " on file " $i
	string=$i
	echo "${matFunction}('${i}')" > tmpMatFile
	#cat tmpMatFile
	${matlabExecutable} -nojvm -nodisplay -nosplash < tmpMatFile
done
rm tmpMatFile
