function transformedSignal = applyOnSignal(signal,fun)
%example: m=applyOnSignal(extractSignal(data,'pupilSize','timeDotsStart',''),@mean)

for dd = 1:length(signal)
    disp(['Processing file: ' signal(dd).filename]);
    for tr = 1:length(signal(dd).trial)
        try
            transformedSignal(dd).trial(tr).data = fun(signal(dd).trial(tr).data);
        catch
            transformedSignal(dd).trial(tr).data = NaN;
            warning('Cannot find the onset variable in trialData');
        end
    end
end
end

