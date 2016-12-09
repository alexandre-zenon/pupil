function [eyelinkTrial, eyelinkBlock] = read_eyelink(FILENAME)

% This function takes as input the name of an eyelink file and outputs the
% data trial by trial in eyelinkTrial, and as single continuous vectors in
% eyelinkBlock. 
% 
% It is based on the COSYgraphics toolbox and assumes that the same toolbox was used to run the experiment.  
%
% A. Zénon, Decembre 9, 2016

PRE_START_RECORD = 0;
BLINK_MARGIN = 100;% determines by how much blink time is appended before and after each Eyelink-detected blink. 

if ~exist([FILENAME(1:end-4) '_events.asc']) || ~exist([FILENAME(1:end-4) '_samples.asc'])
    eyelinkTrial.startTime = NaN;
    eyelinkTrial.stopTime = NaN;
    eyelinkTrial.syncTime = NaN;
    eyelinkTrial.events = NaN;
    eyelinkTrial.blinks = NaN;
    eyelinkBlock = NaN;
    disp('Non existent Eyelink file');
    return
end
try
    [eyelinkEvents, header] = getEyelinkAscEvents([FILENAME(1:end-4) '_events.asc']);
catch
    eyelinkTrial.startTime = NaN;
    eyelinkTrial.stopTime = NaN;
    eyelinkTrial.syncTime = NaN;
    eyelinkTrial.events = NaN;
    eyelinkTrial.blinks = NaN;
    eyelinkBlock = NaN;
    disp('Impossible to run getEyelinkAscEvents');
    return
end
disp(' Reading eyelink file');
[N,T] = stdtextread([FILENAME(1:end-4) '_samples.asc'], 25, 0, '%n%n%n%n%s%n%n%s', '-skip','E', '-skip','S', '-skip','MSG', '-nan','   .');

disp(' Extracting start/stop trials and event codes');
eyelinkMSG = eyelinkEvents(4).evLine;
for ii = 1:length(eyelinkMSG)
    msg = eyelinkMSG{ii};
    firstTab = find(double(msg)==9,1);
    spaces = find(double(msg)==32);
    timeStamp = str2num(msg(firstTab+1:spaces(1)-1));
    col = findstr(msg,':');
    if ~isempty(col) && length(spaces)>=2
        endOfType = min(spaces(2),col(1));
    elseif length(spaces)>=2
        endOfType = spaces(2);
    elseif ~isempty(col)
        endOfType = col(1);
    end
    type = msg(spaces(1)+1:endOfType-1);
    switch type
        case 'SUBJECT'
            Subject = msg(col+1:end);
        case 'STARTTRIAL'
            pawn = findstr(msg,'#');
            startTrialIndex = str2num(msg(pawn+1:col-1));
        case 'SYNC'
            syncTime = msg(col+1:end-1);
            eyelinkTrial(startTrialIndex).syncTime = syncTime;
        case 'TRIALSYNCTIME'
            eyelinkTrial(startTrialIndex).startTime = timeStamp;
        case 'USEREVENT'
            quotes = findstr(msg,'"');
            eventName = msg(quotes(1)+1:quotes(2)-1);
            eventType = msg(quotes(3)+1:quotes(4)-1);
            eyelinkTrial(startTrialIndex).events(timeStamp-eyelinkTrial(startTrialIndex).startTime+PRE_START_RECORD+1) = eval([eventName '_' eventType])+1;
        case 'STOPTTRIAL'
            pawn = findstr(msg,'#');
            stopTrialIndex = str2num(msg(pawn+1:col-1));
            if stopTrialIndex~=startTrialIndex
                warning('Inconsistencies in trial indices in eyelink .asc file');
            end
            eyelinkTrial(startTrialIndex).stopTime = timeStamp;
        case 'TASK'
            Task = msg(col+1:end-1);
    end
end

%%%%%% eye position data %%%%%%
allPupilVector = N(:,4);
allEyeXVector = N(:,2);
allEyeYVector = N(:,3);
allEyeTimeVector = N(:,1);

