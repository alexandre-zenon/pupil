function [ii0,ii1] = findoptions(c)
% FINDOPTIONS  Find Unix-style option strings ('-*') in a cell array.
%    FINDOPTIONS(C)  finds indexes of strings beginning by a dash in the cell vector C (usually
%    the 'varargin' cell in the caller function).
%
%    [BEGS,ENDS] = FINDOPTIONS(C)  returns also indexes of last elements of each options.
%
% Example:
%    iOpt = findoptions(varargin);
%
% See also: ISOPTION.
%
% Ben, May 2010.

ii0 = find(isoption(c));
if ~isempty(ii0),   ii1 = [ii0(2:end)-1, length(c)];
else                ii1 = [];
end
