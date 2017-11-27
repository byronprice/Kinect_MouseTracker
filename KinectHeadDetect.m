% KinectHeadDetect.m

% work in progress

mouseNum = '04051';Date = 20171123;
files = dir(sprintf('mouse%s-*_%d.mat',mouseNum,Date));

% sometimes the files don't load in the correct order ... rearrange them
fileIDs = zeros(length(files),1);
for ii=1:length(files)
    temp1 = regexp(files(ii).name,'-');
    temp2 = regexp(files(ii).name,'_');
    fileIDs(ii) = str2double(files(ii).name(temp1+1:temp2-1));
end

[~,I] = sort(fileIDs);

reduceY = 50;reduceX = 90;padSize = max(reduceX,reduceY)+5;

se = strel('disk',5);
conn = 8;
for ii=1:length(files)
    load(files(I(ii)).name,'correctedVideo','mmPerPixel','height','width','depthFrames');
    [height,width,numIms] = size(correctedVideo);
    
    rotatedVideo = zeros(reduceY+1,reduceX+1,numIms);
    headPosition = zeros(numIms,2);
    comPosition = zeros(numIms,2);
    bcmAngle = zeros(numIms,1);
    
    if ii==1
        start = 2;
        figure;
        imagesc(correctedVideo(:,:,1));
        title('CLICK ON THE TIP OF THE NOSE');
        [headX,headY] = getpts;
        headPosition(1,:) = [headX,headY];
        
        backSubtract = correctedVideo(:,:,1);
        
        mask = backSubtract>0;
        
%         mask = imopen(mask,se);
% 
%         backSubtract(~mask) = 0;
        
        [r,c] = find(mask~=0);
        cloud = [c,r];
        com_body = [mean(cloud(:,1)),mean(cloud(:,2))];
        
        bodyX = com_body(1);bodyY = com_body(2);
        
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
        
        C = padarray(backSubtract,[padSize padSize],0);
        newC = C(round(com_body(2))+padSize-reduceY/2:round(com_body(2))+padSize+reduceY/2,...
            round(com_body(1))+padSize-reduceX/2:round(com_body(1))+padSize+reduceX/2);
        rotateIm = imrotate(newC,-(360-bcmAngle(1)*180/pi),'nearest','crop');
    
        rotatedVideo(:,:,1) = rotateIm;
    else
        start = 1;
    end
    
    for jj=start:numIms
        backSubtract = correctedVideo(:,:,jj);
        
        mask = backSubtract>0;
        
%         mask = imopen(mask,se);
% 
%         backSubtract(~mask) = 0;
        
        [r,c] = find(mask~=0);
        cloud = [c,r];
        com_body = [mean(cloud(:,1)),mean(cloud(:,2))];
        
        [eigenvectors,eigenvalues] = eigs(cov(cloud),2);
        
        % the estimate of the head is basically 2 standard deviations away
        % from the center of the mass, in the direction opposite the tail
        s1 = 2*sqrt(eigenvalues(1,1));
        
        head1 = [com_body(1)+eigenvectors(1,1)*s1,com_body(2)+eigenvectors(2,1)*s1];
        
        % make sure the estimate actually falls on the body of the mouse
        [~,ind] = min(abs(head1(1)-cloud(:,1)));
        head1(1) = cloud(ind,1);
        [~,ind] = min(abs(head1(2)-cloud(:,2)));
        head1(2) = cloud(ind,2);
        
        % tempeig = eigenvectors(:,2)./norm(eigenvectors(:,2));
        tempX = head1(1)-com_body(1);
        tempY = head1(2)-com_body(2);
        bcmAngle1 = atan(tempY/tempX);
        if tempX > 0 && tempY > 0
        elseif tempX > 0 && tempY < 0
        elseif tempX < 0 && tempY > 0
            bcmAngle1 = bcmAngle1+pi;
        elseif tempX < 0 && tempY < 0
            bcmAngle1 = bcmAngle1+pi;
        end
        
        difference1 = abs(angdiff(bcmAngle1,bcmAngle(jj-1)));
        
        head2 = [com_body(1)-eigenvectors(1,1)*s1,com_body(2)-eigenvectors(2,1)*s1];
        
        % make sure the estimate actually falls on the body of the mouse
        [~,ind] = min(abs(head2(1)-cloud(:,1)));
        head2(1) = cloud(ind,1);
        [~,ind] = min(abs(head2(2)-cloud(:,2)));
        head2(2) = cloud(ind,2);
        
        % tempeig = eigenvectors(:,2)./norm(eigenvectors(:,2));
        tempX = head2(1)-com_body(1);
        tempY = head2(2)-com_body(2);
        bcmAngle2 = atan(tempY/tempX);
        if tempX > 0 && tempY > 0
        elseif tempX > 0 && tempY < 0
        elseif tempX < 0 && tempY > 0
            bcmAngle2 = bcmAngle2+pi;
        elseif tempX < 0 && tempY < 0
            bcmAngle2 = bcmAngle2+pi;
        end
        
        difference2 = abs(angdiff(bcmAngle2,bcmAngle(jj-1)));
        
        if difference1<difference2
            headPosition(jj,:) = [head1(1),head1(2)];
            bcmAngle(jj) = bcmAngle1;
            head = head1;
        elseif difference2<difference1
            headPosition(jj,:) = [head2(1),head2(2)];
            bcmAngle(jj) = bcmAngle2;
            head = head2;
        end
        
        comPosition(jj,:) = [com_body(1),com_body(2)];
        
        C = padarray(backSubtract,[padSize padSize],0);
        newC = C(round(com_body(2))+padSize-reduceY/2:round(com_body(2))+padSize+reduceY/2,...
            round(com_body(1))+padSize-reduceX/2:round(com_body(1))+padSize+reduceX/2);
        rotateIm = imrotate(newC,-(360-bcmAngle(jj)*180/pi),'nearest','crop');
        rotatedVideo(:,:,jj) = rotateIm;
%         backSubtract(head(2)-3:head(2)+3,head(1)-3:head(1)+3) = 100;
%         imagesc(backSubtract);caxis([0 100]);colormap('gray');
%         pause(1/20);
    end
    save(files(I(ii)).name,'correctedVideo','mmPerPixel',...
        'height','width','depthFrames','bcmAngle','headPosition',...
        'comPosition','rotatedVideo');
end
