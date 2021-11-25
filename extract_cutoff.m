% extracts cutoff from .mat file with pupilData format (where times of
% eyelink have already been divided by 1000 {msec to sec})

function [cutoff] = extract_cutoff(filename, data)

load(filename)
    
    TrialbySecond = 1/round(nanmean([data.pupilData.trials.stopTime] - [data.pupilData.trials.startTime]));
    cutoff = TrialbySecond/2;
    
end