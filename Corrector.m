%Corrector 1.2
%This program will apply all our corrections to the data
%It also converts data into eV and sorts
%It also will keep headers

function Corrector_2 (input)
% Parse input into an array of filenames

numFiles = 0; % number of files to operate on

% Prepares the log file name
Date_String = datestr(now);
date_time = regexprep(regexprep(Date_String, ' ', '-'), ':', '-');
logFileName = strcat('Correction-Log-',date_time,'.txt');
headers = 'eV               \tSignal           \tTemperature      \tPhotometer       \tPhoto Correction \tZero Correction  \n';

% This segment of the code splits up the input into multiple strings

	list_names = textscan(input, '%s');
    list_names = list_names{1};
    numFiles = length(list_names);

% Writes basic information in the Log    
fileHandle = fopen(logFileName, 'w');

fprintf(fileHandle, '%s\n', 'Correction Log');
fprintf(fileHandle, '%s%s\n', 'Date and Time: ', Date_String);
fprintf(fileHandle, '%s%s\n', 'Number of Files: ', num2str(numFiles));
fprintf(fileHandle, '%s%s\n', 'Files: ', input);

% Runs the correction for each name submitted
% file is the name of the current file
% newfile is the name of the corrected file
% fileHandle2 is the handle of each individual file, used to write to it

file = '';
newfile = '';


for i = 1:numFiles
	file = list_names(i);
    % newfile is the name of the corrected file's output
    newfile = regexprep(regexprep(file, '.dat', '_corrected.dat'), '.out_corrected', '_corrected.out');
    [success, data] = parse(char(file));
    fprintf(fileHandle, '%s%s\n', 'File: ', char(file));

    if (success == 0)    
        fprintf(fileHandle, '%s\n', 'Parsing File Failed.');
    else
        data_sort = sort(data);
        data_prime = photometerCorrect(data_sort);
        data_double_prime = negativeCorrect(data_sort);
        total_data = [data_sort data_prime data_double_prime];
        printData(total_data, char(newfile), headers);
        fprintf(fileHandle, '%s%s\n', 'Corrected file printed to: ', char(newfile));
        
    end
end

fclose(fileHandle)

    % The following function attempts to parse the data and collects
    % relevant information about the run.
    function [success, data] = parse(filenamer)
        data = zeros(1);
        success = 0;
        try
        % First, we attempt to parse the data.
        dataStructure = importdata(filenamer);
		is_A_Structure = isstruct(dataStructure);
        
        % If there are headers, dataStructure becomes a structure. If there
        % are none, then it is just the data array we want. is_A_Structure
        % tests this, and extracts the data correctly for each of the two
        % cases.
        
        if(is_A_Structure == 1)
            data = dataStructure.data;
        else
            data = dataStructure;
        end
        success = 1;
        catch exception
        end
    end
    % The following function prints the data, in tab-delimited format
    function printData(g, newfile, headers)
        [m, n] = size(g);

         format = '%.15f';
         for k = 2:n
             format = strcat(format, '\t%.15f');
         end
         format = strcat(format, '\n');
         
		%Opens a file for writing
		fileHandle2 = fopen(newfile, 'w');

        fprintf(fileHandle2, headers);
		for i = 1:m
			% special formatting for the output file
			fprintf(fileHandle2, format, g(i,:));
		end

		% close the file
		fclose(fileHandle2);
    
    end
    % The following function sorts the data
    function sorted = sort(g)
        [m, n] = size(g);
        g_prime = g;
        if (g(1,1) > 5) % if units are in wavelength
        for k = 1:m
            g_prime(k,1) = 12398.4/g_prime(k,1); % convert to eV
        end
        end
        if (n == 3)
            extra = zeros(m,1);
            sorted = [sortrows(g_prime, 1) extra]; % sort according to row 1            
        else
            sorted = sortrows(g_prime, 1); % sort according to row 1            
        end
    end
    % The following function applies the photometer correction    
    function g_prime = photometerCorrect(g)
    [m, n] = size(g);
    g_prime = zeros(m,1);

    if (n >= 4)
    average = mean(g(:,4));
        if (average > 0.05)
            for i = 1:m
                g_prime(i) = g(i,2)/g(i,4);
            end                
        end
            
        if (average < -0.05)
            for i = 1:m
                g_prime(i) = -g(i,2)/g(i,4);
            end                
        end
    end
    
    end
    % The following function applies the negatives correction
    function g_prime = negativeCorrect(g)
    [m, n] = size(g);
    g_prime = zeros(m,1);
    % find the minimum value of the entire signal; if all is > 0, no
    % correction needed
        min_value = 0;
        for i = 1:m
            if g(i,2) < min_value
                min_value = g(i,2);
            end
        end
        
        for i = 1:m
            g_prime(i) = g(i,2) - min_value; 
            % subtracts out the negative value
        end
    end
    % The following function applies the negatives correction
    function g_prime = laserCorrect(g)
    [m, n] = size(g);
        g_prime = g;
    % find the minimum value of the entire signal; if all is > 0, no
    % correction needed
        min_value = 0;
        for i = 1:m
            if g(i,2) < min_value
                min_value = g(i,2);
            end
        end
        
        for i = 1:m
            g_prime(i,2) = g(i,2) - min_value; 
            % subtracts out the negative value
        end
    end
end
