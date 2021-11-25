function [data, filenames] = extractData(d,dataVariable,varargin)
% examples: 
% extractedData = extractData(data,'timeClick')

if length(varargin)==0
    dim=1;
else
    dim=varargin{1};
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
            d = direct(di).data(dd).trialData.(dataVariable);
            for tr = 1:size(d,dim)
                switch dim
                    case 1
                        data.directory(di).file(dd).trial(tr).data = d(tr,:);
                    case 2
                        data.directory(di).file(dd).trial(tr).data = d(:,tr,:);
                    case 3
                        data.directory(di).file(dd).trial(tr).data = d(:,:,tr,:);
                    case 4
                        data.directory(di).file(dd).trial(tr).data = d(:,:,:,tr,:);
                    case 5
                        data.directory(di).file(dd).trial(tr).data = d(:,:,:,:,tr,:);
                end
            end
        catch
            data.directory(di).file(dd).trial(1).data = NaN;
            warning('Cannot find the onset variable in trialData');
        end
    end
end