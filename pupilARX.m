function output = pupilARX(pupilData,inputMatrix,sampleRate,varargin)
% output = pupilARX(pupilData,inputMatrix,sampleRate)
%
% pupilData: vector of pupil signal Nx1
% inputMatrix: matrix of I input signals NxI. If empty, just the AR model
% is run.
% sampleRate in Hz
% optional last arguments:
%   - vector of orders (same convention as the arx function). When absent,
%   the orders are selected so as to maximize the chosen criterion.
%   - string indicating the criterion for order selection (default='aic')
%   - cell array with the range of order to test in the automatic order
%   selection
%
% This function assumes a maximal model order equal to sample Rate.
% If there are more than 2 input signals, the model orders are selected
% separately for the first 2 inputs, then successively for each additional
% input. This prevents combinatorial explosion of the computational cost.
%
% output is a structure containing the fitted model (iddata object), the model predictions
% (horizon 1), the model parameters with their standard deviations, the impulse responses and the
% innovation error (residuals) together with some sanity check on these residuals.
%
% A. Zénon, Decembre 9, 2016

% checks inputs
sPD=size(pupilData);
sIM=size(inputMatrix);
if ~any(sPD==1)
    error('Pupil data should be a vector');
elseif sPD(2)>sPD(1)
    pupilData=pupilData(:);
    sPD=size(pupilData);
end
AR=false;
if all(sIM==0)
    AR=true;
elseif all(sPD(1)~=sIM)
    error('Input matrix should have the same length as the pupil vector');
elseif sPD(1)==sIM(2)
    inputMatrix=inputMatrix';
    sIM=size(inputMatrix);
end
if ~AR
    c=corr(inputMatrix);
    c(eye(size(c))==1)=NaN;
    if any(c>.8)
        warning('Strong correlations between input variables !!');
    end
end
h=adftest(pupilData);
if ~h
    warning('Pupil signal is not stationary !!');
end

METHOD='aic';
propTrain = 0.5;% proportion of data included in training
selectOrder=true;
%default values of range of orders tested in automatic selection procedure
orderRange = {};
minOrder=1;
maxOrder=sampleRate;
maxLatency=sampleRate*2;
minLatency=1;
nVarargin=length(varargin);
if nVarargin==1 | nVarargin==2
    for ii = 1:nVarargin
        if isstr(varargin{ii})
            METHOD=varargin{ii};
        elseif iscell(varargin{ii})
            orderRange = varargin{ii};
            if length(orderRange)>5
                error('Cannot include order range > 5');
            end
        elseif isvector(varargin{ii})
            selectOrder=false;
            nn=varargin{1};
        end
    end
elseif nVarargin>2
    error('Wrong number of arguments');
end
if selectOrder && sIM(2)>5
    error('This script does not support input matrices with more than 4 inputs');
end

%general model parameters
opt = arxOptions('Focus','Simulation','EnforceStability',true);
orderSelectionCrit=METHOD;

