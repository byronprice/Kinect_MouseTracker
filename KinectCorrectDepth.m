function [] = KinectCorrectDepth(mouseNum,Date)
% KinectCorrectDepth.m
%  Load videos and correct the depth based on tangent (the sensor detects
%   distance from itself, but we really care about distance from the plane
%   created by the sensor
%INPUT:
%      mouseNum - a string with the mouse's number
%      Date - the date as a number, e.g. 20171120 ... always use 
%              YYYYMMDD
% 
% Created: 2017/11/20
%  Byron Price
% Updated: 2017/11/20
% By: Byron Price

%mouseNum = '04051';Date = 20171119;
files = dir(sprintf('mouse%s-*_%d.mat',mouseNum,Date));

backgroundFile = dir(sprintf('Background_%d.mat',Date));
load(backgroundFile(1).name,'background');

imshow(uint16(background));caxis([675 750]);
title('CLICK ON FOUR CORNERS OF THE BASE OF THE BOX');
[x,y] = getpts;

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

[height,width] = size(background(hMin:hMax,wMin:wMax));
conn = 8;
for ii=1:length(files)
    load(files(ii).name);
    [~,~,numIms] = size(depthVideo);
    
    for jj=1:numIms
        temp = background-depthVideo(:,:,jj);
        depthVideo(:,:,jj) = temp;
    end
    correctedVideo = depthVideo(hMin:hMax,wMin:wMax,:);
    correctedVideo(correctedVideo<=10) = 0;
    correctedVideo(correctedVideo>200) = 0;
    for jj=1:numIms
        temp = correctedVideo(:,:,jj);
        temp = medfilt2(temp);
        temp = medfilt2(temp);
        
        binaryim = temp>0;
        CC = bwconncomp(binaryim,conn);
        area = cellfun(@numel, CC.PixelIdxList);
        
        [maxarea,ind] = max(area);
        if maxarea>50
            idxToKeep = CC.PixelIdxList(ind);
            idxToKeep = vertcat(idxToKeep{:});
            
            mask = false(size(binaryim));
            mask(idxToKeep) = true;
            
            % eliminate everything in the image except the biggest connected
            %  object

            temp(~mask) = 0;
        end
        
        temp = medfilt2(temp);
        correctedVideo(:,:,jj) = temp;
    end
    correctedVideo = medfilt3(correctedVideo,[3 3 3]);
    correctedVideo = medfilt3(correctedVideo,[3 3 5]);
    correctedVideo = medfilt3(correctedVideo,[3 3 5]);
    save(files(ii).name,'correctedVideo','depthFrames','mmPerPixel','height','width');
end

end