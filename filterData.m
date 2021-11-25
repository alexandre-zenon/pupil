function filteredData = filterData(d,includes,excludes)
% includes and excludes are either structures with fields 'directoryNames' and
% 'fileNames' or cell arrays of strings. In the latter case, the filter
% applies only to filenames. In the former, the fields contain also cell
% arrays of strings.
%
% examples:
% filteredData = filterData(data,{'_'},{'MVC','psychophy'});
%
% A. Zénon, August 7th 2018

if isstruct(includes) && isstruct(excludes)
    dirIncludes = includes.directoryNames;
    fileIncludes = includes.fileNames;
    dirExcludes = excludes.directoryNames;
    fileExcludes = excludes.fileNames;
elseif iscell(includes) && iscell(excludes)
    dirIncludes = {};
    fileIncludes = includes;
    dirExcludes = {};
    fileExcludes = excludes;
else
    error('Incorrect arguments');
end

if isfield(d,'directories')
    direct=d.directories;
else
    direct.data=d;
    direct.name='single directory';
end
di=1;
while di <= length(direct)
    dirname = direct(di).name;
    ok=true;
    if ~isempty(dirIncludes)
        for ii = 1:length(dirIncludes)
            if ~contains(dirname,dirIncludes{ii})
                ok=false;
            end
        end
    end
    if ~isempty(dirExcludes)
        for ii = 1:length(dirExcludes)
            if contains(dirname,dirExcludes{ii})
                ok=false;
            end
        end
    end
    if ~ok
        disp(['Deleting directory: ' direct(di).name]);
        direct(di)=[];
    else
        dd=1;
        while dd <= length(direct(di).data)
            filename = direct(di).data(dd).filename;
            ok=true;
            if ~isempty(fileIncludes)
                for ii = 1:length(fileIncludes)
                    if ~contains(filename,fileIncludes{ii})
                        ok=false;
                    end
                end
            end
            if ~isempty(fileExcludes)
                for ii = 1:length(fileExcludes)
                    if contains(filename,fileExcludes{ii})
                        ok=false;
                    end
                end
            end
            if ~ok
                disp(['Deleting file: ' direct(di).data(dd).filename]);
                direct(di).data(dd)=[];
            else
                dd=dd+1;
            end
        end
        
        di=di+1;
    end
end
filteredData.directories=direct;