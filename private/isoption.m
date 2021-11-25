function [b,e] = isoption(s)
% ISOPTION  True for character string beginning with a dash.
%    ISOPTION(S)  if S is a string, returns 1 if S begins with a dash ('-'), 0 otherwise ; if S is 
%    a cell array, returns a logical vector containing 1 at the emplacements of strings beginning
%    by a dash, and 0 everywhere else.
%
% Common usage:
%    isoption(varargin);
%
% See also: FINDOPTIONS.
%
% Ben, Apr 2010.

% Performances:
%    1x5  cell:  62 탎 on CHEOPS, MATLAB 7.5.
%    1x50 cell: 462 탎 on CHEOPS, MATLAB 7.5.

if ischar(s)
    b = ~isempty(strmatch('-',s));
    
elseif iscell(s)
    b = false(size(s));
    for i = 1:length(s)
        % 462 탎:
        if ischar(s{i})
            str = s{i};
            if ~isempty(str)
                if str(1) == '-';
                    b(i) = true;
                end
            end
        end
        
%         % 478 탎:
%         str = s{i};
%         if ischar(str)
%             if ~isempty(str)
%                 if str(1) == '-';
%                     b(i) = true;
%                 end
%             end
%         end

%         % 812 탎:
%         str = s{i};
%         if ischar(str) && ~isempty(str) && str(1) == '-';
%             b(i) = true;
%         end
        
%         % 514 탎:
%         if ischar(s{i})
%             if ~isempty(s{i})
%                 if s{i}(1) == '-';
%                     b(i) = true;
%                 end
%             end
%         end

%         % 590 탎:
%         str = s{i};
%         if ischar(str)
%             if ~isempty(str)
%                 if strcmp(str(1),'-');
%                     b(i) = true;
%                 end
%             end
%         end

%         % 703 탎:
%         str = s{i};
%         if ~isempty(str)
%             if strcmp(str(1),'-');
%                 b(i) = true;
%             end
%         end
        
    end

else
    b = false;
    
end