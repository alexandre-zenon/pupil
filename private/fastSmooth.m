function smoothedData=fastSmooth(data,smoothWin)
% Smooths data by taking average in sliding window. Implementation is
% faster than the builtin smooth function but it accepts only odd values as
% window size. 
%
% A. Zénon, Decembre 9, 2016

if (smoothWin/2)=round(smoothWin/2)
    error('Accepts only odd values as window size');
end
data=data(:);
d=(smoothWin+1)/2;
for ss = 1:d
    z(:,ss) = [data(d-ss+1:end); nan(d-ss,1)];
end
for ss = d+1:smoothWin
    z(:,ss) = [nan(ss-d,1); data(1:end-ss+d)];
end
smoothedData=nanmean(z,2);

