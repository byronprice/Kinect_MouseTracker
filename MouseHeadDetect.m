% MouseHeadDetect.m
% gather the files
mouseNum = 45180;
files = dir(sprintf('mouse%d-*_bw.mat',mouseNum));

% sometimes the files don't load in the correct order ... rearrange them
fileIDs = zeros(length(files),1);
for ii=1:length(files)
    temp1 = regexp(files(ii).name,'-');
    temp2 = regexp(files(ii).name,'_');
    fileIDs(ii) = str2double(files(ii).name(temp1+1:temp2-1));
end

[~,I] = sort(fileIDs);

freeParam_Illumination = -80; % -80, difference between mouse and background
freeParam_MouseSize = 400; % 400, minimum mouse size in pixels
freeParam_TailSize = 5; % 5, minimum tail size in pixels
freeParam_Convolution = 45; % 45, for convolution with 15x15 kernel

% load background image
backgroundFile = dir(sprintf('mouse%d*-Background.mat',mouseNum));
load(backgroundFile(1).name,'background');

% very simple, non-optimal Kalman filter, just a weighted average of the previous
% position and the tail position estimated by the algorithm,
%  initialized with the tail position in the first frame
%  you ought to be able to take the first few measurements
%   without the Kalman filter and then bring it online
[width,height] = size(background);
M = 1;C = 2.0;MC = 1./(M+C);        
tailPosition = [width/2,height/2];
prevPosition = [width/2,height/2];
velocity = tailPosition-prevPosition;

clear width height;

h = ones(15,15);
conn = 8;
for ii=1:length(files)
   load(files(I(ii)).name);
   bwVideo = double(bwVideo);
   [width,height,numIms] = size(bwVideo);
   tic;
   for jj=1:numIms
%       tic;
      % subtract background
      color_im = bwVideo(:,:,jj)-background;
      
      % remove junk left after background subtraction
      %  and any shadows, etc. ... this threshold is somewhat arbitrary but
      %  should work if the image has luminance values from 0 (black) to 255
      %  (white) and the black mouse is on a white background ... will
      %  obviously depend on the type of illumination, so we could
      %  implement a sliding threshold or just calibrate before acquisition
      color_im(color_im>freeParam_Illumination) = 0;color_im = abs(color_im); 
      
%       % ignore area outside of mouse's box (my hand was moving in some of
%       % the images so that wouldn't get background subtracted
%       color_im(1:212,:) = 0;
%       color_im(:,1:52) = 0;
%       color_im(530:end,:) = 0;

%       CC = bwconncomp(color_im);
%       numPixels = cellfun(@numel,CC.PixelIdxList);
%       [~,idx] = max(numPixels);
%       color_im(CC.PixelIdxList{idx}) = -10;
%       imagesc(color_im);pause(1/60);
      
      BW = color_im~=0;
%       [PixelIdxList,~] = bwconncomp_2d(BW, conn);
      CC = bwconncomp(BW,conn);
      area = cellfun(@numel, CC.PixelIdxList);

      idxToKeep = CC.PixelIdxList(area >= freeParam_MouseSize);
      idxToKeep = vertcat(idxToKeep{:});

      mask = false(size(color_im));
      mask(idxToKeep) = true;

      % eliminate anything left in the image that is small
%       mask = bwareaopen(color_im,freeParam_MouseSize);
      color_im(~mask) = 0;

      % find the tail using a convolution technique,
      %  to see how it works, imagesc the convIm
      color_binary = double(color_im>0);
      row = sum(color_binary,1);
      column = sum(color_binary,2);
      
      top = find(column>0,1,'first');
      bottom = find(column>0,1,'last');
      left = find(row>0,1,'first');
      right = find(row>0,1,'last');

      convIm = filter2(h,color_binary(top:bottom,left:right),'same');
      convIm(color_binary(top:bottom,left:right)==0) = 0;
      tail_mask = convIm; % Get the mask for the tail
      
      tail_mask(convIm>freeParam_Convolution) = 0; %Thresholding ... the value of 70 is arbitrary 
      %  and will epend on the distance to the camera but should be consistent
      %  for each distance
     
      temp = tail_mask>0;
%       temp = bwareaopen(temp,freeParam_TailSize);
      CC = bwconncomp(temp, conn);
      area = cellfun(@numel, CC.PixelIdxList);

      idxToKeep = CC.PixelIdxList(area >= freeParam_TailSize);
      idxToKeep = vertcat(idxToKeep{:});

      temp = false(size(temp));
      temp(idxToKeep) = true;
      tail_mask(temp==0) = 0;

      % imagesc(tail_mask)
      % watch this to observe just the tail, the crux of the whole
      % algorithm is about finding the tail ... if you lose the tail, then 
      % it's going to fail (which is why the kalman filter should help)
      
      % weighted average of measured position and estimate of the current
      %  position based on the previous position and the velocity
      if sum(tail_mask(:)) == 0
          tail_x = tailPosition(1)+velocity;
          tail_y = tailPosition(2)+velocity;
      else
        [~, idx] = max(tail_mask(:));
        [tail_y, tail_x] = ind2sub(size(tail_mask),idx);
        tail_y = tail_y+top-1;
        tail_x = tail_x+left-1;
      end
%       vecError = [vecError,sum(abs(tailPosition+velocity-[tail_x,tail_y]))];
%       prevError = [prevError,sum(abs(tailPosition-[tail_x,tail_y]))];
      tailPosition = (C.*(tailPosition+velocity)+[tail_x,tail_y]).*MC;
      velocity = tailPosition-prevPosition;
      prevPosition = tailPosition;
      
      %Remove tail from the image for PCA
      body_image = color_im;
      temp = zeros(size(body_image));
      temp(top:bottom,left:right) = tail_mask;
      body_image(temp>0) = 0;
      
      % make a point cloud to find the principal axes of the mouse's body
      [r,c] = find(body_image~=0);
      cloud = [c,r]; %Make point cloud of these pixels
      
      % PCA ... eigenvectors determine direction of body axis
%       cloud_covariance = cov(cloud);
      [eigenvectors,eigenvalues] = eigs(cov(cloud),2);
      
      % get center of mass
      com_body = [mean(cloud(:,1)),mean(cloud(:,2))];
      
      % Make sure vector is pointing towards head (from base of tail to center
      % of body mass)
      dotproduct = sum(((com_body-[tailPosition(1), tailPosition(2)])/norm(com_body-[tailPosition(1), tailPosition(2)]))'.*(eigenvectors(:,2)/norm(eigenvectors(:,2))));
      if (dotproduct<0)
          eigenvectors(:,2) = -eigenvectors(:,2);
      end
      
      % find the head position
      
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
      
      
%       toc;
      
      % display the image with the head position marked ... remove this
      % part and the code will run much faster
      bwVideo(max(head(2)-3,1):min(head(2)+3,width),max(head(1)-3,1):min(head(1)+3,height),jj) = 255;
      imagesc(bwVideo(:,:,jj));colormap('bone');
      pause(0.01);
   end
   % figure out on average how much time required for processing per frame
   %  y gives the time in seconds, them multiply by 1000 to get to
   %  milliseconds and divide by the number of images processed, in this
   %  case 100
   y = toc;
   fprintf('Run-time per frame: %3.2f ms\n',y*1000/numIms);
end