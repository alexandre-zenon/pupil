function h = plotImpulse( timp, imp, impsd, alpha , varargin)
% inputs:
%   timp = time bin vector
%   imp = impulse response from the impulse function
%   impsd = impulse SD from the impulse function
%   alpha = desired alpha for the CI
if length(varargin)==1
    labels=varargin{1};
elseif length(varargin)>1
    error('Incorrect number of arguments');
else
    labels={};
end

timp=timp(:);
imp=squeeze(imp);
impsd=squeeze(impsd);

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

