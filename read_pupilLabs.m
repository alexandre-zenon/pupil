function [pupilLabsTrial, pupilLabsBlock] = read_pupilLabs(data)

% This function takes as input a structure containing the matlab data from
% an experiment using COSYgraphics and the pupilLabs eyetracker. It outputs the
% data trial by trial in pupilLabsTrial, and as single continuous vectors in
% pupilLabsBlock.
%
% A. Z�non, Decembre 9, 2016

SRO = 30;% Default pupilLabs sampling rate

trialOnsets=[data.response(:).trialOnset];
TrialNumber=length(trialOnsets);
allPupilVector=[data.pupilData(:).pupil_diameter_px];
allEyeTimeVector=[data.pupilData(:).timestamp];
allEyeTimeVector=1000*(allEyeTimeVector-allEyeTimeVector(1))+data.pupilRecordStart;
allEyeXVector=[data.pupilData(:).gaze_norm_pos_x];
allEyeYVector=[data.pupilData(:).gaze_norm_pos_y];
pupilConfidence=[data.pupilData(:).pupil_confidence];

ti=round((allEyeTimeVector-allEyeTimeVector(1))/SRO)+1;
pupilVect(ti)=allPupilVector;
pupilConf(ti)=pupilConfidence;
eyeX(ti)=allEyeXVector;
eyeY(ti)=allEyeYVector;
timeVector=linspace(allEyeTimeVector(1),allEyeTimeVector(end),length(pupilVect));
vectZeros=find(pupilVect==0 & [0 diff(pupilVect)~=0]);
for vz = vectZeros
    if pupilVect(vz+1)~=0
        pupilVect(vz)=(pupilVect(vz-1)+pupilVect(vz+1))/2;
        pupilConf(vz)=(pupilConf(vz-1)+pupilConf(vz+1))/2;
        eyeX(vz)=(eyeX(vz-1)+eyeX(vz+1))/2;
        eyeY(vz)=(eyeY(vz-1)+eyeY(vz+1))/2;
    end
end

params.dataZ=4;
params.derivZ=2;
params.accelZ=2;

dataY = log(pupilVect);
out = excludeWrongDataFromPupilLabs( dataY , params);
dataY=interp1(find(~out),dataY(~out),[1:length(dataY)]);

disp(' Processing blink data');
error = pupilVect-exp(dataY);
RMS = log(fastSmooth(error.^2,5));
RMS(isinf(RMS))=NaN;
[ks,x]=ksdensity(RMS,'width',.8);
zer=find(abs(x)==min(abs(x)));
outlierThresh=x(zer+find(diff(ks(zer:end))>0,1)-1);
blinks=RMS>outlierThresh;

for trial = 1:TrialNumber
    pupilLabsTrial(trial).syncTime = trialOnsets(trial);
    pupilLabsTrial(trial).startTime = trialOnsets(trial);
    pupilLabsTrial(trial).events = NaN;
    if trial==TrialNumber
        pupilLabsTrial(trial).stopTime = allEyeTimeVector(end);
    else
        pupilLabsTrial(trial).stopTime = trialOnsets(trial+1)-1;
    end
    [z,beg]=min(abs(timeVector-pupilLabsTrial(trial).startTime));
    [z,eend]=min(abs(timeVector-pupilLabsTrial(trial).stopTime));
    bl=blinks(beg:eend);
    
    pupilLabsTrial(trial).blinks = blinks(beg:eend);
    pupilLabsTrial(trial).eyeX = eyeX(beg:eend);
    pupilLabsTrial(trial).eyeY = eyeY(beg:eend);
    pupilLabsTrial(trial).pupilSize = dataY(beg:eend);
    pupilLabsTrial(trial).eyeTime = timeVector(beg:eend);
end


allBlinkVector=blinks;
allPupilVector=dataY;
allEyeXVector=eyeX;
allEyeYVector=eyeY;

allBlinkVector=logical(allBlinkVector);

pupilLabsBlock.pupilSize=allPupilVector;
pupilLabsBlock.blinks=allBlinkVector;
pupilLabsBlock.eyeX=allEyeXVector;
pupilLabsBlock.eyeY=allEyeYVector;
pupilLabsBlock.time=timeVector;

end


%%%%%%%%%%%%%%%%%%%%%
function out = excludeWrongDataFromPupilLabs( dataY , params )

dataZ = params.dataZ;
derivZ = params.derivZ;
accelZ = params.accelZ;

pupilDeriv = [0 diff(dataY)];
pupilAccel = [0 diff(dataY)];
dataD = pupilDeriv;
dataA = pupilAccel;

out = dataY==0 | isinf(dataY) | isnan(dataY) | isinf(dataD);

dout=Inf;
MAXITER = 10;
iter=0;
while dout>0 & iter < MAXITER
    iter=iter+1;
    my= mode(round(dataY(~out)*10)/10);
    md= mode(round(dataD(~out)*10)/10);
    ma= mode(round(dataA(~out)*10)/10);
    athreshUp = ma+accelZ*std(dataA(~out));
    athreshDown = ma-accelZ*std(dataA(~out));
    dthreshUp = md+derivZ*std(dataD(~out));
    dthreshDown = md-derivZ*std(dataD(~out));
    ythresh = my-dataZ*std(dataY(~out));
    nout = out | dataD<dthreshDown | dataD>dthreshUp | dataY<ythresh | dataA<athreshDown | dataA>athreshUp;
    dout = sum(nout)-sum(out);
    out=nout;
end

end

