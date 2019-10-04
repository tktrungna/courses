function showConfusion(trueLabels, predLabels, className)
% SHOWCONFUSION draws the confusion matrix.
%   SHOWCONFUSION(TRUELABELS, PREDLABELS, CLASSNAMES) shows the confusion
%   matrix. Each rows correspond to true labels and columns correspond to
%   predictions. Thus entry (i,j) in the table are items of class i
%   classified as class j. Thus the total correctly classified items is
%   equal to the sum of the diagonals. Errors are off diagonal.
%
% This code is part of:
%
%   CMPSCI 670: Computer Vision, Fall 2014
%   University of Massachusetts, Amherst
%   Instructor: Subhransu Maji
%
%   Homework 5: Recognition

fprintf('\nConfusion matrix:\n');

fprintf(' \t');
for i = 1:length(className)
    fprintf('%s\t', className{i});
end
fprintf('\n');

for i = 1:length(className)
    fprintf(' %s\t', className{i});    
    for j = 1:length(className), 
        count = sum(trueLabels == i & predLabels == j);
        fprintf('%d\t', count);
    end
    fprintf('\n');
end

fprintf('\n');

fprintf('Total correct: %i/%i\n', sum(trueLabels == predLabels), length(trueLabels));

