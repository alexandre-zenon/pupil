function pupilData = processBlinks(pupilData,samplingRate,interpolation,plotOption,extraBlinkRemoval)

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

if isstruct(pupilData) && isfield(pupilData,'block')
    blockData = pupilData.block; % data coming from loadWithPupil
    noTrials = false;
elseif isstruct(pupilData)
    blockData = pupilData; % data coming directly from read_eyelink
    noTrials = true;
else % just a vector of pupil data
    blockData.pupilSize = pupilData;
    blockData.eyeY = pupilData*0;
    blockData.eyeX = pupilData*0;
    blockData.time = [1:length(pupilData)];
    blockData.saccades = pupilData*NaN;
    blockData.blinks = pupilData<=0;
    noTrials = true;
end

sampleIndices=[1:length(blockData.time)];
bl = double(blockData.blinks);
sc = double(blockData.saccades);

%% takes saccade indices that contain blinks as indices for blinks (SR Research suggestion)
if ~all(sc==0) && ~all(isnan(sc))
    saccOnsets = find(diff(sc)>0)+1;saccOnsets = saccOnsets(:);
    if sc(1)
        saccOnsets = [1; saccOnsets];
    end
    saccOffsets = find(diff(sc)<0);saccOffsets=saccOffsets(:);
    if sc(end)
        saccOffsets = [saccOffsets; length(sc)];
    end
    blinkOnsets = find(diff(bl)>0)+1;
    if bl(1)
        blinkOnsets = [1; blinkOnsets(:)];
    end
    bl2 = bl*0;
    for bb = 1:length(blinkOnsets)
        f = (blinkOnsets(bb)>=saccOnsets) & (blinkOnsets(bb)<=saccOffsets);
        bl2(saccOnsets(f):saccOffsets(f)) = 1;
    end
    bl = bl2;
    clear bl2;
else
    blinkOnsets = find(diff(bl)>0)+1;
    if bl(1)
        blinkOnsets = [1; blinkOnsets(:)];
    end
end

if ~all(bl==1)
    fd=find(diff(bl)==1);
    nfd=find(diff(bl)==-1);
    
    if bl(end)==1
        nfd = [nfd; length(bl)];
    end
    if ~isempty(fd)
        nfd=nfd(find(nfd>fd(1),1):end);
        if ~isempty(nfd)
            fd=fd(1:find(fd<nfd(end),1,'last'));
        else
            fd = [];
        end
    end
    blinkDurations=(nfd-fd)*2;%in ms
    nonBlinks=find(blinkDurations>(samplingRate/2));%500 ms threshold
    excludeBl=bl*false;
    for ii = 1:length(nonBlinks)
        excludeBl(fd(nonBlinks(ii)):nfd(nonBlinks(ii)))=true;
    end
    excludeBl(isnan(excludeBl)) = 0;
    bl(isnan(bl)) = 0;
    excludeBl = excludeBl&bl;
    bl(excludeBl==1)=0;
    longBlinks=union(find(excludeBl),setdiff([sampleIndices(1):sampleIndices(end)],sampleIndices));
else
    blinkDurations=NaN;
    longBlinks=bl;
    bl=bl*NaN;
end

pu = blockData.pupilSize;
eyeX = blockData.eyeX;
eyeY = blockData.eyeY;
unprocessedPupil = pu;
data2nan = union(union(longBlinks,find(pu==0)),find(bl==1));
pu(data2nan) = NaN;
eyeX(data2nan) = NaN;
eyeY(data2nan) = NaN;

if extraBlinkRemoval
    % takes too large changes in pupil size and travels backward and forward
    % until speed of change reaches zero
%     newbl = removeRemainingBlinks(pu,bl,samplingRate,50);
%     pu(newbl==1) = NaN;
%     eyeX(newbl==1) = NaN;
%     eyeY(newbl==1) = NaN;
    
    newbl = removeRemainingBlinks(pu,bl,samplingRate,12);
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
%blinks and interpolates
if ~all(isnan(pu))
    fd=find(diff((~isnan(pu)))==1);
    nfd=find(diff((~isnan(pu)))==-1);
    if isnan(pu(end))
        fd = [fd; length(pu)];
    end
    %if ~isempty(nfd), nfd=nfd(find(nfd>fd(1),1):end);end
    if ~isempty(nfd) && ~isempty(fd)
        nfd=nfd(find(nfd>fd(1),1):end);
    end
    if ~isempty(nfd) && ~isempty(fd)
        fd=fd(1:find(fd<nfd(end),1,'last'));
        pupilTraceDurations=(nfd-fd)*(1000/samplingRate);%in ms
        nonPupil=find(pupilTraceDurations<500);
        excludePu=bl*false;
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
    if isnan(pu(end))
        blinkOffsets = [blinkOffsets; length(pu)];
    end
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

