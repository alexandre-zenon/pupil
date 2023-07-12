function [data,b,a] = filterPupil( data, cutoff, fsamp )
% filteredPupil = filterPupil( data, cutoffFreq, fsamp )
% pupilSignal is the original data. It can be in structure format, coming directly from loadData or it can be a vector.
% cutoff is the desired cutoff frequency in Hz
% fsamp is the sampling rate

plotFlag = false;
filterType = 'filtfilt';
nF = length(cutoff);
if cutoff < 0.004
    warning('Cutoff freq is too small --> changing to 0.004 Hz');
    cutoff = 0.004;
end
if isstruct(data) && isfield(data,'pupilData') && isfield(data(1).pupilData,'block')
    for dd = 1:length(data)
        blockData = data(dd).pupilData.block; % data coming from loadWithPupil
        trialData = data(dd).pupilData.trials;
        if isstruct(blockData)
            if nargin<3
                df = nanmean(diff(blockData.time));
                if df<1
                    fsamp = round(1./nanmean(diff(blockData.time)));
                else
                    fsamp = round(1000./nanmean(diff(blockData.time)));
                end
            end
            pupil = blockData.pupilSize;
            for ff = 1:nF
                [blockData.filteredPupilSize(ff,:),b(:,ff),a(:,ff)] = filterPupil( pupil, cutoff(ff), fsamp );
            end
            
            T = length(trialData);
            for tr = 1:T
                if ~isempty(trialData(tr).pupilSize)
                ix = (blockData.time>=trialData(tr).startTime) & (blockData.time<=trialData(tr).stopTime);
                for ff = 1:nF
                    trialData(tr).filteredPupilSize(ff,:) = blockData.filteredPupilSize(ff,ix);
                end
                else
                    disp(['warning no pupil in this trial (',num2str(tr),') skipping -- stempio'])
                end
            end
            data(dd).pupilData.block = blockData;
            data(dd).pupilData.trials = trialData;
            
            if plotFlag
                figure(dd);
                for ff = 1:nF
                    subplot(nF,2,2*(ff-1)+1);
                    hold on
                    title('Frequency response of filter around cutoff');
                    % tests filter
                    [H,F]=freqz(b(:,ff),a(:,ff),2048,fsamp);
                    [~,m]=min(abs(F-(cutoff)));
                    plot(F(1:2*m),abs(H(1:2*m)));
                    xlabel('Frequency (Hz)')
                    ylabel('gain (linear scale)');
                    subplot(nF,2,2*(ff-1)+2);
                    title('Filtered and detrended non filtered data');
                    hold on
                    z(~isnan(blockData.pupilSize)) = detrend(blockData.pupilSize(~isnan(blockData.pupilSize)));
                    z(isnan(blockData.pupilSize)) = NaN;
                    plot(z);
                    plot(blockData.filteredPupilSize(ff,:));
                    legend('Non filtered','Filtered');
                end
            end
        end
    end
elseif isvector(data)
    pupil = data; % data coming directly from read_eyelink
    
    % makes filter
    Nyquist = fsamp/2;
    attenuation = 40;
    ripple = 1;
    [n,Wn] = cheb2ord(cutoff/Nyquist,(cutoff/2)/Nyquist,ripple,attenuation);
    [b,a] = cheby2(n,attenuation,Wn,'high');
    
    if any(isnan(pupil))
      %  warning('Caution! There are still some NaN values in the data.');
    end
    switch filterType
        case 'filtfilt'
            try
                fpupil(~isnan(pupil)) = filtfilt(b,a,pupil(~isnan(pupil)));
            catch
                fpupil(~isnan(pupil)) = pupil(~isnan(pupil));
            end
        case 'normal'
            fpupil(~isnan(pupil)) = filter(b,a,pupil(~isnan(pupil)));
    end
    fpupil(isnan(pupil)) = NaN;
    data = fpupil;
else
    error('Unrecognized data type');
end

end

