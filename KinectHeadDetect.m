% KinectHeadDetect.m

% work in progress

mouseNum = '04051';Date = 20171119;
files = dir(sprintf('mouse%s-*_%d.mat',mouseNum,Date));

% sometimes the files don't load in the correct order ... rearrange them
fileIDs = zeros(length(files),1);
for ii=1:length(files)
    temp1 = regexp(files(ii).name,'-');
    temp2 = regexp(files(ii).name,'_');
    fileIDs(ii) = str2double(files(ii).name(temp1+1:temp2-1));
end

[~,I] = sort(fileIDs);

conn = 8;
for ii=1:length(files)
    load(files(I(ii)).name,'correctedVideo');
    [height,width,numIms] = size(correctedVideo);
    for jj=1:numIms
        backSubtract = correctedVideo(:,:,jj);
        
        binaryim = backSubtract~=0;
        %       [PixelIdxList,~] = bwconncomp_2d(BW, conn);
        CC = bwconncomp(binaryim,conn);
        area = cellfun(@numel, CC.PixelIdxList);
        
        [~,ind] = max(area);
        idxToKeep = CC.PixelIdxList(ind);
        idxToKeep = vertcat(idxToKeep{:});
        
        mask = false(size(binaryim));
        mask(idxToKeep) = true;
        
        %imagesc(mask);
        
        % eliminate everything in the image except the biggest connected
        %  object
        backSubtract(~mask) = 0;
        
        [r,c] = find(mask~=0);
        cloud = [c,r];
        com_body = [mean(cloud(:,1)),mean(cloud(:,2))];
        
        [eigenvectors,eigenvalues] = eigs(cov(cloud),2);
        
        tempeig = eigenvectors(:,2)./norm(eigenvectors(:,2));
        subplot(2,1,1);
        imagesc(backSubtract);caxis([0 100]);colormap('gray');
        subplot(2,1,2);
        plot(tempeig(1),tempeig(2),'.','LineWidth',10);axis([-1 1 -1 1]);
        pause(1/20);
    end
end