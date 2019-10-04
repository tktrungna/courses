function [ features ] = constructFeatures( imdb, param, image_id )
%CONSTRUCTFETURES from trained dictionary

image_name = load('../../CUB_200_2011/CUB_200_2011/images.txt');

% reading images id and content
images_path = '../../CUB_200_2011/CUB_200_2011/images.txt';
fid = fopen(images_path);
tmp = textscan(fid,'%s','Delimiter','\n');
tmp = tmp{:};
image = regexp(tmp, ' ', 'split');
image = vertcat(image{:});
fclose(fid);

numImages = size(image_id,2);
localFeatures = zeros(60000,128);
loc_stride = param.sift.stride;
loc_binSize = param.sift.binSize;

tag = num2str(param.sift.dictionarySize);
filename = strcat('../image_mat/bird_sift_features_',tag,'.mat');
phowOpts = {'Step', 3} ;
switch param.mode_test
        case 'train'
        conf.numSpatialX = [2 4] ;
        conf.numSpatialY = [2 4] ;
        ind = 0;
        for j=1:numImages
            imname = image(image_id(1,j),2)
            {j image_id(1,j) imname}
            %imfile = char(fullfile(imdb.imageDir,imname{:}));
            im = img_preprocess(imdb, image_id(1,j), param.is_resize, param.resize, 1, 1);
            %im = standarizeImage(im) ;
            im = im2single(im) ;
            width = size(im,2) ;
            height = size(im,1) ;
            numWords = size(imdb.dict, 1) ;
            [frames, descrs] = vl_phow(im, phowOpts{:}) ;
            vocab = double(imdb.dict);
            D = dist2(vocab, im2double(descrs'));
            [~, codeWord] = min(D, [], 1);
            wordHist = histc(codeWord, 1:param.sift.dictionarySize);
            
            %wordHist = extract_feature( imfile, param, imdb.dict);
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
        features = zeros(numImages,param.sift.dictionarySize);
        for j=1:numImages
            imname = image(image_id(1,j),2)
            {j image_id(1,j) imname}
            %imfile = char(fullfile(imdb.imageDir,imname{:}));
            im = img_preprocess(imdb, image_id(1,j), param.is_resize, param.resize, 1, 1);
            %im = standarizeImage(im) ;
            im = im2single(im) ;
            width = size(im,2) ;
            height = size(im,1) ;
            numWords = size(imdb.dict, 1) ;
            [frames, descrs] = vl_phow(im, phowOpts{:}) ;
            vocab = imdb.dict';
            [drop, binsa] = min(vl_alldist(vocab, single(descrs)), [], 1) ;
%             for i = 1:length(conf.numSpatialX)
%               binsx = vl_binsearch(linspace(1,width,conf.numSpatialX(i)+1), frames(1,:)) ;
%               binsy = vl_binsearch(linspace(1,height,conf.numSpatialY(i)+1), frames(2,:)) ;
% 
%               % combined quantization
%               bins = sub2ind([conf.numSpatialY(i), conf.numSpatialX(i), numWords], ...
%                              binsy,binsx,binsa) ;
%               hist1 = zeros(conf.numSpatialY(i) * conf.numSpatialX(i) * numWords, 1) ;
%               hist1 = vl_binsum(hist1, ones(size(bins)), bins) ;
%               hists{i} = single(hist1 / sum(hist1)) ;
%             end
%             hist1 = cat(1,hists{:}) ;
%             hist1 = hist1/sum(hist1) ;
%             
            wordHist = histc(binsa, 1:param.sift.dictionarySize);
            ind = ind + 1;
            %features(ind,:) = hist1;
            features(ind,:) = wordHist;
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