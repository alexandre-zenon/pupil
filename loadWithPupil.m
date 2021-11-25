function [behavioralData, pupilData]=loadWithPupil(filename,varargin)
% Opens filename and outputs matlab data and eyetracking data from an
% experiment using PTB.
%
% Other arguments are optional:
%
% Optional string argument:
%   should contain the name of the variable in the matlab
%   data which indicates the onset of the first display following
%   starttrial. If empty, no alignement between the matlab and eyetracking
%   dataset will be performed.
%
% Optional structure argument:
%   The structure should have a "key" field, containing the event names, and a "value" field, containing the corresponding event
%   codes. This applies if coded eyelink events were used in the
%   experiment.
%
% Optional integer argument:
%   Includes additional samples prior to synchro event in each trial data.
%   The value of the integer determines the number of extra ms to add.
%
% Optional cell argument:
%   Includes inclusion criteria
%
% Optional logical argument:
%   Implements extra blink removal 
%
% example: [behavioralData, pupilData]=loadWithPupil('OCIntegralTimone_051112_7.mat','trialData.phaseOnset');
%
% A. Z???non, Decembre 9, 2016
defaultRatio = 1/1000;
matlabOnsetVariable=[];
eventList=struct;
baselineDuration=0;
extraBlinkRemoval = true;
for ii = 1:length(varargin)
    if ischar(varargin{ii})
        matlabOnsetVariable=varargin{ii};
    elseif isstruct(varargin{ii})
        eventList=varargin{ii};
    elseif isnumeric(varargin{ii}) && numel(varargin{ii})==1
        baselineDuration=varargin{ii};
    elseif iscell(varargin{ii})
        inclusionCriteria = varargin{ii};
    elseif islogical(varargin{ii})
        extraBlinkRemoval = varargin{ii};
    else
        error('Unrecognized argument');
    end
end
disp(' ');
disp(['Reading file ' filename]);
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
warning off; behavioralData=load(filename);warning on;
ok = true;
for ic = 1:size(inclusionCriteria,1)
    f=findstr(inclusionCriteria{ic,1},'.');
    f = [0 f length(inclusionCriteria{ic,1})+1];
    str = 'behavioralData';
    for ff = 1:length(f)-1
        field(ff).name = inclusionCriteria{ic,1}(f(ff)+1:f(ff+1)-1);
        str = [str '.' field(ff).name];
    end
    try
        if isstr(eval(str))
            eval([str ' =  lower( ' str ');'])
        end
        eval(['ok(ic) = isequal(' str ', inclusionCriteria{ic,2});'])
    catch
        ok(ic) = true;% hard to choose what to do here.
    end
