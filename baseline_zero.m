function Aaron_Zero_2 (name)
structure = importdata(name);
signal = structure.data;

[m, n] = size(signal);

 min = 100;
 index = 1;

for j = 1:m
if abs(signal(j,1) - 1.653) < min
    index = j;
    min = abs(signal(j,1) - 1.653);
end
end

 min2 = 100;
 index2 = 1;

for k = 1:m
if abs(signal(k,1) - 1.127) < min2
    index2 = k;
    min2 = abs(signal(k,1) - 1.127);
end
end

 amplitude1 = signal(index,2) / f(signal(index,1))
 amplitude2 = signal(index2,2) / f(signal(index2,1))

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
    
    
    
end

function y = f(x)
r = 12400.0/x; 
y = 0.0015873240642803 - 0.00000025667991263308*r +0.000000000011008884166353*r*r;
end

function tt = amp(m, y1, y2, x1, x2)
tt = (y1 - y2) / (x1 - x2) * (m - x2) + y2;
end