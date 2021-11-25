function [trialImpulse,residuals,alignedData] = pupilTrialResponses( data, model, input, method )
% Computes per-trial response from impulse responses and data (from original raw data) and innovation error in model (from
% pupilARX) on the basis of the input vector indexing trial
% onsets.
% data: vector of pupil data (Nx1)
% model: output from pupilARX
% input: vector of features (integers corresponding to feature order in the
% model: e.g. 1 for first feature, 2 for second feature, ...)
% method: different experimental methods. Strong recommendations for
% default (regress)

if nargin<4
    method = 'regress';
end

U = unique(input(input~=0));
LU = length(U);

if isstruct(model)
    I = squeeze(model.impulse);
elseif isvector(model)
    I = model;
    I = repmat(I,1,LU);
elseif ismatrix(model)
    I = model;
end

next=0;
for uu = 1:LU
    tr = find(diff(input)==U(uu));
    tr_end = find(diff(input)==-U(uu));
    for tt = 1:length(tr)
        ev = input*0;
        ev(tr(tt)+1:tr_end(tt)) = 1;
        z = conv(ev,I(:,uu));
        next=next+1;
        x(:,next) = z(1:length(input));
    end
end

switch method
    case 'regress'
        [b,~,R] = regress(data,[ones(size(x,1),1) x]);
        trialImpulse = reshape(b(2:end),(length(b)-1)/LU,LU);
        residuals=event_align(R(:),input,1,[-10 80]);
        alignedData=event_align(data(:),input,1,[-10 80]);
    case 'robust'
        b = robustfit(x,data);
        trialImpulse = reshape(b(2:end),(length(b)-1)/LU,LU);
    case 'mean'
        %I(I<0) = 0;
        %I = I./nansum(I,1);
        b=nansum(x.*data);
        trialImpulse = reshape(b,length(b)/LU,LU);
    case 'normalisedRegress'
        I = I./nansum(I,1);
        b = regress(data,[ones(size(x,1),1) x]);
        trialImpulse = reshape(b(2:end),(length(b)-1)/LU,LU);
end
end

