function [signal, filenames] = extractSignal(d,signalVariable,varargin)
% examples: 
% extractedData = extractSignal(data,'pupilSize')
% extractedData = extractSignal(data,'pupilSize','timeDotsStart')
% extractedData = extractSignal(data,'pupilSize','','timeCrossStart')

if length(varargin)==0
    onsetVariableName='';
    offsetVariableName='';
elseif length(varargin)==1
    onsetVariableName=varargin{1};
    offsetVariableName='';
elseif length(varargin)==2
    onsetVariableName=varargin{1};
    offsetVariableName=varargin{2};
else
    error('Unsupported number of arguments')
end

if isfield(d,'directories')
    direct=d.directories;
else
    direct.data=d;
    direct.name='single directory';
end
for di = 1:length(direct)
    disp(['Processing directory: ' direct(di).name]);
    filenames.directory(di).name = direct(di).name;
    for dd = 1:length(direct(di).data)
        disp(['Processing file: ' direct(di).data(dd).filename]);
        filenames.directory(di).file(dd).name = direct(di).data(dd).filename;
        try
            if ~isempty(onsetVariableName)
                onsets = direct(di).data(dd).trialData.(onsetVariableName);
            else
                onsets = [];
            end
            if ~isempty(offsetVariableName)
                offsets = direct(di).data(dd).trialData.(offsetVariableName);
            else
                offsets = [];
            end
            for tr = 1:length(direct(di).data(dd).signalData.trials)
                d = direct(di).data(dd).signalData.trials(tr);
                timings = d.eyeTime;
                if ~isempty(onsets)
                    [~,o]=min(abs(timings-onsets(tr)));
                else
                    o = 1;
                end
                if ~isempty(offsets)
                    [~,off]=min(abs(timings-offsets(tr)));
                else
                    off=length(d.(signalVariable));
                end
                signal.directory(di).file(dd).trial(tr).data = d.(signalVariable)(o:off);
            end
        catch
            signal.directory(di).file(dd).trial(1).data = NaN;
            warning('Cannot find the onset variable in trialData');
        end
    end
end