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
    load(files(I(ii)).name,'correctedVideo','mmPerPixel','height','width','depthFrames');
    [height,width,numIms] = size(correctedVideo);
    
    headPosition = zeros(numIms,2);
    comPosition = zeros(numIms,2);
    bcmAngle = zeros(numIms,1);
    
%     temp = correctedVideo(:,:,1);
%     mask = imopen(mask,se);
%     temp(~mask) = 0;
%     correctedVideo(:,:,1) = temp;
    if ii==1
        start = 2;
        figure;
        imagesc(correctedVideo(:,:,1));
        title('CLICK ON THE TIP OF THE NOSE');
        [headX,headY] = getpts;
        headPosition(1,:) = [headX,headY];
        
        imagesc(correctedVideo(:,:,1));
        title('CLICK ON THE BODY CENTER-OF-MASS');
        [bodyX,bodyY] = getpts;
        comPosition(1,:) = [bodyX,bodyY];
        
        tempX = headX-bodyX;
        tempY = headY-bodyY;
        bcmAngle(1) = atan(tempY/tempX);
        if tempX > 0 && tempY > 0
        elseif tempX > 0 && tempY < 0
        elseif tempX < 0 && tempY > 0
            bcmAngle(1) = bcmAngle(1)+pi;
        elseif tempX < 0 && tempY < 0
            bcmAngle(1) = bcmAngle(1)+pi;
        end
        
    else
        start = 1;
    end
    
    for jj=start:numIms
        backSubtract = correctedVideo(:,:,jj);
        
        mask = backSubtract>=10;
        mask = imopen(mask,se);
        
        [r,c] = find(mask~=0);
        cloud = [c,r];
        com_body = [mean(cloud(:,1)),mean(cloud(:,2))];
        
        [eigenvectors,eigenvalues] = eigs(cov(cloud),2);
        
        % the estimate of the head is basically 2 standard deviations away
        % from the center of the mass, in the direction opposite the tail
        s1 = 2*sqrt(eigenvalues(1,1));
        s2 = 2*sqrt(eigenvalues(2,2));
        head = [com_body(1)+eigenvectors(1,2)*s2,com_body(2)+eigenvectors(2,2)*s2];
        
        % make sure the estimate actually falls on the body of the mouse
        [~,ind] = min(abs(head(1)-cloud(:,1)));
        head(1) = cloud(ind,1);
        [~,ind] = min(abs(head(2)-cloud(:,2)));
        head(2) = cloud(ind,2);
        
        % tempeig = eigenvectors(:,2)./norm(eigenvectors(:,2));
        tempX = head(1)-com_body(1);
        tempY = head(2)-com_body(2);
        bcmAngle(jj) = atan(tempY/tempX);
        if tempX > 0 && tempY > 0
        elseif tempX > 0 && tempY < 0
        elseif tempX < 0 && tempY > 0
            bcmAngle(jj) = bcmAngle(jj)+pi;
        elseif tempX < 0 && tempY < 0
            bcmAngle(jj) = bcmAngle(jj)+pi;
        end
        
        difference = abs(bcmAngle(jj)-bcmAngle(jj-1));
        if difference > pi/6
            head = [com_body(1)-eigenvectors(1,2)*s2,com_body(2)-eigenvectors(2,2)*s2];
            
            % make sure the estimate actually falls on the body of the mouse
            [~,ind] = min(abs(head(1)-cloud(:,1)));
            head(1) = cloud(ind,1);
            [~,ind] = min(abs(head(2)-cloud(:,2)));
            head(2) = cloud(ind,2);
            
            tempX = head(1)-com_body(1);
            tempY = head(2)-com_body(2);
            bcmAngle(jj) = atan(tempY/tempX);
            if tempX > 0 && tempY > 0
            elseif tempX > 0 && tempY < 0
            elseif tempX < 0 && tempY > 0
                bcmAngle(jj) = bcmAngle(jj)+pi/2;
            elseif tempX < 0 && tempY < 0
                bcmAngle(jj) = bcmAngle(jj)+pi;
            end
        end
        headPosition(jj,:) = [head(1),head(2)];
        comPosition(jj,:) = [com_body(1),com_body(2)];
        
        backSubtract(~mask) = 0;
        correctedVideo(:,:,jj) = backSubtract;
%         backSubtract(head(2)-3:head(2)+3,head(1)-3:head(1)+3) = 100;
%         imagesc(backSubtract);caxis([0 100]);colormap('gray');
%         pause(1/20);
    end
    save(files(I(ii)).name,'correctedVideo','mmPerPixel',...
        'height','width','depthFrames','bcmAngle','headPosition',...
        'comPosition');
end