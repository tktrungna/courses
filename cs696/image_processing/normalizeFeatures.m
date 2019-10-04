function features = normalizeFeatures(features)
% NORMALIZEFEATURES normalizes the features.
%   FEATURES = NORMALIZEDFEATURES(FEATURES) computes the normalized version
%   of the features using various norms. For example if the l2 norm of the
%   features are used, each column is of unit length.

% Implement this!
%features = [1 2;3 4;5 6];
for i=1:size(features,2)
    features(:,i) = features(:,i)/sum(abs(features(:,i)));
end
