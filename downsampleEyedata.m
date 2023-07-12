function data = downsampleEyedata( data, desiredSR, fsamp )

warning off % to avoid downsamplevector warnings
if ~isstruct(data) || ~isfield(data,'pupilData')
    error('First argument should be data structure coming out from loadData');
end

for dd = 1:length(data)
    blockData = data(dd).pupilData.block;
    trialData = data(dd).pupilData.trials;
    if isstruct(blockData)
        
        if nargin<3
            df = nanmean(diff(data(dd).pupilData.block.time));
            if df < 1
                fsamp = round(1./df);
            else
                fsamp = round(1000./df);
            end
        end
        
        L = length(blockData.pupilSize);
        F = fieldnames(blockData);
        for ff = 1:length(F)
            if length(blockData.(F{ff})) == L
                blockData.(F{ff}) = downsampleVector(blockData.(F{ff}),fsamp,desiredSR);
            end
        end
        T = length(trialData);
        
        for tt = 1:T
            F = fieldnames(trialData(tt));
            L = length(trialData(tt).pupilSize);
            for ff = 1:length(F)
                if length(trialData(tt).(F{ff})) == L
                    trialData(tt).(F{ff}) = downsampleVector(trialData(tt).(F{ff}),fsamp,desiredSR);
                end
            end
        end
        warning on
        %freqz(b,a,2048,fsamp);
        
        data(dd).pupilData.block = blockData;
        data(dd).pupilData.trials = trialData;
    end
end
end

