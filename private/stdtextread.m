function [NUMERIC,TEXT,titles,format] = stdtextread(file,headerlines,headercolumns,format,varargin)
%STDTEXTREAD  Read a standard ascii table from file.
%   (with TABs or comas as column separators and LF or CR+LF as line end).
%   Return numeric data in matrix NUMERIC and text data in cell array TEXT.
%   This is the same output format as in XLSREAD (see 'help xlsread'), but the number 
%   of header lines and header columns is fixed, here (1 and 0, respectively, by default)
%
%   [NUMERIC,TEXT] = STDTEXTREAD(file)  reads file, skipping the first line (supposed to be column titles).
%
%   [NUMERIC,TEXT] = STDTEXTREAD(file,m)  skips the m first lines.  Default is m = 1.
%
%   [NUMERIC,TEXT] = STDTEXTREAD(file,c)  skips lines beginning with character c.
%   [NUMERIC,TEXT] = STDTEXTREAD(file,str)  where str is something like '#+1', skips lines beginning with '#' + 1 line.
%
%   [NUMERIC,TEXT] = STDTEXTREAD(file,m,n)  skips the m first lines and the n first columns.
%
%   [NUMERIC,TEXT] = STDTEXTREAD(file,m,n,format)  precises format argument for STRREAD (see 'help strread').
%
%   [NUMERIC,TEXT] = STDTEXTREAD(file,m,n,format,'-skip',pattern)  skips lines beginning by pattern.
%   '-skip' option can be used several times. See example below.
%
%   [NUMERIC,TEXT] = STDTEXTREAD(file,m,n,format,'-nan',pattern)  replaces pattern by 'NaN'. See example below.
%
%   [NUMERIC,TEXT,TITLES] = STDTEXTREAD(...)  returns the skipped line(s) in the cell array TITLES
%
%   [NUMERIC,TEXT,TITLES,FORMAT] = STDTEXTREAD(...)  returns the FORMAT vector, containing 'n' for
%   numeric columns and 's' for string ("text") columns.
%
% Example: To read a .asc file from EyeLink:
%       [N,T] = stdtextread('active.asc', 25, 0, '%n%n%n%n%s%n%n%s', '-skip','E', '-skip','S', '-skip','MSG', '-nan','   .');

% ben   20-07-2006
%       24-08       Help, 'headercolumns' argument, 'titles' output
%       27-08-2007  stdtextread(file,c) and stdtextread(file,str)
%       05-12       Cosmetic changes in help and version infos.
%       28-04-2009  Fix Titles Output: 1) Fix strange bug line 114: 'data_barbara.m' was hard coded !?
%                   2) Rewrite code without rea%dtext to fix case where they are spaces in the titles.
%       08-05-2009  Add 'FORMAT' output arg. Fix nargin bug, when nargin = 3.
%       26-01-2010  Read also coma separated.
%       08-09-2011  Add '-skip' and '-nan' options.
%       22-11-2012  Improve error message: print file name.
%       14-02-2014  Check that file exists.

tic

%% INPUT ARGS
if nargin < 2
    headerlines = 1;
end
if nargin < 3
    headercolumns = 0;
end
%dt49=toc, tic
% Options:
skippattern = {};
nanpattern = {};
opts = findoptions(varargin);
for i = opts
    switch lower(varargin{i})
        case '-skip'
            skippattern{end+1} = varargin{i+1};
        case '-nan'
            nanpattern{end+1} = varargin{i+1};
    end
end
%dt62=toc, tic

%% READ FILE
% and stock file content in a contenting vector
if ~exist(file), error(['Cannot find file "' file '". No such file exist.']); end
fid = fopen(file);
if fid < 0, error(['Cannot open file "' file '".']), end
content = fscanf(fid,'%c');
fclose(fid);
%dt69=toc, tic

%% STANDARDIZE LINE BREAKS
% Suppress carriage returns (13); keep line feeds (10). (Unix standard)
content(find(content == 13)) = [];

if content(end) ~= 10
    content(end+1) = 10;
end
%dt77=toc, tic

%% -SKIP: DELETE LINES TO SKIP 
for p = 1:length(skippattern)
    ii0 = strfind(content,[10 skippattern{p}]) + 1;
    ii1 = zeros(size(ii0));
    all_lf = find(content == 10);
    for i = 1 : length(ii0)
        i0 = ii0(i);
        f = find(all_lf > i0);
        i1 = all_lf(f(1)) - 1;
%         disp((content(i0:i1)))
        content(i0:i1) = '@';
    end
end
content(strfind(content,[10 10])) == '@';
%dt90=toc, tic
content(content=='@') = [];
%dt92=toc, tic

