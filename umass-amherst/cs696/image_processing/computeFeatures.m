function [features, dict] = computeFeatures(imdb, param)

switch param.feature
    case 'tinyimage'
        features = tinyimageFeatures(imdb, param);
        dict = [];
    case 'gist'
        features = gistFeatures(imdb, param);
        dict = [];
    case 'bow-sift'
        [features, dict] = bowFeaturesSIFT(imdb, param);
    case 'bow-patches'
        [features, dict] = bowFeaturesPatches(imdb, param);
    otherwise
        disp('warning: using random features?');
        features = randomFeatures(imdb, param);
        dict = [];
end
fprintf('Computed %i %s features.\n', size(features, 2), param.feature);

%--------------------------------------------------------------------------
%                                                           random features
%--------------------------------------------------------------------------
function features = randomFeatures(imdb, param)
numImages = length(imdb.images.name);
features = rand(3, numImages);

%--------------------------------------------------------------------------
%                                                       tiny image features
%--------------------------------------------------------------------------
function features = tinyimageFeatures(imdb, param)
% Compute grayscale features by resizing the images into a pathDim x patchDim 
% patch and resizing the image into a vector.

% Implement this
numImages = length(imdb.images.name);
features = [];%= zeros(param.tinyimage.patchDim^2, numImages);
for i=1:numImages
    imname = imdb.images.name(i);
    imfile = char(fullfile(imdb.imageDir,imname));
    im = imread(imfile);
    im = im2double(im);
    im = imresize(im, [param.tinyimage.patchDim param.tinyimage.patchDim]);
    im = reshape(im,1,[]);
    features = [features; im];
end
features = features';

%--------------------------------------------------------------------------
%                                                   gist feature descriptor
%--------------------------------------------------------------------------
function features = gistFeatures(imdb, param)
% 
% Optionally implement this


%--------------------------------------------------------------------------
%                                                   bag of words model with 
%                                                   dense local pathces
%--------------------------------------------------------------------------
function [features, dict] = bowFeaturesPatches(imdb, param)

% STEP 1: Write a function that extracts dense grayscale patches from an image
% STEP 2: Learn a dictionary
%           -- sample many desriptors (~10k) from train+val images
%           -- learn a dictionary using k-means
% STEP 3: Loop over all the images in imdb.images.names and extract
%         features (same as step 1) and assign them to dictionary items.
%         Build global histograms over these.
%
% Some useful code snippets:
%
%   trainValId = find(ismember(imdb.images.imageSet, [1 2]));
%   testId = find(ismember(imdb.images.imageSet, 3));
%  
%   D = dist2(dict, localFeatures); % compute all pair distances 
%   [~, codeWord] = min(D, [], 1); % compute codeword assignment
%   NOTE: make sure the dimensions of dict and localFeatures are correct.
%
%   wordHist = histc(codeWord, 1:dictionarySize); % build histogram

% Implement this
retrain = 0;
redict = 0;
refeature= 0;
%load features_trained
numImages = length(imdb.images.name);
loc_stride = param.patches.stride;
loc_radius = param.patches.radius;
localFeatures = zeros(100000,(2*loc_radius+1)*(2*loc_radius+1));
if retrain==0
trainValId = find(ismember(imdb.images.imageSet, [1 2]));
%trainValId = datasample(trainValId,50);
numPatch=0;
for i=1:size(trainValId,1)
    imname = imdb.images.name(trainValId(i,1))
    imfile = char(fullfile(imdb.imageDir,imname));
    im = imread(imfile);
    im = im2double(im);
    im = rgb2gray(im);
    for u=loc_stride:loc_stride:size(im,1)-loc_stride
        for v=loc_stride:loc_stride:size(im,2)-loc_stride
            sample = im(u-loc_radius:u+loc_radius,v-loc_radius:v+loc_radius);
            sample = reshape(sample,1,[]);
            numPatch = numPatch + 1;
            localFeatures(numPatch,:) = sample;
        end
    end
end
localFeatures = localFeatures(1:numPatch,:);
save('patch_features_train.mat','localFeatures');
else
    localFeatures = importdata('patch_features_train.mat');
