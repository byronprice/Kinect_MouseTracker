% ReadBinaryKinectFiles.m

Date = datetime('today','Format','yyyy-MM-dd');
Date = char(Date);Date = strrep(Date,'-','');Date = str2double(Date);
name = '04052';

numDepthFrames = 18000; %18000 for 10 minutes

depth_width = 512;
depth_height = 424;

fileIters = 1000; % between 500 and 1000

numIter = round(numDepthFrames/fileIters);

filename = sprintf('DepthData2.bin');
fileID = fopen(filename);
formatSpec = 'float32';
globalCount = 1;
for jj=1:numIter
    depthVideo = zeros(depth_height,depth_width,fileIters);
    depthFrames = zeros(fileIters,1);
    
    for ii=1:fileIters
        depthFrames(ii) = globalCount;
        Z = fread(fileID,[depth_width*depth_height,1],formatSpec);
        Z = reshape(Z,[depth_width,depth_height]);
        depthVideo(:,:,ii) = Z';
        
        
        globalCount = globalCount+1;
    end
    
%         figure();
%         for ii=1:fileIters
%             subplot(1,2,1);
%             imagesc(depthVideo(:,:,ii)');caxis([590 680]);colormap('hsv');
%             subplot(1,2,2);
%             imagesc(rgbVideo(:,:,ii)');colormap('bone');
%             pause(1/20);
%         end

    
fileName = sprintf('mouse%s-%d_%d.mat',name,jj,Date);
save(fileName,'depthVideo','depthFrames');
end
fclose(fileID);
