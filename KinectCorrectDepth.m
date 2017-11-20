% KinectCorrectDepth.m
%  Load videos and correct the depth based on tangent (the sensor detects
%   distance from itself, but we really care about distance from the plane
%   created by the sensor

mouseNum = '04051';Date = 20171119;
files = dir(sprintf('mouse%s-*_%d.mat',mouseNum,Date));

backgroundFile = dir(sprintf('Background_%d.mat',Date));
load(backgroundFile(1).name,'background');
[height,width] = size(background);
Y = 1:height;X = 1:width;
imshow(uint16(background));caxis([675 750]);
title('CLICK ON FOUR CORNERS OF THE BASE OF THE BOX');
[x,y] = getpts;

hMin = round(min(y));
hMax = round(max(y));
wMin = round(min(x));
wMax = round(max(x));

boxDiag = sqrt((max(y)-min(y)).^2+(max(x)-min(x)).^2);
trueBoxDiag = sqrt(450.^2+450.^2);% mm

mmPerPixel = trueBoxDiag/boxDiag;

imshow(uint16(background));caxis([675 750]);
title('CLICK ON FOUR CORNERS OF BLACK TAPE ON THE BOX');
[x,y] = getpts;

hMin = round(min(y));
hMax = round(max(y));
wMin = round(min(x));
wMax = round(max(x));

[newHeight,newWidth] = size(background(hMin:hMax,wMin:wMax));
center = [height/2,width/2];
for ii=1:length(files)
    load(files(ii).name);
    [~,~,numIms] = size(depthVideo);
    
    for jj=1:numIms
        temp = background-depthVideo(:,:,jj);
        depthVideo(:,:,jj) = temp;
    end
    correctedVideo = depthVideo(hMin:hMax,wMin:wMax,:);
    correctedVideo(correctedVideo<=3) = 0;
    correctedVideo(correctedVideo>200) = 0;
    for jj=1:numIms
        temp = correctedVideo(:,:,jj);
        temp = medfilt2(temp);
        temp = medfilt2(temp);
        correctedVideo(:,:,jj) = medfilt2(temp);
    end
    correctedVideo = medfilt3(correctedVideo,[3 3 3]);
    correctedVideo = medfilt3(correctedVideo,[3 3 3]);
    correctedVideo = medfilt3(correctedVideo,[3 3 3]);
    save(files(ii).name,'correctedVideo','depthFrames','mmPerPixel');
end