function [ wordHist ] = extract_feature( imfile, param, dict )
%EXTRACT_FEATURE Summary of this function goes here
%   Detailed explanation goes here
loc_stride = param.sift.stride;
loc_binSize = param.sift.binSize;
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
D = dist2(dict, feature);
[~, codeWord] = min(D, [], 1);
wordHist = histc(codeWord, 1:param.sift.dictionarySize);

end

