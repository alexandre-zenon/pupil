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