%ARX Model
if selectOrder
    %fprintf('Selecting best model order\n');
    if AR
        data=iddata(pupilData,[],1/sampleRate);
        if any(isnan(pupilData))
            data=misdata(data,idpoly);
        end
        
        s=size(data);
        if ~isempty(orderRange)
            V = arxstruc(data(1:floor(s(1)*propTrain)),data(floor(s(1)*propTrain)+1:end),struc(orderRange{1}));
        else
            disp('Using default order range values');
            V = arxstruc(data(1:floor(s(1)*propTrain)),data(floor(s(1)*propTrain)+1:end),struc(minOrder:maxOrder));
        end
        nn = selstruc(nanmean(V,3),orderSelectionCrit);
    else
        if size(inputMatrix,2)==1
            data=iddata(pupilData,inputMatrix,1/sampleRate);
            if any(isnan(pupilData))
                data=misdata(data,idpoly);
            end
            s=size(data);
            if ~isempty(orderRange) && length(orderRange)==3
                V = arxstruc(data(1:floor(s(1)*propTrain)),data(floor(s(1)*propTrain)+1:end),struc(orderRange{1},orderRange{2},orderRange{3}));
            else
                disp('Using default order range values');
                V = arxstruc(data(1:floor(s(1)*propTrain)),data(floor(s(1)*propTrain)+1:end),struc(minOrder:maxOrder,minOrder:maxOrder,minLatency:maxLatency));
            end
            nn = selstruc(nanmean(V,3),orderSelectionCrit);
        elseif size(inputMatrix,2)>=2
            data=iddata(pupilData,inputMatrix(:,1:2),1/sampleRate);
            if any(isnan(pupilData))
                data=misdata(data,idpoly);
            end
            s=size(data);
            if ~isempty(orderRange) && length(orderRange)==5
                V = arxstruc(data(1:floor(s(1)*propTrain)),data(floor(s(1)*propTrain)+1:end),struc(orderRange{1},orderRange{2},orderRange{3},orderRange{4},orderRange{5}));
            else
                disp('Using default order range values');
                V = arxstruc(data(1:floor(s(1)*propTrain)),data(floor(s(1)*propTrain)+1:end),struc(minOrder:maxOrder,minOrder:maxOrder,minOrder:maxOrder,minLatency:maxLatency,minLatency:maxLatency));
            end
            nn = selstruc(nanmean(V,3),orderSelectionCrit);
        end
        if size(inputMatrix,2)>2
            disp('Using default order range values for inputs beyond two');
            data=iddata(pupilData,inputMatrix(:,1:3),1/sampleRate);
            if any(isnan(pupilData))
                data=misdata(data,idpoly);
            end
            s=size(data);
            V = arxstruc(data(1:floor(s(1)*propTrain)),data(floor(s(1)*propTrain)+1:end),struc(nn(1),nn(2),nn(3),minOrder:maxOrder,nn(4),nn(5),minLatency:maxLatency));
            nn = selstruc(nanmean(V,3),orderSelectionCrit);
        end
        if size(inputMatrix,2)>3
            disp('Using default order range values for inputs beyond two');
            data=iddata(pupilData,inputMatrix(:,1:4),1/sampleRate);
            if any(isnan(pupilData))
                data=misdata(data,idpoly);
            end
            s=size(data);
            V = arxstruc(data(1:floor(s(1)*propTrain)),data(floor(s(1)*propTrain)+1:end),struc(nn(1),nn(2),nn(3),nn(4),minOrder:maxOrder,nn(5),nn(6),nn(7),minLatency:maxLatency));
            nn = selstruc(nanmean(V,3),orderSelectionCrit);
        end
        if size(inputMatrix,2)>4
            disp('Using default order range values for inputs beyond two');
            data=iddata(pupilData,inputMatrix(:,1:5),1/sampleRate);
            if any(isnan(pupilData))
                data=misdata(data,idpoly);
            end
            s=size(data);
            V = arxstruc(data(1:floor(s(1)*propTrain)),data(floor(s(1)*propTrain)+1:end),struc(nn(1),nn(2),nn(3),nn(4),nn(5),minOrder:maxOrder,nn(6),nn(7),nn(8),nn(9),minLatency:maxLatency));
            nn = selstruc(nanmean(V,3),orderSelectionCrit);
        end
    end
else
    data=iddata(pupilData,inputMatrix,1/sampleRate);
    if any(isnan(pupilData))
        data=misdata(data,idpoly);
    end
end

%fprintf('Fitting the model\n');
output.ARXorders=nn;
output.model=arx(data,nn,opt);
y=predict(output.model,data,1);
output.predictedData=y.OutputData;
[A1,B1,C,D,F,dA1,dB1,dC,dD,dF] = polydata(output.model);
output.modelParameters.A=A1;
output.modelParameters.Asd=dA1;
output.modelParameters.B=B1;
output.modelParameters.Bsd=dB1;

%checks innovation errors
output.innovationError.data=pupilData-output.predictedData(:);
[h,p] = lbqtest(output.innovationError.data);
output.innovationError.autocorr.LjungBox=p;
[acfARX,lagsARX,bounds] = autocorr(output.innovationError.data);
output.innovationError.autocorr.acf=acfARX;
output.innovationError.autocorr.acfLags=lagsARX;
output.innovationError.autocorr.acfSignificanceThreshold=bounds;
[paracfARX,parlagsARX,bounds] = parcorr(output.innovationError.data(~isnan(output.innovationError.data)));
output.innovationError.autocorr.paracf=paracfARX;
output.innovationError.autocorr.paracfLags=parlagsARX;
output.innovationError.autocorr.paracfSignificanceThreshold=bounds;
[c,p]=corr(output.innovationError.data(~isnan(output.innovationError.data)),...
    [1:sum(~isnan(output.innovationError.data))]','type','Spearman');
output.innovationError.trend.correlationCoeff=c;
output.innovationError.trend.pValue=p;
[h,p] = lillietest(output.innovationError.data);
output.innovationError.LillieforsTest=p;

% computes impulse response
tbins=[0:1/sampleRate:10];
[imp,tbins,innovz,impsd] = impulse(output.model,tbins);
output.impulse=imp;
output.impulseTimeBins=tbins;
output.impulseSD=impsd;