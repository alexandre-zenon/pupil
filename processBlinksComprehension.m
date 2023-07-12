function pupilData = processBlinksComprehension(pupilData,samplingRate,interpolation,plotOption,extraBlinkRemoval)
%% saccades need to be improved!

if nargin<5
    extraBlinkRemoval = true;
end
if nargin<4
    plotOption = false;
end
if nargin <3
    interpolation = 'linear';
end
if nargin ==1
    error('Missing sampling rate argument');
end

switch samplingRate
    case 10
        smoothingParam = 8;
    case 1000
        smoothingParam = 16;
    otherwise
        smoothingParam = 8;
end

sampleIndices=[1:length(pupilData.time)];
bl = double(pupilData.blinks);
sc = double(pupilData.saccades);

pu = pupilData.pupilSize;
eyeX = pupilData.eyeX;
eyeY = pupilData.eyeY;
unprocessedPupil = pu;

data2nan = union(find(pu==0),find(bl==1));
pu(data2nan) = NaN;
eyeX(data2nan) = NaN;
eyeY(data2nan) = NaN;

blinkMinSize = 5;
bl = isnan(pu);

blinkOnsets = find(diff(bl)>0)+1;
blinkOffsets = find(diff(bl)<0)+1;
if bl(1)
    blinkOnsets = [1; blinkOnsets(:)];
end
if bl(end)
    blinkOffsets = [blinkOffsets(:); length(bl)];
end
blinkDurations = blinkOffsets-blinkOnsets;
lostSamples = find(blinkDurations<blinkMinSize);
for bb = 1:length(lostSamples)
    ix = blinkOnsets(lostSamples(bb)):blinkOffsets(lostSamples(bb));
    pu(ix) = interp1(find(~isnan(pu)),pu(~isnan(pu)),ix);%remove isolated nans
    eyeX(ix) = interp1(find(~isnan(eyeX)),eyeX(~isnan(eyeX)),ix);%remove isolated nans
    eyeY(ix) = interp1(find(~isnan(eyeY)),eyeY(~isnan(eyeY)),ix);%remove isolated nans
end
bl=isnan(pu);

blinkOnsets = find(diff(bl)>0)+1;
blinkOffsets = find(diff(bl)<0)+1;
if bl(1)
    blinkOnsets = [1; blinkOnsets(:)];
end
if bl(end)
    blinkOffsets = [blinkOffsets(:); length(bl)];
end

md = bl;

if extraBlinkRemoval
    % takes too large changes in pupil size and travels backward and forward
    % until speed of change reaches zero
    %blinkEdges = setdiff(unique(sort([find(bl(:))-1, find(bl(:))+1])),find(bl));
    xPu = interp1(find(~isnan(pu)),pu(~isnan(pu)),[1:length(pu)],'linear');%temporary interp for derivative
    dPu = diff2pt(samplingRate,xPu(:),smoothingParam);
    %remainingBlinks=intersect(find(dPu<-.1),blinkEdges);%blink onsets
    remainingBlinks = find(diff(isnan(pu))==1);%blink onsets
    remainingBlinks=union(remainingBlinks,find(dPu<prctile(dPu,5)));
    blinkOffsets = find(diff(isnan(pu))==-1);
    blinkOffsets=union(blinkOffsets,find(dPu>prctile(dPu,95)));
    newbl = bl;
    for ii = 1:length(remainingBlinks)
        ix = remainingBlinks(ii);
        newbl(ix) = 1;
        while (dPu(ix)<prctile(dPu,25)) && ix>1
            ix = ix-1;
            newbl(ix) = 1;
        end
        ix = remainingBlinks(ii);
        while all(ix~=blinkOffsets) && ix<length(dPu)
            ix = ix+1;
            newbl(ix) = 1;
        end
    end
    %remainingBlinks=intersect(find(dPu>.1),blinkEdges);
    remainingBlinks = blinkOffsets;%blink offsets
    for ii = 1:length(remainingBlinks)
        ix = remainingBlinks(ii);
        newbl(ix) = 1;
        while (dPu(ix)>prctile(dPu,75)) && ix<length(dPu)
            ix = ix+1;
            newbl(ix) = 1;
        end
    end
    pu(newbl==1) = NaN;
    eyeX(newbl==1) = NaN;
    eyeY(newbl==1) = NaN;
end

%removes extra data before and after blinks, if necessary
if 0% no extra removal implemented for now
    extraMargin = [30 30];
    fd = find(diff(bl)>0)+1;
    nfd = find(diff(bl)<0);
    for bb = 1:length(fd)
        
        x = fd(bb)-extraMargin(1):nfd(bb)+extraMargin(2);
        x(x<1) = [];
        x(x>length(pu)) = [];
        pu(x) = NaN;
    end
