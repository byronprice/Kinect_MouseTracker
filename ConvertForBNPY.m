% ConvertForBNPY.m

mouseNums = {'04051','04052','04053','04054'};

vids = 18;
numIms = 1000;
totalIms = numIms*vids;
D = 10;

load('PCA10_20171129.mat','Winv','mu','keptInds');
Date = 20171129;

for ii=1:4
    sequence = zeros(totalIms,D);
    count = 1;
    for jj=1:vids
        filename = sprintf('mouse%s-%d_%d.mat',mouseNums{ii},jj,Date);
        load(filename,'rotatedVideo');
        for kk=1:numIms
            temp = rotatedVideo(:,:,kk);
            [C,~] = wavedec2(temp,5,'db6');
            C = C';
            x = Winv*(C(keptInds)-mu);
            sequence(count,:) = x';
            count = count+1;
        end
    end
    savefilename = sprintf('mouse%s-sequence.mat',mouseNums{ii});
    
    dsFactor = 3;
    lenX = ceil(length(sequence(:,1))/dsFactor);
    X = zeros(lenX,D);
    for jj=1:D
        temp = sequence(:,jj);
        X(:,jj) = decimate(temp,dsFactor);
    end
    clear sequence;
    doc_range = round(linspace(0,lenX,2));
    % technically, doc_range should separate different videos from each
    %  other, so each animal would have it's own doc, and doc_range would
    %  be something like linspace(0,lenX*numAnimals,numAnimals+1);
    %  all of the videos would be smushed together in X
%     Xprev = zeros(size(X));Xprev(2:end,:) = X(1:end-1,:);Xprev(1,:) = X(1,:);
    save(savefilename,'X','doc_range');
%     fileID = fopen(savefilename,'w');
%     fprintf(fileID,'%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n','PC1','PC2','PC3',...
%         'PC4','PC5','PC6','PC7','PC8','PC9','PC10');
%     for jj=1:vids*numIms
%         fprintf(fileID,'%5.5f,%5.5f,%5.5f,%5.5f,%5.5f,%5.5f,%5.5f,%5.5f,%5.5f,%5.5f\n',sequence(jj,:));
%     end
%     fclose(fileID);
end