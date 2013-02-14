function zero (input)
	% This segment of the code splits up the input into multiple strings

	list_names = textscan(input, '%s');
	%???
	%list_names is already defined as an array, does making it a single element
	%cause problems? Like the current inability to work on multiple files?
	list_names = list_names{1}

	%???
	%Can matlab handle using the length function in the for loop terminator?
	numFiles = length(list_names)

	% Runs the zeroing for each name submitted

	for i = 1:numFiles
		file = list_names(i);
		subtractBaseline(file);
	end


	function subtractBaseline (fileName)
		% Grab the data.

		dataStructure = importdata(char(fileName));
		% The .data part of a structure is the numerical part. Headers will be ignored.
		signal = dataStructure.data;

		% The data, signal, will be an array with 3 columns (wavelength, signal,
		% and temperature. m gives the number of points. n is 3.

		[m, n] = size(signal);

		% This algorithm calculates the point that is closest to the first
		% callibration wavelength. min represents the distance to the
		% desired value. I just use a minimization loop to find the value that
		% gives the lowest min value. The first callibration point is 1.653 eV, or
		% 7500 A.

		min = 100;
		calibrationPoint1 = 1;

		% I start and end at these points because I want to average nearby points, and I don't want an ArrayOutOfBounds error.
		% Absolute value is required to handle negative spikes

		for i = 3:m-3
			if abs(signal(i,1) - 1.653) < min
				calibrationPoint1 = i;
				min = abs(signal(i,1) - 1.653);
			end
		end

		% This repeats the same procedure, but for a second callibration point:
		% This one is at 1.127 eV, or 11000 A.

		min2 = 100;
		calibrationPoint2 = 1;

		for i = 3:m-3
			if abs(signal(i,1) - 1.127) < min2
				calibrationPoint2 = i;
				min2 = abs(signal(i,1) - 1.127);
			end
		end

		% This part of the code callibrates our fit to the data. The idea is that
		% the value of the signal should be zero at 11000 A and 7500 A. We multiply
		% our fit by a linear function (called amp) and use that to callibrate our
		% data. We incorporate an averaging feature to avoid peak and dip features.

		 average1 = (signal(calibrationPoint1-2,2) + signal(calibrationPoint1-1,2) + signal(calibrationPoint1,2) + signal(calibrationPoint1+1,2) + signal(calibrationPoint1+2,2))/5.0;
		 amplitude1 = average1 / backgroundQuadraticApprox(signal(calibrationPoint1,1));
		 average2 = (signal(calibrationPoint2-2,2) + signal(calibrationPoint2-1,2) + signal(calibrationPoint2,2) + signal(calibrationPoint2+1,2) + signal(calibrationPoint2+2,2))/5.0;
		 amplitude2 = average2 / backgroundQuadraticApprox(signal(calibrationPoint2,1));


		% This is my way to make the filename of the outputfile 'a_corrected.dat',
		% if the original file was 'a.something'
		% Don't judge me!

		%???
		%I don't understand this well enough to reasonably rename the variables
		 ar = char(fileName);
		 inder = 1;
		 hithere = 0;
		 while hithere < 1
			 new(inder) = ar(inder);
			 inder = inder + 1;
			 if (ar(inder) == '.')
				hithere = 3;
			 end
		 end

		%Opens a file for writing
		fileHandle = fopen(strcat(new,'_corrected.dat'), 'w');

		% Subtract out the callibration and put it in the file.
		%m is total number of points

		for i = 1:m
			g(i,1) = signal(i,1);
			g(i,2) = signal(i,2) - amp(signal(i, 1)) * backgroundQuadraticApprox(signal(i,1));
			g(i,3) = signal(i,3);

			% special formatting for the output file
			fprintf(fileHandle, '%.9f\t%.9f\t%.9f\n', g(i,:));
		end

		% close the file
		fclose(fileHandle);


		% This function is our quadratic fit of the background GaAs wafer.
		function y = backgroundQuadraticApprox(x)
			%???
			%Is this function definition recursive?

			r = 12400.0/x; % The original formula is in wavelength, and our data is in eV.
			y = 0.0015873240642803 - 0.00000025667991263308*r +0.000000000011008884166353*r*r;
		end


		% This function calculates the final correction to our data. It's a linear
		% fit of our fit, so to speak. This process skews the fit by multiplying a
		% line to the original background.
		function correction = amp(x)
			%???
			%Is this function definition recursive?

			correction = (amplitude2 - amplitude1)/(signal(calibrationPoint2,1) - signal(calibrationPoint1,1)) * (x - signal(calibrationPoint1, 1)) + amplitude1;
		end
	end
end