% structures data
bl(longBlinks) = NaN;
md = pu*0;
md(longBlinks) = 1;
if isstruct(pupilData)
    pupilData.block.pupilSize = pu;
    pupilData.block.missingData = md;
    pupilData.block.blinks = bl;
    pupilData.block.blinkRate=60*500*(nansum(diff(bl)==1)/sum(~isnan(bl)));%blinks per minute
    pupilData.block.eyeX = eyeX;
    pupilData.block.eyeY = eyeY;
    
    
    if ~noTrials % only for data coming from read_eyelink
        for tr = 1:length(pupilData.trials)
            ti = pupilData.block.time;
            start = find(ti==pupilData.trials(tr).startTime);
            
            %         if ~isfield(pupilData.trials(tr),'stopTime') || isempty(pupilData.trials(tr).stopTime)
            %             pupilData.trials(tr).stopTime = start + length(pupilData.trials(tr).pupilSize)-1;
            %         end
            if isempty(pupilData.trials(tr).stopTime)
                stop = start + length(pupilData.trials(tr).eyeTime)-1;
            else
                stop = find(ti==pupilData.trials(tr).stopTime);
            end
            
            bltr = bl(start:stop);
            putr = pu(start:stop);
            eyeXtr = eyeX(start:stop);
            eyeYtr = eyeY(start:stop);
            sactr = pupilData.trials(tr).saccades;
            try
                sactr(end+1:length(putr)) = NaN;
            catch
                sactr(end+1:length(putr)) = 0;
            end
            pupilData.trials(tr).blinks = bltr(:);
            pupilData.trials(tr).pupilSize = putr(:);
            pupilData.trials(tr).eyeX = eyeXtr(:);
            pupilData.trials(tr).eyeY = eyeYtr(:);
            pupilData.trials(tr).saccades = sactr(1:length(putr));
            % warning('stempio tweaked here so that length of pupilData.trials(tr).eyeTime was same as corrected pupil size, in order for it to be downsampled later')
            pupilData.trials(tr).eyeTime = pupilData.trials(tr).eyeTime(1:length(putr));
        end
    else
        blockData.pupilSize = pu;
        blockData.blinks = bl;
        pupilData = blockData;
    end
else
    blockData.pupilSize = pu;
    blockData.blinks = bl;
    pupilData = blockData;
end

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
end

function newbl = removeRemainingBlinks(pu,bl,samplingRate,threshON)
scale = ceil(20/(1000/samplingRate));
xPu = interp1(find(~isnan(pu)),zscore(pu(~isnan(pu))),[1:length(pu)],'linear');%temporary interp for derivative
dPu = diff2pt(samplingRate,xPu(:),scale);
aPu = diff2pt(samplingRate,dPu(:),scale);
thresh2 = round(threshON/8);
remainingBlinks=find(diff(dPu<-threshON)==1);
blinkOffsets = find(diff(dPu>threshON)==-1);

newbl = bl;
for ii = 1:length(remainingBlinks)
    ix = remainingBlinks(ii);
    while (dPu(ix)<-thresh2) && ix>1
        ix = ix-1;
        newbl(ix) = true;
    end
    
    ix = remainingBlinks(ii);
    while (dPu(ix)<thresh2*1.1) && ix<length(dPu)
        ix = ix+1;
        newbl(ix) = true;
    end
    
    while (dPu(ix)>thresh2*0.5) && ix<length(dPu)
        ix = ix+1;
        newbl(ix) = true;
    end
    
    %newbl(ix:(ix+scale*10)) = true;
    R = 200;
    if false
        subplot(1,3,1)
        plot(xPu(remainingBlinks(ii)-R:remainingBlinks(ii)+R))
        hold on
        plot(find(newbl(remainingBlinks(ii)-R:remainingBlinks(ii)+R)),xPu(remainingBlinks(ii)-R+find(newbl(remainingBlinks(ii)-R:remainingBlinks(ii)+R))))
        hold off;
        subplot(1,3,2)
        plot(dPu(remainingBlinks(ii)-R:remainingBlinks(ii)+R))
        hold on
        plot(find(newbl(remainingBlinks(ii)-R:remainingBlinks(ii)+R)),dPu(remainingBlinks(ii)-R+find(newbl(remainingBlinks(ii)-R:remainingBlinks(ii)+R))));
        hold off;
        subplot(1,3,3)
        plot(aPu(remainingBlinks(ii)-R:remainingBlinks(ii)+R))
        hold on
        plot(find(newbl(remainingBlinks(ii)-R:remainingBlinks(ii)+R)),aPu(remainingBlinks(ii)-R+find(newbl(remainingBlinks(ii)-R:remainingBlinks(ii)+R))));
        hold off;
        pause;
    end
end
for ii = 1:length(blinkOffsets)
    ix = blinkOffsets(ii);
    while (dPu(ix)>thresh2) && ix<length(dPu)
        ix = ix+1;
        newbl(ix) = true;
    end
    if false
        subplot(1,3,1)
        plot(find(newbl(blinkOffsets(ii)-100:blinkOffsets(ii)+100)),xPu(blinkOffsets(ii)-100+find(newbl(blinkOffsets(ii)-100:blinkOffsets(ii)+100))),'g')
        hold off;
        subplot(1,3,2)
        plot(find(newbl(blinkOffsets(ii)-100:blinkOffsets(ii)+100)),dPu(blinkOffsets(ii)-100+find(newbl(blinkOffsets(ii)-100:blinkOffsets(ii)+100))),'g');
        hold off;
        subplot(1,3,3)
        plot(find(newbl(remainingBlinks(ii)-100:remainingBlinks(ii)+100)),aPu(remainingBlinks(ii)-100+find(newbl(remainingBlinks(ii)-100:remainingBlinks(ii)+100))),'g');
        hold off;
        pause;
    end
end
end