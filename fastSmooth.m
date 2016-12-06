function smoothedData=fastSmooth(data,smoothWin)

data=data(:);
d=(smoothWin+1)/2;
for ss = 1:d
    z(:,ss) = [data(d-ss+1:end); nan(d-ss,1)];
end
for ss = d+1:smoothWin
    z(:,ss) = [nan(ss-d,1); data(1:end-ss+d)];
end
smoothedData=nanmean(z,2);