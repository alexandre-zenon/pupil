function data=downsampleVector(data,originalSR,targetSR,varargin)
n=length(varargin);
if n==1
    varType = varargin{1};
elseif n==0
    varType = 'normal';
else
    error('Invalid number of arguments');
end

SRratio=originalSR/targetSR;
if SRratio ~= round(SRratio)
    error('Original sampling rate should be a multiple of target sampling rate');
end
data=data(:);

if strcmp(varType,'normal') && (all(data(~isnan(data)&(data~=0))==1))
    varType = 'binomial';
end
    
bl=mod(length(data),SRratio);
switch varType
    case 'binomial'
        data=squeeze(nanmax(reshape(data(1:end-bl),SRratio,(length(data)-bl)/SRratio)));
    case 'normal'
        data=squeeze(nanmean(reshape(data(1:end-bl),SRratio,(length(data)-bl)/SRratio)));
    case 'multinomial'
        data=squeeze(nanmedian(reshape(data(1:end-bl),SRratio,(length(data)-bl)/SRratio)));
end
disp(['The last ' num2str(bl) ' elements were lost in the process']);