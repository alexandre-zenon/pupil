function [eyelinkEvents, header] = getEyelinkAscEvents(FILENAME)
% getEyelinkAscEvents  Extract event lines frome .asc file.
%
% Alex Zenon, 2011.

fid = fopen(FILENAME);
FR = fread(fid);
f = find(FR==10);
f2 = strfind(FR(:)','INPUT');
f3 = f(find(f>f2(1),1));
header = char(FR(1:f3))';
F = FR(f3:end);
eventTypes = {'EBLINK','ESACC','EFIX','MSG','SFIX','SSACC','SBLINK'};

for et = 1:length(eventTypes)
    f = findstr(char(F)',char([10 double(eventTypes{et})]))+1;
    next=0;
    for ev = f
        next=next+1;
        eof = find(F(ev:min([ev+1000, length(F)]))==10);
        evLine = char(F(ev:ev+eof(1)-2))';
        eyelinkEvents(et).evLine{next} = evLine;
    end
end
fclose(fid);