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

se = strel('disk',3);
conn = 8;
for ii=1:length(files)
    load(files(I(ii)).name,'correctedVideo');
    [height,width,numIms] = size(correctedVideo);
    for jj=1:numIms
        backSubtract = correctedVideo(:,:,jj);
        
        mask = backSubtract>0;
        mask = imopen(mask,se);
        
        [r,c] = find(mask~=0);
        cloud = [c,r];
        com_body = [mean(cloud(:,1)),mean(cloud(:,2))];
        
        [eigenvectors,eigenvalues] = eigs(cov(cloud),2);
        
        tempeig = eigenvectors(:,2)./norm(eigenvectors(:,2));
        
        backSubtract(~mask) = 0;
        subplot(2,1,1);
        imagesc(backSubtract);caxis([0 100]);colormap('gray');
        subplot(2,1,2);
        plot(tempeig(1),tempeig(2),'.','LineWidth',10);axis([-1 1 -1 1]);
        pause(1/30);
    end
end