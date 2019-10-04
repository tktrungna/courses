function [ features ] = constructFeatures( imdb, param )
%CONSTRUCTFETURES from trained dictionary

numImages = length(imdb.images.name);
localFeatures = zeros(60000,128);
loc_stride = param.sift.stride;
loc_binSize = param.sift.binSize;

tag = num2str(param.sift.dictionarySize);
filename = strcat('../image_mat/bird_sift_features_',tag,'.mat');
phowOpts = {'Step', 3} ;
switch param.mode_test
    case 'train'
        features = zeros(numImages,param.sift.dictionarySize);
        ind = 0;
        for i=1:numImages
            k=i
            imname = imdb.images.name(i);
            imfile = char(fullfile(imdb.imageDir,imname{:}));
            wordHist = extract_feature( imfile, param, imdb.dict);
            ind = ind + 1;
            features(ind,:) = wordHist;
        end
        features = features(1:ind,:);
        features = features';
        size(features)
        save(filename,'features');
    case 'vlfeat_train'
        conf.numSpatialX = [2 4] ;
        conf.numSpatialY = [2 4] ;
        ind = 0;
        for i=1:numImages
            k=i
            imname = imdb.images.name(i);
            imfile = char(fullfile(imdb.imageDir,imname{:}));
            im = img_preprocess( imfile, param.is_resize, param.resize);
            im = standarizeImage(im) ;
            width = size(im,2) ;
            height = size(im,1) ;
            numWords = size(imdb.dict, 1) ;
            [frames, descrs] = vl_phow(im, phowOpts{:}) ;
            vocab = imdb.dict';
            [drop, binsa] = min(vl_alldist(vocab, single(descrs)), [], 1) ;
            for i = 1:length(conf.numSpatialX)
              binsx = vl_binsearch(linspace(1,width,conf.numSpatialX(i)+1), frames(1,:)) ;
              binsy = vl_binsearch(linspace(1,height,conf.numSpatialY(i)+1), frames(2,:)) ;

              % combined quantization
              bins = sub2ind([conf.numSpatialY(i), conf.numSpatialX(i), numWords], ...
                             binsy,binsx,binsa) ;
              hist1 = zeros(conf.numSpatialY(i) * conf.numSpatialX(i) * numWords, 1) ;
              hist1 = vl_binsum(hist1, ones(size(bins)), bins) ;
              hists{i} = single(hist1 / sum(hist1)) ;
            end
            hist1 = cat(1,hists{:}) ;
            hist1 = hist1 / sum(hist1) ;
            
            %wordHist = extract_feature( imfile, param, imdb.dict);
            ind = ind + 1;
            features(ind,:) = hist1;
        end
        save(filename,'features');
    case 'load'
        features = importdata(filename);
    case 'vlfeat_load'
        features = importdata(filename);
        features = features';
    otherwise
        disp('Error option');
        features = importdata(filename);
end

% -------------------------------------------------------------------------
function im = standarizeImage(im)
% -------------------------------------------------------------------------

im = im2single(im) ;
if size(im,1) > 480, im = imresize(im, [480 NaN]) ; end