function [predictions, scores] = makePredictions(features, classifier)
% MAKEPREDICTIONS on the new examples using learned classifier
%   [PREDICTIONS, SCORE] = MAKEPREDICTIONS(FEATURES, CLASSIFIER) makes
%   predicitons on the FEATURES by applying the CLASSIFIER and return
%   PREDICTIONS which are predicted class labels, and SCORES which are
%   confidences of the classifier. NOTE, scores are non-empty only for SVM
%   classifiers. 
%
%
% This code is part of:
%
%   CMPSCI 670: Computer Vision, Fall 2014
%   University of Massachusetts, Amherst
%   Instructor: Subhransu Maji
%
%   Homework 5: Recognition


switch classifier.type
    case 'knn'
        predictions = predictKNN(features, classifier);
        scores = []; %scores not defined for k-nn classifiers
    case 'svm'
        [predictions, scores] = predictSVM(features, classifier);
end
fprintf('Made predictions on %i features using %s classifier.\n', ...
                                        size(features,2), classifier.type);


%--------------------------------------------------------------------------
%                                     make predictions using kNN classifier
%--------------------------------------------------------------------------
function predictions = predictKNN(features, classifier)
numFeatures = size(features, 2);
predictions = zeros(numFeatures,1);
for i = 1:numFeatures, 
    delta = bsxfun(@minus, classifier.features, features(:,i));
    dist = sum(delta.^2, 1);
    [~,ord] = sort(dist,'ascend');
    predLabels = classifier.labels(ord(1:classifier.k));
    predictions(i) = mode(predLabels);
end

%--------------------------------------------------------------------------
%                                     make predictions using SVM classifier
%--------------------------------------------------------------------------
function [predictions, scores] = predictSVM(features, classifier)
scores = classifier.wts*features + classifier.bias;
numFeatures = size(features, 2);
predictions = zeros(numFeatures, 1);
predictions(scores >= 0) = 1; % positive class is cat = 1;
predictions(scores < 0) = 2;  % negative class is dog = 2;