end

%removes pieces of data that are too short to be real fixations between
%blinks
if ~all(isnan(pu))
    fd=find(diff((~isnan(pu)))==1);
    nfd=find(diff((~isnan(pu)))==-1);
    if ~isempty(nfd), nfd=nfd(find(nfd>fd(1),1):end);end
    if ~isempty(nfd) && ~isempty(fd)
        fd=fd(1:find(fd<nfd(end),1,'last'));
        pupilTraceDurations=(nfd-fd)*2;%in ms
        nonPupil=find(pupilTraceDurations<samplingRate/2);
        excludePu=false(length(bl),1);
        for ii = 1:length(nonPupil)
            excludePu(fd(nonPupil(ii)):nfd(nonPupil(ii)))=true;
        end
        lastBlinks=find(excludePu);
        bl(lastBlinks)=1;
        pu(lastBlinks)=NaN;
        eyeX(lastBlinks) = NaN;
        eyeY(lastBlinks) = NaN;
    end
    blinkOnsets = find(diff(isnan(pu))>0)+1;
    blinkOffsets = find(diff(isnan(pu))<0);
    if ~isempty(blinkOnsets) && ~isempty(blinkOffsets)
        if (blinkOffsets(1)<blinkOnsets(1)) % data begins with blink
            blinkOffsets(1) = [];
        end
        if blinkOffsets(end)<blinkOnsets(end)
            blinkOffsets = [blinkOffsets(:); length(pu)];
        end
    end
    switch interpolation
        case 'linear'
            pu=interp1(find(~isnan(pu)),pu(~isnan(pu)),[1:length(pu)]);
            eyeX=interp1(find(~isnan(eyeX)),eyeX(~isnan(eyeX)),[1:length(eyeX)]);
            eyeY=interp1(find(~isnan(eyeY)),eyeY(~isnan(eyeY)),[1:length(eyeY)]);
        case 'ARX'
            %TODO
            
        case 'GP'
            warning('This method is very slow and not optimal yet.');
            warning('Not implemented for eye position data.');
            for bb = 1:length(fd)
                x = [fd(bb)-samplingRate:nfd(bb)+samplingRate]';
                x(x<1) = [];
                x(x>length(pu)) = [];
                y = pu(x)';
                gprMdl = fitrgp(x(~isnan(y)),y(~isnan(y)));
                xtest = x;
                ypred = predict(gprMdl,xtest);
                pu(x(isnan(y))) = ypred(isnan(y));
                %                 figure(12);
                %                 plot(x,pu(x));
                %                 hold on
                %                 plot(x,y);
                %                 pause;
                %                 hold off;
            end
        case 'spline'
            warning('Not implemented for eye position data.');
            L = 10;
            for ii = 1:length(blinkOnsets)
                b = max([1 blinkOnsets(ii)-L]);
                c = min([length(pu) blinkOffsets(ii)+L]);
                a = max([1 b-(c-b)]);
                d = min([c+(c-b) length(pu)]);
                z=pu(a:d);
                x=[a:d]';
                ix = [find(x==a) find(x==b) find(x==c) find(x==d)];
                ok=~isnan(z);
                xnok=x(~ok);
                if length(unique([a b c d]))==4
                    i=interp1([a b c d],z(ix),x,'spline');
                    pu(xnok)=i(~ok);
                end
            end
            
    end
end

%% saccades
dx = diff2pt(samplingRate,eyeX(:),2);
dy = diff2pt(samplingRate,eyeY(:),2);
d = sqrt(dx.^2+dy.^2);
dd = diff2pt(samplingRate,d(:),2);
ddd = diff2pt(samplingRate,dd(:),2);
so = find(ddd>prctile(ddd,99.9) | ddd<prctile(ddd,.1));
ds = diff(so);
saccadeOnset = [so(1) so(find(ds>samplingRate/4)+1)'];
saccadeOffset = [so(find(ds>samplingRate/4))' so(end)];
saccades = pu*0;
for ss = 1:length(saccadeOnset)
    saccades(saccadeOnset:saccadeOffset) = 1;
end

pupilData.pupilSize = pu;
pupilData.blinks = bl;
pupilData.saccades = saccades;
pupilData.eyeX = eyeX;
pupilData.eyeY = eyeY;

if plotOption
    figure;
    for bl = 1:length(blinkOnsets)
        x=[blinkOnsets(bl)-samplingRate:blinkOffsets(bl)+samplingRate];
        x(x<=0)=[];
        x(x>length(pu)) = [];
        if ~isempty(x)
            plot(unprocessedPupil(x));
            hold on
            plot(pu(x));
            hold off;
            pause;
        end
    end
end
