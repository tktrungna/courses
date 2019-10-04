tic;
clear; close all;
dataDir = fullfile('.','data');
%imdb = readDataset(dataDir);


% Store ids for training, validation and test set of images
%trainSet = imdb.images.imageSet == 1;
%valSet   = imdb.images.imageSet == 2;
%testSet  = imdb.images.imageSet == 3;

% Set parameters for features, classifiers, etc.
clear param;

param.numOfSample = 10;
param.is_resize = 0; %not resize
param.resize = 100; % number of row of resized images


param.feature = 'bow-sift'; % or default, tinyimage, bow-patches, bow-sift (optionally gist)
param.classifier = 'svm'; % or svm 'knn'
param.knn.k = 3; % Number of neighbours for the kNN classifier
param.svm.lambda = 1; % lambda parameter (regularization SVM)
param.mode_train = 'train';%'load''train' % training again dataset or not
param.mode_dict = 'train';%'load' % training again dataset or not
param.mode_test = 'train';%'load' % training again dataset or not

% Tiny images paramters (param.feature = 'tinyimage')
param.tinyimage.patchDim = 4;

% Paramters for dense Patches features (param.feature = 'bow-patches')
param.patches.dictionarySize = 64;
param.patches.radius = 8;
param.patches.stride  = 12;

% Paramters for dense SIFT features (param.feature = 'bow-sift')
param.sift.dictionarySize = 64;
param.sift.binSize = 8;  % Size of the bin in terms of number of pixels in 
                         % the image. Recall that SIFT has 4x4=16 bins.
                        
param.sift.stride  = 12; % Spacing between succesive x (and y) coordinates 
                         % for sampling dense features.

param.sift.vlfeat = false; %

imdb = readCUB('../../../CUB_200_2011/CUB_200_2011/',param);

% Parameters for GIST features (param.feature = 'gist')
% Optionally specify parameters for GIST feature

%% Compute features and dictionary (for bag of words models)
[features, dict] = computeFeatures(imdb, param);
%[features, dict] = computeFeatures(imdb, param);

%% Normalize features (except for tiny image features)
if ~strcmp(param.feature, 'tinyimage')
    features = normalizeFeatures(features);
end

%% Visualize dictionary if using tiny patches with bag of words model
%  NOTE: For visualizing with SIFT you will have to keep track of the
%  patches that correspond to each SIFT descriptor. You could implement
%  this for extra credit
if strcmp(param.feature, 'bow-patches') 
    dictionaryPatches = reshape(dict', ...
        [(2*param.patches.radius+1)*ones(1, 2) 1 param.patches.dictionarySize]);
    montage(dictionaryPatches);
    title('Learned dictionary');
end


%% Train on 'train' and test on 'val'
% Use this mode for tuning your parameters
fprintf('\n====================================================\n')
fprintf('Experiment setup: trainSet = train, testSet = val\n');
classifier = trainClassifier(features, param);
[valPredictions, valScores] = makePredictions(features(:,valSet), classifier);
showConfusion(imdb.images.classId(valSet), valPredictions, imdb.meta.class);

%% Train on 'train' + 'val' and test on 'test'
% Once the optimal parameters are found run this only once. Avoid running
% on the test set multiple times to avoid overfitting to the test set. In
% reality for various benchmarks the labels for the test set are not
% released so you can't optimize your parameters on the test set. The
% labels are included here for convinience.
fprintf('\n====================================================\n')
fprintf('Experiment setup: trainSet = train+val, testSet = test\n');
classifier = trainClassifier(features(:, trainSet|valSet), ...
                    imdb.images.classId(trainSet|valSet), param);
[predictions, scores] = makePredictions(features(:,testSet), classifier);
showConfusion(imdb.images.classId(testSet), predictions, imdb.meta.class);

%% Lets analyze the test set and see what the mistakes the classifier makes
% We can do this only for linear SVMs which also return a score (a proxy
% for confidence of prediction)

if strcmp(classifier.type, 'svm');
    testSetClass = imdb.images.classId(testSet);
    testSetIds = find(testSet);
    catIds = find(testSetClass == 1);
    dogIds = find(testSetClass == 2);

    figure;
    % Most cat like cat
    subplot(2,2,1);
    [~,mostCatCat] = max(scores(catIds));
    im = imread(fullfile(imdb.imageDir, imdb.images.name{testSetIds(catIds(mostCatCat))}));
    imshow(im); axis image off;
    title('Most cat like cat','fontSize',16);
    
    % Most dog like cat
    subplot(2,2,2);
    [~,mostDogCat] = min(scores(catIds));
    im = imread(fullfile(imdb.imageDir, imdb.images.name{testSetIds(catIds(mostDogCat))}));
    imshow(im); axis image off;
    title('Most dog like cat','fontSize',16);
    
    % Most cat like dog
    subplot(2,2,3);
    [~,mostCatDog] = max(scores(dogIds));
    im = imread(fullfile(imdb.imageDir, imdb.images.name{testSetIds(dogIds(mostCatDog))}));
    imshow(im); axis image off;
    title('Most cat like dog','fontSize',16);
    
    % Most dog like dog
    subplot(2,2,4);
    [~,mostDogDog] = min(scores(dogIds));
    im = imread(fullfile(imdb.imageDir, imdb.images.name{testSetIds(dogIds(mostDogDog))}));
    imshow(im); axis image off;
    title('Most dog like dog','fontSize',16);
end
toc
