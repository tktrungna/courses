function [ im ] = img_preprocess( imdb, imgid, is_resized, resize, is_cropped, is_merged )

% is_resized: resize image or not
% is_cropped: crop image based on bounding box or not
% is_merged: merge three channels RGB or not

imname = imdb.images.all_imname(imgid);
bounding = imdb.images.bounding(imgid,:);
imfile = char(fullfile(imdb.imageDir,imname{:}));

% reading original image
im = imread(imfile);
im = im2double(im);
% crop image
if is_cropped == 1
    im = im(bounding(1,3)+1:min(bounding(1,3)+bounding(1,5),size(im,1)),...
        bounding(1,2)+1:min(bounding(1,2)+bounding(1,4),size(im,2)),:);
end

if is_resized == 1
    scale = resize/(size(im,1)+0.0);
    im = imresize(im,scale);
end

tmp_im = [];
if is_merged == 1
    for i=1:size(im,3)
        tmp_im = [tmp_im im(:,:,i)];
    end
end
im = tmp_im;




