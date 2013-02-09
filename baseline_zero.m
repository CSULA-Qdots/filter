function baseline_zero (name)

% Grab the data.
structure = importdata(name);
signal = structure.data; % The .data part of a structure is the numerical part. Headers will be ignored.

% The data, signal, will be an array with 3 columns (wavelength, signal,
% and temperature. m gives the number of points. n is 3.

[m, n] = size(signal);

% This algorithm calculates the point that is closest to the first
% callibration wavelength. min represents the distance to the
% desired value. I just use a minimization loop to find the value that
% gives the lowest min value. The first callibration point is 1.653 eV, or
% 7500 A.

min = 100;
index = 1;

for j = 3:m-3 % I start and end at these points because I want to average nearby points, and I don't want an ArrayOutOfBounds error.
if abs(signal(j,1) - 1.653) < min % Use absolute value!
    index = j;
    min = abs(signal(j,1) - 1.653); % Use absolute value!
end
end

% This repeats the same procedure, but for a second callibration point:
% This one is at 1.127 eV, or 11000 A.

min2 = 100;
index2 = 1;

for k = 3:m-3 % I start and end at these points because I want to average nearby points, and I don't want an ArrayOutOfBounds error.
if abs(signal(k,1) - 1.127) < min2 % Use absolute value!
    index2 = k;
    min2 = abs(signal(k,1) - 1.127); % Use absolute value!
end
end

% This part of the code callibrates our fit to the data. The idea is that
% the value of the signal should be zero at 11000 A and 7500 A. We multiply
% our fit by a linear function (called amp) and use that to callibrate our
% data. In this version, we incorporate an averaging feature, which helps
% to avoid peak and dip features.

 average1 = (signal(index-2,2) + signal(index-1,2) + signal(index,2) + signal(index+1,2) + signal(index+2,2))/5.0;
 amplitude1 = average1 / f(signal(index,1));
 average2 = (signal(index2-2,2) + signal(index2-1,2) + signal(index2,2) + signal(index2+1,2) + signal(index2+2,2))/5.0;
 amplitude2 = average2 / f(signal(index2,1));


% This is my way to make the filename of the outputfile 'a_corrected.dat', 
% if the original file was 'a.something' 
% Don't judge me!

 ar = char(name);
 inder = 1;
 hithere = 0;
 while hithere < 1
 new(inder) = ar(inder);
 inder = inder + 1; 
 if (ar(inder) == '.')
 hithere = 3;
 end
 end
 
 filename = strcat(new,'_corrected.dat');
 fid = fopen(filename, 'w');

% Subtract out the callibration and put it in the file.
 
for i = 1:m
    g(i,1) = signal(i,1);
    g(i,2) = signal(i,2) - amp(signal(i, 1)) * f(signal(i,1));
    g(i,3) = signal(i,3);

    fprintf(fid, '%.9f\t%.9f\t%.9f\n', g(i,:)); % special formatting for the output file
end

fclose(fid); % close the file

% This function is our quadratic fit of the background GaAs wafer.

function y = f(x)
r = 12400.0/x; % The original formula is in wavelength, and our data is in eV.
y = 0.0015873240642803 - 0.00000025667991263308*r +0.000000000011008884166353*r*r;
end 

% This function calculates the final correction to our data. It's a linear
% fit of our fit, so to speak. This process skews the fit by multiplying a
% line to the original background.

function correction = amp(x)
correction = (amplitude2 - amplitude1)/(signal(index2,1) - signal(index,1)) * (x - signal(index, 1)) + amplitude1;
end
end
