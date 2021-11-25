function data=loadData(varargin)
% First input argument is directory. If empty, opens a GUI.
% Second and third arguments are either:
%   - a logical indicating whether the directory tree
% should be explored 
%   - a string indicating the variable name providing info on the pupil
%   signal synchronization
%   - a cell array with pairs of string indicating variables values that
%   should be true for the data to be extracted
% Fourth argument activates the option to remove extra blink. 
%
% exemple: data=loadData('','response.trialOnset',{options.version,'calcul'})
extraBlinkRemoval = false;
if nargin==0
    directoryname = uigetdir;
    cd(directoryname);
    exploreTree=true;
    synchroEvent='';
    inclusionCriteria={};
elseif nargin==1
    directoryname = varargin{1};
    if isempty(directoryname)
        directoryname = uigetdir;
    end
    cd(directoryname);
    exploreTree=true;
    inclusionCriteria={};
elseif nargin>=2
    directoryname = varargin{1};
    if isempty(directoryname)
        directoryname = uigetdir;
    end
    cd(directoryname);
    inclusionCriteria={};
    if ischar(varargin{2})
        synchroEvent=varargin{2};
        exploreTree=true;
    elseif iscell(varargin{2})
        inclusionCriteria=varargin{2};
    else
        exploreTree=varargin{2};
        synchroEvent='';
    end
end
if nargin==3
    inclusionCriteria={};
    if ischar(varargin{3})
        synchroEvent=varargin{3};
    elseif iscell(varargin{3})
        inclusionCriteria=varargin{3};
    else
        exploreTree=varargin{3};
    end
end
if nargin==4
    extraBlinkRemoval = varargin{4};
end

files=dir;

if exploreTree
    dirTreeFlag=any([files(3:end).isdir]);%there are subdirectories in this directory
else
    dirTreeFlag=false;
end

nextDir = 0;
if dirTreeFlag
    for filesi = 1:length(files)
        if files(filesi).isdir && ~strcmp(files(filesi).name,'.') && ~strcmp(files(filesi).name,'..')
            cd(files(filesi).name);
            
            %data.directories(nextDir).files=loadData(pwd,true,synchroEvent);
            d=loadData(pwd,true,synchroEvent,extraBlinkRemoval);
            for dd = 1:length(d)
                nextDir=nextDir+1;
                data(nextDir)=d(dd);
            end
            %data.directories(nextDir).name=pwd;
            cd(directoryname);
        end
    end
else
    nextFile=1;
    for filesi = 1:length(files)
        if ~isempty(findstr(files(filesi).name,'mat'))
            try
                [behavioralData, pupilData]=loadWithPupil(files(filesi).name,synchroEvent,inclusionCriteria,extraBlinkRemoval);
                data(nextFile).behavioralData=behavioralData;
                data(nextFile).pupilData=pupilData;
                data(nextFile).filename=files(filesi).name;
                % added by stempio 10/10/2019
                if isfield(files, 'date')
                    data(nextFile).date = files(filesi).date;
                end
                nextFile = nextFile+1;
            catch ME
                warning(['Unable to read ' files(filesi).name ' because of errors:' ME.message ' in ' ME.stack(1).name ', line ' num2str(ME.stack(1).line)])
            end
        end
    end
end
