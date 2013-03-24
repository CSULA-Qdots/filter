function ipf_3(start, num1, num2)
    input = importdata(start);

	numFiles = length(input)

	for i = 1:numFiles

		name = input{i};
        signal = importdata(name);
        fileHand = fopen('NewStuff.dat', 'at');
            fprintf(fileHand, '%s\n', name);
        % close the file
		fclose(fileHand);
    try
        ipf_2(signal(:,num1), signal(:,num2))
        uiwait
    catch exc
        continue;
    end
    end
function ipf_2(x,y)
% ipf(y), ipf(x,y), or ipf(DataMatrix)   Version 8.1
% Keyboard-operated Interactive Peak Fitter for data in separate x,y
% vectors, or in a single y vector, or in a data matrix with
% x values in column 1 and y values in column 2 (e.g. [x y]).
% This version uses keyboard commands only. Press K key for list.
% See http://terpconnect.umd.edu/~toh/spectrum/CurveFittingC.html
% See http://www.wam.umd.edu/~toh/spectrum/InteractivePeakFitter.htm
% T. C. O'Haver (toh@umd.edu). Version 8.1, April 2012, Added bootstrap
% estimation of standard deviations of peak parameters ('v' and 'n' keys).
%
% Example 1: x=[0:.005:1];y=humps(x).^3;ipf(x,y)
% Example 2: x=[-10:.1:10];y=exp(-(x).^2);ipf(x,y)
% x=[0:.005:1];y=humps(x).^3;ipf(x,y)
% Keyboard Controls:
% Pan signal left and right...Coarse pan: < and >
%                             Fine pan: left and right cursor arrow keys
%                             Nudge: [ ]
% Zoom in and out.............Coarse zoom: / and '
%                             Fine zoom: up and down cursor arrow keys
% Resets pan and zoom.........ESC
% elect # of peaks............Number keys 1-6
% Select peak shape...........g Gaussian
%                             h Equal-width Gaussians
%                             l Lorentzian
%                             ; Equal-width Lorentzians
%                             o Logistic
%                             p Pearson (use a,z keys to adjust shape)
%                             e exponentially-broadened Gaussian
%                             j exponential-broadened equal-width Gaussians
%                                 (a,z keys adjust broadening)
%                             u exponential pUlse: exp(-tau1.*x).*(1-exp(-tau2.*x))
%                             s Sigmoid: 1./(1 + exp((t1 - t)/t2))
% Fit.........................f
% Select autozero mode........t  selects none, linear, or quadratic autozero
% Toggle log y mode OFF/ON....m  Plot linear or log Y axis on lower graph
% 2-point Baseline............b, then click left and right baseline
% Background subtraction......Backspace, then click baseline at multiple points
% Restore original baseline...\  to cancel previous background subtraction
% Cursor start position.......c, then click on each peak position
% Adjust 'extra' up or down...a,z
% Print parameters & results..q
% Print fit results only......r
% Plot signal in figure 2.....y
% Print out model data table..d
% Refine fit..................x
% Print peakfit function......w  with all input arguments
% Compute bootstrap stats.....v  Estimates standard deViations of parameters.
% Fit single bootstrap........n  Extracts and Fits siNgle bootstrap sub-sample
% Prints list of commands.....k
global X Y xo dx NumPeaks NumTrials Shape AA PEAKHEIGHTS xxx
global start extra delta AUTOZERO SavedSignal logplot
%
format short g
format compact
warning off all

% process input arguments
if nargin==1,
    datasize=size(x);
    if isvector(x),
        X=1:length(x); % Use this only to create an x vector if needed
        Y=x;
    else
        if datasize(1)<datasize(2),x=x';end
        X=x(:,1);
        Y=x(:,2);
    end
else
    X=x;
    Y=y;
end
% Adjust X and Y vector shape to 1 x n (rather than n x 1)
X=reshape(X,1,length(X));
Y=reshape(Y,1,length(Y));
% If necessary, flip the data vectors so that X increases
if X(1)>X(length(X)),
    disp('X-axis flipped.')
    X=fliplr(X);
    Y=fliplr(Y);
end

% Set initial values of parameters
NumPeaks=1; % Initial Number of peaks in model
NumTrials=10; % Number of repeat fits when X key is pressed
Shape=1; % Initial Shape of the peaks (1=Gaussian, 2=Lorentzian, etc)
extra=1;
delta=0; % Initial Random change in initial start guesses for each re-fit
xo=length(Y)/2; % Initial Pan setting
dx=length(Y)/4; % Initial Zoom setting
start=length(Y)/2;
PEAKHEIGHTS=zeros(NumPeaks,1);
xxx=zeros(1,100);
AA=zeros(NumPeaks,100);
AUTOZERO=1; % Sets autozero operation. Press T to toggle AUTOZERO off and on.
logplot=0;
SavedSignal=Y;

% Plot the signal and its fitted components and residuals
[xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);