disp(' Processing blink data');
eyelinkEBLINK = eyelinkEvents(1).evLine;
allBlinkVector = allPupilVector*0;
for ii = 1:length(eyelinkEBLINK)
    msg = eyelinkEBLINK{ii};
    tabs = find(double(msg)==9);
    spaces = find(double(msg)==32);
    begTimeStamp = str2num(msg(spaces(2)+1:tabs(1)-1))-BLINK_MARGIN;
    endTimeStamp = str2num(msg(tabs(1)+1:tabs(2)-1))+BLINK_MARGIN;
    [z,begInd]=min(abs(allEyeTimeVector-begTimeStamp));
    [z,endInd]=min(abs(allEyeTimeVector-endTimeStamp));
    vectorIndices = [begInd:endInd];
    
    allBlinkVector(vectorIndices) = 1;
    if exist('eyelinkTrial') && isfield(eyelinkTrial,'startTime') && isfield(eyelinkTrial,'stopTime')
        if ~isempty(begTimeStamp) & ~isempty(endTimeStamp)
            trialIndex = find(([eyelinkTrial.startTime]<endTimeStamp)&([eyelinkTrial.stopTime]>begTimeStamp));
        elseif ~isempty(begTimeStamp)
            trialIndex = find(([eyelinkTrial.startTime]<begTimeStamp)&([eyelinkTrial.stopTime]>begTimeStamp));
        elseif ~isempty(endTimeStamp)
            trialIndex = find(([eyelinkTrial.startTime]<endTimeStamp)&([eyelinkTrial.stopTime]>endTimeStamp));
        end
        if ~isempty(trialIndex) && length(trialIndex)<2
            if ~isempty(begTimeStamp) & ~isempty(endTimeStamp)
                blinkTime = [begTimeStamp:endTimeStamp]-eyelinkTrial(trialIndex).startTime+PRE_START_RECORD+1;
            elseif ~isempty(begTimeStamp)
                blinkTime = [begTimeStamp:eyelinkTrial(trialIndex).stopTime]-eyelinkTrial(trialIndex).startTime+PRE_START_RECORD+1;
            elseif ~isempty(endTimeStamp)
                blinkTime = [eyelinkTrial(trialIndex).startTime:endTimeStamp]-eyelinkTrial(trialIndex).startTime+PRE_START_RECORD+1;
            end
            blinkTime(blinkTime<=0) = [];
            eyelinkTrial(trialIndex).blinks(blinkTime) = 1;
        end
    end
end
if exist('eyelinkTrial') && ~isfield(eyelinkTrial,'blinks')
    for ii = 1:length(eyelinkTrial)
        eyelinkTrial(ii).blinks =NaN;
    end
end

allBlinkVector=logical(allBlinkVector);
allPupilVector=allPupilVector/2000;
eyelinkBlock.pupilSize=allPupilVector;
eyelinkBlock.blinks=allBlinkVector;
eyelinkBlock.eyeX=allEyeXVector;
eyelinkBlock.eyeY=allEyeYVector;
eyelinkBlock.time=allEyeTimeVector;

disp(' Reformating in trials');
if exist('eyelinkTrial') && isfield(eyelinkTrial,'startTime')
    for ii = 1:length(eyelinkTrial)
        start = eyelinkTrial(ii).startTime;
        if ii <length(eyelinkTrial)
            stop = eyelinkTrial(ii+1).startTime;
        else
            stop = allEyeTimeVector(end)+1;
        end
        
        if ~isempty(stop)
            ix = find((allEyeTimeVector>=start) & (allEyeTimeVector<stop));
            eyelinkTrial(ii).eyeX = allEyeXVector(ix);
            eyelinkTrial(ii).eyeY = allEyeYVector(ix);
            eyelinkTrial(ii).pupilSize = allPupilVector(ix);
            eyelinkTrial(ii).eyeTime = allEyeTimeVector(ix);
        else
            eyelinkTrial(ii) = [];
        end
    end
else
    eyelinkTrial=NaN;
end