end
if redict == 0
dict_train = datasample(localFeatures,param.patches.dictionarySize*50);
%dict_train = localFeatures;
[idx, dict]= kmeans(dict_train,param.patches.dictionarySize, ...
    'EmptyAction','drop', 'MaxIter',500);

save('patch_dict.mat','dict');
else
    %dict = importdata('dict_zarrin.mat');
    dict = importdata('patch_dict.mat');
    %dict = importdata('bak_8_12/patch_dict.mat');
end
if refeature==1
    features = importdata('patch_features.mat');
    return
end
features = [];
%trainValId = find(ismember(imdb.images.imageSet, [1 2]));

%feature = zeros(100000,(2*loc_radius+1)*(2*loc_radius+1));
for i=1:numImages
    feature = zeros(50000,(2*loc_radius+1)*(2*loc_radius+1));
    imname = imdb.images.name(i);
    imfile = char(fullfile(imdb.imageDir,imname));
    im = imread(imfile);
    im = im2double(im);
    im = rgb2gray(im);
    numPatch = 0;
    for u=loc_stride:loc_stride:size(im,1)-loc_stride
        for v=loc_stride:loc_stride:size(im,2)-loc_stride
            sample = im(u-loc_radius:u+loc_radius,v-loc_radius:v+loc_radius);
            sample = reshape(sample,1,[]);
            numPatch = numPatch + 1;
            feature(numPatch,:) = sample;
        end
    end
    feature = feature(1:numPatch,:);
    size_feature = size(feature);
    D = dist2(dict, feature);
    [~, codeWord] = min(D, [], 1);
    wordHist = histc(codeWord, 1:param.patches.dictionarySize);
    features = [features; wordHist];
    size_features = size(features);
end
features = features';
save('patch_features.mat','features');

%--------------------------------------------------------------------------
%                                             bag of words model with dense
%                                             SIFT descriptors
%--------------------------------------------------------------------------
function [features, dict] = bowFeaturesSIFT(imdb, param)

numImages = length(imdb.images.name);
localFeatures = zeros(60000,128);
loc_stride = param.sift.stride;
loc_binSize = param.sift.binSize;
switch param.mode_train
    case 'train'
        ind = 0;
        for i=1:numImages
            i
            imname = imdb.images.name(i);
            imfile = char(fullfile(imdb.imageDir,imname{:}));
            im = img_preprocess( imfile, param.is_resize, param.resize);
            circles = zeros(60000,3);
            indc = 0;
            for u=loc_stride:loc_stride:size(im,1)-loc_stride
                for v=loc_stride:loc_stride:size(im,2)-loc_stride
                    indc = indc + 1;
                    circles(indc,:) = [u v loc_binSize];
                end
            end
            circles = circles(1:indc,:);
            feature = find_sift(im, circles);
            add_ind = size(feature,1);
            localFeatures(ind+1:ind+add_ind,:) = feature;
            ind = ind+add_ind;
        end
        localFeatures = localFeatures(1:ind,:);
        save('bird_sift_features_train.mat','localFeatures','-v7.3');
	case 'load'
        localFeatures = importdata('bird_sift_features_train.mat');
    otherwise
        disp('Error option');
        %localFeatures = importdata('bird_sift_features_train.mat');
end

switch param.mode_dict
    case 'train'
        dict_train = datasample(localFeatures,param.sift.dictionarySize*100);
        [idx, dict]= kmeans(dict_train,param.sift.dictionarySize, ...
            'EmptyAction','drop', 'MaxIter',500);
        save('bird_sift_dict.mat','dict');
    case 'load'
        dict = importdata('bird_sift_dict.mat');
    otherwise
        disp('Error option');
        dict = importdata('bird_sift_dict.mat');
end

switch param.mode_test
    case 'train'
        features = zeros(numImages,param.patches.dictionarySize);
        ind = 0;
        for i=1:numImages
            i
            imname = imdb.images.name(i);
            imfile = char(fullfile(imdb.imageDir,imname{:}));
            wordHist = extract_feature( imfile, param, dict);
            ind = ind + 1;
            features(ind,:) = wordHist;
        end
        features = features(1:ind,:);
        features = features';
        size(features)
        save('bird_sift_features.mat','features');
    case 'load'
        features = importdata('bird_sift_features.mat');
    otherwise
        disp('Error option');
        features = importdata('sift_features.mat');
end