% Attaches KeyPress test function to the figure.
set(gcf,'KeyPressFcn',@ReadKey)
uicontrol('Style','text')
% end of outer function
% ----------------------------SUBFUNCTIONS--------------------------------
function ReadKey(obj,eventdata)
% Interprets key presses from the Figure window.
global X Y xx yy xo dx start FitResults NumPeaks NumTrials Shape residual
global delta AA xxx PEAKHEIGHTS AUTOZERO extra MeanFitError SavedSignal logplot
% When a key is pressed, interprets key and calls corresponding function.
% Note: If you don't like my key assignments, you can change the numbers
% in the case statements here to re-assign that function to any other key.
NumTrialsBoot=1;
key=get(gcf,'CurrentCharacter');
if isscalar(key),
    ly=length(Y);
    switch double(key),
        case 28
            % Pans down when right arrow pressed.
            xo=xo-dx/20;
            if xo<1,xo=1;end
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case 29
            % Pans up when left arrow pressed.
            xo=xo+dx/20;
            if xo>ly,xo=ly;end
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case 91
            % Nudge down 1 point when [ pressed.
            xo=xo-1;
            if xo<1,xo=1;end
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case 93
            % Nudge up 1 point when ] pressed.
            xo=xo+1;
            if xo>ly,xo=ly;end
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case 44
            % Pans down when > key pressed.
            xo=xo-dx;
            if xo<1,xo=1;end
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case 46
            % Pans up when < key pressed.
            xo=xo+dx;
            if xo>ly,xo=ly;end
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case 31
            % Zooms up when up arrow pressed.
            dx=dx+dx/10;
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case 30
            % Zooms down when down arrow pressed.
            dx=dx-dx/10;
            if dx<2,dx=2;end
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case 47
            % Zooms 2% up when / pressed.
            dx=dx+ly/50;
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case 39
            % Zooms 2% down when ' pressed.
            dx=dx-ly/50;
            if dx<2,dx=2;end
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case 109
            % When 'M' is pressed, toggles on/off log plot mode
            if logplot==0,
                logplot=1;
            else
                logplot=0;
            end
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case 27 % When 'ESC' key is pressed, resets pan and zoom
            xo=length(Y)/2; % Initial Pan setting
            dx=length(Y)/4; % Initial Zoom setting
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case 102
            % When 'f' key is pressed, tweaks start values, computes and plots fit.
            startnow=start;
            delta=(max(xx)-min(xx))/100;
            for k=1:2:2*NumPeaks,
                startnow(k)=start(k)+randn*delta;
            end
            [FitResults,MeanFitError]=FitAndPlot(xx,yy,NumPeaks,Shape,delta,startnow,extra);
        case 99
            % When 'c' key is pressed, user clicks graph to enter start positons,
            % then fit is computed and graph re-drawn.
            % Acquire first-guess peak positions from user mouse pointer
            figure(1);subplot(2,1,1);xlabel('Click on the estimated positions of each proposed component peak.')
            [clickX,clickY] = ginput(NumPeaks);
            % Create a "start" vector using these peak positions, with peak
            % widths
            n=max(xx)-min(xx);
            width=n/(5*NumPeaks);
            start=[];
            for k=1:NumPeaks,
                start=[start clickX(k) width];
            end
            [FitResults,MeanFitError]=FitAndPlot(xx,yy,NumPeaks,Shape,delta,start,extra);
        case 98
            % When 'b' key is pressed, user clicks graph before and after peaks
            % to enter background points, then fit is computed and graph re-drawn.
            figure(1);subplot(2,1,1);xlabel('Click on the baseline to the LEFT the peak(s).')
            [X1,Y1] = ginput(1);
            figure(1);subplot(2,1,1);xlabel('Now click on the baseline to the RIGHT the peak(s).')
            [X2,Y2] = ginput(1);
            n=length(xx);
            %  Create "start" for this number of peaks
            yy=yy-((Y2-Y1)/(X2-X1)*(xx-X1)+Y1);
            [FitResults,MeanFitError]=FitAndPlot(xx,yy,NumPeaks,Shape,delta,start,extra);
        case 8
            % When 'Backspace' key is pressed, user clicks the graph
            % along the presumed background points, then the program
            % subtracts the interploated background between the points.
            SavedSignal=Y;
            BaselinePoints=input('Number of baseline points to click): ');
            if isempty(BaselinePoints),BaselinePoints=8;end
            % Acquire background points from user mouse clicks
            subplot(2,1,2)
            title(['Click on ' num2str(BaselinePoints) ' points on the baseline between the peaks.'])
            bX=[];bY=[];
            for g=1:BaselinePoints;
                [clickX,clickY] = ginput(1);
                bX(g)=clickX;
                bY(g)=clickY;
                xlabel(['Baseline point '  num2str(g) ' / ' num2str(BaselinePoints) ])
            end
            yy=Y;
            for k=1:length(bX)-1,
                fp=val2ind(X,bX(k)); % First point in segment
                lp=val2ind(X,bX(k+1));  % Last point in segment
                % Subtract piecewise linear background from Y
                yy(fp:lp)=Y(fp:lp)-((bY(k+1)-bY(k))/(bX(k+1)-bX(k))*(X(fp:lp)-bX(k))+bY(k));
            end
            Y=yy;
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case 92
            % When '\' key is pressed, restoreed original signal
            Y=SavedSignal;
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case {49,50,51,52,53,54}
            % When a number key is pressed, sets the number of peaks to that number.
            n=key-48;
            ShapeString='';
            if round(n)~=NumPeaks,
                NumPeaks=round(n);
                switch Shape
                    case 1
                        ShapeString='Gaussian';
                    case 2
                        ShapeString='Lorentzian';
                    case 3
                        ShapeString='logistic';
                    case 4
                        ShapeString='Pearson7';
                    case 5
                        ShapeString='ExpGaussian';
                    case 6
                        ShapeString='Equal width Gaussians';
                    case 7
                        ShapeString='Equal width Lorentzians';
                    case 8
                        ShapeString='Equal-width ExpGauss.';
                    case 9
                        ShapeString='Exponental pulse';
                    case 10
                        ShapeString='Sigmoid';
                    otherwise
                        ShapeString='';
                end % switch
                subplot(2,1,2)
                xlabel(['Number of peaks = ' num2str(NumPeaks) '    Shape = ' ShapeString  ] )
            end % if
            n=max(xx)-min(xx);
            % Create a start value for this number of peaks
            start=[];
            startpos=[n/(NumPeaks+1):n/(NumPeaks+1):n-(n/(NumPeaks+1))]+min(xx);
            for marker=1:NumPeaks,
                markx=startpos(marker);
                start=[start markx n/(5*NumPeaks)];
            end
            PEAKHEIGHTS=zeros(NumPeaks,1);
            AA=zeros(NumPeaks,100);
            RedrawSignal(X,Y,xo,dx,NumPeaks);
            xlabel(['Number of peaks = ' num2str(NumPeaks) '    Shape = ' ShapeString  ] )
        case {103,108,111,112,101,104,59,106,117,115}
            % Selects peak shape when G,L,O,P,E,H,:,J,U,or S key is pressed
            switch key
                case 103 % When 'g' key is pressed, peak shape is set to Gaussian.
                    n=1;
                case 108 % When 'l' key is pressed, peak shape is set to Lorentzian.
                    n=2;
                case 111 % When 'o' key is pressed, peak shape is set to Logistic.
                    n=3;
                case 112 % When 'p' key is pressed, peak shape is set to Pearson.
                    n=4;
                case 101 % When 'e' key is pressed, peak shape is set to exponentally-broadened gaussian.
                    n=5;
                case 104 % When 'h' key is pressed, peak shape is set to equal width gaussians.
                    n=6;
                case 59 % When ';' key is pressed, peak shape is set to equal width gaussians.
                    n=7;
                case 106 % When 'J' key is pressed, peak shape is set to exponentally-broadened equal width gaussians.
                    n=8;
                case 117 % When 'U' key is pressed, peak shape is set to exponental pulse.
                    n=9;
                case 115 % When 'S' key is pressed, peak shape is set to Sigmoid.
                    n=10;
                otherwise
            end % switch
            if round(n)~=Shape,
                Shape=round(n);
                switch Shape
                    case 1
                        ShapeString='Gaussian';
                    case 2
                        ShapeString='Lorentzian';
                    case 3
                        ShapeString='logistic';
                    case 4
                        ShapeString='Pearson';
                    case 5
                        ShapeString='ExpGaussian';
                    case 6
                        ShapeString='Equal-width Gaus.';
                    case 7
                        ShapeString='Equal-width Lor.';
                    case 8
                        ShapeString='Equal-width ExpGauss.';
                    case 9
                        ShapeString='Exponental pulse';
                    case 10
                        ShapeString='Sigmoid';
                    otherwise
                end % switch
                figure(1);subplot(2,1,2)
                xlabel(['Number of peaks = ' num2str(NumPeaks) '    Shape = ' ShapeString  ] )
            end % if
        case 61        
        fileHandler = fopen('NewStuff.dat', 'at');
        GiveMe = FitResults(:,1:5);
        [m n] = size(GiveMe);
		for i = 1:m
            fprintf(fileHandler, '%.9f\t%.9f\t%.9f\t%.9f\t%.9f\n', GiveMe(i,:));
        end
		% close the file
		fclose(fileHandler);

        case 97
            % When 'a' key is pressed, increases "extra" by 5%
            extra=extra+.05*extra;
            if extra==0, extra=.01;end
            if Shape==4||5, % Only do a re-fit if Pearson or ExpGaussian shape
                [FitResults,MeanFitError]=FitAndPlot(xx,yy,NumPeaks,Shape,delta,start,extra);
            else
                [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
            end
        case 122
            % When 'z' key is pressed, decreases "extra" by 5%
            extra=extra-.05*extra;
            if extra==0, extra=.01;end
            if Shape==4||5, % Only do a re-fit if Pearson or ExpGaussian shape
                [FitResults,MeanFitError]=FitAndPlot(xx,yy,NumPeaks,Shape,delta,start,extra);
            else
                [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
            end
        case 114
            % When 'r' key is pressed, prints out table of fit results
            disp(['Fitting Error = ' num2str(MeanFitError) '%'])
            if Shape==9||Shape==10,
                disp('         Peak#     Tau1         Height       Tau2          Area');
            else
                disp('         Peak#   Position       Height       Width         Area');
            end
            disp(FitResults)
        case 100
            % When 'd' key is pressed, prints out table of model peak data
            % disp('     x          y')
            switch NumPeaks,
                case 1
                    disp('     x           peak 1')
                    disp([xxx' PEAKHEIGHTS(1)*AA(1,:)' ])
                case 2
                    disp('     x           peak 1        peak 2')
                    disp([xxx' PEAKHEIGHTS(1)*AA(1,:)' PEAKHEIGHTS(2)*AA(2,:)'])
                case 3
                    disp('     x           peak 1        peak 2       peak 3')
                    disp([xxx' PEAKHEIGHTS(1)*AA(1,:)' PEAKHEIGHTS(2)*AA(2,:)' PEAKHEIGHTS(3)*AA(3,:)'])
                case 4
                    disp('     x           peak 1        peak 2       peak 3       peak 4')
                    disp([xxx' PEAKHEIGHTS(1)*AA(1,:)' PEAKHEIGHTS(2)*AA(2,:)' PEAKHEIGHTS(3)*AA(3,:)'  PEAKHEIGHTS(4)*AA(4,:)'])
                case 5
                    disp('     x           peak 1        peak 2       peak 3       peak 4       peak 5')
                    disp([xxx' PEAKHEIGHTS(1)*AA(1,:)' PEAKHEIGHTS(2)*AA(2,:)' PEAKHEIGHTS(3)*AA(3,:)'  PEAKHEIGHTS(4)*AA(4,:)'  PEAKHEIGHTS(5)*AA(5,:)'])
                case 6
                    disp('     x           peak 1        peak 2       peak 3       peak 4       peak 5       peak 6')
                    disp([xxx' PEAKHEIGHTS(1)*AA(1,:)' PEAKHEIGHTS(2)*AA(2,:)' PEAKHEIGHTS(3)*AA(3,:)'  PEAKHEIGHTS(4)*AA(4,:)'  PEAKHEIGHTS(5)*AA(5,:)'  PEAKHEIGHTS(6)*AA(6,:)'])
            end
        case 61
            PEAKHEIGHTS
        case 116
            % When 't' key is pressed, steps through AUTOZERO modes
            AUTOZERO=AUTOZERO+1;
            if AUTOZERO==3,AUTOZERO=0;end
            [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks);
        case 107
            % When 'k' key is pressed, prints out table of keyboar commands
            disp('KEYBOARD CONTROLS (Version 8):')
            disp(' Pan signal left and right...Coarse: < and >')
            disp('                             Fine: left and right cursor arrow keys')
            disp('                             Nudge: [ ] ')
            disp(' Zoom in and out.............Coarse zoom: / and "  ')
            disp('                             Fine zoom: up and down cursor arrow keys')
            disp(' Resets pan and zoom.........ESC')
            disp(' Select # of peaks...........Number keys 1-6')
            disp(' Select peak shape...........g Gaussian')
            disp('                             h equal-width Gaussians')
            disp('                             e Exponential-broadened Gaussian')
            disp('                             j exponential-broadened equal-width Gaussians')
            disp('                                 (a,z keys adjust broadening)')
            disp('                             l Lorentzian')
            disp('                             ; equal-width Lorentzians')
            disp('                             o LOgistic')
            disp('                             p Pearson (a,z keys adjust shape)')
            disp('                             u exponential pUlse')
            disp('                             s Sigmoid')
            disp(' Fit.........................f')
            disp(' Select autozero mode........t  selects none, linear, or quadratic autozero')
            disp(' Toggle log y mode OFF/ON....m  Plot linear or log Y axis on lower graph')
            disp(' 2-point Baseline............b, then click left and right baseline')
            disp(' Background subtraction......Backspace, then click baseline at multiple points')
            disp(' Restore original baseline...\  to cancel previous background subtraction')
            disp(' Cursor start positions......c, then click on each peak position')
            disp(' Adjust "extra" up or down...a,z (exponentually broadened and Pearson shapes only')
            disp(' Print parameters & results..q')
            disp(' Print fit results only......r')
            disp(' Compute bootstrap stats.....v  Estimates standard deViations of parameters.')
            disp(' Fit single bootstrap........n  Extracts and Fits siNgle bootstrap sub-sample.')
            disp(' Plot signal in figure 2.....y')
            disp(' Print model data table......d')
            disp(' Refine fit..................x Takes best of 10 trial fits')
            disp(' Print peakfit function......w  Print peakfit function with all input arguments')
        case 120 % When 'x' key is pressed, calls peakfit to take best of 'NumTrials' trial fits
            center=(max(xx)+min(xx))/2;
            window=max(xx)-min(xx);
            disp(['Best of ' num2str(NumTrials) ' trial fits.' ])
            [FitResults,MeanFitError]=peakfit([X',Y'],center,window,NumPeaks,Shape,extra,NumTrials,start);
            disp(['Percent Fitting Error ' num2str(MeanFitError) '%'])
            disp('          Peak#     Position     Height      Width         Area  ')
            disp(FitResults(:,1:5))
            figure(1)
        case 119
            % When 'W' is pressed, prints out peakfit functions with arguments in command window
            center=(max(xx)+min(xx))/2;
            window=max(xx)-min(xx);
            FirstGuess=[];
            for peaknumber=1:NumPeaks,
                FirstGuess=[FirstGuess FitResults(peaknumber,2) FitResults(peaknumber,4)];
            end
            disp(['[FitResults,MeanFitError]=peakfit(datamatrix,' num2str(center) ',' num2str(window) ',' num2str(NumPeaks) ',' num2str(Shape) ',' num2str(extra) ',1,[' num2str(FirstGuess) '], ' num2str(AUTOZERO) ' ) ']);
        case 113
            % When 'q' key is pressed, prints out fitting parameters
            switch Shape
                case 1
                    ShapeString='Gaussian';
                case 2
                    ShapeString='Lorentzian';
                case 3
                    ShapeString='Logistic';
                case 4
                    ShapeString='Pearson';
                case 5
                    ShapeString='Exponentially-broadened Gaussian';
                case 6
                    ShapeString='Equal width Gaussians';
                case 7
                    ShapeString='Equal width Lorentzians';
                case 8
                    ShapeString='Equal-width ExpGauss.';
                case 9
                    ShapeString='Exponental pulse';
                case 10
                    ShapeString='Sigmoid';
                otherwise
            end % switch
            disp('------------------------------------------------------------------')
            disp(['Peak Shape = ' ShapeString])
            switch AUTOZERO,
                case 0
                    disp('Autozero OFF')
                case 1
                    disp('Linear autozero')
                case 2
                    disp('Quadratic autozero')
            end
            disp(['Number of peaks = ' num2str(NumPeaks)])
            if Shape==4||Shape==5||Shape==8, disp(['Extra = ' num2str(extra)]), end
            disp(['Fitted x range = ' num2str(min(xx)) ' - ' num2str(max(xx)) ' (dx=' num2str(max(xx)-min(xx)) ')  (Center=' num2str((max(xx)+min(xx))/2) ')  ' ])
            disp(['Percent Fitting Error = ' num2str(MeanFitError) '%' ])
            if Shape==9||Shape==10,
                disp('         Peak#     Tau1         Height       Tau2          Area');
            else
                disp('         Peak#   Position       Height       Width         Area');
            end
            disp(FitResults)
        case 121    % When 'Y' key is pressed (Added on version 5)
            figure(2) % Plot the entire signal cleanly in Figure window 2
            plot(X,Y)
            axis([X(1) X(length(X)) min(residual) max(Y)]);
            hold on
            for m=1:NumPeaks,
                % Add the individual component peaks in green lines
                plot(xxx,PEAKHEIGHTS(m)*AA(m,:),'g')
            end
            % Show residual in red
            plot(xx,residual,'r')
            hold off
            title('Blue=Original Data; Green=Computed Fit; Red=Residual (Fit-Data)')
            % figure(1)
        case 118 % When 'v' key is pressed (Added on version 8)
            NumTrialsBoot=input('Number of fit trials per bootstrap sample: ');
            if isempty(NumTrialsBoot),NumTrialsBoot=1;end
            if NumTrialsBoot,
                disp('Computing bootstrap sampling statistics....May take several minutes.')
                tic;
                BootstrapResultsMatrix=zeros(5,100,NumPeaks);
                BootstrapErrorMatrix=zeros(1,100,NumPeaks);
                center=(max(xx)+min(xx))/2;
                window=max(xx)-min(xx);
                clear bx by
                cutoff=0.5;
                for trial=1:100,
                    n=1;
                    bx=X';
                    by=Y';
                    while n<length(X)-1,
                        if rand>cutoff,
                            bx(n)=X(n+1);
                            by(n)=Y(n+1);
                        end
                        n=n+1;
                    end
                    [FitResults,MeanFitError]=peakfit([bx,by],center,window,NumPeaks,Shape,extra,NumTrialsBoot,start);
                    for peak=1:NumPeaks,
                        BootstrapResultsMatrix(:,trial,peak)=FitResults(peak,:);
                        % size(MeanFitError)
                        BootstrapErrorMatrix(:,trial,peak)=MeanFitError;
                    end
                end
                for peak=1:NumPeaks,
                    disp(' ')
                    disp(['Peak #',num2str(peak) '         Position   Height      Width      Area']);
                    BootstrapMean=mean(real(BootstrapResultsMatrix(:,:,peak)'));
                    BootstrapSTD=sqrt(2)*std(BootstrapResultsMatrix(:,:,peak)');
                    PercentRSD=100.*BootstrapSTD./BootstrapMean;
                    MaxError=max(real(BootstrapErrorMatrix(:,:,peak)'));
                    MinError=min(real(BootstrapErrorMatrix(:,:,peak)'));
                    disp(['Bootstrap Mean: ', num2str(BootstrapMean(2:5))])
                    disp(['Bootstrap STD:  ', num2str(BootstrapSTD(2:5))])
                    disp(['Percent RSD:    ', num2str(PercentRSD(2:5))])
                end
                toc;
                disp(['Min/Max Fitting Error of the 100 bootstrap samples: ', num2str(MaxError) '/' num2str(MinError) ])
                disp('-------------------------------------------------------------------')
            end
            figure(1)
            title('ipf 8.1  Typical Bootstrap sample fit')
        case 110 % When 'n' key is pressed (Added on version 8)
            disp('Fit to single bootstrap sample')
            tic;
            center=(max(xx)+min(xx))/2;
            window=max(xx)-min(xx);
            clear bx by
            cutoff=0.5;
            n=1;
            bx=X';
            by=Y';
            while n<length(X)-1,
                if rand>cutoff,
                    bx(n)=X(n+1);
                    by(n)=Y(n+1);
                end
                n=n+1;
            end
            [FitResults,MeanFitError]=peakfit([bx,by],center,window,NumPeaks,Shape,extra,NumTrialsBoot,start);
            disp(['Fitting Error = ' num2str(MeanFitError) '%'])
            if Shape==9||Shape==10,
                disp('         Peak#     Tau1         Height       Tau2          Area');
            else
                disp('         Peak#   Position       Height       Width         Area');
            end
            disp(FitResults)
            figure(1)
            title('ipf 8.1  Single Bootstrap sample fit')
        otherwise
            UnassignedKey=double(key)
            disp('Press k to print out list of keyboard commands')
    end % switch
end % if
% ----------------------------------------------------------------------
function [xx,yy,start]=RedrawSignal(X,Y,xo,dx,NumPeaks)
% Plots the entire signal (X,Y) in the lower half of the plot window and an
% isolated segment (xx,yy) in the upper half, controlled by Pan and Zoom
% keys. Top half of the figure shows original signal
global AUTOZERO AA xxx PEAKHEIGHTS logplot
minX=min(X);maxX=max(X);minY=min(Y);maxY=max(Y);
Startx=round(xo-(dx/2));
Endx=abs(round(xo+(dx/2)-1));
if Endx>length(Y),Endx=length(Y);end
if Startx<1,Startx=1;end
PlotRange=Startx:Endx;
if (Endx-Startx)<2, PlotRange=xo:xo+2;end
xx=X(PlotRange);
yy=Y(PlotRange);
X1=min(xx);
X2=max(xx);
Y1=min(Y);
Y2=max(Y);

% Remove linear baseline from data segment if AUTOZERO==1
X1=min(xx);
X2=max(xx);
bkgsize=round(length(xx)/5);
if bkgsize<2,bkgsize=2;end
if AUTOZERO==1, % linear autozero operation
    Y1=mean(yy(1:bkgsize));
    Y2=mean(yy((length(xx)-bkgsize):length(xx)));
    yy=yy-((Y2-Y1)/(X2-X1)*(xx-X1)+Y1);
end % if

lxx=length(xx);
bkgsize=5;
if AUTOZERO==2, % Quadratic autozero operation
    XX1=xx(1:round(lxx/bkgsize));
    XX2=xx((lxx-round(lxx/bkgsize)):lxx);
    Y1=yy(1:round(length(xx)/bkgsize));
    Y2=yy((lxx-round(lxx/bkgsize)):lxx);
    bkgcoef=polyfit([XX1,XX2],[Y1,Y2],2);  % Fit parabola to sub-group of points
    bkg=polyval(bkgcoef,xx);
    yy=yy-bkg;
end % if autozero
hold off
clf
figure(1);subplot(2,1,1); % Select upper window
plot(xx,yy,'b.'); % Plot the original signal in blue in upper window
xlabel('Line up the estimated peak positions roughly with the vertical lines')
lyy=min(yy);
uyy=max(yy)+(max(yy)-min(yy))/10;
switch AUTOZERO,
    case 0
        title('ipf 8.1 Autozero OFF. Pan and Zoom to isolate peaks to be fit in upper window.')
        if lyy<uyy;axis([X(Startx) X(Endx) lyy uyy ]);end
    case 1
        title('ipf 8.1 Linear autozero. Pan and Zoom to isolate peaks to be fit in upper window.')
        if lyy<uyy;axis([X(Startx) X(Endx) lyy uyy ]);end
    case 2
        title('ipf 8.1 Quadratic autozero. Pan and Zoom to isolate peaks to be fit in upper window.')
        if lyy<uyy;axis([X(Startx) X(Endx) lyy uyy ]);end
end
hold on
% Mark starting peak positions with vertical dashed lines in upper window
% Determine locations for peak (vertical line) markers
n=X2-X1;
width=n/(5*NumPeaks);
start=[];
startpos=[n/(NumPeaks+1):n/(NumPeaks+1):n-(n/(NumPeaks+1))]+X1;
for marker=1:NumPeaks,
    markx=startpos(marker);
    start=[start markx width];
    plot([markx markx],[lyy uyy],'m--')
end % for marker
hold off
%
% Bottom half of the figure shows full signal in either linear or log mode
% as set by the M key.
subplot(2,1,2);cla
if logplot,
    semilogy(X,abs(Y))  % Graph the signal with linear Y axis
    ylabel('Log y mode')
    axis([X(1) X(length(X)) min(abs(Y)) max(Y)]); % Update plot
else
    plot(X,Y)  % Graph the signal with linear Y axis
    ylabel('Linear y mode')
    axis([X(1) X(length(X)) min(Y) max(Y)]); % Update plot
end
title('# peaks 1-6  Shapes: G H E J L ; O P U S  Fit=F  T=autozero  M=linear/log')
hold on
for marker=1:NumPeaks,
    markx=startpos(marker);
    plot([markx markx],[minY maxY],'m--')
end % for marker
% Added on version 5
for m=1:NumPeaks,
    % [size(xxx), size(PEAKHEIGHTS(m)), size(AA(m,:))] remove this line
    plot(xxx,PEAKHEIGHTS(m)*AA(m,:),'g')  % Plot the individual component peaks in green lines
end
% Mark the limits of the upper windows on the lower whole-signal plot
plot([X1 X1],[minY maxY],'g--')
plot([X2 X2],[minY maxY],'g--')
hold off
xlabel(['Press K to print out all keyboard commands'])
% ----------------------------------------------------------------------
function [FitResults,MeanFitError]=FitAndPlot(xx,yy,NumPeaks,Shape,delta,start,extra)
% Given isolated segment of signal (xx,yy), plots it in upper half, computes fit with
% "NumPeaks" component peaks of shape "Shape", starting with start values
% "start", then plots residuals in lower half.
%  T. C. O'Haver (toh@umd.edu),  Version 2.2,  October, 2011.
global PEAKHEIGHTS AUTOZERO AA xxx residual
PEAKHEIGHTS=zeros(1,NumPeaks);
n=length(xx);
x0=min(xx);
% Perform peak fitting for selected peak shape using fminsearch function
options = optimset('TolX',.00001,'Display','off' );
switch Shape
    case 1
        FitParameters=fminsearch(@fitgaussian,start,options,xx,yy);
        ShapeString='Gaussian';
    case 2
        FitParameters=fminsearch(@fitlorentzian,start,options,xx,yy);
        ShapeString='Lorentzian';
    case 3
        FitParameters=fminsearch(@fitlogistic,start,options,xx,yy);
        ShapeString='Logistic';
    case 4
        FitParameters=fminsearch(@fitpearson,start,options,xx,yy,extra);
        ShapeString='Pearson';
    case 5
        FitParameters=fminsearch(@fitexpgaussian,start,options,xx,yy,-extra);
        ShapeString='ExpGaussian';
    case 6
        cwnewstart(1)=start(1);
        for pc=2:NumPeaks,
            cwnewstart(pc)=start(2.*pc-1);
        end
        cwnewstart(NumPeaks+1)=(max(xx)-min(xx))/5;
        FitParameters=fminsearch(@fitewgaussian,cwnewstart,options,xx,yy);
        ShapeString='Equal width Gauss.';
    case 7
        cwnewstart(1)=start(1);
        for pc=2:NumPeaks,
            cwnewstart(pc)=start(2.*pc-1);
        end
        cwnewstart(NumPeaks+1)=(max(xx)-min(xx))/5;
        FitParameters=fminsearch(@fitewlorentzian,cwnewstart,options,xx,yy);
        ShapeString='Equal width Lor.';
    case 8
        cwnewstart(1)=start(1);
        for pc=2:NumPeaks,
            cwnewstart(pc)=start(2.*pc-1);
        end
        cwnewstart(NumPeaks+1)=(max(xx)-min(xx))/5;
        FitParameters=fminsearch(@fitexpewgaussian,cwnewstart,options,xx,yy,-extra);
        ShapeString='Exp. equal width Gaussians';
    case 9
        FitParameters=fminsearch(@fitexppulse,start,options,xx,yy);
        ShapeString='Exponential Pulse';
    case 10
        FitParameters=fminsearch(@fitsigmoid,start,options,xx,yy);
        ShapeString='Sigmoid';
    otherwise
end % switch

% Construct model from fitted parameters
A=zeros(NumPeaks,n);
AA=zeros(NumPeaks,100);
xxx=linspace(min(xx),max(xx));
for m=1:NumPeaks,
    switch Shape
        case 1
            A(m,:)=gaussian(xx,FitParameters(2*m-1),FitParameters(2*m));
            AA(m,:)=gaussian(xxx,FitParameters(2*m-1),FitParameters(2*m));
        case 2
            A(m,:)=lorentzian(xx,FitParameters(2*m-1),FitParameters(2*m));
            AA(m,:)=lorentzian(xxx,FitParameters(2*m-1),FitParameters(2*m));
        case 3
            A(m,:)=logistic(xx,FitParameters(2*m-1),FitParameters(2*m));
            AA(m,:)=logistic(xxx,FitParameters(2*m-1),FitParameters(2*m));
        case 4
            A(m,:)=pearson(xx,FitParameters(2*m-1),FitParameters(2*m),extra);
            AA(m,:)=pearson(xxx,FitParameters(2*m-1),FitParameters(2*m),extra);
        case 5
            A(m,:)=expgaussian(xx,FitParameters(2*m-1),FitParameters(2*m),-extra)';
            AA(m,:)=expgaussian(xxx,FitParameters(2*m-1),FitParameters(2*m),-extra*length(xxx)./length(xx))';
        case 6
            A(m,:)=gaussian(xx,FitParameters(m),FitParameters(NumPeaks+1));
            AA(m,:)=gaussian(xxx,FitParameters(m),FitParameters(NumPeaks+1));
        case 7
            A(m,:)=lorentzian(xx,FitParameters(m),FitParameters(NumPeaks+1));
            AA(m,:)=lorentzian(xxx,FitParameters(m),FitParameters(NumPeaks+1));
        case 8
            A(m,:)=expgaussian(xx,FitParameters(m),FitParameters(NumPeaks+1),-extra);
            AA(m,:)=expgaussian(xxx,FitParameters(m),FitParameters(NumPeaks+1),-extra*length(xxx)./length(xx)');
        case 9
            A(m,:)=exppulse(xx,FitParameters(2*m-1),FitParameters(2*m));
            AA(m,:)=exppulse(xxx,FitParameters(2*m-1),FitParameters(2*m));
        case 10
            A(m,:)=sigmoid(xx,FitParameters(2*m-1),FitParameters(2*m));
            AA(m,:)=sigmoid(xxx,FitParameters(2*m-1),FitParameters(2*m));
        otherwise
    end % switch
end % for
model=PEAKHEIGHTS'*A;  % Multiplies each row by the corresponding amplitude and adds them up
mmodel=PEAKHEIGHTS'*AA;
% Top half of the figure shows original signal and the fitted model.
figure(1);subplot(2,1,1);plot(xx,yy,'b.'); % Plot the original signal in blue dots
hold on
for m=1:NumPeaks,
    plot(xxx,PEAKHEIGHTS(m)*AA(m,:),'g')  % Plot the individual component peaks in green lines
    area(m)=trapz(xx,PEAKHEIGHTS(m)*A(m,:)); % Compute the area of each component peak using trapezoidal method
end
% Mark starting peak positions with vertical dashed lines
for marker=1:NumPeaks,
    markx=start((2*marker)-1);
    subplot(2,1,1);plot([markx markx],[0 max(yy)],'m--')
end % for
plot(xxx,mmodel,'r');  % Plot the total model (sum of component peaks) in red lines
hold off;
lyy=min(yy);
uyy=max(yy)+(max(yy)-min(yy))/10;
if AUTOZERO,
    axis([min(xx) max(xx) lyy uyy]);
else
    axis([min(xx) max(xx) 0 uyy]);
end
switch AUTOZERO,
    case 0
        title('ipf 8.1 Autozero OFF. Pan and Zoom to isolate peaks to be fit in upper window.')
    case 1
        title('ipf 8.1 Linear autozero. Pan and Zoom to isolate peaks to be fit in upper window.')
    case 2
        title('ipf 8.1 Quadratic autozero. Pan and Zoom to isolate peaks to be fit in upper window.')
end
xlabel('Vertical dotted lines indicate first guess peak positions. C to customize.');
% Bottom half of the figure shows the residuals and displays RMS error
% between original signal and model
residual=yy-model;
figure(1);subplot(2,1,2);plot(xx,residual,'b.')
MeanFitError=100*norm(residual)./(sqrt(n)*max(yy));
title('Press Q to print report, R for peak table only, X for best of 10 trials')
ylabel('Residuals')
if Shape==4||Shape==5||Shape==8,
    xlabel(['Peaks = ' num2str(NumPeaks) '     Shape = ' ShapeString '     Error = ' num2str(round(100*MeanFitError)/100) '%     Extra = ' num2str(extra) ] )
else
    xlabel(['Peaks = ' num2str(NumPeaks) '     Shape = ' ShapeString '     Error = ' num2str(round(100*MeanFitError)/100) '% ' ] )
end

minres=min(residual);
maxres=max(residual);
if minres<maxres,
    axis([min(xx) max(xx) minres maxres ]);
else
    yysize=size(yy);
    modelsize=size(model);
end

% Put results into a matrix, one row for each peak, showing peak index number,
% position, amplitude, and width.
for m=1:NumPeaks,
    if m==1,
        if Shape==6||Shape==7||Shape==8,
            FitResults=[[round(m) FitParameters(m) PEAKHEIGHTS(m) abs(FitParameters(NumPeaks+1)) area(m)]];
        else
            FitResults=[[round(m) FitParameters(2*m-1) PEAKHEIGHTS(m) abs(FitParameters(2*m)) area(m)]];
        end % if peakshape
    else
        if Shape==6||Shape==7||Shape==8,
            FitResults=[FitResults ; [round(m) FitParameters(m) PEAKHEIGHTS(m) abs(FitParameters(NumPeaks+1)) area(m)]];
        else
            FitResults=[FitResults ; [round(m) FitParameters(2*m-1) PEAKHEIGHTS(m) abs(FitParameters(2*m)) area(m)]];
        end % if peakshape
    end % m==1
end % for m=1:NumPeaks

% Display Fit Results on upper graph
subplot(2,1,1);
startx=min(xx)+(max(xx)-min(xx))./20;
dxx=(max(xx)-min(xx))./10;
dyy=(max(yy)-min(yy))./10;
starty=max(yy)-dyy;
FigureSize=get(gcf,'Position');
if Shape==9||Shape==10,
    text(startx,starty+dyy/2,['Peak #          tau1           Height           tau2             Area'] );
else
    text(startx,starty+dyy/2,['Peak #          Position        Height         Width             Area'] );
end
% Alternative method of printing FitResults using sprintf
for peaknumber=1:NumPeaks,
    for column=1:5,
        itemstring=sprintf('%0.4g',FitResults(peaknumber,column));
        xposition=startx+(1.7.*dxx.*(column-1).*(600./FigureSize(3)));
        yposition=starty-peaknumber.*dyy.*(400./FigureSize(4));
        text(xposition,yposition,itemstring);
    end
end
% Alternative method of printing FitResults using num2str
% text(startx, starty-(NumPeaks./2).*dyy,num2str(FitResults));
% ----------------------------------------------------------------------
function [FitResults,LowestError,BestStart,xi,yi]=peakfit(signal,center,window,NumPeaks,peakshape,extra,NumTrials,start)
% A command-line peak fitting function
%
global AA xxx PEAKHEIGHTS xoffset AUTOZERO residual

format short g
format compact
warning off all

datasize=size(signal);
if datasize(1)<datasize(2),signal=signal';end
datasize=size(signal);
if datasize(2)==1, %  Must be isignal(Y-vector)
    X=1:length(signal); % Create an independent variable vector
    Y=signal;
else
    % Must be isignal(DataMatrix)
    X=signal(:,1); % Split matrix argument
    Y=signal(:,2);
end
X=reshape(X,1,length(X)); % Adjust X and Y vector shape to 1 x n (rather than n x 1)
Y=reshape(Y,1,length(Y));
% If necessary, flip the data vectors so that X increases
if X(1)>X(length(X)),
    disp('X-axis flipped.')
    X=fliplr(X);
    Y=fliplr(Y);
end
% Y=Y-min(Y);  % Remove excess offset from data
% Isolate desired segment from data set for curve fitting
if nargin==1 || nargin==2,center=(max(X)-min(X))/2;window=max(X)-min(X);end
xoffset=center-window/2;
n1=val2ind(X,center-window/2);
n2=val2ind(X,center+window/2);
if window==0,n1=1;n2=length(X);end
xx=X(n1:n2)-xoffset;
yy=Y(n1:n2);
ShapeString='Gaussian';

% Define values of any missing arguments
switch nargin
    case 1
        NumPeaks=1;
        peakshape=1;
        extra=0;
        NumTrials=1;
        xx=X;yy=Y;
        start=calcstart(xx,NumPeaks,xoffset);
    case 2
        NumPeaks=1;
        peakshape=1;
        extra=0;
        NumTrials=1;
        xx=signal;yy=center;
        start=calcstart(xx,NumPeaks,xoffset);
    case 3
        NumPeaks=1;
        peakshape=1;
        extra=0;
        NumTrials=1;
        start=calcstart(xx,NumPeaks,xoffset);
    case 4
        peakshape=1;
        extra=0;
        NumTrials=1;
        start=calcstart(xx,NumPeaks,xoffset);
    case 5
        extra=0;
        NumTrials=1;
        start=calcstart(xx,NumPeaks,xoffset);
    case 6
        NumTrials=1;
        start=calcstart(xx,NumPeaks,xoffset);
    case 7
        start=calcstart(xx,NumPeaks,xoffset);
    otherwise
end % switch nargin

% Remove baseline from data segment
X1=min(xx);X2=max(xx);Y1=min(Y);Y2=max(Y);
if AUTOZERO==1, % linear autozero operation
    Y1=mean(yy(1:length(xx)/20));
    Y2=mean(yy((length(xx)-length(xx)/20):length(xx)));
    yy=yy-((Y2-Y1)/(X2-X1)*(xx-X1)+Y1);
end % if

if AUTOZERO==2, % Quadratic autozero operation
    lxx=length(xx);
    bkgsize=5;
    XX1=xx(1:round(lxx/bkgsize));
    XX2=xx((lxx-round(lxx/bkgsize)):lxx);
    Y1=yy(1:round(length(xx)/bkgsize));
    Y2=yy((lxx-round(lxx/bkgsize)):lxx);
    bkgcoef=polyfit([XX1,XX2],[Y1,Y2],2);  % Fit parabola to sub-group of points
    bkg=polyval(bkgcoef,xx);
    yy=yy-bkg;
end % if autozero

PEAKHEIGHTS=zeros(1,NumPeaks);
n=length(xx);
newstart=start;
switch NumPeaks
    case 1
        newstart(1)=start(1)-xoffset;
    case 2
        newstart(1)=start(1)-xoffset;
        newstart(3)=start(3)-xoffset;
    case 3
        newstart(1)=start(1)-xoffset;
        newstart(3)=start(3)-xoffset;
        newstart(5)=start(5)-xoffset;
    case 4
        newstart(1)=start(1)-xoffset;
        newstart(3)=start(3)-xoffset;
        newstart(5)=start(5)-xoffset;
        newstart(7)=start(7)-xoffset;
    case 5
        newstart(1)=start(1)-xoffset;
        newstart(3)=start(3)-xoffset;
        newstart(5)=start(5)-xoffset;
        newstart(7)=start(7)-xoffset;
        newstart(9)=start(9)-xoffset;
    case 6
        newstart(1)=start(1)-xoffset;
        newstart(3)=start(3)-xoffset;
        newstart(5)=start(5)-xoffset;
        newstart(7)=start(7)-xoffset;
        newstart(9)=start(9)-xoffset;
        newstart(11)=start(11)-xoffset;
    otherwise
end % switch NumPeaks

% Perform peak fitting for selected peak shape using fminsearch function
options = optimset('TolX',.00001,'Display','off' );
LowestError=1000; % or any big number greater than largest error expected
FitParameters=zeros(1,NumPeaks.*2);
BestStart=zeros(1,NumPeaks.*2);
height=zeros(1,NumPeaks);
bestmodel=zeros(size(yy));
for k=1:NumTrials,
    % disp(['Trial number ' num2str(k) ] ) % optionally prints the current trial number as progress indicator
    switch peakshape
        case 1
            TrialParameters=fminsearch(@fitgaussian,newstart,options,xx,yy);
            ShapeString='Gaussian';
        case 2
            TrialParameters=fminsearch(@fitlorentzian,newstart,options,xx,yy);
            ShapeString='Lorentzian';
        case 3
            TrialParameters=fminsearch(@fitlogistic,newstart,options,xx,yy);
            ShapeString='Logistic';
        case 4
            TrialParameters=fminsearch(@fitpearson,newstart,options,xx,yy,extra);
            ShapeString='Pearson';
        case 5
            TrialParameters=fminsearch(@fitexpgaussian,newstart,options,xx,yy,-extra);
            ShapeString='ExpGaussian';
        case 6
            cwnewstart(1)=newstart(1);
            for pc=2:NumPeaks,
                cwnewstart(pc)=newstart(2.*pc-1);
            end
            cwnewstart(NumPeaks+1)=(max(xx)-min(xx))/5;
            TrialParameters=fminsearch(@fitewgaussian,cwnewstart,options,xx,yy);
            ShapeString='Equal width Gaussians';
        case 7
            cwnewstart(1)=newstart(1);
            for pc=2:NumPeaks,
                cwnewstart(pc)=newstart(2.*pc-1);
            end
            cwnewstart(NumPeaks+1)=(max(xx)-min(xx))/5;
            TrialParameters=fminsearch(@fitlorentziancw,cwnewstart,options,xx,yy);
            ShapeString='Equal width Lorentzians';
        case 8
            cwnewstart(1)=newstart(1);
            for pc=2:NumPeaks,
                cwnewstart(pc)=newstart(2.*pc-1);
            end
            cwnewstart(NumPeaks+1)=(max(xx)-min(xx))/5;
            TrialParameters=fminsearch(@fitexpewgaussian,cwnewstart,options,xx,yy,-extra);
            ShapeString='Exp. equal width Gaussians';
        case 9
            TrialParameters=fminsearch(@fitexppulse,newstart,options,xx,yy);
            ShapeString='Exponential Pulse';
        case 10
            TrialParameters=fminsearch(@fitsigmoid,newstart,options,xx,yy);
            ShapeString='Sigmoid';
        otherwise
    end % switch peakshape
    
    % Construct model from Trial parameters
    A=zeros(NumPeaks,n);
    for m=1:NumPeaks,
        switch peakshape
            case 1
                A(m,:)=gaussian(xx,TrialParameters(2*m-1),TrialParameters(2*m));
            case 2
                A(m,:)=lorentzian(xx,TrialParameters(2*m-1),TrialParameters(2*m));
            case 3
                A(m,:)=logistic(xx,TrialParameters(2*m-1),TrialParameters(2*m));
            case 4
                A(m,:)=pearson(xx,TrialParameters(2*m-1),TrialParameters(2*m),extra);
            case 5
                A(m,:)=expgaussian(xx,TrialParameters(2*m-1),TrialParameters(2*m),-extra)';
            case 6
                A(m,:)=gaussian(xx,TrialParameters(m),TrialParameters(NumPeaks+1));
            case 7
                A(m,:)=lorentzian(xx,TrialParameters(m),TrialParameters(NumPeaks+1));
            case 8
                A(m,:)=expgaussian(xx,TrialParameters(m),TrialParameters(NumPeaks+1),-extra)';
            case 9
                A(m,:)=exppulse(xx,TrialParameters(2*m-1),TrialParameters(2*m));
            case 10
                A(m,:)=sigmoid(xx,TrialParameters(2*m-1),TrialParameters(2*m));
            otherwise
        end % switch
        switch NumPeaks % adds random variation to non-linear parameters
            case 1
                newstart=[newstart(1)*(1+randn/50) newstart(2)*(1+randn/10)];
            case 2
                newstart=[newstart(1)*(1+randn/50) newstart(2)*(1+randn/10) newstart(3)*(1+randn/50) newstart(4)*(1+randn/10)];
            case 3
                newstart=[newstart(1)*(1+randn/50) newstart(2)*(1+randn/10) newstart(3)*(1+randn/50) newstart(4)*(1+randn/10) newstart(5)*(1+randn/50) newstart(6)*(1+randn/10)];
            case 4
                newstart=[newstart(1)*(1+randn/50) newstart(2)*(1+randn/10) newstart(3)*(1+randn/50) newstart(4)*(1+randn/10) newstart(5)*(1+randn/50) newstart(6)*(1+randn/10)  newstart(7)*(1+randn/50) newstart(8)*(1+randn/10)];
            case 5
                newstart=[newstart(1)*(1+randn/50) newstart(2)*(1+randn/10) newstart(3)*(1+randn/50) newstart(4)*(1+randn/10) newstart(5)*(1+randn/50) newstart(6)*(1+randn/10)  newstart(7)*(1+randn/50) newstart(8)*(1+randn/10)  newstart(9)*(1+randn/50) newstart(10)*(1+randn/10)];
            otherwise
        end % switch NumPeaks
    end % for
    % Multiplies each row by the corresponding amplitude and adds them up
    model=PEAKHEIGHTS'*A;
    
    % Compare trial model to data segment and compute the fit error
    MeanFitError=100*norm(yy-model)./(sqrt(n)*max(yy));
    % Take only the single fit that has the lowest MeanFitError
    if MeanFitError<LowestError,
        if min(PEAKHEIGHTS)>0,  % Consider only fits with positive peak heights
            LowestError=MeanFitError;  % Assign LowestError to the lowest MeanFitError
            FitParameters=TrialParameters;  % Assign FitParameters to the fit with the lowest MeanFitError
            BestStart=newstart; % Assign BestStart to the start with the lowest MeanFitError
            height=PEAKHEIGHTS; % Assign height to the PEAKHEIGHTS with the lowest MeanFitError
            bestmodel=model; % Assign bestmodel to the model with the lowest MeanFitError
        end % if min(PEAKHEIGHTS)>0
    end % if MeanFitError<LowestError
end % for k (NumTrials)
%
% Construct model from best-fit parameters
AA=zeros(NumPeaks,100);
xxx=linspace(min(xx),max(xx));
for m=1:NumPeaks,
    switch peakshape
        case 1
            AA(m,:)=gaussian(xxx,FitParameters(2*m-1),FitParameters(2*m));
        case 2
            AA(m,:)=lorentzian(xxx,FitParameters(2*m-1),FitParameters(2*m));
        case 3
            AA(m,:)=logistic(xxx,FitParameters(2*m-1),FitParameters(2*m));
        case 4
            AA(m,:)=pearson(xxx,FitParameters(2*m-1),FitParameters(2*m),extra);
        case 5
            AA(m,:)=expgaussian(xxx,FitParameters(2*m-1),FitParameters(2*m),-extra*length(xxx)./length(xx))';
        case 6
            AA(m,:)=gaussian(xxx,FitParameters(m),FitParameters(NumPeaks+1));
        case 7
            AA(m,:)=lorentzian(xxx,FitParameters(m),FitParameters(NumPeaks+1));
        case 8
            AA(m,:)=expgaussian(xxx,FitParameters(m),FitParameters(NumPeaks+1),-extra*length(xxx)./length(xx))';
        case 9
            AA(m,:)=exppulse(xxx,FitParameters(2*m-1),FitParameters(2*m));
        case 10
            AA(m,:)=sigmoid(xxx,FitParameters(2*m-1),FitParameters(2*m));
        otherwise
    end % switch
end % for

% Multiplies each row by the corresponding amplitude and adds them up
heightsize=size(height');
AAsize=size(AA);
if heightsize(2)==AAsize(1),
    mmodel=height'*AA;
else
    mmodel=height*AA;
end
% Top half of the figure shows original signal and the fitted model.
subplot(2,1,1);plot(xx+xoffset,yy,'b.'); % Plot the original signal in blue dots
hold on
for m=1:NumPeaks,
    plot(xxx+xoffset,height(m)*AA(m,:),'g')  % Plot the individual component peaks in green lines
    area(m)=trapz(xxx+xoffset,height(m)*AA(m,:)); % Compute the area of each component peak using trapezoidal method
    yi(m,:)=height(m)*AA(m,:); % (NEW) Place y values of individual model peaks into matrix yi
end
xi=xxx+xoffset; % (NEW) Place the x-values of the individual model peaks into xi

% Mark starting peak positions with vertical dashed lines
for marker=1:NumPeaks,
    markx=BestStart((2*marker)-1);
    subplot(2,1,1);plot([markx+xoffset markx+xoffset],[0 max(yy)],'m--')
end % for
plot(xxx+xoffset,mmodel,'r');  % Plot the total model (sum of component peaks) in red lines
hold off;
axis([min(xx)+xoffset max(xx)+xoffset min(yy) max(yy)]);
switch AUTOZERO,
    case 0
        title('ipf 8.1 Autozero OFF. Best of 10 trial fits.')
    case 1
        title('ipf 8.1 Linear autozero. Best of 10 trial fits.')
    case 2
        title('ipf 8.1 Quadratic autozero. Best of 10 trial fits.')
end
if peakshape==4||peakshape==5||peakshape==8, % Shapes with Extra factor
    xlabel(['Peaks = ' num2str(NumPeaks) '     Shape = ' ShapeString '     Error = ' num2str(round(100*LowestError)/100) '%    Extra = ' num2str(extra) ] )
else
    xlabel(['Peaks = ' num2str(NumPeaks) '     Shape = ' ShapeString '     Error = ' num2str(round(100*LowestError)/100) '%' ] )
end

% Bottom half of the figure shows the residuals and displays RMS error
% between original signal and model
residual=yy-bestmodel;
subplot(2,1,2);plot(xx+xoffset,residual,'b.')
axis([min(xx)+xoffset max(xx)+xoffset min(residual) max(residual)]);
xlabel('Residual Plot')

% Put results into a matrix, one row for each peak, showing peak index number,
% position, amplitude, and width.
for m=1:NumPeaks,
    if m==1,
        if peakshape==6||peakshape==7||peakshape==8, % equal-width peak models
            FitResults=[[round(m) FitParameters(m)+xoffset height(m) abs(FitParameters(NumPeaks+1)) area(m)]];
        else
            FitResults=[[round(m) FitParameters(2*m-1)+xoffset height(m) abs(FitParameters(2*m)) area(m)]];
        end % if peakshape
    else
        if peakshape==6||peakshape==7||peakshape==8, % equal-width peak models
            FitResults=[FitResults ; [round(m) FitParameters(m)+xoffset height(m) abs(FitParameters(NumPeaks+1)) area(m)]];
        else
            FitResults=[FitResults ; [round(m) FitParameters(2*m-1)+xoffset height(m) abs(FitParameters(2*m)) area(m)]];
        end % if peakshape
    end % m==1
end % for m=1:NumPeaks

% Display Fit Results on upper graph
subplot(2,1,1);
startx=min(xx)+xoffset+(max(xx)-min(xx))./20;
dxx=(max(xx)-min(xx))./10;
dyy=(max(yy)-min(yy))./10;
starty=max(yy)-dyy;
FigureSize=get(gcf,'Position');
if peakshape==9||peakshape==10,
    text(startx,starty+dyy/2,['Peak #          tau1           Height           tau2             Area'] );
else
    text(startx,starty+dyy/2,['Peak #          Position        Height         Width             Area'] );
end
% Display FitResults using sprintf
for peaknumber=1:NumPeaks,
    for column=1:5,
        itemstring=sprintf('%0.4g',FitResults(peaknumber,column));
        xposition=startx+(1.7.*dxx.*(column-1).*(600./FigureSize(3)));
        yposition=starty-peaknumber.*dyy.*(400./FigureSize(4));
        text(xposition,yposition,itemstring);
    end
end
% ----------------------------------------------------------------------
function start=calcstart(xx,NumPeaks,xoffset)
n=max(xx)-min(xx);
start=[];
startpos=[n/(NumPeaks+1):n/(NumPeaks+1):n-(n/(NumPeaks+1))]+min(xx);
for marker=1:NumPeaks,
    markx=startpos(marker)+ xoffset;
    start=[start markx n/(5*NumPeaks)];
end % for marker
% ----------------------------------------------------------------------
function [index,closestval]=val2ind(x,val)
% Returns the index and the value of the element of vector x that is closest to val
% If more than one element is equally close, returns vectors of indicies and values
% Tom O'Haver (toh@umd.edu) October 2006
% Examples: If x=[1 2 4 3 5 9 6 4 5 3 1], then val2ind(x,6)=7 and val2ind(x,5.1)=[5 9]
% [indices values]=val2ind(x,3.3) returns indices = [4 10] and values = [3 3]
dif=abs(x-val);
index=find((dif-min(dif))==0);
closestval=x(index);
% ----------------------------------------------------------------------
function err = fitgaussian(lambda,t,y)
% Fitting function for a Gaussian band signal.
global PEAKHEIGHTS
numpeaks=round(length(lambda)/2);
A = zeros(length(t),numpeaks);
for j = 1:numpeaks,
    A(:,j) = gaussian(t,lambda(2*j-1),lambda(2*j))';
end
PEAKHEIGHTS = abs(A\y');
z = A*PEAKHEIGHTS;
err = norm(z-y');
% ----------------------------------------------------------------------
function err = fitewgaussian(lambda,t,y)
% Fitting function for a Gaussian band signal with equal peak widths.
global PEAKHEIGHTS
numpeaks=round(length(lambda)-1);
A = zeros(length(t),numpeaks);
for j = 1:numpeaks,
    A(:,j) = gaussian(t,lambda(j),lambda(numpeaks+1))';
end
PEAKHEIGHTS = abs(A\y');
z = A*PEAKHEIGHTS;
err = norm(z-y');
% ----------------------------------------------------------------------
function err = fitewlorentzian(lambda,t,y)
% Fitting function for a Lorentzian band signal with equal peak widths.
global PEAKHEIGHTS
numpeaks=round(length(lambda)-1);
A = zeros(length(t),numpeaks);
for j = 1:numpeaks,
    A(:,j) = lorentzian(t,lambda(j),lambda(numpeaks+1))';
end
PEAKHEIGHTS = abs(A\y');
z = A*PEAKHEIGHTS;
err = norm(z-y');
% ----------------------------------------------------------------------
function g = gaussian(x,pos,wid)
%  gaussian(X,pos,wid) = gaussian peak centered on pos, half-width=wid
%  X may be scalar, vector, or matrix, pos and wid both scalar
% Examples: gaussian([0 1 2],1,2) gives result [0.5000    1.0000    0.5000]
% plot(gaussian([1:100],50,20)) displays gaussian band centered at 50 with width 20.
g = exp(-((x-pos)./(0.6005615.*wid)) .^2);
% ----------------------------------------------------------------------
function err = fitlorentzian(lambda,t,y)
%	Fitting function for single lorentzian, lambda(1)=position, lambda(2)=width
%	Fitgauss assumes a lorentzian function
global PEAKHEIGHTS
A = zeros(length(t),round(length(lambda)/2));
for j = 1:length(lambda)/2,
    A(:,j) = lorentzian(t,lambda(2*j-1),lambda(2*j))';
end
PEAKHEIGHTS = A\y';
z = A*PEAKHEIGHTS;
err = norm(z-y');
% ----------------------------------------------------------------------
function g = lorentzian(x,position,width)
% lorentzian(x,position,width) Lorentzian function.
% where x may be scalar, vector, or matrix
% position and width scalar
% T. C. O'Haver, 1988
% Example: lorentzian([1 2 3],2,2) gives result [0.5 1 0.5]
g=ones(size(x))./(1+((x-position)./(0.5.*width)).^2);
% ----------------------------------------------------------------------
function err = fitlogistic(lambda,t,y)
%	Fitting function for logistic, lambda(1)=position, lambda(2)=width
%	between the data and the values computed by the current
%	function of lambda.  Fitlogistic assumes a logistic function
%  T. C. O'Haver, May 2006
global PEAKHEIGHTS
A = zeros(length(t),round(length(lambda)/2));
for j = 1:length(lambda)/2,
    A(:,j) = logistic(t,lambda(2*j-1),lambda(2*j))';
end
PEAKHEIGHTS = A\y';
z = A*PEAKHEIGHTS;
err = norm(z-y');
% ----------------------------------------------------------------------
function g = logistic(x,pos,wid)
% logistic function.  pos=position; wid=half-width (both scalar)
% logistic(x,pos,wid), where x may be scalar, vector, or matrix
% pos=position; wid=half-width (both scalar)
% T. C. O'Haver, 1991
n = exp(-((x-pos)/(.477.*wid)) .^2);
g = (2.*n)./(1+n);
% ----------------------------------------------------------------------
function err = fitlognormal(lambda,t,y)
%	Fitting function for lognormal, lambda(1)=position, lambda(2)=width
%	between the data and the values computed by the current
%	function of lambda.  Fitlognormal assumes a lognormal function
%  T. C. O'Haver, May 2006
global PEAKHEIGHTS
A = zeros(length(t),round(length(lambda)/2));
for j = 1:length(lambda)/2,
    A(:,j) = lognormal(t,lambda(2*j-1),lambda(2*j))';
end
PEAKHEIGHTS = A\y';
z = A*PEAKHEIGHTS;
err = norm(z-y');
% ----------------------------------------------------------------------
function g = lognormal(x,pos,wid)
% lognormal function.  pos=position; wid=half-width (both scalar)
% lognormal(x,pos,wid), where x may be scalar, vector, or matrix
% pos=position; wid=half-width (both scalar)
% T. C. O'Haver, 1991
g = exp(-(log(x/pos)/(0.01.*wid)) .^2);
% ----------------------------------------------------------------------
function err = fitpearson(lambda,t,y,shapeconstant)
%   Fitting functions for a Pearson 7 band signal.
% T. C. O'Haver (toh@umd.edu),   Version 1.3, October 23, 2006.
global PEAKHEIGHTS
A = zeros(length(t),round(length(lambda)/2));
for j = 1:length(lambda)/2,
    A(:,j) = pearson(t,lambda(2*j-1),lambda(2*j),shapeconstant)';
end
PEAKHEIGHTS = A\y';
z = A*PEAKHEIGHTS;
err = norm(z-y');
% ----------------------------------------------------------------------
function g = pearson(x,pos,wid,m)
% Pearson VII function.
% g = pearson7(x,pos,wid,m) where x may be scalar, vector, or matrix
% pos=position; wid=half-width (both scalar)
% m=some number
%  T. C. O'Haver, 1990
g=ones(size(x))./(1+((x-pos)./((0.5.^(2/m)).*wid)).^2).^m;
% ----------------------------------------------------------------------
function err = fitexpgaussian(lambda,t,y,timeconstant)
%   Fitting functions for a exponentially-broadened Gaussian band signal.
%  T. C. O'Haver, October 23, 2006.
global PEAKHEIGHTS
A = zeros(length(t),round(length(lambda)/2));
for j = 1:length(lambda)/2,
    A(:,j) = expgaussian(t,lambda(2*j-1),lambda(2*j),timeconstant);
end
PEAKHEIGHTS = A\y';
z = A*PEAKHEIGHTS;
err = norm(z-y');
% ----------------------------------------------------------------------
function err = fitexpewgaussian(lambda,t,y,timeconstant)
% Fitting function for exponentially-broadened Gaussian bands with equal peak widths.
global PEAKHEIGHTS
numpeaks=round(length(lambda)-1);
A = zeros(length(t),numpeaks);
for j = 1:numpeaks,
    A(:,j) = expgaussian(t,lambda(j),lambda(numpeaks+1),timeconstant);
end
PEAKHEIGHTS = abs(A\y');
z = A*PEAKHEIGHTS;
err = norm(z-y');
% ----------------------------------------------------------------------
function g = expgaussian(x,pos,wid,timeconstant)
%  Exponentially-broadened gaussian(x,pos,wid) = gaussian peak centered on pos, half-width=wid
%  x may be scalar, vector, or matrix, pos and wid both scalar
%  T. C. O'Haver, 2006
g = exp(-((x-pos)./(0.6005615.*wid)) .^2);
g = ExpBroaden(g',timeconstant);
% ----------------------------------------------------------------------
function yb = ExpBroaden(y,t)
% ExpBroaden(y,t) convolutes y by an exponential decay of time constant t
% by multiplying Fourier transforms and inverse transforming the result.
fy=fft(y);
a=exp(-[1:length(y)]./t);
fa=fft(a);
fy1=fy.*fa';
yb=real(ifft(fy1))./sum(a);
% ----------------------------------------------------------------------
function err = fitexppulse(tau,x,y)
% Iterative fit of the sum of exponental pulses
% of the form Height.*exp(-tau1.*x).*(1-exp(-tau2.*x)))
global PEAKHEIGHTS
A = zeros(length(x),round(length(tau)/2));
for j = 1:length(tau)/2,
    A(:,j) = exppulse(x,tau(2*j-1),tau(2*j));
end
PEAKHEIGHTS =abs(A\y');
z = A*PEAKHEIGHTS;
err = norm(z-y');
% ----------------------------------------------------------------------
function g = exppulse(x,t1,t2)
% Exponential pulse of the form
% Height.*exp(-tau1.*x).*(1-exp(-tau2.*x)))
e=(x-t1)./t2;
p = 4*exp(-e).*(1-exp(-e));
p=p .* [p>0];
g = p';
% ----------------------------------------------------------------------
function err = fitsigmoid(tau,x,y)
% Fitting function for iterative fit to the sum of
% sigmiods of the form Height./(1 + exp((t1 - t)/t2))
global PEAKHEIGHTS
A = zeros(length(x),round(length(tau)/2));
for j = 1:length(tau)/2,
    A(:,j) = sigmoid(x,tau(2*j-1),tau(2*j));
end
PEAKHEIGHTS = A\y';
z = A*PEAKHEIGHTS;
err = norm(z-y');
% ----------------------------------------------------------------------
function g=sigmoid(x,t1,t2)
g=1./(1 + exp((t1 - x)./t2))';
