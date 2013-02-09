function Aaron_Zero_3 (name)

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

for j = 1:m
if abs(signal(j,1) - 1.653) < min % Use absolute value!
    index = j;
    min = abs(signal(j,1) - 1.653); % Use absolute value!
end
end

% This repeats the same procedure, but for a second callibration point:
% This one is at 1.127 eV, or 11000 A.

min2 = 100;
index2 = 1;

for k = 1:m
if abs(signal(k,1) - 1.127) < min2 % Use absolute value!
    index2 = k;
    min2 = abs(signal(k,1) - 1.127); % Use absolute value!
end
end

% This part of the code callibrates our fit to the data. The idea is that
% the value of the signal should be zero at 11000 A and 7500 A. We multiply
% our fit by a linear function (called amp) and use that to callibrate our
% data. 

 amplitude1 = signal(index,2) / f(signal(index,1));
 amplitude2 = signal(index2,2) / f(signal(index2,1));

 index
 index2
 
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
 
 new
 inder
 filename = strcat(new,'_corrected.dat');
fid = fopen(filename, 'w');

 
for i = 1:m
    g(i,1) = signal(i,1);
    g(i,2) = signal(i,2) - amp(signal(i, 1), amplitude1, amplitude2, signal(index,1), signal(index2,1)) * f(signal(i,1));
    g(i,3) = signal(i,3);

    fprintf(fid, '%.9f\t%.9f\t%.9f\n', g(i,:));
end
fclose(fid);

plot(g(:,1),g(:,2))
    
function y = f(x)
r = 12400.0/x; 
y = 0.0015873240642803 - 0.00000025667991263308*r +0.000000000011008884166353*r*r;
end

function tt = amp(m, y1, y2, x1, x2)
tt = (y1 - y2) / (x1 - x2) * (m - x2) + y2;
end

    
    
end
