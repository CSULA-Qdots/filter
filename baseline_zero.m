function baseline_zero(name)

structure = importdata(name);
global signal;
signal = structure.data;

[m, n] = size(signal);

slope(1,1) = 1;
slope(1,2) = 0;
for i = 2:m
slope(i,1) = i;
slope(i,2) = (signal(i,2) - signal(i-1,2))/(signal(i,1) - signal(i-1,1));
end

flagger(1,1) = 1;
flagger(1,2) = 1;
for j = 2:m-1
flagger(j,1) = j;
flagger(j,2) = 0;

if slope(j,2) * slope(j+1,2) < 0
flagger(j,2) = 1;
end
end
flagger(m,1) = m;
flagger(m,2) = 1;

min = signal(1,2);
index = 1;

for k = 1:m
trial = signal(k,2);
if (trial < min && flagger(k,2) == 1)
    index = k;
    min = signal(k,2);
end
end

flagger(index, 2) = 0;

index
min

index2 = index;

while abs(index2 - index) < 20
flagger(index2,2) = 0;
min2 = 1000;
index2 = 10;

for k = 1:m
trial = signal(k,2);
if (trial < min2 && flagger(k,2) == 1)
    index2 = k;
    min2 = signal(k,2);
end
end
end
index2
min2

for i = 1:m
signal(i,2) = signal(i,2) - min + (-min2 + min)/(signal(index2,1) - signal(index,1))*(signal(i,1) - signal(index,1)); 
end

signal

plot(signal(:,1), signal(:,2))
end
