function [behavioralData, pupilData]=loadWithPupil(filename,matlabOnsetVariable)
% Opens filename and outputs matlab data and eyetracking data from an
% experiment using the COSYgraphics toolbox.
% The second argument should contain the name of the variable in the matlab
% data which indicates the onset of the first display following
% starttrial. If empty, no alignement between the matlab and eyetracking
% dataset will be performed. 
% 
% example: [behavioralData, pupilData]=loadWithPupil('OCIntegralTimone_051112_7.mat','trialData.phaseOnset');
%
% A. Zénon, Decembre 9, 2016

disp('Parsing matlabOnsetVariable')
if ~isempty(matlabOnsetVariable)
    f=findstr(matlabOnsetVariable,'.');
    if length(f)==1
        field1 = matlabOnsetVariable(1:f-1);
        field2 = matlabOnsetVariable(f+1:end);
    elseif length(f)>1
        error('Cannot handle matlab onset variables with more than 2 fields')
    else
        field1 = matlabOnsetVariable;
        field2 = [];
    end
else
    field1 = [];
    field2 = [];
end

disp('Loading behavioral data');
behavioralData=load(filename);
disp('Loading pupil data');
if isfield(behavioralData,'eyelinkFlag') && ~behavioralData.eyelinkFlag
    eyelink=false;
else
    eyelink=true;
end
if eyelink
    f=filename(1:end-4);
    ff=findstr(f,'_');
    f2 = [f f(ff(1):end)];
    f3 = [f f(ff(2):end)];
    
    if exist([f '.edf'])
        [trialData,blockData]=read_eyelink([f '.mat']);
    elseif exist([f2 '.edf'])
        [trialData,blockData]=read_eyelink([f2 '.mat']);
    elseif exist([f3 '.edf'])
        [trialData,blockData]=read_eyelink([f3 '.mat']);
    else
        error('There is no pupil data');
    end
    
    
    disp('Processing pupil data');
    disp('Synchronizing behaviour with pupil');
    if exist('trialData')
        ELstart=trialData(1).startTime;
        if ~isempty(field1)
           try
                if ~isempty(field2)
                    MATLABstart=behavioralData.(field1)(1).(field2)(1);
                else
                    MATLABstart=behavioralData.(field1)(1);
                end
                ELoffset = ELstart-MATLABstart;
            catch
                warning('Cannot synchronize matlab and pupil data');
                ELoffset = 0;
            end
        else
            warning('Cannot synchronize matlab and pupil data');
            ELoffset = 0;
        end
    else
        warning('Cannot synchronize matlab and pupil data');
        ELoffset = 0;
    end
    
    if exist('blockData') && isstruct(blockData)
        timeIndices=ceil((blockData.time-blockData.time(1)+1)/2);%500 Hz
        bl(timeIndices) = double(blockData.blinks);
        if ~all(bl==1)
            fd=find(diff(bl)==1);
            nfd=find(diff(bl)==-1);
            if ~isempty(fd)
                nfd=nfd(find(nfd>fd(1),1):end);
                fd=fd(1:find(fd<nfd(end),1,'last'));
            end
            blinkDurations=(nfd-fd)*2;%in ms
            nonBlinks=find(blinkDurations>500);
            excludeBl=bl*false;
            for ii = 1:length(nonBlinks)
                excludeBl(fd(nonBlinks(ii)):nfd(nonBlinks(ii)))=true;
            end
            excludeBl=excludeBl&bl;
            bl(excludeBl==1)=0;
            missingData=union(find(excludeBl),setdiff([timeIndices(1):timeIndices(end)],timeIndices));
        else
            blinkDurations=NaN;
            missingData=bl;
            bl=bl*NaN;
        end
        
        
        pu(timeIndices) = blockData.pupilSize;
        pu(missingData) = NaN;%missing data is put to NaN
        pu(pu==0) = NaN;%missing data is put to NaN
        pu(bl==1) = NaN;%blinks are put to NaN
        
        remainingBlinks=find(abs(diff(pu))>.02);
        remainingBlinks=sort([remainingBlinks(:), remainingBlinks(:)-1, remainingBlinks(:)+1]);
        remainingBlinks=unique(remainingBlinks(:));
        remainingBlinks(remainingBlinks<1)=[];
        remainingBlinks(remainingBlinks>length(bl))=[];
        bl(remainingBlinks)=1;
        pu(remainingBlinks)=NaN;
        
        if ~all(isnan(pu))
            fd=find(diff((~isnan(pu)))==1);
            nfd=find(diff((~isnan(pu)))==-1);
            nfd=nfd(find(nfd>fd(1),1):end);
            if ~isempty(nfd)
                fd=fd(1:find(fd<nfd(end),1,'last'));
                pupilTraceDurations=(nfd-fd)*2;%in ms
                nonPupil=find(pupilTraceDurations<500);
                excludePu=bl*false;
                for ii = 1:length(nonPupil)
                    excludePu(fd(nonPupil(ii)):nfd(nonPupil(ii)))=true;
                end
                lastBlinks=find(excludePu);
                bl(lastBlinks)=1;
                pu(lastBlinks)=NaN;
            end
            
            pu=interp1(find(~isnan(pu)),pu(~isnan(pu)),[1:length(pu)]);
        end
        
        bl(missingData) = NaN;
        md = pu*0;
        md(missingData) = 1;
        
        pupilData.block.pupilSize = pu;
        pupilData.block.missingData = md;
        pupilData.block.blinks = bl;
        pupilData.block.blinkRate=60*500*(nansum(diff(bl)==1)/sum(~isnan(bl)));%blinks per minute
        
       %pupilData.block.time=blockData.time(1)-ELoffset+[timeIndices(1):timeIndices(end)]+9;
        pupilData.block.time=blockData.time-ELoffset;
    else
        pupilData.block.pupilSize = NaN;
        pupilData.block.missingData = NaN;
        pupilData.block.blinks = NaN;
        pupilData.block.blinkRate=NaN;
        pupilData.block.time = NaN;
    end
    if exist('trialData') && isstruct(trialData)
        pupilData.trials = trialData;
        for tr = 1:length(pupilData.trials)
            pupilData.trials(tr).startTime = pupilData.trials(tr).startTime-ELoffset;
            pupilData.trials(tr).stopTime = pupilData.trials(tr).stopTime-ELoffset;
            pupilData.trials(tr).eyeTime = pupilData.trials(tr).eyeTime-ELoffset;
            
            ti=pupilData.block.time;
            dtiStart=abs(ti-pupilData.trials(tr).startTime);
            beg=find(dtiStart==min(dtiStart));
            blockIx=[beg:beg+length(pupilData.trials(tr).eyeTime)-1];
            pupilData.trials(tr).pupilSize = pupilData.block.pupilSize(blockIx);
        end
    else
        pupilData.trials = NaN;
    end
else % pupilLabs
    try
        [trialData,blockData]=read_pupilLabs(behavioralData);
        pupilData.trials = trialData;
        pupilData.block = blockData;
    catch
        warning('Unable to read pupil data');
        pupilData.trials = NaN;
        pupilData.block = NaN;
    end
    
end