%% SEPARATORS
tabs = find(content == 9);
comas = find(content == ',');
if ~isempty(tabs) && ~isempty(comas)    % TAB separated, French localized..
    content(comas) = '.'; % ..replace comas by points
elseif isempty(tabs) && ~isempty(comas) % Coma separated..
    content(comas) = 9;   % ..replace comas by TABs
end
%dt98=toc, tic

%% -NAN: MISSING DATA
for p = 1:length(nanpattern)
    ii0 = union(strfind(content,[nanpattern{p} 9]), strfind(content,[nanpattern{p} 10]));
    ii0 = ii0(:)'; %<12/2/2015: Fix MATLAB 2012b+: bug in union(), >
    if length(nanpattern{p}) >= 3
        for i0 = ii0
            s = ['NaN' repmat(' ',1,length(nanpattern{p}-3))];
            content(i0:i0+length(s)-1) = s;
        end
    else 
        for i0 = ii0(end:-1:1)
            d = length(nanpattern{p});
            content = [content(1:i0-1) 'NaN' content(i0+d:end)];
        end
    end
end
%dt114=toc, tic

%% REPLACE COMAS BY POINTS (FIX LOCALIZATION ERRORS)
f = find(content == ',');
content(f) = repmat('.',1,length(f));
%dt118=toc, tic

%% EXTRACT FIRST LINE OF DATA
f = find(content == 10);
if headerlines, 
    if ischar(headerlines)
        m = length(find(content == headerlines(1)));
        if length(headerlines) > 1
            m = eval([num2str(m) headerlines(2:end)]);
        end
        headerlines = m;
    end
    i0 = f(headerlines) + 1;
else         
    i0 = 1;
end
i1 = f(headerlines+1) - 1;
firstline = content(i0:i1);
tabs = find(firstline == 9);
begs = [1 tabs+1];
ends = [tabs-1 length(firstline)];
J = length(begs);
%dt139=toc, tic

%% DETERMINE FORMAT (NUMERIC/TEXT) OF EACH COLUMN
% If FORMAT argument was not given, deduce it automatically
% from the first line of data. (The FORMAT argument is needed
% by STRREAD.)
if ~exist('format','var') || isempty(format)
    format = '';
    for n = 1 : J
        i0 = begs(n);
        i1 = ends(n);
        if length( str2num( firstline(i0:i1) ) ); % if it is a number or 'NaN' or 'nan'
            format = [format '%n']; %numeric
        else
            format = [format '%s']; %text
        end
    end
else
    J = length(format) / 2;
end
%dt158=toc, tic

%% EXTRACT COLUMN DATA WITH STRREAD
% f=find(double(content)==10,1);
% firstLine = content(1:f);
% firstLine(double(firstLine)==32)='';
% f=find(double(firstLine)==9);
% b=[1 f+1];
% e=[f-1 length(firstLine)];
% format='';
% for ff = 1:length(b)
%     if ~isempty(str2num(firstLine(b(ff):e(ff))))
%         format=[format '%d'];
%     else
%         format=[format '%s'];
%     end
% end
    
[columns{1:J}] = strread(content,format,'headerlines',headerlines,'delimiter',char(9)); % <15-jun-2011: Fix space bug: add 'delimiter' param>
%dt161=toc, tic

%% STORE DATA IN 2 OUTPUT ARGUMENTS OF SAME FORMAT THAN IN XLSREAD
I = length(columns{1});
if length(find(format=='n')), NUMERIC = NaN + zeros(I,J);
else                          NUMERIC = [];
end
if length(find(format=='n')), TEXT = cell(I,J);
else                          TEXT = {};
end
for j = 1 : J
    if format(2*j) == 'n', 
        NUMERIC(:,j) = columns{j};
    else
        TEXT(:,j) = columns{j};
    end
end
%dt177=toc, tic

%% SUPPRESS HEADER COLUMNS
NUMERIC = NUMERIC(:,1+headercolumns:end);
TEXT    = TEXT(:,1+headercolumns:end);
%dt181=toc, tic

%% OUTPUT
% titles:
if nargout >= 3 & headerlines
%     [cc{1:J}]=textread('data_barbara.m',repmat('%s',1,J),headerlines); % ???
    content(content==13) = ''; % delete CRs
    LF1 = find(content==10);
    LF1 = LF1(1);
    TABs = find(content(1:LF1) == 9);
    TABs = [0 TABs LF1];
    for j = 1 : length(TABs)-1
        titles{j} = content(TABs(j)+1:TABs(j+1)-1);
    end
end

% format:
format(1:2:end) = '';
%dt198=toc, tic