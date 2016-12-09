function h = plotImpulse(varargin)
% inputs:
%   Option 1: output from the pupilARX function (1 argument)
%   Option 2: outputs from the impulse functino (3 arguments):
%       1st: timp = time bin vector
%       2nd: imp = impulse response from the impulse function
%       3rd: impsd = impulse SD from the impulse function
%   In both cases, one more optional argument indicates the desired alpha for
%   computing the confidence intervals (2nd in option 1, 4th in option 2) 
%   In both cases, the last argument (3rd in option 1, 5th in option 2) can also include the names of the variables.
%
% A. Zénon, Decembre 9, 2016


labels={};
if nargin<=3
    arxOutput=varargin{1};
    timp=arxOutput.impulseTimeBins(:);
    imp=squeeze(arxOutput.impulse);
    impsd=squeeze(arxOutput.impulseSD);
    if nargin==1
        alpha=0.05;
    elseif nargin >=2
        alpha=varargin{2};
    end
    if nargin==3
        labels=varargin{3};
    end
elseif nargin<=5
    timp=varargin{1}(:);
    imp=squeeze(varargin{2});
    impsd=squeeze(varargin{3});
    if nargin==3
        alpha=0.05;
    elseif nargin >=4
        alpha=varargin{4};
    end
    if nargin==5
        labels=varargin{5};
    end
else
    error('Too many arguments');
end

colors={'b','g','r','c','m','y'};

ax=gca;
hold(ax,'on');
legendstr='';
for pp = 1:size(imp,2)
    if ~isempty(impsd)
        h{pp}=shadedErrorBar(timp,imp(:,pp),tinv(1-alpha/2,10000)*impsd(:,pp),colors{pp});
        shadedPlot=true;
    else
        h{pp}=plot(timp,imp(:,pp),colors{pp});
        shadedPlot=false;
    end
    %set(gca,'XScale','log')
end
xlabel('Time (s)')
ylabel('Pupil response (AU)')
a=cell2mat(h);
if shadedPlot
    legend([a.mainLine],labels)
else
    legend(a,labels)
end
hold(ax,'off');
end

