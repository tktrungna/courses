function [ dict ] = constructDict( imdb, param )

switch param.feature
    case 'bow-sift'
        [dict] = bowFeaturesSIFT(imdb, param);
    otherwise
        disp('warning: using random features?');
        dict = [];
end
%fprintf('Computed %i %s features.\n', size(features, 2), param.feature);

%--------------------------------------------------------------------------
%                                             bag of words model with dense
%                                             SIFT descriptors
%--------------------------------------------------------------------------
function [dict] = bowFeaturesSIFT(imdb, param)

numImages = length(imdb.images.all_imname);

rand_imgid = randperm(numImages);
rand_imgid = rand_imgid(:,1:2000); %select random image 2000 for trainning dict

localFeatures = zeros(60000,128);
loc_stride = param.sift.stride;
loc_binSize = param.sift.binSize;

tag = num2str(param.sift.dictionarySize);
sift_filename = strcat('../image_mat/bird_sift_',tag,'.mat');
phowOpts = {'Step', 3} ;
tic
switch param.mode_train
    case 'train'
        ind = 0;
        for i=1:numImages
            i
            imname = imdb.images.name(i);
            imfile = char(fullfile(imdb.imageDir,imname{:}));
            im = img_preprocess(imdb,imfile, param.is_resize, param.resize);
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
        %save('../image_mat/bird_sift_features_train.mat','localFeatures');
        save(sift_filename,'localFeatures');
    case 'vlfeat_train'
        descrs = {};
        for i=1:size(rand_imgid,2)
            vlfeat_train = i
            imgid = rand_imgid(1,i);
            im = img_preprocess(imdb,imgid, param.is_resize, param.resize, 1, 1);% TODO
            %im = standarizeImage(im) ;
            im = im2single(im) ;
            [drop, descrs{i}] = vl_phow(im, phowOpts{:}) ;
        end
        descrs = vl_colsubset(cat(2, descrs{:}), 10e4) ;
        descrs = single(descrs) ;
        save(sift_filename,'descrs');
	case 'load'
        if strcmpi(param.mode_dict,'train')
            %localFeatures = importdata('../text_processing/code_image/bird_sift_features_train.mat');
            localFeatures = importdata(sift_filename);
        end
    case 'vlfeat_load'
        descrs = importdata(sift_filename);
    otherwise
        disp('Error option');
end
toc
tag = num2str(param.sift.dictionarySize);
dictfilename = strcat('../image_mat/bird_sift_dict_',tag,'.mat');

%Training dictionary from extracted desciptor
switch param.mode_dict
    case 'train'
        dict_train = datasample(localFeatures,param.sift.dictionarySize*100);
        disp('begin kmeans');
        tic
        [centers, assignments] = vl_kmeans(dict_train', param.sift.dictionarySize);
        toc
        dict = centers';
        save(dictfilename,'dict');
    case 'vlfeat_train'
        disp('begin vl_kmeans');
        vocab = vl_kmeans(descrs, param.sift.dictionarySize ...
            , 'verbose', 'algorithm', 'elkan', 'MaxNumIterations', 50) ;
        dict = vocab';
        save(dictfilename,'dict');
    case 'load'
        dict = importdata(dictfilename);
    case 'vlfeat_load'
        dict = importdata(dictfilename);
    otherwise
        disp('Error option');
        dict = importdata(dictfilename);
end

% -------------------------------------------------------------------------
function im = standarizeImage(im)
% -------------------------------------------------------------------------

im = im2single(im) ;
if size(im,1) > 480, im = imresize(im, [480 NaN]) ; end
