function output = pupilARX(pupilData,inputMatrix,sampleRate,varargin)
% output = pupilARX(pupilData,inputMatrix,sampleRate)
%
% pupilData: vector of pupil signal Nx1
% inputMatrix: matrix of I input signals NxI.
% sampleRate in Hz
%
% This function assumes a maximal model order equal to sample Rate.
% If there are more than 2 input signals, the model orders are selected
% separately for the first 2 inputs, then successively for each additional
% input. This prevents combinatorial explosion of the computational cost.
%
% output is a structure containing the fitted model (iddata object), the model predictions
% (horizon 1), the model parameters with their standard deviations, and the
% innovation error (residuals) together with some sanity check on these residuals.
%
% A. Zénon, June 21, 2016


% checks inputs
sPD=size(pupilData);
sIM=size(inputMatrix);
if ~any(sPD==1)
    error('Pupil data should be a vector');
elseif sPD(2)>sPD(1)
    pupilData=pupilData(:);
    sPD=size(pupilData);
end
if all(sPD(1)~=sIM)
    error('Input matrix should have the same length as the pupil vector');
elseif sPD(1)==sIM(2)
    inputMatrix=inputMatrix';
    sIM=size(inputMatrix);
end
if sIM(2)>5
    error('This script does not support input matrices with more than 4 inputs');
end
c=corr(inputMatrix);
c(eye(size(c))==1)=NaN;
if any(c>.8)
    warning('Strong correlations between input variables !!');
end
h=adftest(pupilData);
if ~h
    warning('Pupil signal is not stationary !!');
end

if isempty(varargin)
    selectOrder=true;
elseif length(varargin)==1
    selectOrder=false;
    nn=varargin{1};
else
    error('Wrong number of arguments');
end

%general model parameters
opt = arxOptions('Focus','Stability');
orderSelectionCrit='bic';

%ARX Model
minOrder=2;
maxOrder=sampleRate;
if selectOrder
    fprintf('Selecting best model order\n');
    if size(inputMatrix,2)==1
        data=iddata(pupilData,inputMatrix,1/sampleRate);
        V = arxstruc(data,data,struc(minOrder:maxOrder,minOrder:maxOrder,minOrder:maxOrder));
        nn = selstruc(nanmean(V,3),orderSelectionCrit);
    elseif size(inputMatrix,2)>=2
        data=iddata(pupilData,inputMatrix(:,1:2),1/sampleRate);
        V = arxstruc(data,data,struc(minOrder:maxOrder,minOrder:maxOrder,minOrder:maxOrder,minOrder:maxOrder,minOrder:maxOrder));
        nn = selstruc(nanmean(V,3),orderSelectionCrit);
    end
    if size(inputMatrix,2)>2
        data=iddata(pupilData,inputMatrix(:,1:3),1/sampleRate);
        V = arxstruc(data,data,struc(nn(1),nn(2),nn(3),minOrder:maxOrder,nn(4),nn(5),minOrder:maxOrder));
        nn = selstruc(nanmean(V,3),orderSelectionCrit);
    end
    if size(inputMatrix,2)>3
        data=iddata(pupilData,inputMatrix(:,1:4),1/sampleRate);
        V = arxstruc(data,data,struc(nn(1),nn(2),nn(3),nn(4),minOrder:maxOrder,nn(5),nn(6),nn(7),minOrder:maxOrder));
        nn = selstruc(nanmean(V,3),orderSelectionCrit);
    end
    if size(inputMatrix,2)>4
        data=iddata(pupilData,inputMatrix(:,1:5),1/sampleRate);
        V = arxstruc(data,data,struc(nn(1),nn(2),nn(3),nn(4),nn(5),minOrder:maxOrder,nn(6),nn(7),nn(8),nn(9),minOrder:maxOrder));
        nn = selstruc(nanmean(V,3),orderSelectionCrit);
    end
else
    data=iddata(pupilData,inputMatrix,1/sampleRate);
end

fprintf('Fitting the model\n');
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
[paracfARX,parlagsARX,bounds] = parcorr(output.innovationError.data);
output.innovationError.autocorr.paracf=paracfARX;
output.innovationError.autocorr.paracfLags=parlagsARX;
output.innovationError.autocorr.paracfSignificanceThreshold=bounds;
[c,p]=corr(output.innovationError.data,[1:length(output.innovationError.data)]','type','Spearman');
output.innovationError.trend.correlationCoeff=c;
output.innovationError.trend.pValue=p;
[h,p] = lillietest(output.innovationError.data);
output.innovationError.LillieforsTest=p;