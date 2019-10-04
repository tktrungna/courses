function imdb = readDataset(dataDir)
% READDATASET creates a structure describing the dataset
%   IMDB = READDATASET(DATADIR) reads the images and annotations in the
%   DATADIR into an IMDB structure. The IMDB structure contains the
%   following fields
%       IMDB.IMAGEDIR - directory where images reside
%       IMDB.IMAGES - a structure with the following subfields
%           IMAGES.NAME - names of images
%           IMAGES.CLASSID - class labels (1 = cat, 2 = dog)
%           IMAGES.IMAGESET - the subset it belons (1=train, 2=val, 3=test)
%       IMAGES.META - meta information such as mappings from classId to
%           class label and imageSet to imageSet labels.
%
% This code is part of:
%
%   CMPSCI 670: Computer Vision, Fall 2014
%   University of Massachusetts, Amherst
%   Instructor: Subhransu Maji
%
%   Homework 5: Recognition

imdb.imageDir = fullfile(dataDir, 'images');
[imageName, classId, imageSet] = textread(fullfile(dataDir,'labels.txt'),'%s %d %d');
imdb.images.name = imageName;
imdb.images.classId = classId;
imdb.images.imageSet = imageSet;
imdb.meta.class = {'Cats', 'Dogs'};
imdb.meta.imageSet = {'train', 'val', 'test'};
fprintf('Read dataset with %i images with %i cats and %i dogs.\n', ...
    length(imdb.images.name), sum(imdb.images.classId==1), sum(imdb.images.classId==2));
