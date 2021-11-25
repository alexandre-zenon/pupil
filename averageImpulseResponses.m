function [overallMean,overallVariance,overallSE,CI]=averageImpulseResponses(pupilResponses,alpha)
%combines observations/studies in rows
%Based on "Introduction to Meta-Analysis" by Michael Borenstein, Larry Hedges, Hannah Rothstein
%
% Inputs:
%   pupilResponses:
%       - a cell array with 2 cells:
%           - first cell contains a matrix of impulse responses with rows corresponding to
%           observations and columns to time bins
%           - second cell contains a matrix of impulse response SDs with
%           rows corresponding to observations and columns to time bins
%       - a structure coming from the pupilARX function
% Outputs are self-explanatory.
%
% A. Zénon, Decembre 9, 2016

if isstruct(pupilResponses)
    for ii = 1:length(pupilResponses)
        if ~isempty(pupilResponses(ii).impulseTimeBins)
            ok(ii)=true;
            nf(ii)=size(pupilResponses(ii).impulse,3);
            ns(ii,:)=pupilResponses(ii).impulseTimeBins;
        else
            ok(ii)=false;
        end
    end
    NF=unique(nf(ok));
    pupilResponses=pupilResponses(ok);
    ns=ns(ok,:);
    if length(NF)>1
        error('Inconsistant number of factors in inputs');
    end
    cA=corr(ns');
    if mean(cA(:))~=1
        error('Inconsistant time bins in inputs');
    end
    for ff = 1:NF
        means = zeros(length(pupilResponses),size(ns,2));
        variances = zeros(length(pupilResponses),size(ns,2));
        for ii = 1:length(pupilResponses)
            means(ii,:)=pupilResponses(ii).impulse(:,:,ff);
            if ~isempty(pupilResponses(ii).impulseSD)
                variances(ii,:)=pupilResponses(ii).impulseSD(:,:,ff);
            else
                variances(ii,:)=means(ii,:)*NaN;
            end
        end
        pupilCell{1}=means;
        pupilCell{2}=variances;
        [overallMean{ff},overallVariance{ff},overallSE{ff},CI{ff}]=averageImpulseResponses(pupilCell,alpha);
    end
elseif iscell(pupilResponses)
    means=pupilResponses{1};
    variances=pupilResponses{2};
    
    lv=log(variances);
    for ss = 1:size(lv,1)
        flv=find(~isinf(lv(ss,:)));
        lv2(ss,:)=interp1(flv,lv(ss,flv),[1:length(lv)],'linear','extrap');
    end
    variances=exp(lv2);
    W=1./variances;
    W(isinf(W))=NaN;
    Q=nansum((means.^2).*W,1) - (nansum((means).*W,1).^2 ./ nansum(W,1));
    df=size(means,1)-1;
    C=nansum(W,1)-(nansum(W.^2,1)./nansum(W,1));
    
    T2=(Q-df)./C;
    T2(T2<=0)=0;
    
    Wstar=1./(variances+repmat(T2,size(variances,1),1));
    Wstar(isinf(Wstar))=NaN;
    overallMean=nansum(Wstar.*means,1)./nansum(Wstar,1);
    overallVariance=1./nansum(Wstar,1);
    overallSE=sqrt(overallVariance);
    CI(1,:)=overallMean-overallSE*tinv(1-alpha/2,10000);
    CI(2,:)=overallMean+overallSE*tinv(1-alpha/2,10000);
end