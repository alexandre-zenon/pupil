function eyelinkBlock = read_comprehension_eyedata(FILENAME)

% This function takes as input the name of an eyelink file and outputs the
% data trial by trial in eyelinkTrial, and as single continuous vectors in
% eyelinkBlock.
%
% If coded eyelink events are available, they should be provided as a
% structure in second argument. The structure should have a "key" field,
% containing the event names, and a "value" field, containing the corresponding event
% codes.
%
% It is based on the COSYgraphics toolbox and assumes that the same toolbox was used to run the experiment.
%
% A. Z?non, Decembre 9, 2016


PRE_START_RECORD = 0;
BLINK_MARGIN = 0;% determines by how much blink time is appended before and after each Eyelink-detected blink.

disp(' Reading eyelink file');
fid = fopen([FILENAME]);
if fid~=-1
    content = fscanf(fid,'%c');
    fclose(fid);
    content = strrep(content,char([9 46 46 46 10]),char(10));
    content = strrep(content,char([32 32 32 46]),'');
    f=find(double(content)==10,100);
    df=diff(f);
    firstIndex = 38;
    ff=find(df>=df(38) & df<=df(38)+5,2);
    firstlines = content(1:f(ff(1)));
    secondline = content(f(ff(1))+1:f(ff(2)));
    columns = findstr(secondline,char(9));
    numColumns = length(columns)-1;
    D = textscan(content(f(ff(1))+1:end),'%d64%s%d%f%f%f%f%f%f%d%d%d%d%d%d%s');
    
    eyelinkTrial.startTime = NaN;
    eyelinkTrial.stopTime = NaN;
    eyelinkTrial.syncTime = NaN;
    eyelinkTrial.events = NaN;
    eyelinkTrial.blinks = NaN;
    eyelinkTrial.saccades = NaN;
    eyelinkTrial.eyeTime = NaN;
    
    %%%%%% eye position data %%%%%%
    allPupilVector = D{6}+D{7}/2;
    allEyeTimeVector = D{1};
    allEyeXVector = D{4};
    allEyeYVector = D{5};
    
    eyelinkBlock.pupilSize=allPupilVector;
    eyelinkBlock.blinks=allPupilVector*0;
    eyelinkBlock.saccades=allPupilVector*0;
    eyelinkBlock.eyeX=allEyeXVector;
    eyelinkBlock.eyeY=allEyeYVector;
    eyelinkBlock.time=allEyeTimeVector;
    eyelinkBlock.events=D{3};
else
    eyelinkBlock = NaN;
end