end
if all(ok)
    disp('Loading pupil data');
    detectPupilSystem=false; % do not try to detect whether eyelink or pupilLabs system was used
    if detectPupilSystem
        if isfield(behavioralData,'eyelinkFlag') && ~behavioralData.eyelinkFlag
            eyelink=false;
        else
            eyelink=true;
        end
    else
        eyelink=true;
    end
    if eyelink
        f=filename(1:end-4);
        ff=findstr(f,'_');
        if ~isempty(ff)
            f2 = [f f(ff(1):end)];
            f3 = [f f(ff(2):end)];
        else
            f2=[];
            f3=[];
        end
        
        if exist([f '.edf']) || (exist([f '_events.asc']) && exist([f '_samples.asc']))
            [trialData,blockData]=read_eyelink([f '.mat'],eventList);
        elseif exist([f2 '.edf']) || (exist([f2 '_events.asc']) && exist([f2 '_samples.asc']))
            [trialData,blockData]=read_eyelink([f2 '.mat'],eventList);
        elseif exist([f3 '.edf']) || (exist([f3 '_events.asc']) && exist([f3 '_samples.asc']))
            [trialData,blockData]=read_eyelink([f3 '.mat'],eventList);
        else
            warning('There is no pupil data');
            pupilData.trials = NaN;
            pupilData.block = NaN;
            return
        end
        for tr = 1:length(trialData)
            if isempty(trialData(tr).stopTime)
                trialData(tr).stopTime = trialData(tr).startTime+length(trialData(tr).eyeTime)-1;
            end
        end
        p.trials = trialData;
        p.block = blockData;
        binInterval = unique(diff(blockData.time));
        samplingRate = 1000/binInterval;
        p = processBlinks(p,samplingRate,'linear',false,extraBlinkRemoval);
        trialData = p.trials;
        blockData = p.block;
        clear p
        
        disp('Processing pupil data');
        disp('Synchronizing behaviour with pupil');
        if exist('trialData')
            ELonsets = [trialData.startTime];
            ELstart = ELonsets(1);% first trial onset from Eyelink
            if ~isempty(field1)
                try
                    if ~isempty(field2)
                        MATLABstart=[behavioralData.(field1).(field2)];
                    else
                        MATLABstart=[behavioralData.(field1)];
                    end
                    MATLABstart = sort(MATLABstart);
                catch
                    warning('Invalid synchro event');
                    if ~isnan(ELstart)
                        MATLABstart=ELstart;
                    else
                        MATLABstart=blockData.time(1);
                    end
                end
            elseif ~isnan(ELstart)
                MATLABstart=ELonsets; % editted by SY replaced ELstart with ELonsets
            else
                MATLABstart=blockData.time(1);
            end
            if length(MATLABstart)>1
                tDurMATLAB = diff(MATLABstart);%duration of trials in MATLAB time
                tDurEL = diff(ELonsets);% duration of trials in EL time
                ratio = round(1000*nanmean(tDurMATLAB./tDurEL))/1000;% ratio of MATLAB and EL timings
            else
                tDurEL = trialData.stopTime-trialData.startTime;
                ratio = defaultRatio;
                warning(['Only one trial: No way to compute eyelink-matlab time ratio. Using default value of ' num2str(defaultRatio)]);
            end
            %blockData.time = [blockData.time(1)*ratio:ratio:blockData.time(end)*ratio];
            blockData.time = blockData.time*ratio;
            ELonsets = [trialData.startTime]*ratio;
            ELstart = ELonsets(1);% first trial onset from Eyelink
            if isnan(trialData(1).startTime)
                ELstart=blockData.time(1);
                ELoffset = ELstart-MATLABstart(1);
                onsets=MATLABstart-MATLABstart(1);
                for tr = 1:length(onsets)-1
                    trialData(1,tr).startTime = ELstart+onsets(tr);
                    trialData(1,tr).stopTime = ELstart+onsets(tr+1);
                    
                end
                tr=length(onsets);
                trialData(1,tr).startTime = ELstart+onsets(end);
                trialData(1,tr).stopTime = ELstart+blockData.time(end);
            elseif length(trialData)==1
                ELoffset = ELstart-MATLABstart(1);
            else
                ELoffset = ELstart-MATLABstart(1);
            end
        else
            warning('Cannot synchronize matlab and pupil data');
            ELoffset = 0;
        end
        
        if exist('blockData') && isstruct(blockData)
            
            pupilData.block.pupilSize = blockData.pupilSize;
            pupilData.block.blinks = blockData.blinks;
            pupilData.block.saccades = blockData.saccades;
            pupilData.block.blinkRate=60*500*(nansum(diff(blockData.blinks)==1)/sum(~isnan(blockData.blinks)));%blinks per minute
            
            %pupilData.block.time=blockData.time(1)-ELoffset+[timeIndices(1):timeIndices(end)]+9;
            pupilData.block.time=blockData.time-ELoffset;
            pupilData.block.eyeX=blockData.eyeX;
            pupilData.block.eyeY=blockData.eyeY;
        else
            pupilData.block.pupilSize = NaN;
            pupilData.block.missingData = NaN;
            pupilData.block.blinks = NaN;
            pupilData.block.saccades = NaN;
            pupilData.block.blinkRate=NaN;
            pupilData.block.time = NaN;
        end
        if exist('trialData') && isstruct(trialData)
            pupilData.trials = trialData;
            ti=pupilData.block.time;
            for tr = 1:length(pupilData.trials)
                pupilData.trials(tr).startTime = (pupilData.trials(tr).startTime*ratio)-ELoffset-baselineDuration;
                pupilData.trials(tr).stopTime = (pupilData.trials(tr).stopTime*ratio)-ELoffset;
                
                [~,start] = min(abs(ti-pupilData.trials(tr).startTime));
                [~,stop] = min(abs(ti-pupilData.trials(tr).stopTime));
                blockIx=[start:stop];
                
                pupilData.trials(tr).eyeTime = pupilData.block.time(blockIx);
                pupilData.trials(tr).blinks = pupilData.block.blinks(blockIx);
                pupilData.trials(tr).saccades = pupilData.block.saccades(blockIx);
                pupilData.trials(tr).eyeX = pupilData.block.eyeX(blockIx);
                pupilData.trials(tr).eyeY = pupilData.block.eyeY(blockIx);
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
else
    warning('Does not conform to inclusion criteria');
    pupilData.trials = NaN;
    pupilData.block = NaN;
    behavioralData = struct;
end