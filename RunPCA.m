Date = 20171129;
Animals = {'04051','04052','04053','04054'};

numAnimals = 4;
numFiles = 18;

DIM = [51,101];
[C,~]= wavedec2(zeros(DIM),5,'db6');
N = 20000;
fullData = zeros(length(C),N);

count = 1;
for ii=1:2000
    vidNum = random('Discrete Uniform',numFiles,[1,1]);
    anNum = random('Discrete Uniform',numAnimals,[1,1]);
    filename = sprintf('mouse%s-%d_%d.mat',Animals{anNum},vidNum,Date);
    load(filename,'rotatedVideo');
    
    frames = random('Discrete Uniform',1000,[10,1]);
    for jj=frames'
       temp = rotatedVideo(:,:,jj);
       [C,~] = wavedec2(temp,5,'db6');
       fullData(:,count) = C(:);
       count = count+1;
    end
end
disp(count);
keptInds = var(fullData,[],2)>1;

fullData = fullData(keptInds,:);
[d,N] = size(fullData);
S = cov(fullData');
[V,D] = eig(S);

mu = mean(fullData,2);
fullData = fullData-repmat(mu,[1,N]);

q = 50;
start = d-q+1;
eigenvals = diag(D);
meanEig = mean(eigenvals(1:start-1));
W = V(:,start:end)*sqrtm(D(start:end,start:end)-meanEig.*eye(q));
W = fliplr(W);

Winv = pinv(W);

save('PCA50_20171129.mat','Winv','mu','q','W','keptInds');


q = 10;
start = d-q+1;
eigenvals = diag(D);
meanEig = mean(eigenvals(1:start-1));
W = V(:,start:end)*sqrtm(D(start:end,start:end)-meanEig.*eye(q));
W = fliplr(W);

Winv = pinv(W);

save('PCA10_20171129.mat','Winv','mu','q','W','keptInds');