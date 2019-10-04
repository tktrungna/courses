function [ imdb, param ] = preData(  )
% Set parameters for features, classifiers, etc.
clear param;

param.numOfSample = 10;
param.is_resize = true; % resize original image or not
param.resize = 100; % number of row of resized images

param.feature = 'bow-sift'; % or default, tinyimage, bow-patches, bow-sift (optionally gist)
param.classifier = 'svm'; % or svm 'knn'
param.knn.k = 3; % Number of neighbours for the kNN classifier
param.svm.lambda = 1; % lambda parameter (regularization SVM)
param.mode_train = 'vlfeat_load';%'load''train''none' % training again dataset or not
param.mode_dict = 'vlfeat_load';%'load''train''none' % training again dataset or not
param.mode_test = 'vlfeat_load';%'load''train''none' % training again dataset or not

param.svm = 'vlfeat1'; % 'matlab; vlfeat'
% Paramters for dense SIFT features (param.feature = 'bow-sift')
param.sift.dictionarySize = 4096;
param.sift.binSize = 8;  % Size of the bin in terms of number of pixels in 
                         % the image. Recall that SIFT has 4x4=16 bins.                        
param.sift.stride  = 12; % Spacing between succesive x (and y) coordinates 
                         % for sampling dense features.
param.sift.vlfeat = false; %

imdb = readCUB('../../CUB_200_2011/CUB_200_2011/',param);

%% Compute features and dictionary (for bag of words models)
%imdb.dict = computeFeatures(imdb, param);
imdb.dict = constructDict(imdb, param);
