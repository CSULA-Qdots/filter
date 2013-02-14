function zero (input)
	% This segment of the code splits up the input into multiple strings

	list_names = textscan(input, '%s');
	list_names = list_names{1}

	% list_names now becomes an array that holds the names of the files
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
		% gives the lowest min value.

		calPoint1eV = 1.653;
		%calPoint1A = 7500;
		calPoint2eV = 1.127;
		%calPoint2A = 11000;

		min = 100;
		calibrationPoint1 = 1;

		% I start and end at these points because I want to average nearby points, and I don't want an ArrayOutOfBounds error.
		% Absolute value is required to handle negative spikes

		for i = 3:m-3
			if abs(signal(i,1) - calPoint1eV) < min
				calibrationPoint1 = i;
				min = abs(signal(i,1) - calPoint1eV);
			end
		end

		% This repeats the same procedure, but for a second callibration point:

		min2 = 100;
		calibrationPoint2 = 1;

		for i = 3:m-3
			if abs(signal(i,1) - calPoint2eV) < min2
				calibrationPoint2 = i;
				min2 = abs(signal(i,1) - calPoint2eV);
			end
		end

		% This part of the code callibrates our fit to the data. The idea is that
		% the value of the signal should be zero at 11000 A and 7500 A. We multiply
		% our fit by a linear function (called amp) and use that to callibrate our
		% data. We incorporate an averaging feature to avoid peak and dip features.

        % These are the average values, not arrays.
		 average1 = (signal(calibrationPoint1-2,2) + signal(calibrationPoint1-1,2) + signal(calibrationPoint1,2) + signal(calibrationPoint1+1,2) + signal(calibrationPoint1+2,2))/5.0;
		 amplitude1 = average1 / backgroundQuadraticApprox(signal(calibrationPoint1,1));
		 average2 = (signal(calibrationPoint2-2,2) + signal(calibrationPoint2-1,2) + signal(calibrationPoint2,2) + signal(calibrationPoint2+1,2) + signal(calibrationPoint2+2,2))/5.0;
		 amplitude2 = average2 / backgroundQuadraticApprox(signal(calibrationPoint2,1));


		% This is my way to make the filename of the outputfile 'a_corrected.dat',
		% if the original file was 'a.something'

		% ar is a character array, with all the characters of fileName.
        % index_name is an index that keeps track of what character we're
        % on. The for loop keeps scanning the character array, looking for
        % a period. If it finds a period, the conditional is_Period becomes
        % greater than 1 and the loop terminates. All the characters before
        % the period are put into the character array called new. This
        % array is then concatenated with _corrected.dat, and that is our
        % filename.
        
        ar = char(fileName);
		 index_name = 1;
		 is_Period = 0;
		 while is_Period < 1
			 new(index_name) = ar(index_name);
			 index_name = index_name + 1;
			 if (ar(index_name) == '.')
				is_Period = 3;
			 end
		 end

		%Opens a file for writing
		fileHandle = fopen(strcat(new,'_corrected.dat'), 'w');

		% Subtract out the callibration and put it in the file.
		% m is total number of points

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

            bgFitParam1 = 12400.0;
			bgConst = 0.0015873240642803;
			bgLinear = 0.00000025667991263308;
			bgQuadratic = 0.000000000011008884166353;

			r = bgFitParam1/x; % The original formula is in wavelength, and our data is in eV.
			y = bgConst - bgLinear*r +bgQuadratic*r*r;
		end


		% This function calculates the final correction to our data. It's a linear
		% fit of our fit, so to speak. This process skews the fit by multiplying a
		% line to the original background.
		function correction = amp(x)

			correction = (amplitude2 - amplitude1)/(signal(calibrationPoint2,1) - signal(calibrationPoint1,1)) * (x - signal(calibrationPoint1, 1)) + amplitude1;
		end
	end
end
